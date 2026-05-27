using AutoMapper;
using ClaimAI.Application.DTOs.AiMl;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Templates;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Entities.Templates;
using ClaimAI.Domain.Enums;
using ClaimAI.Domain.Interfaces.Repositories;
using ClaimAI.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace ClaimAI.Infrastructure.Services;

public class TemplateService : ITemplateService
{
    private readonly ApplicationDbContext _context;
    private readonly ITemplateRepository _templates;
    private readonly IMapper _mapper;
    private readonly ILogger<TemplateService> _logger;
    private readonly IAiMlClient _aiMlClient;

    public TemplateService(
        ApplicationDbContext context,
        ITemplateRepository templates,
        IMapper mapper,
        ILogger<TemplateService> logger,
        IAiMlClient aiMlClient)
    {
        _context = context;
        _templates = templates;
        _mapper = mapper;
        _logger = logger;
        _aiMlClient = aiMlClient;
    }

    /// <inheritdoc />
    public async Task<Result<PagedResult<TemplateListItemDto>>> ListAsync(TemplateListQuery query, CancellationToken cancellationToken = default)
    {
        var (items, total) = await _templates.ListAsync(
            query.CompanyName, query.InsuranceType, query.Status,
            query.PageNumber, query.PageSize, cancellationToken);

        var page = new PagedResult<TemplateListItemDto>
        {
            Items = items.Select(t => _mapper.Map<TemplateListItemDto>(t)).ToList(),
            TotalCount = total,
            PageNumber = query.PageNumber < 1 ? 1 : query.PageNumber,
            PageSize = query.PageSize < 1 ? 20 : query.PageSize
        };

        return Result<PagedResult<TemplateListItemDto>>.Success(page);
    }

    /// <inheritdoc />
    public async Task<Result<TemplateDetailDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var template = await _templates.GetByIdWithChildrenAsync(id, cancellationToken);
        if (template is null)
            return Result<TemplateDetailDto>.Failure("Template not found.");

