import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/features/profile/domain/entities/help_article.dart';
import 'package:house_rental/features/profile/presentation/providers/help_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends ConsumerStatefulWidget {
  const HelpCenterPage({super.key});

  @override
  ConsumerState<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends ConsumerState<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(helpSearchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _contactSupport(String method) async {
    Uri url;
    if (method == 'email') {
      url = Uri.parse('mailto:support@nestora.ai?subject=Help Request');
    } else {
      // Mock WhatsApp or Chat
      url = Uri.parse('https://wa.me/1234567890');
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch support link")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = ref.watch(filteredHelpArticlesProvider);
    final selectedCategory = ref.watch(helpSelectedCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Help Center", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search help articles",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear), 
                      onPressed: () => _searchController.clear()
                    ) 
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),

          // Categories Section
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(null, "All"),
                ...HelpCategory.values.map((cat) => _buildCategoryChip(cat, cat.name.toUpperCase())),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // FAQ List
          Expanded(
            child: filteredArticles.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) => _buildFAQItem(filteredArticles[index]),
                ),
          ),

          // Bottom Support Actions
          _buildSupportSection(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(HelpCategory? category, String label) {
    final isSelected = ref.watch(helpSelectedCategoryProvider) == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          ref.read(helpSelectedCategoryProvider.notifier).state = val ? category : null;
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildFAQItem(HelpArticle article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: AppColors.primary,
        collapsedIconColor: Colors.grey,
        title: Text(
          article.question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Text(
              article.answer,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Still need help?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _contactSupport('email'),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text("Email Us"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactSupport('chat'),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Live Chat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No results found",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            "Try searching for another keyword",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
