using ClaimAI.Application.DTOs.MobileUsers;
using ClaimAI.Domain.Common;

namespace ClaimAI.Application.Interfaces;

public interface IMobileUserService
{
    Task<Result<List<MobileUserDto>>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<Result<MobileUserDto>> GetByIdAsync(string id, CancellationToken cancellationToken = default);
}
