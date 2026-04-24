using System.ComponentModel.DataAnnotations;

namespace ClaimAI.Application.DTOs.Mobile.Auth;

public class VerifyOtpRequestDto
{
    [Required(ErrorMessage = "Phone number is required.")]
    [Phone(ErrorMessage = "Invalid phone number format.")]
    public string PhoneNumber { get; set; } = string.Empty;

    [Required(ErrorMessage = "OTP is required.")]
    [StringLength(6, MinimumLength = 6, ErrorMessage = "OTP must be 6 digits.")]
    public string Otp { get; set; } = string.Empty;
}
