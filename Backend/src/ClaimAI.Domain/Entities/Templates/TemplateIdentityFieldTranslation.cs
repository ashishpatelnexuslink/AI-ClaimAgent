namespace ClaimAI.Domain.Entities.Templates;

/// <summary>Per-locale override for a <see cref="TemplateIdentityField"/>.</summary>
public class TemplateIdentityFieldTranslation : BaseEntity
{
    public Guid TemplateIdentityFieldId { get; set; }
    public TemplateIdentityField TemplateIdentityField { get; set; } = null!;

    /// <summary>BCP-47 language tag, e.g. <c>de</c>, <c>fr</c>, <c>pt-BR</c>.</summary>
    public string Locale { get; set; } = string.Empty;

    public string Label { get; set; } = string.Empty;
    public string PromptText { get; set; } = string.Empty;
    public string? Placeholder { get; set; }
}
