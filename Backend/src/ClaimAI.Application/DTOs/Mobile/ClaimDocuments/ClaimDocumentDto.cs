namespace ClaimAI.Application.DTOs.Mobile.ClaimDocuments;

public class ClaimDocumentDto
{
    public string Id { get; set; } = string.Empty;
    public string? ClaimId { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long FileSize { get; set; }
    public string Kind { get; set; } = string.Empty;
    public string? GroupKey { get; set; }
    public string? Label { get; set; }
    public string? Angle { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class AttachClaimDocumentsRequestDto
{
    public string ClaimId { get; set; } = string.Empty;
    public List<string> DocumentIds { get; set; } = new();
}

public class AttachClaimDocumentsResponseDto
{
    public int AttachedCount { get; set; }
}
