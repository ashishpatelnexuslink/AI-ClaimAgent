using ClaimAI.Application.DTOs.Mobile.Claims;
using FluentValidation;

namespace ClaimAI.Application.Validators;

public class CreateClaimValidator : AbstractValidator<CreateClaimDto>
{
    public CreateClaimValidator()
    {
        RuleFor(x => x.ClaimType)
            .NotEmpty().WithMessage("Claim type is required.");

        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Full name is required.");

        RuleFor(x => x.PolicyNumber)
            .NotEmpty().WithMessage("Policy number is required.");

        RuleFor(x => x.IncidentDate)
            .NotNull().WithMessage("Incident date is required.")
            .LessThanOrEqualTo(DateTime.UtcNow).WithMessage("Incident date cannot be in the future.");
    }
}
