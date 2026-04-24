using ClaimAI.Application.DTOs.Templates;
using FluentValidation;

namespace ClaimAI.Application.Validators.Templates;

public class CreateGroupRuleValidator : AbstractValidator<CreateGroupRuleDto>
{
    public CreateGroupRuleValidator()
    {
        RuleFor(x => x.GroupKey)
            .NotEmpty().WithMessage("Group key is required.")
            .MaximumLength(60);

        RuleFor(x => x.MinRequired)
            .GreaterThanOrEqualTo(0).WithMessage("MinRequired must be >= 0.");

        RuleFor(x => x.MaxAllowed)
            .GreaterThanOrEqualTo(x => x.MinRequired)
            .When(x => x.MaxAllowed.HasValue)
            .WithMessage("MaxAllowed must be >= MinRequired when supplied.");

        // Error message is optional; the client auto-generates a fallback
        // (see normalizeWizardForm in the admin panel) before POST/PUT.
    }
}
