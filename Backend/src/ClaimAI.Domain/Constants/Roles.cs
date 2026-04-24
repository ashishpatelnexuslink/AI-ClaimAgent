namespace ClaimAI.Domain.Constants;

public static class Roles
{
    public const string SuperAdmin = "Super Admin";
    public const string Reviewer = "Reviewer";
    public const string Viewer = "Viewer";
    public const string Admin = "Admin";
    public const string MobileUser = "MobileUser";

    public static readonly string[] AdminRoles = [SuperAdmin, Reviewer, Viewer, Admin];
}
