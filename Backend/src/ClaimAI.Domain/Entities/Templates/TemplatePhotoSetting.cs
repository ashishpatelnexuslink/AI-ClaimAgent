namespace ClaimAI.Domain.Entities.Templates;

public class TemplatePhotoSetting : BaseEntity
{
    public Guid TemplateId { get; set; }
    public Template Template { get; set; } = null!;

    public string GroupKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string? Instruction { get; set; }

    public int MinCount { get; set; }
    public int MaxCount { get; set; }
    public bool IsRequired { get; set; } = true;

    public List<string> AllowedAngles { get; set; } = new();
    public List<string> SampleImageUrls { get; set; } = new();

    public int MaxFileSizeMb { get; set; } = 10;
    public List<string> AllowedMimeTypes { get; set; } = new() { "image/jpeg", "image/png" };

    public int DisplayOrder { get; set; }
}
