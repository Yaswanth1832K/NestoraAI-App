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
import 'package:house_rental/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';

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
    if (user == null) return const Center(child: Text('Please login'));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(userRoommateProfileProvider(user.uid));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return _buildNoProfileState(isDark);
        }
        return _buildMatchesList(profile, isDark);
      },
      loading: () => _buildSkeletonMatches(isDark),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSkeletonMatches(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ShimmerContainer(
          height: 240,
          width: double.infinity,
          borderRadius: 24,
        ),
      ),
    );
  }

  Widget _buildNoProfileState(bool isDark) {
    return Center(
      child: GlassContainer.standard(
        context: context,
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        borderRadius: 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_alt_rounded, size: 64, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Find your match',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a roommate profile to start matching with compatible people in your city.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoommateProfileScreen()),
              ),
              child: const Text('Create My Profile', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ],
        ),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),
                Text(
                  'No matches found yet',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildFilters(myProfile, filteredMatches, isDark),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : (isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? Colors.white70 : (isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterPicker(String title, List<String> options, String? currentValue, Function(String?) onSelected, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer.standard(
        context: context,
        padding: const EdgeInsets.all(24),
        borderRadius: 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildOptionChip('All', currentValue == null, () {
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
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), 
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
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
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.05)],
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  match.name[0].toUpperCase(), 
                  style: TextStyle(fontSize: 24, color: primaryColor, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.name, 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${match.occupation} • ${match.gender}', 
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: score >= 75 ? Colors.green.withOpacity(0.12) : score >= 50 ? Colors.orange.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$score%', 
                  style: TextStyle(
                    color: score >= 75 ? Colors.green : score >= 50 ? Colors.orange : Colors.grey, 
                    fontSize: 12, 
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildFeatureTag(Icons.location_on_rounded, match.city, isDark),
              const SizedBox(width: 12),
              _buildFeatureTag(Icons.currency_rupee_rounded, 'Up to ₹${match.budget}', isDark),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            match.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, height: 1.5, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.person_search_rounded, size: 18),
                  label: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: () {
                    // Could navigate to detail profile
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text('Message', style: TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: () => _startChat(match),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.black54),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w700)),
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
        context.push(
          AppRouter.chat,
          extra: {'chatRoomId': chatRoom.id, 'title': otherUser.name},
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
