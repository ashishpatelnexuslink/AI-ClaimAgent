using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.Templates;

public class TemplateListItemDto
{
    public Guid Id { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public InsuranceType InsuranceType { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Version { get; set; }
    public TemplateStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
