import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/roommate/domain/entities/roommate_entity.dart';
import 'package:house_rental/features/roommate/presentation/pages/roommate_profile_screen.dart';
import 'package:house_rental/features/roommate/presentation/providers/roommate_providers.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_page.dart';
import 'package:house_rental/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:house_rental/core/widgets/shimmer_container.dart';
import 'package:house_rental/core/widgets/glass_container.dart';

class RoommateFeedScreen extends ConsumerStatefulWidget {
  const RoommateFeedScreen({super.key});

  @override
  ConsumerState<RoommateFeedScreen> createState() => _RoommateFeedScreenState();
}

/// Computes compatibility score 0–100 from city, gender preference, budget, occupation.
int roommateCompatibilityScore(RoommateEntity me, RoommateEntity other) {
  int score = 0;
  if (me.city.toLowerCase() == other.city.toLowerCase()) score += 25;
  final iMatchThem = me.preferredGender == 'Any' || me.preferredGender == other.gender;
  final theyMatchMe = other.preferredGender == 'Any' || other.preferredGender == me.gender;
  if (iMatchThem && theyMatchMe) score += 25;
  if ((other.budget - me.budget).abs() <= 5000) score += 25;
  if (me.occupation.isNotEmpty && other.occupation.isNotEmpty &&
      me.occupation.toLowerCase() == other.occupation.toLowerCase()) {
    score += 25;
  }
  return score.clamp(0, 100);
}

