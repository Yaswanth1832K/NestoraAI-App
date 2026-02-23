import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/roommate/domain/entities/roommate_entity.dart';
import 'package:house_rental/features/roommate/presentation/pages/roommate_profile_screen.dart';
import 'package:house_rental/features/roommate/presentation/providers/roommate_providers.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_page.dart';

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

    final profileAsync = ref.watch(userRoommateProfileProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Find Roommate', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          profileAsync.maybeWhen(
            data: (profile) => profile != null
                ? IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
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
            return _buildNoProfileState();
          }
          return _buildMatchesList(profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildNoProfileState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 100, color: Colors.blueAccent.withOpacity(0.3)),
          const SizedBox(height: 32),
          const Text(
            'Find your perfect roommate',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildMatchesList(RoommateEntity myProfile) {
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
          return const Center(
            child: Text(
              'No matches found in your city yet.\nCheck back later!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(myProfile, filteredMatches),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredMatches.length,
                itemBuilder: (context, index) {
                  return _buildRoommateCard(filteredMatches[index], myProfile);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error matching: $err')),
    );
  }

  Widget _buildFilters(RoommateEntity myProfile, List<RoommateEntity> matches) {
    final occupations = matches.map((m) => m.occupation).where((o) => o.isNotEmpty).toSet().toList()..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          DropdownButton<String>(
            value: _filterOccupation,
            hint: const Text('Occupation', style: TextStyle(color: Colors.grey, fontSize: 13)),
            underline: const SizedBox(),
            isDense: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...occupations.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))),
            ],
            onChanged: (v) => setState(() => _filterOccupation = v),
          ),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: _filterMaxBudget,
            hint: const Text('Max budget', style: TextStyle(color: Colors.grey, fontSize: 13)),
            underline: const SizedBox(),
            isDense: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              const DropdownMenuItem(value: 15000, child: Text('≤ ₹15k')),
              const DropdownMenuItem(value: 25000, child: Text('≤ ₹25k')),
              const DropdownMenuItem(value: 40000, child: Text('≤ ₹40k')),
            ],
            onChanged: (v) => setState(() => _filterMaxBudget = v),
          ),
        ],
      ),
    );
  }

  Widget _buildRoommateCard(RoommateEntity match, RoommateEntity myProfile) {
    final score = roommateCompatibilityScore(myProfile, match);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  child: Text(match.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('${match.occupation} • ${match.gender}', style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.blueAccent.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(match.city, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(width: 12),
                          Icon(Icons.currency_rupee_rounded, size: 14, color: Colors.green.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text('Up to ₹${match.budget}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: score >= 75 ? Colors.green.withOpacity(0.2) : score >= 50 ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$score%', style: TextStyle(color: score >= 75 ? Colors.green : score >= 50 ? Colors.orange : Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white12),
            const Text('About me', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              match.bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
