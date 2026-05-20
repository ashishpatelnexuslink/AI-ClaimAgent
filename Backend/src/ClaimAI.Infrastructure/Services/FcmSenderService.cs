using ClaimAI.Application.Interfaces;
using FirebaseAdmin.Messaging;
using Microsoft.Extensions.Logging;

namespace ClaimAI.Infrastructure.Services;

public class FcmSenderService : IFcmSender
{
    private readonly ILogger<FcmSenderService> _logger;

    public FcmSenderService(ILogger<FcmSenderService> logger)
    {
        _logger = logger;
    }

    public async Task<FcmSendResult> SendToTokensAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        IDictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        var tokenList = tokens.Where(t => !string.IsNullOrWhiteSpace(t)).Distinct().ToList();
        var result = new FcmSendResult();

        if (tokenList.Count == 0)
            return result;

        var message = new MulticastMessage
        {
            Tokens = tokenList,
            Notification = new Notification
            {
                Title = title,
                Body = body,
            },
            Data = data as IReadOnlyDictionary<string, string> ?? data?.ToDictionary(kv => kv.Key, kv => kv.Value),
        };

        try
        {
            var response = await FirebaseMessaging.DefaultInstance
                .SendEachForMulticastAsync(message, cancellationToken);

            result.SuccessCount = response.SuccessCount;
            result.FailureCount = response.FailureCount;

            for (var i = 0; i < response.Responses.Count; i++)
            {
                var resp = response.Responses[i];
                if (resp.IsSuccess) continue;

                var errCode = resp.Exception?.MessagingErrorCode;
                if (errCode == MessagingErrorCode.Unregistered ||
                    errCode == MessagingErrorCode.InvalidArgument)
                {
                    result.InvalidTokens.Add(tokenList[i]);
                }
                else
                {
                    _logger.LogWarning(resp.Exception,
                        "FCM send failed for token {Token}: {Error}",
                        tokenList[i], errCode);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "FCM multicast send failed");
            result.FailureCount = tokenList.Count;
        }

        return result;
    }
}
