import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLayout extends StatelessWidget {
  final Widget content;

  const AuthLayout({super.key, required this.content});

  static const _bgColor = Color(0xFFF8F8F8);
  static const _cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Logo - source PNG is 500x500 with whitespace,
                    // display larger so visible content matches Figma
                    Image.asset(
                      'assets/images/draudita_logo.png',
                      width: 420,
                      height: 168,
                      fit: BoxFit.contain,
                    ),
                    // Title — pulled up to reduce gap from logo's built-in whitespace
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: const Text(
                        'AI-Powered\nClaim Handling',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Claims handled with care and precision.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // White card - contains content + secure text + terms
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Middle content (Login form or OTP form)
                          content,
                          const SizedBox(height: 24),
                          // Secure encrypted access
                          const Text(
                            'SECURE ENCRYPTED ACCESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9CA3AF),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Divider line
                          const Divider(
                            color: Color(0xFFE5E7EB),
                            thickness: 1,
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          // Terms text
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                              ),
                              children: const [
                                TextSpan(
                                    text:
                                        'By continuing, you agree to our '),
                                TextSpan(
                                  text: 'Terms of\nService',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom bar - Verified Protection (floating rounded card)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Shield icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Color(0xFF044DAE),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Verified Protection',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your data is secured by neural encryption.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
