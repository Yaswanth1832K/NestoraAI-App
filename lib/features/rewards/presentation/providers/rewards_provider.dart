import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final rewardsProvider = StateNotifierProvider<RewardsNotifier, List<String>>((ref) {
  return RewardsNotifier();
});

class RewardsNotifier extends StateNotifier<List<String>> {
  RewardsNotifier() : super([]) {
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final rewards = prefs.getStringList('my_rewards') ?? [];
    state = rewards;
  }

  Future<void> addReward(String reward) async {
    final prefs = await SharedPreferences.getInstance();
    final rewards = prefs.getStringList('my_rewards') ?? [];
    rewards.add(reward);
    await prefs.setStringList('my_rewards', rewards);
    state = rewards;
  }
}
