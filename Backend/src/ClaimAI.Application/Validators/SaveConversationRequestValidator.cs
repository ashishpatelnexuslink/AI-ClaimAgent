using ClaimAI.Application.DTOs.Mobile.Chat;
using FluentValidation;

namespace ClaimAI.Application.Validators;

public class SaveConversationRequestValidator : AbstractValidator<SaveConversationRequestDto>
{
    public SaveConversationRequestValidator()
    {
        RuleFor(x => x.Messages)
            .NotEmpty().WithMessage("Messages are required.");

        RuleForEach(x => x.Messages).SetValidator(new SaveConversationMessageValidator());
    }
}

public class SaveConversationMessageValidator : AbstractValidator<SaveConversationMessageDto>
{
    public SaveConversationMessageValidator()
    {
        RuleFor(x => x.Role)
            .NotEmpty().WithMessage("Role is required.");

        RuleFor(x => x.Content)
            .NotEmpty().WithMessage("Content is required.");
    }
}
