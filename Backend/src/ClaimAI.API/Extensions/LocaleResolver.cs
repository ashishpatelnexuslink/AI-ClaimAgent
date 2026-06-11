namespace ClaimAI.API.Extensions;

/// <summary>
/// Helpers for parsing the <c>Accept-Language</c> header into a single BCP-47
/// tag. Used by controllers that surface localized resources (templates,
/// notifications).
/// </summary>
public static class LocaleResolver
{
    /// <summary>
    /// Picks the first language tag out of an <c>Accept-Language</c> header
    /// value (e.g. <c>"de-CH,de;q=0.9,en;q=0.8"</c> → <c>"de-CH"</c>). Returns
    /// <c>null</c> when the header is missing/blank so callers can fall back
    /// to a default.
    /// </summary>
    public static string? ResolveLanguage(string? acceptLanguage)
    {
        if (string.IsNullOrWhiteSpace(acceptLanguage)) return null;
        var first = acceptLanguage.Split(',')[0].Split(';')[0].Trim();
        return string.IsNullOrEmpty(first) ? null : first;
    }
}
