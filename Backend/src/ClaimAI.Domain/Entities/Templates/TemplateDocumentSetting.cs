namespace ClaimAI.Domain.Entities.Templates;

public class TemplateDocumentSetting : BaseEntity
{
    public Guid TemplateId { get; set; }
    public Template Template { get; set; } = null!;

    public string DocKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string? Instruction { get; set; }

    public int MinCount { get; set; }
    public int MaxCount { get; set; }
    public bool IsRequired { get; set; } = true;

    public int MaxFileSizeMb { get; set; } = 10;
    public List<string> AllowedMimeTypes { get; set; } = new() { "application/pdf", "image/jpeg", "image/png" };

    public int DisplayOrder { get; set; }
}
