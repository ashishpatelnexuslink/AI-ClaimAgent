using ClaimAI.Application.DTOs.AppVersions;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Entities;
using ClaimAI.Domain.Enums;
using ClaimAI.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.Infrastructure.Services;

public class AppVersionService : IAppVersionService
{
    private readonly ApplicationDbContext _context;

    public AppVersionService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<List<AppVersionDto>>> GetAllAsync(AppPlatform? platform, CancellationToken cancellationToken = default)
    {
        var query = _context.AppVersions.AsNoTracking();
        if (platform.HasValue)
            query = query.Where(v => v.Platform == platform.Value);

        var versions = await query
            .OrderByDescending(v => v.ReleaseDate)
            .ThenByDescending(v => v.VersionCode)
            .Select(v => Map(v))
            .ToListAsync(cancellationToken);

        return Result<List<AppVersionDto>>.Success(versions);
    }

    public async Task<Result<AppVersionDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _context.AppVersions.AsNoTracking()
            .FirstOrDefaultAsync(v => v.Id == id, cancellationToken);
        if (entity is null)
            return Result<AppVersionDto>.Failure("App version not found.");
        return Result<AppVersionDto>.Success(Map(entity));
    }

    public async Task<Result<AppVersionDto>> GetLatestAsync(AppPlatform platform, CancellationToken cancellationToken = default)
    {
        var entity = await _context.AppVersions.AsNoTracking()
            .Where(v => v.Platform == platform && v.IsLatest)
            .FirstOrDefaultAsync(cancellationToken);

        // Fallback to highest VersionCode if no row is explicitly marked latest
        entity ??= await _context.AppVersions.AsNoTracking()
            .Where(v => v.Platform == platform)
            .OrderByDescending(v => v.VersionCode)
            .FirstOrDefaultAsync(cancellationToken);

        if (entity is null)
            return Result<AppVersionDto>.Failure("No app version configured for this platform.");

        return Result<AppVersionDto>.Success(Map(entity));
    }

    public async Task<Result<AppVersionDto>> CreateAsync(CreateAppVersionDto dto, CancellationToken cancellationToken = default)
    {
        var duplicate = await _context.AppVersions
            .AnyAsync(v => v.Platform == dto.Platform && v.VersionCode == dto.VersionCode, cancellationToken);
        if (duplicate)
            return Result<AppVersionDto>.Failure($"Version code {dto.VersionCode} already exists for {dto.Platform}.");

        await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);

        if (dto.IsLatest)
            await ClearLatestAsync(dto.Platform, cancellationToken);

        var entity = new AppVersion
        {
            Platform = dto.Platform,
            VersionName = dto.VersionName.Trim(),
            VersionCode = dto.VersionCode,
            MinSupportedVersionCode = dto.MinSupportedVersionCode,
            IsLatest = dto.IsLatest,
            IsMandatory = dto.IsMandatory,
            ReleaseNotes = dto.ReleaseNotes,
            ReleaseDate = dto.ReleaseDate ?? DateTime.UtcNow,
            StoreUrl = dto.StoreUrl,
        };

        _context.AppVersions.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        await tx.CommitAsync(cancellationToken);

        return Result<AppVersionDto>.Success(Map(entity), "App version created.");
    }

    public async Task<Result<AppVersionDto>> UpdateAsync(Guid id, UpdateAppVersionDto dto, CancellationToken cancellationToken = default)
    {
        var entity = await _context.AppVersions.FirstOrDefaultAsync(v => v.Id == id, cancellationToken);
        if (entity is null)
            return Result<AppVersionDto>.Failure("App version not found.");

        var duplicate = await _context.AppVersions
            .AnyAsync(v => v.Id != id && v.Platform == dto.Platform && v.VersionCode == dto.VersionCode, cancellationToken);
        if (duplicate)
            return Result<AppVersionDto>.Failure($"Version code {dto.VersionCode} already exists for {dto.Platform}.");

        await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);

        if (dto.IsLatest && (!entity.IsLatest || entity.Platform != dto.Platform))
            await ClearLatestAsync(dto.Platform, cancellationToken, exceptId: id);

        entity.Platform = dto.Platform;
        entity.VersionName = dto.VersionName.Trim();
        entity.VersionCode = dto.VersionCode;
        entity.MinSupportedVersionCode = dto.MinSupportedVersionCode;
        entity.IsLatest = dto.IsLatest;
        entity.IsMandatory = dto.IsMandatory;
        entity.ReleaseNotes = dto.ReleaseNotes;
        if (dto.ReleaseDate.HasValue)
            entity.ReleaseDate = dto.ReleaseDate.Value;
        entity.StoreUrl = dto.StoreUrl;

        await _context.SaveChangesAsync(cancellationToken);
        await tx.CommitAsync(cancellationToken);

        return Result<AppVersionDto>.Success(Map(entity), "App version updated.");
    }

    public async Task<Result> DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _context.AppVersions.FirstOrDefaultAsync(v => v.Id == id, cancellationToken);
        if (entity is null)
            return Result.Failure("App version not found.");

        entity.IsDeleted = true;
        entity.IsLatest = false;
        await _context.SaveChangesAsync(cancellationToken);
        return Result.Success("App version deleted.");
    }

    public async Task<Result<VersionCheckResponseDto>> CheckAsync(VersionCheckRequestDto request, CancellationToken cancellationToken = default)
    {
        var latestResult = await GetLatestAsync(request.Platform, cancellationToken);
        if (!latestResult.Succeeded || latestResult.Data is null)
            return Result<VersionCheckResponseDto>.Failure(latestResult.Errors.FirstOrDefault() ?? "No version found.");

        var latest = latestResult.Data;
        var updateRequired = request.VersionCode < latest.MinSupportedVersionCode
            || (latest.IsMandatory && request.VersionCode < latest.VersionCode);
        var updateAvailable = request.VersionCode < latest.VersionCode;

        return Result<VersionCheckResponseDto>.Success(new VersionCheckResponseDto
        {
            UpdateRequired = updateRequired,
            UpdateAvailable = updateAvailable,
            IsMandatory = latest.IsMandatory,
            LatestVersionName = latest.VersionName,
            LatestVersionCode = latest.VersionCode,
            MinSupportedVersionCode = latest.MinSupportedVersionCode,
            StoreUrl = latest.StoreUrl,
            ReleaseNotes = latest.ReleaseNotes,
        });
    }

    private async Task ClearLatestAsync(AppPlatform platform, CancellationToken cancellationToken, Guid? exceptId = null)
    {
        var rows = await _context.AppVersions
            .Where(v => v.Platform == platform && v.IsLatest && (exceptId == null || v.Id != exceptId))
            .ToListAsync(cancellationToken);
        foreach (var r in rows)
            r.IsLatest = false;
    }

    private static AppVersionDto Map(AppVersion v) => new()
    {
        Id = v.Id,
        Platform = v.Platform.ToString(),
        VersionName = v.VersionName,
        VersionCode = v.VersionCode,
        MinSupportedVersionCode = v.MinSupportedVersionCode,
        IsLatest = v.IsLatest,
        IsMandatory = v.IsMandatory,
        ReleaseNotes = v.ReleaseNotes,
        ReleaseDate = v.ReleaseDate,
        StoreUrl = v.StoreUrl,
        CreatedAt = v.CreatedAt,
        UpdatedAt = v.UpdatedAt,
    };
}
