namespace ClaimAI.Domain.Entities;

/// <summary>
/// Catalog of notification message templates. Each <see cref="Notification"/>
/// row may reference a template by <see cref="Key"/>; the API resolves the
/// per-locale strings via <see cref="Translations"/> at fetch time and falls
/// back to <see cref="DefaultTitle"/>/<see cref="DefaultMessage"/>.
/// </summary>
public class NotificationTemplate : BaseEntity
{
    /// <summary>Stable key, e.g. <c>claim.status.approved</c>.</summary>
    public string Key { get; set; } = string.Empty;

    public string DefaultTitle { get; set; } = string.Empty;
    public string DefaultMessage { get; set; } = string.Empty;

    public ICollection<NotificationTemplateTranslation> Translations { get; set; }
        = new List<NotificationTemplateTranslation>();
}