        return Result<TemplateDetailDto>.Success(ToDetailDto(template));
    }

    /// <inheritdoc />
    public async Task<Result<TemplateDetailDto>> GetActiveAsync(string companyName, InsuranceType insuranceType, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(companyName))
            return Result<TemplateDetailDto>.Failure("Company name is required.");

        var template = await _templates.GetActiveAsync(companyName, insuranceType, cancellationToken);
        if (template is null)
            return Result<TemplateDetailDto>.Failure($"No active template for {companyName} / {insuranceType}.");

        return Result<TemplateDetailDto>.Success(ToDetailDto(template));
    }

    /// <inheritdoc />
    public async Task<Result<TemplateDetailDto>> GetSingleActiveAsync(string? language = null, CancellationToken cancellationToken = default)
    {
        var template = await _templates.GetSingleActiveAsync(cancellationToken);
        if (template is null)
            return Result<TemplateDetailDto>.Failure("No active template found.");

        var dto = ToDetailDto(template);
        ApplyTranslations(dto, template, language);
        return Result<TemplateDetailDto>.Success(dto);
    }

    /// <summary>
    /// Substitutes per-locale Label / Instruction / PromptText / Placeholder
    /// from each child's <c>Translations</c> collection into the DTO. Looks
    /// up the exact tag first ("de-CH"), then the primary subtag ("de").
    ///
    /// When no per-row translation exists (e.g. an admin-created template
    /// that hasn't had translations added via the AdminPanel yet), falls
    /// back to a static GroupKey/DocKey/FieldKey dictionary so the common
    /// standard keys are still localized. Children with no match anywhere
    /// keep their seed English values.
    /// </summary>
    private static void ApplyTranslations(TemplateDetailDto dto, Template entity, string? language)
    {
        if (string.IsNullOrWhiteSpace(language)) return;

        var full = language.Replace('_', '-').ToLowerInvariant();
        var primary = full.Split('-')[0];

        foreach (var photoDto in dto.PhotoSettings)
        {
            var src = entity.PhotoSettings.FirstOrDefault(p => p.Id == photoDto.Id);
            var match = src is null
                ? null
                : src.Translations.FirstOrDefault(t => Norm(t.Locale) == full)
                  ?? src.Translations.FirstOrDefault(t => Norm(t.Locale) == primary);
            if (match is not null)
            {
                photoDto.Label = match.Label;
                photoDto.Instruction = match.Instruction ?? photoDto.Instruction;
                continue;
            }

            // Fallback: per-GroupKey label dictionary.
            if (PhotoGroupFallback.TryGetValue(photoDto.GroupKey, out var byKey) &&
                (byKey.TryGetValue(full, out var label) || byKey.TryGetValue(primary, out label)))
            {
                photoDto.Label = label;
            }
        }

        foreach (var docDto in dto.DocumentSettings)
        {
            var src = entity.DocumentSettings.FirstOrDefault(d => d.Id == docDto.Id);
            var match = src is null
                ? null
                : src.Translations.FirstOrDefault(t => Norm(t.Locale) == full)
                  ?? src.Translations.FirstOrDefault(t => Norm(t.Locale) == primary);
            if (match is not null)
            {
                docDto.Label = match.Label;
                docDto.Instruction = match.Instruction ?? docDto.Instruction;
                continue;
            }

            if (DocumentKeyFallback.TryGetValue(docDto.DocKey, out var byKey) &&
                (byKey.TryGetValue(full, out var label) || byKey.TryGetValue(primary, out label)))
            {
                docDto.Label = label;
            }
        }

        foreach (var fieldDto in dto.IdentityFields)
        {
            var src = entity.IdentityFields.FirstOrDefault(f => f.Id == fieldDto.Id);
            var match = src is null
                ? null
                : src.Translations.FirstOrDefault(t => Norm(t.Locale) == full)
                  ?? src.Translations.FirstOrDefault(t => Norm(t.Locale) == primary);
            if (match is not null)
            {
                fieldDto.Label = match.Label;
                fieldDto.PromptText = match.PromptText;
                fieldDto.Placeholder = match.Placeholder ?? fieldDto.Placeholder;
                continue;
            }

            if (IdentityFieldFallback.TryGetValue(fieldDto.FieldKey, out var byKey) &&
                (byKey.TryGetValue(full, out var label) || byKey.TryGetValue(primary, out label)))
            {
                fieldDto.Label = label;
            }
        }
    }

    private static string Norm(string locale)
        => locale.Replace('_', '-').ToLowerInvariant();

    /// <summary>
    /// Static fallback for standard <see cref="TemplatePhotoSetting.GroupKey"/>
    /// values when an admin-created row has no per-row translation. Outer key:
    /// GroupKey. Inner key: locale (BCP-47, lowercase). Inner value: Label.
    /// </summary>
    private static readonly IReadOnlyDictionary<string, IReadOnlyDictionary<string, string>> PhotoGroupFallback =
        new Dictionary<string, IReadOnlyDictionary<string, string>>(StringComparer.OrdinalIgnoreCase)
        {
            ["vehicle_photos"] = new Dictionary<string, string>
            {
                ["de"] = "Fahrzeugfotos",
                ["it"] = "Foto del veicolo",
                ["fr"] = "Photos du véhicule",
                ["es"] = "Fotos del vehículo",
                ["pl"] = "Zdjęcia pojazdu",
                ["lt"] = "Transporto priemonės nuotraukos",
                ["lv"] = "Transportlīdzekļa fotogrāfijas",
            },
            ["damage_photos"] = new Dictionary<string, string>
            {
                ["de"] = "Schadensfotos",
                ["it"] = "Foto del danno",
                ["fr"] = "Photos des dommages",
                ["es"] = "Fotos del daño",
                ["pl"] = "Zdjęcia uszkodzeń",
                ["lt"] = "Žalos nuotraukos",
                ["lv"] = "Bojājumu fotogrāfijas",
            },
            ["driver_license"] = new Dictionary<string, string>
            {
                ["de"] = "Führerschein",
                ["it"] = "Patente di guida",
                ["fr"] = "Permis de conduire",
                ["es"] = "Licencia de conducir",
                ["pl"] = "Prawo jazdy",
                ["lt"] = "Vairuotojo pažymėjimas",
                ["lv"] = "Vadītāja apliecība",
            },
        };

    /// <summary>Static fallback for standard <see cref="TemplateDocumentSetting.DocKey"/> values.</summary>
    private static readonly IReadOnlyDictionary<string, IReadOnlyDictionary<string, string>> DocumentKeyFallback =
        new Dictionary<string, IReadOnlyDictionary<string, string>>(StringComparer.OrdinalIgnoreCase)
        {
            ["bill_invoice"] = new Dictionary<string, string>
            {
                ["de"] = "Rechnung / Beleg",
                ["it"] = "Fattura / Ricevuta",
                ["fr"] = "Facture / Reçu",
                ["es"] = "Factura / Recibo",
                ["pl"] = "Rachunek / Faktura",
                ["lt"] = "Sąskaita / Kvitas",
                ["lv"] = "Rēķins / Kvīts",
            },
            ["insurance_policy"] = new Dictionary<string, string>
            {
                ["de"] = "Versicherungspolice",
                ["it"] = "Polizza assicurativa",
                ["fr"] = "Police d'assurance",
                ["es"] = "Póliza de seguro",
                ["pl"] = "Polisa ubezpieczeniowa",
                ["lt"] = "Draudimo polisas",
                ["lv"] = "Apdrošināšanas polise",
            },
            ["police_report"] = new Dictionary<string, string>
            {
                ["de"] = "Polizeibericht",
                ["it"] = "Rapporto di polizia",
                ["fr"] = "Rapport de police",
                ["es"] = "Informe policial",
                ["pl"] = "Raport policyjny",
                ["lt"] = "Policijos ataskaita",
                ["lv"] = "Policijas ziņojums",
            },
            ["supporting_docs"] = new Dictionary<string, string>
            {
                ["de"] = "Belege",
                ["it"] = "Documenti di supporto",
                ["fr"] = "Documents justificatifs",
                ["es"] = "Documentos de apoyo",
                ["pl"] = "Dokumenty uzupełniające",
                ["lt"] = "Papildomi dokumentai",
                ["lv"] = "Pavaddokumenti",
            },
        };

    /// <summary>Static fallback for standard <see cref="TemplateIdentityField.FieldKey"/> values.</summary>
    private static readonly IReadOnlyDictionary<string, IReadOnlyDictionary<string, string>> IdentityFieldFallback =
        new Dictionary<string, IReadOnlyDictionary<string, string>>(StringComparer.OrdinalIgnoreCase)
        {
            ["full_name"] = new Dictionary<string, string>
            {
                ["de"] = "Vollständiger Name",
                ["it"] = "Nome completo",
                ["fr"] = "Nom complet",
                ["es"] = "Nombre completo",
                ["pl"] = "Imię i nazwisko",
                ["lt"] = "Vardas ir pavardė",
                ["lv"] = "Vārds un uzvārds",
            },
            ["policy_number"] = new Dictionary<string, string>
            {
                ["de"] = "Policennummer",
                ["it"] = "Numero di polizza",
                ["fr"] = "Numéro de police",
                ["es"] = "Número de póliza",
                ["pl"] = "Numer polisy",
                ["lt"] = "Poliso numeris",
                ["lv"] = "Polises numurs",
            },
            ["vehicle_reg"] = new Dictionary<string, string>
            {
                ["de"] = "Kennzeichen",
                ["it"] = "Targa",
                ["fr"] = "Numéro d'immatriculation",
                ["es"] = "Matrícula",
                ["pl"] = "Numer rejestracyjny",
                ["lt"] = "Valstybinis numeris",
                ["lv"] = "Reģistrācijas numurs",
            },
            ["vin"] = new Dictionary<string, string>
            {
                ["de"] = "Fahrgestellnummer",
                ["it"] = "Numero di telaio",
                ["fr"] = "Numéro de châssis",
                ["es"] = "Número de VIN",
                ["pl"] = "Numer VIN",
                ["lt"] = "VIN numeris",
                ["lv"] = "VIN numurs",
            },
        };

    /// <inheritdoc />
    public async Task<Result<TemplateDetailDto>> CreateAsync(CreateTemplateDto dto, CancellationToken cancellationToken = default)
    {
        await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);

        var nextVersion = await _templates.GetMaxVersionAsync(dto.CompanyName, dto.InsuranceType, cancellationToken) + 1;

        var template = new Template
        {
            CompanyName = dto.CompanyName,
            InsuranceType = dto.InsuranceType,
            Name = dto.Name,
            Version = nextVersion,
            Status = TemplateStatus.Draft,
            ClaimantTypes = dto.ClaimantTypes.ToList(),
            RequireIncidentDt = dto.RequireIncidentDt,
            RequireLocation = dto.RequireLocation,
            MinDescriptionLen = dto.MinDescriptionLen,
            IdentityFields = dto.IdentityFields.Select(f => _mapper.Map<TemplateIdentityField>(f)).ToList(),
            GroupRules = dto.GroupRules.Select(r => _mapper.Map<TemplateFieldGroupRule>(r)).ToList(),
            PhotoSettings = dto.PhotoSettings.Select(p => _mapper.Map<TemplatePhotoSetting>(p)).ToList(),
            DocumentSettings = dto.DocumentSettings.Select(d => _mapper.Map<TemplateDocumentSetting>(d)).ToList()
        };

        _context.Templates.Add(template);
        await _context.SaveChangesAsync(cancellationToken);

        await tx.CommitAsync(cancellationToken);

        _logger.LogInformation("Created template {TemplateId} v{Version} for {Company}/{Type}",
            template.Id, template.Version, template.CompanyName, template.InsuranceType);

        var reloaded = await _templates.GetByIdWithChildrenAsync(template.Id, cancellationToken);
        return Result<TemplateDetailDto>.Success(ToDetailDto(reloaded!), "Template created.");
    }

    /// <inheritdoc />
    public async Task<Result<TemplateDetailDto>> UpdateAsync(Guid id, UpdateTemplateDto dto, CancellationToken cancellationToken = default)
    {
        var template = await _templates.GetByIdWithChildrenAsync(id, cancellationToken);
        if (template is null)
            return Result<TemplateDetailDto>.Failure("Template not found.");

        await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);

        // First pass: soft-delete existing children so the filtered unique
        // indexes won't collide with the replacement rows.
        foreach (var f in template.IdentityFields.ToList()) _context.TemplateIdentityFields.Remove(f);
        foreach (var r in template.GroupRules.ToList()) _context.TemplateFieldGroupRules.Remove(r);
        foreach (var p in template.PhotoSettings.ToList()) _context.TemplatePhotoSettings.Remove(p);
        foreach (var d in template.DocumentSettings.ToList()) _context.TemplateDocumentSettings.Remove(d);

        template.Name = dto.Name;
        template.ClaimantTypes = dto.ClaimantTypes.ToList();
        template.RequireIncidentDt = dto.RequireIncidentDt;
        template.RequireLocation = dto.RequireLocation;
        template.MinDescriptionLen = dto.MinDescriptionLen;

        await _context.SaveChangesAsync(cancellationToken);

        // Second pass: insert the new child rows with the parent id set.
        var newIdentityFields = dto.IdentityFields.Select(f =>
        {
            var entity = _mapper.Map<TemplateIdentityField>(f);
            entity.TemplateId = template.Id;
            return entity;
        }).ToList();
        var newGroupRules = dto.GroupRules.Select(r =>
        {
            var entity = _mapper.Map<TemplateFieldGroupRule>(r);
            entity.TemplateId = template.Id;
            return entity;
        }).ToList();
        var newPhotoSettings = dto.PhotoSettings.Select(p =>
        {
            var entity = _mapper.Map<TemplatePhotoSetting>(p);
            entity.TemplateId = template.Id;
            return entity;
        }).ToList();
        var newDocumentSettings = dto.DocumentSettings.Select(d =>
        {
            var entity = _mapper.Map<TemplateDocumentSetting>(d);
            entity.TemplateId = template.Id;
            return entity;
        }).ToList();

        _context.TemplateIdentityFields.AddRange(newIdentityFields);
        _context.TemplateFieldGroupRules.AddRange(newGroupRules);
        _context.TemplatePhotoSettings.AddRange(newPhotoSettings);
        _context.TemplateDocumentSettings.AddRange(newDocumentSettings);

        await _context.SaveChangesAsync(cancellationToken);
        await tx.CommitAsync(cancellationToken);

        var reloaded = await _templates.GetByIdWithChildrenAsync(template.Id, cancellationToken);
        return Result<TemplateDetailDto>.Success(ToDetailDto(reloaded!), "Template updated.");
    }

    /// <inheritdoc />
    public async Task<Result<TemplateDetailDto>> CloneAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var source = await _templates.GetByIdWithChildrenAsync(id, cancellationToken);
        if (source is null)
            return Result<TemplateDetailDto>.Failure("Template not found.");

        await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);

        var nextVersion = await _templates.GetMaxVersionAsync(source.CompanyName, source.InsuranceType, cancellationToken) + 1;

        var clone = new Template
        {
            CompanyName = source.CompanyName,
            InsuranceType = source.InsuranceType,
            Name = source.Name,
            Version = nextVersion,
            Status = TemplateStatus.Draft,
            ClaimantTypes = source.ClaimantTypes.ToList(),
            RequireIncidentDt = source.RequireIncidentDt,
            RequireLocation = source.RequireLocation,
            MinDescriptionLen = source.MinDescriptionLen,
            IdentityFields = source.IdentityFields.Select(f => new TemplateIdentityField
            {
                FieldKey = f.FieldKey,
                Label = f.Label,
                PromptText = f.PromptText,
                Placeholder = f.Placeholder,
                ValidationRegex = f.ValidationRegex,
                GroupKey = f.GroupKey,
                IsSkippable = f.IsSkippable,
                DisplayOrder = f.DisplayOrder
            }).ToList(),
            GroupRules = source.GroupRules.Select(r => new TemplateFieldGroupRule
            {
                GroupKey = r.GroupKey,
                MinRequired = r.MinRequired,
                MaxAllowed = r.MaxAllowed,
                ErrorMessage = r.ErrorMessage
            }).ToList(),
            PhotoSettings = source.PhotoSettings.Select(p => new TemplatePhotoSetting
            {
                GroupKey = p.GroupKey,
                Label = p.Label,
                Instruction = p.Instruction,
                MinCount = p.MinCount,
                MaxCount = p.MaxCount,
                IsRequired = p.IsRequired,
                AllowedAngles = p.AllowedAngles.ToList(),
                SampleImageUrls = p.SampleImageUrls.ToList(),
                ShowSample = p.ShowSample,
                MaxFileSizeMb = p.MaxFileSizeMb,
                AllowedMimeTypes = p.AllowedMimeTypes.ToList(),
                DisplayOrder = p.DisplayOrder
            }).ToList(),
            DocumentSettings = source.DocumentSettings.Select(d => new TemplateDocumentSetting
            {
                DocKey = d.DocKey,
                Label = d.Label,
                Instruction = d.Instruction,
                MinCount = d.MinCount,
                MaxCount = d.MaxCount,
                IsRequired = d.IsRequired,
                MaxFileSizeMb = d.MaxFileSizeMb,
                AllowedMimeTypes = d.AllowedMimeTypes.ToList(),
                DisplayOrder = d.DisplayOrder
            }).ToList()
        };

        _context.Templates.Add(clone);
        await _context.SaveChangesAsync(cancellationToken);
        await tx.CommitAsync(cancellationToken);

        _logger.LogInformation("Cloned template {SourceId} → {CloneId} v{Version}", source.Id, clone.Id, clone.Version);

        var reloaded = await _templates.GetByIdWithChildrenAsync(clone.Id, cancellationToken);
        return Result<TemplateDetailDto>.Success(ToDetailDto(reloaded!), "Template cloned to a new draft version.");
    }

    /// <inheritdoc />
    public async Task<Result<TemplateDetailDto>> ActivateAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var exists = await _templates.ExistsAsync(id, cancellationToken);
        if (!exists)
            return Result<TemplateDetailDto>.Failure("Template not found.");

        await _templates.ActivateAsync(id, cancellationToken);
        _logger.LogInformation("Activated template {TemplateId}", id);

        var reloaded = await _templates.GetByIdWithChildrenAsync(id, cancellationToken);
        return Result<TemplateDetailDto>.Success(ToDetailDto(reloaded!), "Template activated.");
    }

    /// <inheritdoc />
    public async Task<Result> DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var template = await _templates.GetByIdWithChildrenAsync(id, cancellationToken);
        if (template is null)
            return Result.Failure("Template not found.");

        await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);

        // Explicit cascade soft-delete. The DB FK has ON DELETE CASCADE for physical
        // deletes only; the AuditableEntityInterceptor flips EF deletes to soft-deletes
        // per-row, so we must enumerate the children ourselves.
        foreach (var f in template.IdentityFields.ToList()) _context.TemplateIdentityFields.Remove(f);
        foreach (var r in template.GroupRules.ToList()) _context.TemplateFieldGroupRules.Remove(r);
        foreach (var p in template.PhotoSettings.ToList()) _context.TemplatePhotoSettings.Remove(p);
        foreach (var d in template.DocumentSettings.ToList()) _context.TemplateDocumentSettings.Remove(d);
        _context.Templates.Remove(template);

        await _context.SaveChangesAsync(cancellationToken);
        await tx.CommitAsync(cancellationToken);

        _logger.LogInformation("Soft-deleted template {TemplateId}", id);
        return Result.Success("Template deleted.");
    }

    /// <inheritdoc />
    public async Task<Result<TemplateConfigResponseDto>> SyncToAiAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var template = await _templates.GetByIdWithChildrenAsync(id, cancellationToken);
        if (template is null)
            return Result<TemplateConfigResponseDto>.Failure("Template not found.");

        return await PushTemplateToAiAsync(template, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<Result<TemplateConfigResponseDto>> SyncActiveToAiAsync(string companyName, InsuranceType insuranceType, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(companyName))
            return Result<TemplateConfigResponseDto>.Failure("Company name is required.");

        var template = await _templates.GetActiveAsync(companyName, insuranceType, cancellationToken);
        if (template is null)
            return Result<TemplateConfigResponseDto>.Failure(
                $"No active template for {companyName} / {insuranceType}.");

        return await PushTemplateToAiAsync(template, cancellationToken);
    }

    private async Task<Result<TemplateConfigResponseDto>> PushTemplateToAiAsync(Template template, CancellationToken cancellationToken)
    {
        var payload = _mapper.Map<TemplateConfigRequestDto>(template);
        payload.IdentityFields = template.IdentityFields
            .OrderBy(f => f.DisplayOrder)
            .Select(f => _mapper.Map<TemplateConfigIdentityFieldDto>(f))
            .ToList();
        payload.GroupRules = template.GroupRules
            .OrderBy(r => r.GroupKey)
            .Select(r => _mapper.Map<TemplateConfigGroupRuleDto>(r))
            .ToList();
        payload.PhotoSettings = template.PhotoSettings
            .OrderBy(p => p.DisplayOrder)
            .Select(p => _mapper.Map<TemplateConfigPhotoSettingDto>(p))
            .ToList();
        payload.DocumentSettings = template.DocumentSettings
            .OrderBy(d => d.DisplayOrder)
            .Select(d => _mapper.Map<TemplateConfigDocumentSettingDto>(d))
            .ToList();

        _logger.LogInformation("Syncing template {TemplateId} v{Version} to AI/ML", template.Id, template.Version);
        return await _aiMlClient.SyncTemplateConfigAsync(payload, cancellationToken);
    }

    private TemplateDetailDto ToDetailDto(Template template)
    {
        var dto = _mapper.Map<TemplateDetailDto>(template);
        dto.IdentityFields = template.IdentityFields
            .OrderBy(f => f.DisplayOrder)
            .Select(f => _mapper.Map<IdentityFieldDto>(f))
            .ToList();
        dto.GroupRules = template.GroupRules
            .OrderBy(r => r.GroupKey)
            .Select(r => _mapper.Map<GroupRuleDto>(r))
            .ToList();
        dto.PhotoSettings = template.PhotoSettings
            .OrderBy(p => p.DisplayOrder)
            .Select(p => _mapper.Map<PhotoSettingDto>(p))
            .ToList();
        dto.DocumentSettings = template.DocumentSettings
            .OrderBy(d => d.DisplayOrder)
            .Select(d => _mapper.Map<DocumentSettingDto>(d))
            .ToList();
        return dto;
    }
}
