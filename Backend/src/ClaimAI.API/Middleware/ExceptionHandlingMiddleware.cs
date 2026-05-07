using System.Net;
using System.Text.Json;
using ClaimAI.Application.DTOs.Common;

namespace ClaimAI.API.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred: {Message}", ex.Message);
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

        // TEMP: surface the real exception in the response so we can diagnose
        // a 500 happening only on the deployed server. Revert to the generic
        // message once the root cause is found.
        var details = new List<string>
        {
            $"{exception.GetType().FullName}: {exception.Message}"
        };

        var inner = exception.InnerException;
        while (inner is not null)
        {
            details.Add($"-> {inner.GetType().FullName}: {inner.Message}");
            inner = inner.InnerException;
        }

        if (!string.IsNullOrEmpty(exception.StackTrace))
            details.Add(exception.StackTrace);

        var response = ApiResponse<object>.FailResponse(details, context.Response.StatusCode);

        var jsonOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        await context.Response.WriteAsync(JsonSerializer.Serialize(response, jsonOptions));
    }
}
