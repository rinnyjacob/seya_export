import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/modern_button.dart';
import '../widgets/glass_card.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  final VoidCallback? onAccepted;
  const TermsAcceptanceScreen({super.key, this.onAccepted});

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isLoading = false;

  Future<void> _acceptAndContinue() async {
    if (!_termsAccepted || !_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept both Terms & Conditions and Privacy Policy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Store locally that terms are accepted for this user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('termsAccepted_$userId', true);

      // Update expert document with acceptance using set with merge
      await FirebaseFirestore.instance.collection('experts').doc(userId).set({
        'termsAccepted': true,
        'privacyAccepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        // If callback provided, call it, else default to home
        if (widget.onAccepted != null) {
          widget.onAccepted!();
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    primaryColor.withValues(alpha: 0.05),
                    Colors.white,
                    primaryColor.withValues(alpha: 0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header
                Text(
                  'Welcome! 👋',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Before you continue, please review and accept our policies',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                // Terms & Conditions Card
                GlassCard(
                  borderRadius: 20,
                  blur: 12,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Terms & Conditions',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            '''TERMS & CONDITIONS

(Freelance Expert Agreement)

Effective Date: 24/02/2026
Issued by SEYA-AI SOLUTIONS, managing the brand name SEYA AuOrA (hereinafter referred to as the “Platform”, “Company”, “Firm”, “We”, “Us”, or “Our”).

1. Definitions and Interpretation

For the purposes of this Agreement, the following terms shall have the meanings assigned below:

“Platform” / “Company” / “Firm” means SEY-AI SOLUTIONS the lawful owner and operator of SEYA AuOrA and the SEYA Expert App, including all associated technology, branding, systems, and infrastructure.

“Expert” means an independent freelance individual enrolled on the Platform to provide advisory services.

“User” means any individual or entity accessing or using the Platform to avail services.

“Services” means astrology-based consultations, spiritual guidance, AI-assisted interpretations, digital reports, community facilitation, and related advisory services.

“Content” means profile information, images, videos, chat communications, recordings, testimonials, documents, and any materials uploaded, transmitted, or shared through the Platform.

“App” means the SEYA Expert App and all associated systems, dashboards, websites, and digital interfaces operated by the Platform.

2. Nature of Engagement

The Expert is engaged strictly as an independent freelance contractor. Nothing contained in this Agreement shall be construed to create an employer–employee relationship, partnership, joint venture, agency, or fiduciary relationship between the Expert and the Platform. The Expert remains solely responsible for income tax compliance, GST compliance where applicable, statutory registrations, professional obligations, and regulatory compliance. The Platform does not guarantee minimum work allocation, income levels, session volume, or engagement frequency.

3. Pricing Control and Revenue Sharing

All service pricing displayed on the Platform shall be exclusively determined, controlled, modified, and managed by the Platform. The display pricing and the applicable revenue-sharing percentage may vary depending on the nature, category, duration, complexity, or type of service, consultation, package, or program offered through the Platform. The applicable pricing structure and revenue-sharing ratio shall be decided by the Platform and formally communicated and confirmed to the Expert via official email prior to the commencement or listing of such services.

Experts shall not independently set pricing, negotiate fees outside the Platform, alter approved pricing structures, or accept direct payments from Users under any circumstances. Unless otherwise specifically revised and confirmed through official written communication

In the event that the Expert does not respond to or formally acknowledge the pricing confirmation or any pricing revision communicated via official email, and continues to provide services after such communication, the pricing and applicable revenue-sharing structure conveyed by the Platform shall be deemed automatically accepted, binding, and enforceable. The Expert shall be considered to have given implied consent by continuing to remain active or by rendering services on the Platform.

For initial onboarding, if the Expert fails to provide written acceptance of the communicated display pricing prior to activation, the Expert’s profile shall be placed on hold, and the Expert shall not be permitted to provide services on the Platform until such acceptance is formally received and confirmed by the Platform.

The Platform further reserves the right to introduce promotional pricing, discounts, bundled services, subscription models, dynamic pricing mechanisms, campaign-based adjustments, or commission structure modifications at its sole discretion in response to market conditions, business requirements, or strategic considerations.

4. Payments and Monthly Settlement

Expert payouts shall be processed on a monthly basis by SEYA-AI SOLUTIONS. Payments shall be subject to platform commission deductions, refunds, chargebacks, gateway fees, statutory deductions, and compliance adjustments. The Platform reserves the right to withhold, delay, or adjust payouts in cases involving disputes, suspected misconduct, fraud investigations, user complaints, or policy violations. Settlement statements issued by the Platform shall be deemed final unless formally disputed within a reasonable period.

5. TDS Deduction and Tax Compliance (India)

Tax Deducted at Source (TDS) shall be deducted in accordance with the provisions of the Indian Income Tax Act. Indian Experts must provide a valid Permanent Account Number (PAN), failing which TDS may be deducted at higher statutory rates. The Platform shall issue TDS certificates within legally prescribed timelines. Non-Indian nationals or Experts without PAN may contact support@seyaauora.com for compliance assistance. The Expert remains solely responsible for filing tax returns and fulfilling GST obligations, where applicable.

6. Non-Solicitation and Off-Platform Restrictions

Experts are strictly prohibited from sharing personal contact details including phone numbers, WhatsApp information, email addresses, social media handles, or personal website links with Users. Experts shall not request Users to connect outside the Platform, continue private consultations, or accept direct payments. All communications must remain within the Platform ecosystem. Violation of this clause may result in immediate suspension, permanent termination, forfeiture of pending pay-outs, legal action, and blacklisting. This obligation shall survive termination of this Agreement.

7. Professional Conduct

Experts agree to maintain professionalism at all times and shall not guarantee outcomes, make unverifiable claims, misrepresent qualifications, or claim medical, legal, or financial authority without proper licensing. Harassment, exploitation, coercion, discrimination, or unethical conduct shall result in disciplinary action, including termination.

8. Limitation of Liability and Indemnification

The Platform does not guarantee income levels, user volume, booking frequency, advice accuracy, or client satisfaction. The Platform shall not be liable for financial losses, reputational damage, emotional distress claims, indirect or consequential damages, regulatory complaints, or off-platform arrangements initiated by the Expert. The Expert agrees to indemnify, defend, and hold harmless the Platform against all claims, liabilities, damages, losses, or expenses arising from services rendered or representations made by the Expert.

9. Suspension and Termination

Experts may voluntarily terminate their association by providing written notice via registered email and fulfilling all pending obligations.

The Platform reserves the right to suspend or terminate access without prior notice in cases including but not limited to policy violations, user complaints, fraud, inactivity, payment bypass attempts, reputational risk, regulatory non-compliance, misrepresentation, or internal restructuring. Decisions of the Platform shall be final and binding.

10. Intellectual Property

All trademarks, brand assets, logos, software systems, and proprietary materials remain the exclusive property of SEYA AuOrA. By enrolling, the Expert grants the Platform a worldwide, royalty-free, perpetual license to use their name, likeness, profile image, videos, content and testimonials for branding, advertising, marketing, and promotional purposes.

11. Confidentiality

Experts shall maintain strict confidentiality with respect to all information obtained through or in connection with the Platform, including but not limited to User data, financial arrangements, pricing structures, platform algorithms, internal communications, business strategies, technical processes, and other proprietary or confidential information (“Confidential Information”).

Experts shall not disclose, reproduce, use, or permit the use of any Confidential Information except as strictly necessary for the proper performance of their obligations under this Agreement.

The confidentiality obligations set forth herein shall survive termination or expiration of this Agreement. Any unauthorized disclosure or misuse of Confidential Information may result in legal liability, including but not limited to injunctive relief, damages, and any other remedies available under applicable law.

12. Governing Law and Jurisdiction

This Agreement shall be governed by and construed in accordance with the laws of India. Any disputes arising under or in connection with this Agreement shall be subject to the exclusive jurisdiction of the competent courts located in Indore, Madhya Pradesh, India.

13. Expert Confirmation Statement

Experts represent and warrant that all information, credentials, certifications, licenses, identification documents, and other details provided to the Platform are true, accurate, complete, and not misleading. Submission of forged, falsified, altered, or misleading documents or information is strictly prohibited.

In the event that any information provided by the Expert is found to be false, accurate, misleading, or supported by forged or fraudulent documentation, the Platform shall not be liable for any resulting loss, damage, dispute, or claim arising therefrom. The Platform reserves the absolute right to immediately suspend or terminate the Expert’s access and Agreement without prior notice.

Further, the Platform reserves the right to initiate appropriate legal proceedings, claim damages, and pursue any civil or criminal remedies available under applicable law against the Expert for such misconduct.

By enrolling, registering, or continuing to use SEYA AuOrA, the Expert hereby confirms that they have read, understood, and voluntarily agree to accept and be legally bound by all Terms & Conditions, Privacy Policy provisions, declarations, and policies mentioned in this document in their entirety.

SEYA AuOrA – EXPERT APP''',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          setState(() => _termsAccepted = !_termsAccepted);
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _termsAccepted ? primaryColor : Colors.grey,
                                  width: 2,
                                ),
                                color: _termsAccepted
                                    ? primaryColor
                                    : Colors.transparent,
                              ),
                              child: _termsAccepted
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'I have read and accept the Terms & Conditions',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Privacy Policy Card
                GlassCard(
                  borderRadius: 20,
                  blur: 12,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.lightAccent.withValues(alpha: 0.2),
                            ),
                            child: const Icon(
                              Icons.privacy_tip_outlined,
                              color: AppColors.lightAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Privacy Policy',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            '''PRIVACY POLICY

1. Information Collected

The Platform may collect personal and professional information including name, phone number, email address, PAN details, bank details, identity legal documents, profile photographs, uploaded videos, testimonials, chat logs, session recordings, device identifiers, IP addresses, and approximate location data.

2. Purpose of Data Processing

Collected information may be used for profile display, verification, payment processing, TDS compliance, GST reporting, audit procedures, fraud monitoring, legal compliance, marketing initiatives, branding activities, and social media promotions.

3. Media Usage Consent

By enrolling, the Expert grants the Platform the right to use images, videos, testimonials, and profile information for advertising, promotional, and branding purposes across digital and offline channels. While reasonable safeguards are implemented, the Platform shall not be responsible for third-party misuse beyond its reasonable control.

4. Data Sharing

Information may be shared with payment processors, banking partners, legal authorities, regulatory bodies, auditors, and service providers strictly for operational and statutory purposes. The Platform does not sell personal data to third parties.

5. Data Retention

Personal and transactional data may be retained for compliance requirements, tax reporting, audit purposes, fraud detection, and dispute resolution in accordance with applicable Indian laws.

6. Security Disclaimer

The Platform implements commercially reasonable administrative, technical, and organizational safeguards to protect personal information; however, absolute security cannot be guaranteed due to inherent risks associated with digital transmission.

7. Amendments and Automatic Acceptance

The Platform reserves the right to revise, modify, update, or amend these Terms & Conditions and the Privacy Policy at any time at its sole discretion. Any such revisions shall become effective upon being published on the Platform or communicated through official channels. Continued access to, enrolment in, or use of the Platform after such revisions shall constitute automatic acceptance of the updated Terms & Conditions and Privacy Policy. If the Expert does not agree to the revised terms and policies, the Expert must discontinue use of the Platform immediately.

8. Data Deletion Requests

Experts may request deletion of their personal data maintained by the Platform by submitting a written request to the Platform’s official email address support@seyaauora.com. The request must be sent from the registered email ID associated with the Expert’s account and must clearly specify the data deletion request.

Upon receipt and verification of the request, the Platform shall process the deletion in accordance with applicable laws and internal data retention policies. The Platform reserves the right to retain certain information where required for legal compliance, dispute resolution, fraud prevention, enforcement of this Agreement, or other legitimate business purposes.

Deletion of data may result in suspension or permanent termination of access to the Platform.''',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          setState(() => _privacyAccepted = !_privacyAccepted);
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _privacyAccepted ? AppColors.lightAccent : Colors.grey,
                                  width: 2,
                                ),
                                color: _privacyAccepted
                                    ? AppColors.lightAccent
                                    : Colors.transparent,
                              ),
                              child: _privacyAccepted
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'I have read and accept the Privacy Policy',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Accept Button
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : ModernButton(
                          label: 'Accept & Continue',
                          onPressed: () => _acceptAndContinue(),
                          height: 56,
                        ),
                ),

                const SizedBox(height: 16),

                // Info text
                Center(
                  child: Text(
                    'You must accept both policies to continue',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
