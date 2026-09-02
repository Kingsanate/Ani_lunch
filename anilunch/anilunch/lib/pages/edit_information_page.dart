import 'dart:convert';
import 'dart:typed_data';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/providers/api_provider.dart';

class EditInformationPage extends StatefulWidget {
  const EditInformationPage({super.key});
  @override
  State<EditInformationPage> createState() => _EditInformationPageState();
}

class _EditInformationPageState extends State<EditInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  Uint8List? _pickedBytes;
  String? _existingImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      if (AniApi.isLoggedIn) {
        final data = await AniApi.instance.api.users.me();
        if (mounted) {
          setState(() {
            _nameController.text = data.name;
            _emailController.text = data.email;
            _phoneController.text = data.phone;
            _addressController.text = data.address;
            _existingImageUrl = data.avatarUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Profile fetch notice: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 300, maxHeight: 300);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (mounted) setState(() { _pickedBytes = bytes; });
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  Widget _defaultAvatar() => Image.asset('assets/images/hero.png', fit: BoxFit.cover, width: 120, height: 120);

  Widget _buildAvatarPreview() {
    if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
      return Image.memory(_pickedBytes!, fit: BoxFit.cover, width: 120, height: 120, gaplessPlayback: true, errorBuilder: (_, __, ___) => _defaultAvatar());
    }
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      final url = _existingImageUrl!;
      if (url.startsWith('data:image')) {
        try {
          return Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover, width: 120, height: 120, gaplessPlayback: true, errorBuilder: (_, __, ___) => _defaultAvatar());
        } catch (_) {}
      } else if (url.startsWith('http') || url.startsWith('blob:')) {
        return Image.network(url, fit: BoxFit.cover, width: 120, height: 120, gaplessPlayback: true, errorBuilder: (_, __, ___) => _defaultAvatar());
      }
    }
    return _defaultAvatar();
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      String? finalImageUrl = _existingImageUrl;
      if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
        finalImageUrl = 'data:image/jpeg;base64,${base64Encode(_pickedBytes!)}';
      }

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final address = _addressController.text.trim();

      await AniApi.instance.api.users.updateProfile(UpdateProfileRequest(
        name: name,
        phone: phone,
        address: address,
        avatarUrl: finalImageUrl,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 20), SizedBox(width: 10), Text('Profile updated successfully!', style: TextStyle(fontWeight: FontWeight.bold))]),
          backgroundColor: Color(0xFF43A047),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to update profile. Please try again.'),
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F3),
      appBar: AppBar(
        title: const Text('Edit Information', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade100,
                            border: Border.all(color: const Color(0xFFF15A24).withValues(alpha: 0.4), width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: ClipOval(child: _buildAvatarPreview()),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF15A24),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Color(0x40F15A24), blurRadius: 6, offset: Offset(0, 2))],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Full Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration('Enter your full name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 24),
                const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: _fieldDecoration('Enter your email address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text('Phone Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: _fieldDecoration('Enter your phone number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 24),
                const Text('Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: _fieldDecoration('Enter your full address'),
                  validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 24),
                const Text('Pin Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pincodeController,
                  decoration: _fieldDecoration('Enter your pin code'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Pin code is required' : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveCredentials,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15A24),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFF15A24).withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSaving
                          ? const SizedBox(key: ValueKey('loading'), width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Save Changes', key: ValueKey('label'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
