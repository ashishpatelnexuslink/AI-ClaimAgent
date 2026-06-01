using ClaimAI.Application.DTOs.Mobile.Notifications;
using FluentValidation;

namespace ClaimAI.Application.Validators;

public class RegisterDeviceValidator : AbstractValidator<RegisterDeviceDto>
{
    public RegisterDeviceValidator()
    {
        RuleFor(x => x.FcmToken)
            .NotEmpty().WithMessage("FCM token is required.")
            .MaximumLength(512).WithMessage("FCM token is too long.");

        RuleFor(x => x.Platform)
            .IsInEnum().WithMessage("Invalid device platform.");
    }
}
