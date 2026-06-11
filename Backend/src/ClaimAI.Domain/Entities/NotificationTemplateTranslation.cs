namespace ClaimAI.Domain.Entities;

/// <summary>
/// Per-locale override for a <see cref="NotificationTemplate"/>. The API picks
/// the row matching the request's <c>Accept-Language</c> (exact tag first, then
/// the language part), falling back to the parent's default strings.
/// </summary>
public class NotificationTemplateTranslation : BaseEntity
{
    public Guid NotificationTemplateId { get; set; }
    public NotificationTemplate NotificationTemplate { get; set; } = null!;

    /// <summary>BCP-47 language tag, e.g. <c>de</c>, <c>fr</c>, <c>pt-BR</c>.</summary>
    public string Locale { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}
