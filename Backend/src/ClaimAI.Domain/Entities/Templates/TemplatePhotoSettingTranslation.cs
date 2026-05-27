namespace ClaimAI.Domain.Entities.Templates;

/// <summary>
/// Per-locale override for a <see cref="TemplatePhotoSetting"/>. When the
/// mobile client requests the active template with an <c>Accept-Language</c>
/// header, the service substitutes <see cref="Label"/> and
/// <see cref="Instruction"/> from the matching row (falling back to the
/// parent's seed English values when no translation exists).
/// </summary>
public class TemplatePhotoSettingTranslation : BaseEntity
{
    public Guid TemplatePhotoSettingId { get; set; }
    public TemplatePhotoSetting TemplatePhotoSetting { get; set; } = null!;

    /// <summary>BCP-47 language tag, e.g. <c>de</c>, <c>fr</c>, <c>pt-BR</c>.</summary>
    public string Locale { get; set; } = string.Empty;

    public string Label { get; set; } = string.Empty;
    public string? Instruction { get; set; }
}
