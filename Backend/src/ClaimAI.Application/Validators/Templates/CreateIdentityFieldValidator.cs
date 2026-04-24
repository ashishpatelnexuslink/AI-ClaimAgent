using ClaimAI.Application.DTOs.Templates;
using FluentValidation;

namespace ClaimAI.Application.Validators.Templates;

public class CreateIdentityFieldValidator : AbstractValidator<CreateIdentityFieldDto>
{
    public CreateIdentityFieldValidator()
    {
        RuleFor(x => x.FieldKey)
            .NotEmpty().WithMessage("Identity field key is required.")
            .MaximumLength(60)
            .Matches("^[a-z_]+$").WithMessage("Field key must be lowercase letters and underscores only.");

        RuleFor(x => x.Label)
            .NotEmpty().WithMessage("Identity field label is required.")
            .MaximumLength(150);

        // PromptText is no longer a UI-facing input; the client backfills it
        // from Label when left blank. We still cap length for DB safety.
        RuleFor(x => x.Placeholder).MaximumLength(150);
        RuleFor(x => x.ValidationRegex).MaximumLength(500);
        RuleFor(x => x.GroupKey).MaximumLength(60);
        RuleFor(x => x.DisplayOrder).GreaterThanOrEqualTo(0);
    }
}
