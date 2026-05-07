using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.AiMl;

/// <summary>
/// Mobile-app payload for <c>POST /api/mobile/chat/init-template</c>. Either
/// supply <see cref="TemplateId"/> directly, or the company + insurance type
/// pair so the backend resolves the currently Active template.
/// </summary>
public class InitChatTemplateRequestDto
{
    public Guid? TemplateId { get; set; }
    public string? CompanyName { get; set; }
    public InsuranceType? InsuranceType { get; set; }
}
