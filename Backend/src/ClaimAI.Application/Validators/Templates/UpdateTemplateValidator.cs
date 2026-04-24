using ClaimAI.Application.DTOs.Templates;
using FluentValidation;

namespace ClaimAI.Application.Validators.Templates;

public class UpdateTemplateValidator : AbstractValidator<UpdateTemplateDto>
{
    public UpdateTemplateValidator(
        CreateIdentityFieldValidator identityFieldValidator,
        CreateGroupRuleValidator groupRuleValidator,
        CreatePhotoSettingValidator photoSettingValidator,
        CreateDocumentSettingValidator documentSettingValidator)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Template name is required.")
            .MaximumLength(200);

        RuleFor(x => x.MinDescriptionLen).GreaterThanOrEqualTo(0);

        RuleFor(x => x.ClaimantTypes)
            .NotEmpty().WithMessage("At least one claimant type must be supported.");

        RuleForEach(x => x.IdentityFields).SetValidator(identityFieldValidator);
        RuleForEach(x => x.GroupRules).SetValidator(groupRuleValidator);
        RuleForEach(x => x.PhotoSettings).SetValidator(photoSettingValidator);
        RuleForEach(x => x.DocumentSettings).SetValidator(documentSettingValidator);

        RuleFor(x => x).Custom((dto, ctx) =>
        {
            var declaredGroups = dto.IdentityFields
                .Where(f => !string.IsNullOrWhiteSpace(f.GroupKey))
                .Select(f => f.GroupKey!)
                .ToHashSet();

            foreach (var rule in dto.GroupRules)
                if (!declaredGroups.Contains(rule.GroupKey))
                    ctx.AddFailure($"Group rule '{rule.GroupKey}' has no matching identity field with that group key.");
        });
    }
}
