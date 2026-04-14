import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Widget to display user birth details (age, zodiac sign, place of birth)
class UserBirthDetailsWidget extends StatelessWidget {
  final String userId;
  final Map<String, dynamic>? birthDetailsData; // Optional: pass directly if available
  final bool isCompact; // if true, shows inline, else shows card format
  final Color? textColor;

  const UserBirthDetailsWidget({
    super.key,
    required this.userId,
    this.birthDetailsData,
    this.isCompact = false,
    this.textColor,
  });

  /// Calculate age from birth date
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Get zodiac sign from birth date
  static String getZodiacSign(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return '♈ Aries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return '♉ Taurus';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return '♊ Gemini';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return '♋ Cancer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return '♌ Leo';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return '♍ Virgo';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return '♎ Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return '♏ Scorpio';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return '♐ Sagittarius';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return '♑ Capricorn';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return '♒ Aquarius';
    return '♓ Pisces';
  }

  /// Format birth date
  static String formatBirthDate(DateTime birthDate) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[birthDate.month - 1]} ${birthDate.day}, ${birthDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    // If birthDetailsData is provided directly, use it
    if (birthDetailsData != null) {
      return _buildWithData(context, birthDetailsData!);
    }

    // Otherwise fetch from Firestore users collection
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        // Check if birthDetails is a nested map or direct fields
        final birthData = userData['birthDetails'] as Map<String, dynamic>? ?? userData;

        return _buildWithData(context, birthData);
      },
    );
  }

  Widget _buildWithData(BuildContext context, Map<String, dynamic> birthData) {
    final dateOfBirthTimestamp = birthData['dateOfBirth'] as Timestamp?;

    if (dateOfBirthTimestamp == null) {
      return const SizedBox.shrink();
    }

    try {
      final birthDate = dateOfBirthTimestamp.toDate();
      final age = calculateAge(birthDate);
      final zodiac = getZodiacSign(birthDate);
      final formattedDate = formatBirthDate(birthDate);

      final fullName = birthData['fullName'] as String? ?? 'User';
      final gender = birthData['gender'] as String? ?? '';
      // Support both placeOfBirth and place_of_birth_* fields
      String placeOfBirth = birthData['placeOfBirth'] as String? ?? '';
      if (placeOfBirth.isEmpty) {
        final city = birthData['place_of_birth_city'] as String? ?? '';
        final state = birthData['place_of_birth_state'] as String? ?? '';
        final country = birthData['place_of_birth_country'] as String? ?? '';
        placeOfBirth = [city, state, country].where((e) => e.isNotEmpty).join(', ');
      }
      final timeOfBirth = birthData['timeOfBirth'] as String? ?? '';
      // Support concern as String or List
      String concern = '';
      if (birthData['concern'] is String) {
        concern = birthData['concern'] as String;
      } else if (birthData['concern'] is List) {
        concern = (birthData['concern'] as List).whereType<String>().join(', ');
      }
      final relationship = birthData['relationship'] as String? ?? '';

      if (isCompact) {
        return _buildCompactView(age, zodiac, fullName);
      } else {
        return _buildCardView(
          context,
          age,
          zodiac,
          formattedDate,
          fullName,
          gender,
          placeOfBirth,
          timeOfBirth,
          concern,
          relationship,
        );
      }
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildCompactView(int age, String zodiac, String fullName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          fullName,
          style: TextStyle(
            color: textColor ?? AppColors.lightPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$age yrs',
                style: TextStyle(
                  color: textColor ?? AppColors.lightPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                zodiac,
                style: TextStyle(
                  color: textColor ?? AppColors.lightAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardView(
    BuildContext context,
    int age,
    String zodiac,
    String formattedDate,
    String fullName,
    String gender,
    String placeOfBirth,
    String timeOfBirth,
    String concern,
    String relationship,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 16,
      blur: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Birth Details',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              Icon(
                Icons.cake_outlined,
                size: 18,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fullName.isNotEmpty) ...[
            _detailRow('Name', fullName, context),
            const SizedBox(height: 10),
          ],
          _detailRow('Date of Birth', formattedDate, context),
          const SizedBox(height: 10),
          _detailRow('Age', '$age years old', context),
          const SizedBox(height: 10),
          _detailRow('Zodiac Sign', zodiac, context),
          if (gender.isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailRow('Gender', gender, context),
          ],
          if (placeOfBirth.isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailRow('Place of Birth', placeOfBirth, context),
          ],
          if (timeOfBirth.isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailRow('Time of Birth', timeOfBirth, context),
          ],
          if (concern.isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailRow('Concern', concern, context),
          ],
          if (relationship.isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailRow('Relationship', relationship, context),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white54 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            textAlign: TextAlign.end,
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline widget for showing age and zodiac in compact form
class UserBirthInfoBadge extends StatelessWidget {
  final String userId;
  final Color? backgroundColor;
  final Color? textColor;

  const UserBirthInfoBadge({
    super.key,
    required this.userId,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return UserBirthDetailsWidget(
      userId: userId,
      isCompact: true,
      textColor: textColor,
    );
  }
}
