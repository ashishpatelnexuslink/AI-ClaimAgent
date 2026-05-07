namespace ClaimAI.Application.DTOs.AiMl;

/// <summary>
/// Raw response returned by the AI/ML <c>POST /config</c> endpoint. The shape
/// is opaque to us — we surface the JSON payload back to the caller verbatim
/// plus the upstream HTTP status.
/// </summary>
public class TemplateConfigResponseDto
{
    public int StatusCode { get; set; }
    public string? RawBody { get; set; }
}
