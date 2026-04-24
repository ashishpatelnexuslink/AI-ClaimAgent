using ClaimAI.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace ClaimAI.Infrastructure.Services;

public class SmsService : ISmsService
{
    private readonly ILogger<SmsService> _logger;

    public SmsService(ILogger<SmsService> logger)
    {
        _logger = logger;
    }

    public Task SendSmsAsync(string phoneNumber, string message)
    {
        // TODO: Replace with actual SMS provider (Twilio, AWS SNS, MSG91, etc.)
        _logger.LogInformation("SMS to {PhoneNumber}: {Message}", phoneNumber, message);
        return Task.CompletedTask;
    }
}
