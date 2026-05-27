using ClaimAI.Domain.Entities.Templates;
using ClaimAI.Domain.Enums;
using ClaimAI.Domain.Interfaces.Repositories;
using ClaimAI.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.Infrastructure.Repositories;

public class TemplateRepository : GenericRepository<Template>, ITemplateRepository
{
    public TemplateRepository(ApplicationDbContext context) : base(context)
    {
    }

    /// <inheritdoc />
    public async Task<Template?> GetByIdWithChildrenAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(t => t.IdentityFields).ThenInclude(f => f.Translations)
            .Include(t => t.GroupRules)
            .Include(t => t.PhotoSettings).ThenInclude(p => p.Translations)
            .Include(t => t.DocumentSettings).ThenInclude(d => d.Translations)
            .FirstOrDefaultAsync(t => t.Id == id, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<Template?> GetActiveAsync(string companyName, InsuranceType insuranceType, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(t => t.IdentityFields).ThenInclude(f => f.Translations)
            .Include(t => t.GroupRules)
            .Include(t => t.PhotoSettings).ThenInclude(p => p.Translations)
            .Include(t => t.DocumentSettings).ThenInclude(d => d.Translations)
            .FirstOrDefaultAsync(
                t => t.CompanyName == companyName
                  && t.InsuranceType == insuranceType
                  && t.Status == TemplateStatus.Active,
                cancellationToken);
    }

    /// <inheritdoc />
    public async Task<Template?> GetSingleActiveAsync(CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(t => t.IdentityFields).ThenInclude(f => f.Translations)
            .Include(t => t.GroupRules)
            .Include(t => t.PhotoSettings).ThenInclude(p => p.Translations)
            .Include(t => t.DocumentSettings).ThenInclude(d => d.Translations)
            .Where(t => t.Status == TemplateStatus.Active)
            .OrderByDescending(t => t.UpdatedAt ?? t.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
    }

    /// <inheritdoc />
    public async Task<(IReadOnlyList<Template> Items, int TotalCount)> ListAsync(
        string? companyName,
        InsuranceType? insuranceType,
        TemplateStatus? status,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var query = _dbSet.AsQueryable();

        if (!string.IsNullOrWhiteSpace(companyName))
            query = query.Where(t => t.CompanyName == companyName);

        if (insuranceType.HasValue)
            query = query.Where(t => t.InsuranceType == insuranceType.Value);

        if (status.HasValue)
            query = query.Where(t => t.Status == status.Value);

        var total = await query.CountAsync(cancellationToken);

        var safePage = pageNumber < 1 ? 1 : pageNumber;
        var safeSize = pageSize < 1 ? 20 : pageSize;

        var items = await query
            .OrderByDescending(t => t.CreatedAt)
            .Skip((safePage - 1) * safeSize)
            .Take(safeSize)
            .ToListAsync(cancellationToken);

        return (items, total);
    }

    /// <inheritdoc />
    public async Task<int> GetMaxVersionAsync(string companyName, InsuranceType insuranceType, CancellationToken cancellationToken = default)
    {
        var anyRow = await _dbSet
            .AnyAsync(t => t.CompanyName == companyName && t.InsuranceType == insuranceType, cancellationToken);

        if (!anyRow)
            return 0;

        return await _dbSet
            .Where(t => t.CompanyName == companyName && t.InsuranceType == insuranceType)
            .MaxAsync(t => t.Version, cancellationToken);
    }

    /// <inheritdoc />
    public async Task ActivateAsync(Guid templateId, CancellationToken cancellationToken = default)
    {
        var target = await _dbSet.FirstOrDefaultAsync(t => t.Id == templateId, cancellationToken)
            ?? throw new InvalidOperationException($"Template {templateId} not found.");

        await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);

        var currentActive = await _dbSet.FirstOrDefaultAsync(
            t => t.CompanyName == target.CompanyName
              && t.InsuranceType == target.InsuranceType
              && t.Status == TemplateStatus.Active
              && t.Id != target.Id,
            cancellationToken);

        if (currentActive is not null)
        {
            currentActive.Status = TemplateStatus.Archived;
            await _context.SaveChangesAsync(cancellationToken);
        }

        target.Status = TemplateStatus.Active;
        await _context.SaveChangesAsync(cancellationToken);

        await tx.CommitAsync(cancellationToken);
    }
}
