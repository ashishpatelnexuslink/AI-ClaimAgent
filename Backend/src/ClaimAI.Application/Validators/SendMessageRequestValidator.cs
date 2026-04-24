using ClaimAI.Application.DTOs.Mobile.Chat;
using FluentValidation;

namespace ClaimAI.Application.Validators;

public class SendMessageRequestValidator : AbstractValidator<SendMessageRequestDto>
{
    public SendMessageRequestValidator()
    {
        RuleFor(x => x.Message)
            .NotEmpty().WithMessage("Message is required.");

        RuleFor(x => x.ClaimId)
            .NotEmpty().WithMessage("ClaimId is required.");
    }
}
