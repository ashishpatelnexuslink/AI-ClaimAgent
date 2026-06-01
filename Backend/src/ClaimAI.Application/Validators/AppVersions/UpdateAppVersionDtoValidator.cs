using ClaimAI.Application.DTOs.AppVersions;
using FluentValidation;

namespace ClaimAI.Application.Validators.AppVersions;

public class UpdateAppVersionDtoValidator : AbstractValidator<UpdateAppVersionDto>
{
    public UpdateAppVersionDtoValidator()
    {
        RuleFor(x => x.Platform).IsInEnum().WithMessage("Invalid platform.");
        RuleFor(x => x.VersionName)
            .NotEmpty().WithMessage("Version name is required.")
            .MaximumLength(50);
        RuleFor(x => x.VersionCode).GreaterThan(0).WithMessage("Version code must be > 0.");
        RuleFor(x => x.MinSupportedVersionCode)
            .GreaterThan(0).WithMessage("Min supported version code must be > 0.")
            .LessThanOrEqualTo(x => x.VersionCode)
            .WithMessage("Min supported version code cannot exceed version code.");
        RuleFor(x => x.ReleaseNotes).MaximumLength(4000);
        RuleFor(x => x.StoreUrl).MaximumLength(500);
    }
}
