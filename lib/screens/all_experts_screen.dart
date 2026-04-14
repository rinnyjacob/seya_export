// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/modern_card.dart';

class AllExpertsScreen extends StatefulWidget {
  const AllExpertsScreen({super.key});

  @override
  State<AllExpertsScreen> createState() => _AllExpertsScreenState();
}

class _AllExpertsScreenState extends State<AllExpertsScreen> {
  String _filterStatus = 'all'; // all, online, offline

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          'All Experts',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
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
        child: Column(
          children: [
            // Filter chips
            _buildFilterChips(primaryColor),

            // Experts list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getExpertsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(primaryColor);
                  }

                  final rawDocs = snapshot.data!.docs;
                  final experts = _filterStatus != 'all'
                      ? (List.of(rawDocs)
                        ..sort((a, b) {
                          final aName = (a.data() as Map<String, dynamic>)['name'] ?? '';
                          final bName = (b.data() as Map<String, dynamic>)['name'] ?? '';
                          return aName.toString().toLowerCase().compareTo(bName.toString().toLowerCase());
                        }))
                      : rawDocs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: experts.length,
                    itemBuilder: (context, index) {
                      final expertData = experts[index].data() as Map<String, dynamic>;
                      final expertId = experts[index].id;
                      return _buildExpertCard(expertData, expertId, primaryColor, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getExpertsStream() {
    Query query = FirebaseFirestore.instance.collection('experts');

    if (_filterStatus == 'online') {
      query = query.where('is_online', isEqualTo: true);
    } else if (_filterStatus == 'offline') {
      query = query.where('is_online', isEqualTo: false);
    }

    // Only use orderBy when showing all experts (no where clause)
    // When filtering, we'll sort in the UI instead to avoid composite index requirement
    if (_filterStatus == 'all') {
      return query.orderBy('name').snapshots();
    } else {
      return query.snapshots();
    }
  }

  Widget _buildFilterChips(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('All', 'all', primaryColor),
          const SizedBox(width: 8),
          _buildFilterChip('Online', 'online', primaryColor),
          const SizedBox(width: 8),
          _buildFilterChip('Offline', 'offline', primaryColor),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color primaryColor) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filterStatus = value);
        }
      },
      selectedColor: primaryColor.withValues(alpha: 0.2),
      checkmarkColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : null,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildExpertCard(
    Map<String, dynamic> expertData,
    String expertId,
    Color primaryColor,
    bool isDark,
  ) {
    final name = expertData['name'] ?? 'Expert';
    final skill = expertData['skill'] ?? 'Consultant';
    final experience = expertData['experience'] ?? 0;
    final pricePerMinute = expertData['price_per_minute'] ?? 0;
    final isOnline = expertData['is_online'] == true;
    final email = expertData['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        showGradient: isOnline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header with name and status
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark ? AppColors.darkGradient : AppColors.lightGradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name and skill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skill,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Online status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppColors.onlineGreen.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline ? AppColors.onlineGreen : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.onlineGreen : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? AppColors.onlineGreen : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Experience and price
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.work_outline,
                label: '$experience years',
                color: primaryColor,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.attach_money,
                label: '₹$pricePerMinute/min',
                color: AppColors.lightAccent,
              ),
            ],
          ),

          if (email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewExpertDetails(expertId, expertData),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isOnline ? () => _contactExpert(expertId, expertData) : null,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No experts found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filter',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Experts'),
        content: StatefulBuilder(
          builder: (context, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('All Experts'),
                value: 'all',
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() => _filterStatus = value!);
                  setLocal(() {});
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Online Only'),
                value: 'online',
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() => _filterStatus = value!);
                  setLocal(() {});
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Offline Only'),
                value: 'offline',
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() => _filterStatus = value!);
                  setLocal(() {});
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewExpertDetails(String expertId, Map<String, dynamic> expertData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expert Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Name', expertData['name'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow('Skill', expertData['skill'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow('Experience', '${expertData['experience'] ?? 0} years'),
              const SizedBox(height: 12),
              _buildDetailRow('Rate', '₹${expertData['price_per_minute'] ?? 0}/min'),
              const SizedBox(height: 12),
              _buildDetailRow('Email', expertData['email'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Status',
                expertData['is_online'] == true ? '🟢 Online' : '🔴 Offline',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  void _contactExpert(String expertId, Map<String, dynamic> expertData) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('Contacting ${expertData['name'] ?? 'this expert'} will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

