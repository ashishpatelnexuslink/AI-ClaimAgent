using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.AiMl;

/// <summary>
/// Payload posted to the AI/ML <c>POST {baseUrl}/config</c> endpoint so the
/// agent knows the active template's identity fields, photo, and document rules.
/// </summary>
public class TemplateConfigRequestDto
{
    public Guid TemplateId { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public InsuranceType InsuranceType { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Version { get; set; }

    public List<ClaimantType> ClaimantTypes { get; set; } = new();

    public bool RequireIncidentDt { get; set; }
    public bool RequireLocation { get; set; }
    public int MinDescriptionLen { get; set; }

    public List<TemplateConfigIdentityFieldDto> IdentityFields { get; set; } = new();
    public List<TemplateConfigGroupRuleDto> GroupRules { get; set; } = new();
    public List<TemplateConfigPhotoSettingDto> PhotoSettings { get; set; } = new();
    public List<TemplateConfigDocumentSettingDto> DocumentSettings { get; set; } = new();
}

public class TemplateConfigIdentityFieldDto
{
    public string FieldKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string PromptText { get; set; } = string.Empty;
    public string? Placeholder { get; set; }
    public string? ValidationRegex { get; set; }
    public string? GroupKey { get; set; }
    public bool IsSkippable { get; set; }
    public int DisplayOrder { get; set; }
}

public class TemplateConfigGroupRuleDto
{
    public string GroupKey { get; set; } = string.Empty;
    public int MinRequired { get; set; }
    public int? MaxAllowed { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
}

public class TemplateConfigPhotoSettingDto
{
    public string GroupKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string? Instruction { get; set; }
    public int MinCount { get; set; }
    public int MaxCount { get; set; }
    public bool IsRequired { get; set; }
    public List<string> AllowedAngles { get; set; } = new();
    public List<string> SampleImageUrls { get; set; } = new();
    public int MaxFileSizeMb { get; set; }
    public List<string> AllowedMimeTypes { get; set; } = new();
    public int DisplayOrder { get; set; }
}

public class TemplateConfigDocumentSettingDto
{
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
