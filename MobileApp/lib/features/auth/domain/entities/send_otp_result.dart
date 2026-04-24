class SendOtpResult {
  final String otp;
  final bool isNewUser;

  const SendOtpResult({
    required this.otp,
    required this.isNewUser,
  });
}
