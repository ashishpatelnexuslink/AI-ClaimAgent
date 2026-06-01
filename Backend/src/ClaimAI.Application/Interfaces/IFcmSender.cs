namespace ClaimAI.Application.Interfaces;

public class FcmSendResult
{
    public int SuccessCount { get; set; }
    public int FailureCount { get; set; }
    public List<string> InvalidTokens { get; set; } = new();
}

public interface IFcmSender
{
    Task<FcmSendResult> SendToTokensAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        IDictionary<string, string>? data = null,
        CancellationToken cancellationToken = default);
}
