using ClaimAI.Domain.Entities.Templates;
using ClaimAI.Domain.Enums;

namespace ClaimAI.Domain.Interfaces.Repositories;

/// <summary>
/// Aggregate-root repository for <see cref="Template"/>. The generic repository
/// covers simple CRUD for child entities; this contract adds the loads-with-children
/// and transactional operations that the <c>TemplateService</c> needs.
/// </summary>
public interface ITemplateRepository : IGenericRepository<Template>
{
    /// <summary>
    /// Returns the template with every child collection eagerly loaded, or
    /// <c>null</c> when no live row matches <paramref name="id"/>.
    /// </summary>
    Task<Template?> GetByIdWithChildrenAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns the currently active template (with children) for the given
    /// <paramref name="companyName"/> / <paramref name="insuranceType"/> pair,
    /// or <c>null</c> if none is active.
    /// </summary>
    Task<Template?> GetActiveAsync(string companyName, InsuranceType insuranceType, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns the single active template (with children), regardless of
    /// company / insurance type. Used by the mobile claim-summary page which
    /// only knows there's "the active template" without a tenant filter. If
    /// multiple Active rows exist, the most recently updated wins.
    /// </summary>
    Task<Template?> GetSingleActiveAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Lists templates (flat, no children) filtered by the supplied optional
    /// predicates and paged. Returns total count (before paging) for UI paging.
    /// </summary>
    Task<(IReadOnlyList<Template> Items, int TotalCount)> ListAsync(
        string? companyName,
        InsuranceType? insuranceType,
        TemplateStatus? status,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns the highest existing <c>Version</c> for the given company + insurance
    /// type pair, or 0 if no template exists yet. Used by the clone flow.
    /// </summary>
    Task<int> GetMaxVersionAsync(string companyName, InsuranceType insuranceType, CancellationToken cancellationToken = default);

    /// <summary>
    /// Transactionally activates <paramref name="templateId"/>: archives the current
    /// active row for the same (company, insurance type) pair (if any) and flips the
    /// target to <see cref="TemplateStatus.Active"/>. The partial unique index on
    /// (CompanyName, InsuranceType) WHERE Status='Active' enforces the invariant.
    /// </summary>
    Task ActivateAsync(Guid templateId, CancellationToken cancellationToken = default);
}
