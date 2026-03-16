// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../theme/app_colors.dart';
// import '../widgets/modern_button.dart';
// import '../widgets/modern_text_field.dart';
// import '../widgets/glass_card.dart';
//
// class ExpertEditProfileScreen extends StatefulWidget {
//   const ExpertEditProfileScreen({super.key});
//
//   @override
//   State<ExpertEditProfileScreen> createState() =>
//       _ExpertEditProfileScreenState();
// }
//
// class _ExpertEditProfileScreenState extends State<ExpertEditProfileScreen> with TickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//
//   final _nameCtrl = TextEditingController();
//   final _skillCtrl = TextEditingController();
//   final _expCtrl = TextEditingController();
//   final _priceCtrl = TextEditingController();
//
//   bool isOnline = false;
//   bool loading = true;
//   bool isSaving = false;
//
//   bool canAudio = false;
//   bool canVideo = false;
//   bool canChat = false;
//
//   final uid = FirebaseAuth.instance.currentUser!.uid;
//   late AnimationController _avatarController;
//
//   @override
//   void initState() {
//     super.initState();
//     _avatarController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     )..forward();
//     _loadProfile();
//   }
//
//   Future<void> _loadProfile() async {
//     final doc = await FirebaseFirestore.instance.collection('experts').doc(uid).get();
//     final data = doc.data()!;
//     _nameCtrl.text = data['name'] ?? '';
//     _skillCtrl.text = data['skill'] ?? '';
//     _expCtrl.text = data['experience']?.toString() ?? '';
//     _priceCtrl.text = data['price_per_minute']?.toString() ?? '';
//     isOnline = data['is_online'] ?? false;
//     canAudio = data['can_video'] ?? false;
//     canVideo = data['can_audio'] ?? false;
//     canChat = data['can_chat'] ?? false;
//     setState(() => loading = false);
//   }
//
//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => isSaving = true);
//
//     try {
//       await FirebaseFirestore.instance.collection('experts').doc(uid).update({
//         'name': _nameCtrl.text.trim(),
//         'skill': _skillCtrl.text.trim(),
//         'experience': int.parse(_expCtrl.text),
//         'price_per_minute': int.parse(_priceCtrl.text),
//         'is_online': isOnline,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               const Icon(Icons.check_circle, color: Colors.white),
//               const SizedBox(width: 12),
//               const Text('Profile updated successfully'),
//             ],
//           ),
//           backgroundColor: AppColors.onlineGreen,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               const Icon(Icons.error_outline, color: Colors.white),
//               const SizedBox(width: 12),
//               Expanded(child: Text('Error: ${e.toString()}')),
//             ],
//           ),
//           backgroundColor: AppColors.lightError,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//     }
//
//     setState(() => isSaving = false);
//   }
//
//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _skillCtrl.dispose();
//     _expCtrl.dispose();
//     _priceCtrl.dispose();
//     _avatarController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
//
//     if (loading) {
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Loading profile...',
//                 style: Theme.of(context).textTheme.bodyMedium,
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           // Modern gradient header
//           SliverAppBar(
//             expandedHeight: 240,
//             floating: false,
//             pinned: true,
//             elevation: 0,
//             flexibleSpace: FlexibleSpaceBar(
//               background: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: isDark
//                         ? [
//                             const Color(0xFF1E293B),
//                             const Color(0xFF0F172A),
//                           ]
//                         : [
//                             primaryColor.withValues(alpha: 0.9),
//                             primaryColor.withValues(alpha: 0.6),
//                           ],
//                   ),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     // Animated avatar
//                     ScaleTransition(
//                       scale: Tween<double>(begin: 0.5, end: 1.0).animate(
//                         CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut),
//                       ),
//                       child: Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           gradient: LinearGradient(
//                             colors: isDark
//                                 ? AppColors.darkGradient
//                                 : AppColors.lightGradient,
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           border: Border.all(
//                             color: Colors.white,
//                             width: 4,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: primaryColor.withValues(alpha: 0.4),
//                               blurRadius: 20,
//                               spreadRadius: 5,
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.person,
//                           size: 50,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                       child: Column(
//                         children: [
//                           Text(
//                             'Edit Profile',
//                             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                               fontWeight: FontWeight.w700,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Update your professional information',
//                             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                               color: Colors.white.withValues(alpha: 0.7),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.white),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//
//           // Form content
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Basic Information Section
//                     _buildSectionHeader(context, 'Basic Information', Icons.info_outline),
//                     const SizedBox(height: 16),
//
//                     ModernTextField(
//                       label: 'Full Name',
//                       hint: 'Enter your full name',
//                       controller: _nameCtrl,
//                       prefixIcon: Icons.person_outline,
//                       keyboardType: TextInputType.name,
//                       validator: (v) => v!.isEmpty ? 'Name is required' : null,
//                     ),
//                     const SizedBox(height: 16),
//
//                     ModernTextField(
//                       label: 'Skill/Expertise',
//                       hint: 'e.g., Business Consultant, Financial Advisor',
//                       controller: _skillCtrl,
//                       prefixIcon: Icons.lightbulb_outline,
//                       validator: (v) => v!.isEmpty ? 'Skill is required' : null,
//                     ),
//                     const SizedBox(height: 28),
//
//                     // Professional Details Section
//                     _buildSectionHeader(context, 'Professional Details', Icons.work_outline),
//                     const SizedBox(height: 16),
//
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ModernTextField(
//                             label: 'Experience',
//                             hint: 'Years',
//                             controller: _expCtrl,
//                             keyboardType: TextInputType.number,
//                             prefixIcon: Icons.timeline,
//                             validator: (v) =>
//                                 int.tryParse(v ?? '') == null ? 'Invalid' : null,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: ModernTextField(
//                             label: 'Price/Minute',
//                             hint: '₹',
//                             controller: _priceCtrl,
//                             keyboardType: TextInputType.number,
//                             prefixIcon: Icons.account_balance_wallet_rounded,
//                             validator: (v) =>
//                                 int.tryParse(v ?? '') == null ? 'Invalid' : null,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 28),
//
//                     // Online Status Section
//                     GlassCard(
//                       borderRadius: 20,
//                       blur: 12,
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.circle,
//                                     size: 12,
//                                     color: isOnline
//                                         ? AppColors.onlineGreen
//                                         : AppColors.offlineGray,
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     'Online Status',
//                                     style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 isOnline
//                                     ? '🟢 Available for calls'
//                                     : '🔴 Not visible to clients',
//                                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                                   color: isDark
//                                       ? AppColors.darkTextSecondary
//                                       : AppColors.lightTextSecondary,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           Switch(
//                             value: isOnline,
//                             onChanged: (v) => setState(() => isOnline = v),
//                             activeColor: AppColors.onlineGreen,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//
//                     // Communication Modes Section
//                     _buildSectionHeader(context, 'Communication Modes', Icons.call),
//                     const SizedBox(height: 16),
//                     GlassCard(
//                       borderRadius: 20,
//                       blur: 12,
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           _buildCommMode('Audio Call', canAudio, Icons.headset, isDark, primaryColor),
//                           _buildCommMode('Video Call', canVideo, Icons.videocam, isDark, primaryColor),
//                           _buildCommMode('Chat', canChat, Icons.chat_bubble_outline, isDark, primaryColor),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 28),
//
//                     // Action Buttons
//                     ModernButton(
//                       label: isSaving ? 'Saving...' : 'Save Changes',
//                       isLoading: isSaving,
//                       isEnabled: !isSaving,
//                       onPressed: _save,
//                       icon: Icons.check_circle_outline,
//                     ),
//                     const SizedBox(height: 12),
//
//                     ModernButton(
//                       label: 'Cancel',
//                       isOutlined: true,
//                       onPressed: () => Navigator.pop(context),
//                       icon: Icons.close,
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
//
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: primaryColor.withValues(alpha: 0.2),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, size: 20, color: primaryColor),
//         ),
//         const SizedBox(width: 12),
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCommMode(String label, bool enabled, IconData icon, bool isDark, Color primaryColor) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: enabled ? primaryColor.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
//             shape: BoxShape.circle,
//             border: Border.all(
//               color: enabled ? primaryColor : Colors.grey,
//               width: 2,
//             ),
//           ),
//           child: Icon(
//             icon,
//             color: enabled ? primaryColor : Colors.grey,
//             size: 28,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: TextStyle(
//             color: enabled ? primaryColor : Colors.grey,
//             fontWeight: FontWeight.w600,
//             fontSize: 13,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Icon(
//           enabled ? Icons.check_circle : Icons.cancel,
//           color: enabled ? Colors.green : Colors.red,
//           size: 18,
//         ),
//       ],
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/glass_card.dart';

class ExpertEditProfileScreen extends StatefulWidget {
  const ExpertEditProfileScreen({super.key});

  @override
  State<ExpertEditProfileScreen> createState() =>
      _ExpertEditProfileScreenState();
}

class _ExpertEditProfileScreenState extends State<ExpertEditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool loading = true;
  bool isSaving = false;
  bool isOnline = false;

  /// expert toggles
  bool canAudio = false;
  bool canVideo = false;
  bool canChat = false;

  /// admin permissions
  bool allowAudio = false;
  bool allowVideo = false;
  bool allowChat = false;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  late AnimationController _avatarController;

  @override
  void initState() {
    super.initState();

    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc =
    await FirebaseFirestore.instance.collection('experts').doc(uid).get();

    final data = doc.data()!;

    _nameCtrl.text = data['name'] ?? '';
    _skillCtrl.text = data['skill'] ?? '';
    _expCtrl.text = data['experience']?.toString() ?? '';
    _priceCtrl.text = data['price_per_minute']?.toString() ?? '';

    isOnline = data['is_online'] ?? false;

    /// admin permissions
    allowAudio = data['allow_audio'] ?? true;
    allowVideo = data['allow_video'] ?? false;
    allowChat = data['allow_chat'] ?? false;

    /// expert toggles
    canAudio = data['can_audio'] ?? false;
    canVideo = data['can_video'] ?? false;
    canChat = data['can_chat'] ?? false;

    setState(() => loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('experts').doc(uid).update({
        'name': _nameCtrl.text.trim(),
        'skill': _skillCtrl.text.trim(),
        'experience': int.parse(_expCtrl.text),
        'price_per_minute': int.parse(_priceCtrl.text),

        'is_online': isOnline,

        /// expert toggles
        'can_audio': canAudio,
        'can_video': canVideo,
        'can_chat': canChat,

        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error : $e")),
      );
    }

    setState(() => isSaving = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skillCtrl.dispose();
    _expCtrl.dispose();
    _priceCtrl.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.lightPrimary;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [

          /// HEADER
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(.6),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    ScaleTransition(
                      scale: Tween<double>(begin: .6, end: 1).animate(
                        CurvedAnimation(
                          parent: _avatarController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: const Icon(Icons.person, size: 50),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20)
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          /// BODY
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    /// NAME
                    ModernTextField(
                      label: "Name",
                      hint: "Enter name",
                      controller: _nameCtrl,
                      prefixIcon: Icons.person,
                      validator: (v) =>
                      v!.isEmpty ? "Name required" : null,
                    ),

                    const SizedBox(height: 16),

                    /// SKILL
                    ModernTextField(
                      label: "Skill",
                      hint: "Astrologer, Tarot etc",
                      controller: _skillCtrl,
                      prefixIcon: Icons.star,
                      validator: (v) =>
                      v!.isEmpty ? "Skill required" : null,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [

                        Expanded(
                          child: ModernTextField(
                            label: "Experience",
                            hint: "Years",
                            controller: _expCtrl,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.timeline,
                            validator: (v) =>
                            int.tryParse(v ?? "") == null
                                ? "Invalid"
                                : null,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: ModernTextField(
                            label: "Price / min",
                            hint: "₹",
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.currency_rupee,
                            validator: (v) =>
                            int.tryParse(v ?? "") == null
                                ? "Invalid"
                                : null,
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// ONLINE SWITCH
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 20,
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Online Status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: isOnline,
                            onChanged: (v) =>
                                setState(() => isOnline = v),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// COMMUNICATION MODES
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Communication Modes",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 20,
                      child: Column(
                        children: [

                          _buildCommToggle(
                            label: "Audio Call",
                            icon: Icons.headset,
                            enabled: canAudio,
                            allowed: allowAudio,
                            onChanged: (v) =>
                                setState(() => canAudio = v),
                          ),

                          const SizedBox(height: 10),

                          _buildCommToggle(
                            label: "Video Call",
                            icon: Icons.videocam,
                            enabled: canVideo,
                            allowed: allowVideo,
                            onChanged: (v) =>
                                setState(() => canVideo = v),
                          ),

                          const SizedBox(height: 10),

                          _buildCommToggle(
                            label: "Chat",
                            icon: Icons.chat,
                            enabled: canChat,
                            allowed: allowChat,
                            onChanged: (v) =>
                                setState(() => canChat = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    ModernButton(
                      label: isSaving ? "Saving..." : "Save",
                      onPressed: _save,
                    ),

                    const SizedBox(height: 10),

                    ModernButton(
                      label: "Cancel",
                      isOutlined: true,
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// COMMUNICATION SWITCH UI

  Widget _buildCommToggle({
    required String label,
    required IconData icon,
    required bool enabled,
    required bool allowed,
    required Function(bool) onChanged,
  }) {
    return Opacity(
      opacity: allowed ? 1 : .4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),

          Switch(
            value: enabled,
            onChanged: allowed ? onChanged : null,
          )
        ],
      ),
    );
  }
}