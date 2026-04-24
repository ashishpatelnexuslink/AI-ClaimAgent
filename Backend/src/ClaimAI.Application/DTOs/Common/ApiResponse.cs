namespace ClaimAI.Application.DTOs.Common;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public T? Data { get; set; }
    public List<string>? Errors { get; set; }
    public int StatusCode { get; set; }

    public static ApiResponse<T> SuccessResponse(T data, string? message = null, int statusCode = 200)
        => new() { Success = true, Data = data, Message = message, StatusCode = statusCode };

    public static ApiResponse<T> FailResponse(string error, int statusCode = 400)
        => new() { Success = false, Errors = [error], StatusCode = statusCode };

    public static ApiResponse<T> FailResponse(List<string> errors, int statusCode = 400)
        => new() { Success = false, Errors = errors, StatusCode = statusCode };
}
