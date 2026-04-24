using ClaimAI.Application.DTOs.Templates;
using FluentValidation;

namespace ClaimAI.Application.Validators.Templates;

public class CreateTemplateValidator : AbstractValidator<CreateTemplateDto>
{
    public CreateTemplateValidator(
        CreateIdentityFieldValidator identityFieldValidator,
        CreateGroupRuleValidator groupRuleValidator,
        CreatePhotoSettingValidator photoSettingValidator,
        CreateDocumentSettingValidator documentSettingValidator)
    {
        RuleFor(x => x.CompanyName)
            .MaximumLength(200);

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
            var fieldKeys = dto.IdentityFields.Select(f => f.FieldKey).ToList();
            var duplicateFieldKeys = fieldKeys.GroupBy(k => k).Where(g => g.Count() > 1).Select(g => g.Key).ToList();
            foreach (var dup in duplicateFieldKeys)
                ctx.AddFailure($"Duplicate identity field key '{dup}'.");

            var groupKeys = dto.GroupRules.Select(r => r.GroupKey).ToList();
            var duplicateGroupKeys = groupKeys.GroupBy(k => k).Where(g => g.Count() > 1).Select(g => g.Key).ToList();
            foreach (var dup in duplicateGroupKeys)
                ctx.AddFailure($"Duplicate group rule key '{dup}'.");

            var declaredGroups = dto.IdentityFields
                .Where(f => !string.IsNullOrWhiteSpace(f.GroupKey))
                .Select(f => f.GroupKey!)
                .ToHashSet();

            foreach (var rule in dto.GroupRules)
                if (!declaredGroups.Contains(rule.GroupKey))
                    ctx.AddFailure($"Group rule '{rule.GroupKey}' has no matching identity field with that group key.");

            var photoKeys = dto.PhotoSettings.Select(p => p.GroupKey).ToList();
            foreach (var dup in photoKeys.GroupBy(k => k).Where(g => g.Count() > 1).Select(g => g.Key))
                ctx.AddFailure($"Duplicate photo setting group key '{dup}'.");

            var docKeys = dto.DocumentSettings.Select(d => d.DocKey).ToList();
            foreach (var dup in docKeys.GroupBy(k => k).Where(g => g.Count() > 1).Select(g => g.Key))
                ctx.AddFailure($"Duplicate document setting key '{dup}'.");
        });
    }
}
