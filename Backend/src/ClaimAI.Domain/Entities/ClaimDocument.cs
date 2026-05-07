namespace ClaimAI.Domain.Entities;

public class ClaimDocument : BaseEntity
{
    // Owner
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;

    // Nullable so documents can be uploaded before the Claim row exists
    // (user uploads inside the chat before tapping "Close").
    public Guid? ClaimId { get; set; }
    public Claim? Claim { get; set; }

    // Optional link back to the chat thread the upload happened in.
    public string? ChatThreadId { get; set; }

    public string FileName { get; set; } = string.Empty;        // original name
    public string StoredFileName { get; set; } = string.Empty;  // on-disk name (guid + ext)
    public string RelativeUrl { get; set; } = string.Empty;     // served via UseStaticFiles
    public string ContentType { get; set; } = string.Empty;
    public long FileSize { get; set; }

    /// "Image" | "Document" — free-text so new kinds don't require a schema change.
    public string Kind { get; set; } = "Document";

    /// Logical bucket from the active <c>Template</c>. Holds the template's
    /// <c>TemplatePhotoSetting.GroupKey</c> for image groups (e.g.
    /// "vehicle_photos") or <c>TemplateDocumentSetting.DocKey</c> for document
    /// groups (e.g. "bill_invoice"). Free-text so adding a new template group
    /// does not require a schema change.
    public string? GroupKey { get; set; }

    /// Human label of the group at the time of upload, copied verbatim from
    /// the template (e.g. "Vehicle Photos"). Stored on the row so old uploads
    /// keep their label even if the template later renames the group.
    public string? Label { get; set; }

    /// Optional angle/position tag for image uploads driven by the
    /// `allowed_angles` payload from the chat stream (e.g. "front_left",
    /// "rear_right"). Free-text so new angles can be added without a schema
    /// change. Null for documents and for legacy uploads.
    public string? Angle { get; set; }
}
