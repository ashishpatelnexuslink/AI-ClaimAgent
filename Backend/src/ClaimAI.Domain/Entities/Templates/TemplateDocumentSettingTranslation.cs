namespace ClaimAI.Domain.Entities.Templates;

/// <summary>Per-locale override for a <see cref="TemplateDocumentSetting"/>.</summary>
public class TemplateDocumentSettingTranslation : BaseEntity
{
    public Guid TemplateDocumentSettingId { get; set; }
    public TemplateDocumentSetting TemplateDocumentSetting { get; set; } = null!;

    /// <summary>BCP-47 language tag, e.g. <c>de</c>, <c>fr</c>, <c>pt-BR</c>.</summary>
    public string Locale { get; set; } = string.Empty;

    public string Label { get; set; } = string.Empty;
    public string? Instruction { get; set; }
}
