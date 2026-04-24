using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.Templates;

public class TemplateListQuery
{
    public string? CompanyName { get; set; }
    public InsuranceType? InsuranceType { get; set; }
    public TemplateStatus? Status { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
