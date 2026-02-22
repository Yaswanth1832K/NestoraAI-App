import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/roommate/domain/entities/roommate_entity.dart';
import 'package:house_rental/features/roommate/presentation/providers/roommate_providers.dart';

class RoommateProfileScreen extends ConsumerStatefulWidget {
  final RoommateEntity? existingProfile;

  const RoommateProfileScreen({super.key, this.existingProfile});

  @override
  ConsumerState<RoommateProfileScreen> createState() => _RoommateProfileScreenState();
}

class _RoommateProfileScreenState extends ConsumerState<RoommateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _budgetController;
  late TextEditingController _bioController;
  String _selectedGender = 'Male';
  String _preferredGender = 'Any';
  String _occupation = 'Student';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingProfile?.name ?? '');
    _cityController = TextEditingController(text: widget.existingProfile?.city ?? '');
    _budgetController = TextEditingController(text: widget.existingProfile?.budget.toString() ?? '');
    _bioController = TextEditingController(text: widget.existingProfile?.bio ?? '');
    if (widget.existingProfile != null) {
      _selectedGender = widget.existingProfile!.gender;
      _preferredGender = widget.existingProfile!.preferredGender;
      _occupation = widget.existingProfile!.occupation;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _budgetController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final roommate = RoommateEntity(
      userId: user.uid,
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      budget: int.parse(_budgetController.text.trim()),
      gender: _selectedGender,
      preferredGender: _preferredGender,
      occupation: _occupation,
      bio: _bioController.text.trim(),
      createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
    );

    final result = await ref.read(saveRoommateProfileUseCaseProvider)(roommate);

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message ?? 'An error occurred')),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Roommate profile saved!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Roommate Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Let others know who you are looking for.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              _buildTextField('Full Name', _nameController, Icons.person_outline),
              const SizedBox(height: 20),
              _buildTextField('City', _cityController, Icons.location_city_outlined),
              const SizedBox(height: 20),
              _buildTextField('Monthly Budget (₹)', _budgetController, Icons.currency_rupee_outlined, isNumber: true),
              const SizedBox(height: 24),
              _buildDropdown('Your Gender', ['Male', 'Female', 'Other'], _selectedGender, (val) => setState(() => _selectedGender = val!)),
              const SizedBox(height: 20),
              _buildDropdown('Preferred Roommate', ['Any', 'Male', 'Female'], _preferredGender, (val) => setState(() => _preferredGender = val!)),
              const SizedBox(height: 20),
              _buildDropdown('Occupation', ['Student', 'Working Professional'], _occupation, (val) => setState(() => _occupation = val!)),
              const SizedBox(height: 24),
              _buildTextField('Bio (Tell them about your lifestyle)', _bioController, Icons.edit_note_outlined, maxLines: 4),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blueAccent.withOpacity(0.7)),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: onChanged,
              dropdownColor: const Color(0xFF1F1F1F),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent),
            ),
          ),
        ),
      ],
    );
  }
}
