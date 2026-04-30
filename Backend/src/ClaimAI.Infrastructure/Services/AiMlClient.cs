using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using ClaimAI.Application.DTOs.AiMl;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Infrastructure.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace ClaimAI.Infrastructure.Services;

/// <summary>
/// Typed HttpClient targeting the external AI/ML host. The agent uses a
/// short-lived bearer token issued by <c>POST /auth/login</c>; we cache it
/// in-process and silently re-login on a 401.
/// </summary>
public class AiMlClient : IAiMlClient
{
    private readonly HttpClient _http;
    private readonly AiMlOptions _options;
    private readonly ILogger<AiMlClient> _logger;

    private static readonly SemaphoreSlim _loginLock = new(1, 1);
    private static string? _cachedToken;
    private static DateTime _cachedTokenExpiresAt;

    private static readonly JsonSerializerOptions _json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        DictionaryKeyPolicy = JsonNamingPolicy.SnakeCaseLower,
    };

    public AiMlClient(HttpClient http, IOptions<AiMlOptions> options, ILogger<AiMlClient> logger)
    {
        _http = http;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<Result<TemplateConfigResponseDto>> SyncTemplateConfigAsync(
        TemplateConfigRequestDto request, CancellationToken cancellationToken = default)
    {
        try
        {
            // Step 1 — make sure we have a fresh token.
            var token = await GetTokenAsync(forceRefresh: false, cancellationToken);

            // Step 2 — POST /config with the bearer token.
            // The AI/ML server expects the payload wrapped under a "template" field.
            var envelope = new { template = request };
            var requestJson = JsonSerializer.Serialize(envelope, _json);
            _logger.LogInformation(
                "→ AI/ML POST {BaseUrl}{Path} bearer={TokenPreview} body: {Body}",
                _http.BaseAddress, _options.ConfigPath, Preview(token), requestJson);

            var response = await SendAsync(_options.ConfigPath, envelope, token, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);

            _logger.LogInformation(
                "← AI/ML POST {Path} {Status} body: {Body}",
                _options.ConfigPath, (int)response.StatusCode, body);

            // Retry once on 401 with a freshly-issued token.
            if (response.StatusCode == HttpStatusCode.Unauthorized)
            {
                _logger.LogWarning(
                    "AI/ML /config returned 401 with bearer={TokenPreview}; forcing re-login and retrying once.",
                    Preview(token));
                response.Dispose();

                token = await GetTokenAsync(forceRefresh: true, cancellationToken);

                _logger.LogInformation(
                    "→ AI/ML POST {Path} (retry) bearer={TokenPreview}",
                    _options.ConfigPath, Preview(token));

                response = await SendAsync(_options.ConfigPath, envelope, token, cancellationToken);
                body = await response.Content.ReadAsStringAsync(cancellationToken);

                _logger.LogInformation(
                    "← AI/ML POST {Path} (retry) {Status} body: {Body}",
                    _options.ConfigPath, (int)response.StatusCode, body);
            }

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("AI/ML /config returned {Status}: {Body}", (int)response.StatusCode, body);
                return Result<TemplateConfigResponseDto>.Failure(
                    $"AI/ML sync failed ({(int)response.StatusCode}): {body}");
            }

            return Result<TemplateConfigResponseDto>.Success(new TemplateConfigResponseDto
            {
                StatusCode = (int)response.StatusCode,
                RawBody = body,
            }, "Template synced to AI/ML.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to sync template to AI/ML");
            return Result<TemplateConfigResponseDto>.Failure($"AI/ML sync error: {ex.Message}");
        }
    }

    private async Task<HttpResponseMessage> SendAsync<T>(
        string path, T body, string token, CancellationToken cancellationToken)
    {
        using var content = JsonContent.Create(body, options: _json);
        using var request = new HttpRequestMessage(HttpMethod.Post, path) { Content = content };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await _http.SendAsync(request, cancellationToken);
    }

    private async Task<string> GetTokenAsync(bool forceRefresh, CancellationToken cancellationToken)
    {
        if (!forceRefresh
            && _cachedToken is not null
            && DateTime.UtcNow < _cachedTokenExpiresAt.AddMinutes(-1))
        {
            _logger.LogDebug(
                "AI/ML using cached token {TokenPreview}, expires {Expires:O}",
                Preview(_cachedToken), _cachedTokenExpiresAt);
            return _cachedToken;
        }

        await _loginLock.WaitAsync(cancellationToken);
        try
        {
            if (!forceRefresh
                && _cachedToken is not null
                && DateTime.UtcNow < _cachedTokenExpiresAt.AddMinutes(-1))
            {
                return _cachedToken;
            }

            _logger.LogInformation(
                "→ AI/ML POST {BaseUrl}{Path} (login as {Username})",
                _http.BaseAddress, _options.LoginPath, _options.Username);

            var loginPayload = new { username = _options.Username, password = _options.Password };
            using var loginResponse = await _http.PostAsJsonAsync(
                _options.LoginPath, loginPayload, _json, cancellationToken);

            var loginBody = await loginResponse.Content.ReadAsStringAsync(cancellationToken);

            _logger.LogInformation(
                "← AI/ML POST {Path} {Status} body: {Body}",
                _options.LoginPath, (int)loginResponse.StatusCode, loginBody);

            if (!loginResponse.IsSuccessStatusCode)
                throw new InvalidOperationException(
                    $"AI/ML login failed ({(int)loginResponse.StatusCode}): {loginBody}");

            // Parse {"access_token":"..."} (snake_case) tolerantly.
            var accessToken = ExtractAccessToken(loginBody);
            if (string.IsNullOrWhiteSpace(accessToken))
                throw new InvalidOperationException(
                    $"AI/ML login response did not contain an access token. Body: {loginBody}");

            _cachedToken = accessToken;
            _cachedTokenExpiresAt = TryReadJwtExpiry(accessToken)
                ?? DateTime.UtcNow.AddMinutes(55);

            _logger.LogInformation(
                "AI/ML login OK; token={TokenPreview}, expires {Expires:O}",
                Preview(_cachedToken), _cachedTokenExpiresAt);

            return _cachedToken;
        }
        finally
        {
            _loginLock.Release();
        }
    }

    private static string? ExtractAccessToken(string body)
    {
        try
        {
            using var doc = JsonDocument.Parse(body);
            var root = doc.RootElement;
            foreach (var name in new[] { "access_token", "accessToken", "token", "id_token" })
            {
                if (root.TryGetProperty(name, out var prop) && prop.ValueKind == JsonValueKind.String)
                    return prop.GetString();
            }
        }
        catch
        {
            // Fall through.
        }
        return null;
    }

    private static string Preview(string? token)
    {
        if (string.IsNullOrEmpty(token)) return "<empty>";
        return token.Length <= 16 ? token : $"{token[..12]}…(len={token.Length})";
    }

    private static DateTime? TryReadJwtExpiry(string token)
    {
        try
        {
            var parts = token.Split('.');
            if (parts.Length != 3) return null;

            var payload = parts[1].Replace('-', '+').Replace('_', '/');
            switch (payload.Length % 4)
            {
                case 2: payload += "=="; break;
                case 3: payload += "="; break;
            }

            var bytes = Convert.FromBase64String(payload);
            using var doc = JsonDocument.Parse(bytes);
            if (doc.RootElement.TryGetProperty("exp", out var expProp) && expProp.TryGetInt64(out var exp))
                return DateTimeOffset.FromUnixTimeSeconds(exp).UtcDateTime;
        }
        catch
        {
            // Fall through to caller default.
        }
        return null;
    }

    private sealed class AiMlLoginResponse
    {
        public string AccessToken { get; set; } = string.Empty;
    }
}
