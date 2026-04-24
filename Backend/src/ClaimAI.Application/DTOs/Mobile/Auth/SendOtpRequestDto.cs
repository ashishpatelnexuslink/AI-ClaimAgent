using System.ComponentModel.DataAnnotations;

namespace ClaimAI.Application.DTOs.Mobile.Auth;

public class SendOtpRequestDto
{
    [Required(ErrorMessage = "Phone number is required.")]
    [Phone(ErrorMessage = "Invalid phone number format.")]
    public string PhoneNumber { get; set; } = string.Empty;
}
