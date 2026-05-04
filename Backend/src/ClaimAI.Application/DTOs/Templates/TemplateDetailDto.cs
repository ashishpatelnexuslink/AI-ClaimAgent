using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.Templates;

public class TemplateDetailDto
{
    public Guid Id { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public InsuranceType InsuranceType { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Version { get; set; }
    public TemplateStatus Status { get; set; }
    public List<ClaimantType> ClaimantTypes { get; set; } = new();
    public bool RequireIncidentDt { get; set; }
    public bool RequireLocation { get; set; }
    public int MinDescriptionLen { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public List<IdentityFieldDto> IdentityFields { get; set; } = new();
    public List<GroupRuleDto> GroupRules { get; set; } = new();
    public List<PhotoSettingDto> PhotoSettings { get; set; } = new();
    public List<DocumentSettingDto> DocumentSettings { get; set; } = new();
}

public class IdentityFieldDto
{
    public Guid Id { get; set; }
    public string FieldKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string PromptText { get; set; } = string.Empty;
    public string? Placeholder { get; set; }
    public string? ValidationRegex { get; set; }
    public string? GroupKey { get; set; }
    public bool IsSkippable { get; set; }
    public int DisplayOrder { get; set; }
}

public class GroupRuleDto
{
    public Guid Id { get; set; }
    public string GroupKey { get; set; } = string.Empty;
    public int MinRequired { get; set; }
    public int? MaxAllowed { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
}

public class PhotoSettingDto
{
    public Guid Id { get; set; }
    public string GroupKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string? Instruction { get; set; }
    public int MinCount { get; set; }
    public int MaxCount { get; set; }
    public bool IsRequired { get; set; }
    public List<string> AllowedAngles { get; set; } = new();
    public List<string> SampleImageUrls { get; set; } = new();
    public bool ShowSample { get; set; }
    public int MaxFileSizeMb { get; set; }
    public List<string> AllowedMimeTypes { get; set; } = new();
    public int DisplayOrder { get; set; }
}

public class DocumentSettingDto
{
    public Guid Id { get; set; }
    public string DocKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string? Instruction { get; set; }
    public int MinCount { get; set; }
    public int MaxCount { get; set; }
    public bool IsRequired { get; set; }
    public int MaxFileSizeMb { get; set; }
    public List<string> AllowedMimeTypes { get; set; } = new();
    public int DisplayOrder { get; set; }
}
