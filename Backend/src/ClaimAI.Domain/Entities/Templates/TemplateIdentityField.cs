namespace ClaimAI.Domain.Entities.Templates;

public class TemplateIdentityField : BaseEntity
{
    public Guid TemplateId { get; set; }
    public Template Template { get; set; } = null!;

    public string FieldKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string PromptText { get; set; } = string.Empty;
    public string? Placeholder { get; set; }
    public string? ValidationRegex { get; set; }

    public string? GroupKey { get; set; }
    public bool IsSkippable { get; set; }
    public int DisplayOrder { get; set; }
}