class _RoommateFeedScreenState extends ConsumerState<RoommateFeedScreen> {
  String? _filterOccupation;
  int? _filterMaxBudget;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(userRoommateProfileProvider(user.uid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Find Roommate', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          profileAsync.maybeWhen(
            data: (profile) => profile != null
                ? IconButton(
                    icon: Icon(Icons.edit_note_rounded, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RoommateProfileScreen(existingProfile: profile)),
                    ),
                  )
                : const SizedBox(),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildNoProfileState(isDark);
          }
          return _buildMatchesList(profile, isDark);
        },
        loading: () => _buildSkeletonLoading(isDark),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSkeletonLoading(bool isDark) {
    return Center(
      child: ShimmerContainer(
        height: 200,
        width: MediaQuery.of(context).size.width * 0.8,
        borderRadius: 24,
      ),
    );
  }

  Widget _buildSkeletonMatches(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => const ShimmerContainer(
        height: 240,
        width: double.infinity,
        borderRadius: 24,
        margin: EdgeInsets.only(bottom: 20),
      ),
    );
  }

  Widget _buildNoProfileState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 100, color: Colors.blue.withOpacity(0.3)),
          const SizedBox(height: 32),
          Text(
            'Find your perfect roommate',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create a profile describing your lifestyle and budget to start matching with compatible people in your city.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF385C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Create My Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoommateProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(RoommateEntity myProfile, bool isDark) {
    final matchesAsync = ref.watch(roommateMatchesProvider(myProfile));

    return matchesAsync.when(
      data: (matches) {
        var filteredMatches = matches.where((m) => m.userId != myProfile.userId).toList();
        if (_filterOccupation != null && _filterOccupation!.isNotEmpty) {
          filteredMatches = filteredMatches.where((m) => m.occupation == _filterOccupation).toList();
        }
        if (_filterMaxBudget != null) {
          filteredMatches = filteredMatches.where((m) => m.budget <= _filterMaxBudget!).toList();
        }
        // Sort by compatibility descending
        filteredMatches = List.from(filteredMatches)
          ..sort((a, b) => roommateCompatibilityScore(myProfile, b).compareTo(roommateCompatibilityScore(myProfile, a)));

        if (filteredMatches.isEmpty) {
          return Center(
            child: Text(
              'No matches found in your city yet.\nCheck back later!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(myProfile, filteredMatches, isDark),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: filteredMatches.length,
                itemBuilder: (context, index) {
                  return _buildRoommateCard(filteredMatches[index], myProfile, isDark);
                },
              ),
            ),
          ],
        );
      },
      loading: () => _buildSkeletonMatches(isDark),
      error: (err, stack) => Center(child: Text('Error matching: $err')),
    );
  }

  Widget _buildFilters(RoommateEntity myProfile, List<RoommateEntity> matches, bool isDark) {
    final occupations = matches.map((m) => m.occupation).where((o) => o.isNotEmpty).toSet().toList()..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          _buildFilterChip(
            label: _filterOccupation ?? 'Occupation',
            onTap: () => _showFilterPicker('Occupation', occupations, _filterOccupation, (v) => setState(() => _filterOccupation = v), isDark),
            isDark: isDark,
            isActive: _filterOccupation != null,
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            label: _filterMaxBudget != null ? '≤ ₹${_filterMaxBudget! / 1000}k' : 'Max budget',
            onTap: () => _showFilterPicker('Budget', ['Any', '15000', '25000', '40000'], _filterMaxBudget?.toString(), (v) {
              setState(() => _filterMaxBudget = v == 'Any' ? null : int.parse(v!));
            }, isDark),
            isDark: isDark,
            isActive: _filterMaxBudget != null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onTap, required bool isDark, required bool isActive}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.grey.shade900 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isActive ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterPicker(String title, List<String> options, String? currentValue, Function(String?) onSelected, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildOptionChip('All/Any', currentValue == null, () {
                  onSelected(null);
                  Navigator.pop(context);
                }, isDark),
                ...options.map((o) => _buildOptionChip(o == '15000' ? '≤ ₹15k' : o == '25000' ? '≤ ₹25k' : o == '40000' ? '≤ ₹40k' : o, currentValue == o, () {
                  onSelected(o);
                  Navigator.pop(context);
                }, isDark)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF385C) : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRoommateCard(RoommateEntity match, RoommateEntity myProfile, bool isDark) {
    final score = roommateCompatibilityScore(myProfile, match);
    final primaryColor = Theme.of(context).primaryColor;

    return GlassContainer.standard(
      context: context,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: primaryColor.withOpacity(0.15),
                child: Text(match.name[0].toUpperCase(), style: TextStyle(fontSize: 26, color: primaryColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Text('${match.occupation} • ${match.gender}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: primaryColor.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(match.city, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(width: 12),
                        Icon(Icons.currency_rupee_rounded, size: 14, color: Colors.green.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text('Up to ₹${match.budget}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: score >= 75 ? Colors.green.withOpacity(0.1) : score >= 50 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$score%', style: TextStyle(color: score >= 75 ? Colors.green : score >= 50 ? Colors.orange : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Colors.white12),
          ),
          const Text('LIFE STYLE', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text(
            match.bio,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _startChat(match),
            ),
          ),
        ],
      ),
    );
  }

  void _startChat(RoommateEntity otherUser) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    // Use a modified chat creation logic for roommates
    final result = await ref.read(getOrCreateRoommateChatUseCaseProvider)(user.uid, otherUser.userId);

    if (mounted) Navigator.pop(context); // Pop loading

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message ?? 'Unknown error'))),
      (chatRoom) {
        // Navigate to chat page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              chatRoomId: chatRoom.id,
              title: otherUser.name,
            ),
          ),
        );
      },
    );
  }
}

// Additional Provider for individual user profile
final userRoommateProfileProvider = FutureProvider.family<RoommateEntity?, String>((ref, userId) async {
  final result = await ref.watch(getRoommateProfileUseCaseProvider)(userId);
  return result.fold((l) => throw l.message ?? 'Unknown error', (r) => r);
});

// Matches Provider
final roommateMatchesProvider = FutureProvider.family<List<RoommateEntity>, RoommateEntity>((ref, profile) async {
  final result = await ref.watch(findRoommateMatchesUseCaseProvider)(profile.city, profile.budget, profile.gender);
  return result.fold((l) => throw l.message ?? 'Unknown error', (r) => r);
});
