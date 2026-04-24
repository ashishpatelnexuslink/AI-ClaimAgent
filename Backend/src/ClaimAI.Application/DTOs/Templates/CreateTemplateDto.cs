using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.Templates;

public class CreateTemplateDto
{
    public string CompanyName { get; set; } = string.Empty;
    public InsuranceType InsuranceType { get; set; }
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

public class CreateIdentityFieldDto
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

public class CreateGroupRuleDto
{
    public string GroupKey { get; set; } = string.Empty;
    public int MinRequired { get; set; }
    public int? MaxAllowed { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
}

public class CreatePhotoSettingDto
{
    public string GroupKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string? Instruction { get; set; }
    public int MinCount { get; set; }
    public int MaxCount { get; set; }
    public bool IsRequired { get; set; } = true;
    public List<string> AllowedAngles { get; set; } = new();
    public List<string> SampleImageUrls { get; set; } = new();
    public int MaxFileSizeMb { get; set; } = 10;
    public List<string> AllowedMimeTypes { get; set; } = new() { "image/jpeg", "image/png" };
    public int DisplayOrder { get; set; }
}

public class CreateDocumentSettingDto
{
    public string DocKey { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string? Instruction { get; set; }
    public int MinCount { get; set; }
    public int MaxCount { get; set; }
    public bool IsRequired { get; set; } = true;
    public int MaxFileSizeMb { get; set; } = 10;
    public List<string> AllowedMimeTypes { get; set; } = new() { "application/pdf", "image/jpeg", "image/png" };
    public int DisplayOrder { get; set; }
}
