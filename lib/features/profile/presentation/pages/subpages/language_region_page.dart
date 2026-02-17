import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:house_rental/core/utils/countries.dart';

class LanguageRegionPage extends ConsumerStatefulWidget {
  const LanguageRegionPage({super.key});

  @override
  ConsumerState<LanguageRegionPage> createState() => _LanguageRegionPageState();
}

class _LanguageRegionPageState extends ConsumerState<LanguageRegionPage> {
  String _selectedRegion = "United States of America";
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadRegion();
  }

  Future<void> _loadRegion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRegion = prefs.getString('selected_region') ?? "United States of America";
    });
  }

  Future<void> _saveRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_region', region);
    setState(() {
      _selectedRegion = region;
    });
  }

  void _showRegionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCountries = allCountries
                .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Select Region", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search countries...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredCountries.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                          title: Text(country.name),
                          onTap: () {
                            _saveRegion(country.name);
                            Navigator.pop(context);
                          },
                          trailing: _selectedRegion == country.name ? const Icon(Icons.check, color: Colors.blue) : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _searchQuery = ""; // Reset search on close
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Language and Region")),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text("Language", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _buildLanguageTile("English", "en", currentLocale),
          _buildLanguageTile("Hindi (हिन्दी)", "hi", currentLocale),
          _buildLanguageTile("Bengali (বাংলা)", "bn", currentLocale),
          _buildLanguageTile("Telugu (తెలుగు)", "te", currentLocale),
          _buildLanguageTile("Tamil (தமிழ்)", "ta", currentLocale),
          _buildLanguageTile("Malayalam (മലയാളം)", "ml", currentLocale),
          _buildLanguageTile("Odia (ଓଡ଼ିଆ)", "or", currentLocale),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text("Region", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            title: const Text("Region"),
            subtitle: Text(_selectedRegion),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showRegionPicker,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(String name, String code, Locale currentLocale) {
    return RadioListTile<String>(
      title: Text(name),
      value: code,
      groupValue: currentLocale.languageCode,
      activeColor: Colors.blue,
      onChanged: (val) {
        if (val != null) {
          ref.read(localeProvider.notifier).setLocale(Locale(val));
        }
      },
    );
  }
}

