namespace ClaimAI.Application.DTOs.Common;

/// <summary>
/// Generic paginated result envelope. <see cref="TotalCount"/> is the total
/// number of matching rows before paging; <see cref="Items"/> is the current page.
/// </summary>
public class PagedResult<T>
{
    public IReadOnlyList<T> Items { get; set; } = [];
    public int TotalCount { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => PageSize <= 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
}
