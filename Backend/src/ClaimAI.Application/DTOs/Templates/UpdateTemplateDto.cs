using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.Templates;

/// <summary>
/// Update payload for a Draft template. The identifying tuple
/// (CompanyName, InsuranceType, Version) is immutable; to change those,
/// use <c>POST /clone</c>. Child collections are replaced wholesale — any
/// child row not in the submitted list is soft-deleted.
/// </summary>
public class UpdateTemplateDto
{
    public string Name { get; set; } = string.Empty;
    public List<ClaimantType> ClaimantTypes { get; set; } = new();
    public bool RequireIncidentDt { get; set; } = true;
    public bool RequireLocation { get; set; } = true;
    public int MinDescriptionLen { get; set; } = 40;

    public List<CreateIdentityFieldDto> IdentityFields { get; set; } = new();
    public List<CreateGroupRuleDto> GroupRules { get; set; } = new();
    public List<CreatePhotoSettingDto> PhotoSettings { get; set; } = new();
    public List<CreateDocumentSettingDto> DocumentSettings { get; set; } = new();
}
