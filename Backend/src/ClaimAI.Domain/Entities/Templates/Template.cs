using ClaimAI.Domain.Enums;

namespace ClaimAI.Domain.Entities.Templates;

public class Template : BaseEntity
{
    public string CompanyName { get; set; } = string.Empty;
    public InsuranceType InsuranceType { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Version { get; set; } = 1;
    public TemplateStatus Status { get; set; } = TemplateStatus.Draft;

    public List<ClaimantType> ClaimantTypes { get; set; } = new();

    public bool RequireIncidentDt { get; set; } = true;
    public bool RequireLocation { get; set; } = true;
    public int MinDescriptionLen { get; set; } = 40;

    public ICollection<TemplateIdentityField> IdentityFields { get; set; } = new List<TemplateIdentityField>();
    public ICollection<TemplateFieldGroupRule> GroupRules { get; set; } = new List<TemplateFieldGroupRule>();
    public ICollection<TemplatePhotoSetting> PhotoSettings { get; set; } = new List<TemplatePhotoSetting>();
    public ICollection<TemplateDocumentSetting> DocumentSettings { get; set; } = new List<TemplateDocumentSetting>();
}
