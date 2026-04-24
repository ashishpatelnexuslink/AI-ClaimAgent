using ClaimAI.Application.DTOs.Templates;
using FluentValidation;

namespace ClaimAI.Application.Validators.Templates;

public class CreatePhotoSettingValidator : AbstractValidator<CreatePhotoSettingDto>
{
    public CreatePhotoSettingValidator()
    {
        RuleFor(x => x.GroupKey)
            .NotEmpty().WithMessage("Photo group key is required.")
            .MaximumLength(60);

        RuleFor(x => x.Label)
            .NotEmpty().WithMessage("Photo label is required.")
            .MaximumLength(150);

        RuleFor(x => x.MinCount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.MaxCount)
            .GreaterThanOrEqualTo(x => x.MinCount)
            .WithMessage("MaxCount must be >= MinCount.");

        RuleFor(x => x.MaxFileSizeMb)
            .InclusiveBetween(1, 100)
            .WithMessage("MaxFileSizeMb must be between 1 and 100.");

        RuleFor(x => x.AllowedMimeTypes)
            .NotEmpty().WithMessage("At least one allowed MIME type is required.");

        RuleFor(x => x.DisplayOrder).GreaterThanOrEqualTo(0);
    }
}
