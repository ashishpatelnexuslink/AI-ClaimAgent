using ClaimAI.Application.DTOs.Admin;
using FluentValidation;

namespace ClaimAI.Application.Validators;

public class UpdateAdminUserValidator : AbstractValidator<UpdateAdminUserDto>
{
    private static readonly string[] AllowedRoles = ["Super Admin", "Reviewer", "Viewer"];
    private static readonly string[] AllowedStatuses = ["Active", "Suspended"];

    public UpdateAdminUserValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required.")
            .MaximumLength(200).WithMessage("Name cannot exceed 200 characters.");

        RuleFor(x => x.Role)
            .NotEmpty().WithMessage("Role is required.")
            .Must(r => AllowedRoles.Contains(r))
            .WithMessage($"Role must be one of: {string.Join(", ", AllowedRoles)}.");

        RuleFor(x => x.Status)
            .NotEmpty().WithMessage("Status is required.")
            .Must(s => AllowedStatuses.Contains(s))
            .WithMessage($"Status must be one of: {string.Join(", ", AllowedStatuses)}.");
    }
}
