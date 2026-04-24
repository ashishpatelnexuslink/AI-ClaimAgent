namespace ClaimAI.Domain.Entities.Templates;

public class TemplateFieldGroupRule : BaseEntity
{
    public Guid TemplateId { get; set; }
    public Template Template { get; set; } = null!;

    public string GroupKey { get; set; } = string.Empty;
    public int MinRequired { get; set; }
    public int? MaxAllowed { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
}
