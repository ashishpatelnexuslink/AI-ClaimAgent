using ClaimAI.Application.DTOs.Admin;
using ClaimAI.Domain.Common;

namespace ClaimAI.Application.Interfaces;

public interface IAdminUserService
{
    Task<Result<List<AdminUserDto>>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<Result<AdminUserDto>> CreateAsync(CreateAdminUserDto request, CancellationToken cancellationToken = default);
    Task<Result<AdminUserDto>> UpdateAsync(string id, UpdateAdminUserDto request, CancellationToken cancellationToken = default);
    Task<Result> DeleteAsync(string id, CancellationToken cancellationToken = default);
}
