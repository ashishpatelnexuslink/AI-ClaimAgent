using ClaimAI.Application.DTOs.AiMl;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Templates;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.Interfaces;

public interface ITemplateService
{
    /// <summary>Returns a paged list of templates matching the supplied filters (no children).</summary>
    Task<Result<PagedResult<TemplateListItemDto>>> ListAsync(TemplateListQuery query, CancellationToken cancellationToken = default);

    /// <summary>Returns the full template tree (all four child collections included).</summary>
    Task<Result<TemplateDetailDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>Returns the currently Active template for (<paramref name="companyName"/>, <paramref name="insuranceType"/>).</summary>
    Task<Result<TemplateDetailDto>> GetActiveAsync(string companyName, InsuranceType insuranceType, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns the single active template (no tenant filter). Used by the
    /// mobile claim-summary page which has no company/insurance-type context.
    /// </summary>
    Task<Result<TemplateDetailDto>> GetSingleActiveAsync(CancellationToken cancellationToken = default);

    /// <summary>Creates a new template tree. The new row is always persisted as <c>Draft, Version=1</c> (first version for that company + type) or <c>maxVersion+1</c> if an existing row already occupies version 1.</summary>
    Task<Result<TemplateDetailDto>> CreateAsync(CreateTemplateDto dto, CancellationToken cancellationToken = default);

    /// <summary>Replaces the full tree for a Draft template. Fails when the target is not in <see cref="TemplateStatus.Draft"/>.</summary>
    Task<Result<TemplateDetailDto>> UpdateAsync(Guid id, UpdateTemplateDto dto, CancellationToken cancellationToken = default);

    /// <summary>Deep-copies an existing template into a new Draft row with <c>Version = maxVersion + 1</c>.</summary>
    Task<Result<TemplateDetailDto>> CloneAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>Transitions <paramref name="id"/> to Active, archiving the current active row (if any) for the same (CompanyName, InsuranceType).</summary>
    Task<Result<TemplateDetailDto>> ActivateAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>Soft-deletes a template. Fails when the target is not in <see cref="TemplateStatus.Draft"/>.</summary>
    Task<Result> DeleteAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>Loads the template tree and POSTs it to the AI/ML <c>/config</c> endpoint.</summary>
    Task<Result<TemplateConfigResponseDto>> SyncToAiAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Resolves the active template for (<paramref name="companyName"/>, <paramref name="insuranceType"/>) and POSTs it to the AI/ML <c>/config</c> endpoint.
    /// Used when the mobile app enters chat or voice mode.
    /// </summary>
    Task<Result<TemplateConfigResponseDto>> SyncActiveToAiAsync(string companyName, InsuranceType insuranceType, CancellationToken cancellationToken = default);
}
