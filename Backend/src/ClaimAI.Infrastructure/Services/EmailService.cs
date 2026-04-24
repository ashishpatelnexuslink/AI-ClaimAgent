using ClaimAI.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace ClaimAI.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly ILogger<EmailService> _logger;

    public EmailService(ILogger<EmailService> logger)
    {
        _logger = logger;
    }

    public Task SendEmailAsync(string to, string subject, string body)
    {
        // TODO: Replace with actual email provider (SendGrid, SMTP, etc.)
        _logger.LogInformation("Email sent to {To} with subject: {Subject}", to, subject);
        return Task.CompletedTask;
    }
}
