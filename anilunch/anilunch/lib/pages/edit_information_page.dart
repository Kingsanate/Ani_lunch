import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  XFile? _imageFile;
  String? _existingImageUrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (mounted) {
      setState(() {
        if (_nameController.text.isEmpty) _nameController.text = user.userMetadata?['full_name']?.toString() ?? '';
        if (_emailController.text.isEmpty) _emailController.text = user.email ?? '';
        if (_phoneController.text.isEmpty) _phoneController.text = user.userMetadata?['phone_number']?.toString() ?? '';
        if (_addressController.text.isEmpty) _addressController.text = user.userMetadata?['address']?.toString() ?? '';
        if (_pincodeController.text.isEmpty) _pincodeController.text = user.userMetadata?['pin_code']?.toString() ?? '';
        _existingImageUrl = user.userMetadata?['profile_image_url']?.toString();
      });
    }

    try {
      final data = await Supabase.instance.client.from('users').select().eq('user_id', user.id).maybeSingle();
      if (data != null && mounted) {
        setState(() {
          final dbName = data['name'];
          if (dbName != null && dbName.toString().isNotEmpty) _nameController.text = dbName;

          final dbEmail = data['email'];
          if (dbEmail != null && dbEmail.toString().isNotEmpty) _emailController.text = dbEmail;

          final dbPhone = data['phone_number'];
          if (dbPhone != null && dbPhone.toString().isNotEmpty) _phoneController.text = dbPhone;

          final dbAddress = data['address'];
          if (dbAddress != null && dbAddress.toString().isNotEmpty) _addressController.text = dbAddress;

          final dbPincode = data['pin_code'];
          if (dbPincode != null && dbPincode.toString().isNotEmpty) _pincodeController.text = dbPincode.toString();

          _existingImageUrl = data['profile_image_url'] ?? _existingImageUrl;
        });
      }
    } catch (e) {
      debugPrint('Fetch profile Database notice: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _pickedBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Pick image notice: $e');
    }
  }

  Widget _buildAvatarPreview() {
    if (_pickedBytes != null) {
      return Image.memory(_pickedBytes!, fit: BoxFit.cover, width: 120, height: 120);
    }
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      final url = _existingImageUrl!;
      if (url.startsWith('data:image')) {
        try {
          final base64String = url.split(',').last;
          return Image.memory(base64Decode(base64String), fit: BoxFit.cover, width: 120, height: 120);
        } catch (_) {}
      } else if (url.startsWith('http') || url.startsWith('blob:')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (_, __, ___) => Image.asset('assets/images/hero.png', fit: BoxFit.cover, width: 120, height: 120),
        );
      } else if (url.startsWith('assets/')) {
        return Image.asset(url, fit: BoxFit.cover, width: 120, height: 120);
      }
    }
    return Image.asset('assets/images/hero.png', fit: BoxFit.cover, width: 120, height: 120);
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_pickedBytes != null || _imageFile != null) {
        final bytes = _pickedBytes ?? await _imageFile!.readAsBytes();
        imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        // Background storage upload without blocking save completion
        final path = 'profiles/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Supabase.instance.client.storage.from('users').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        ).then((_) {
          final pubUrl = Supabase.instance.client.storage.from('users').getPublicUrl(path);
          Supabase.instance.client.from('users').update({'profile_image_url': pubUrl}).eq('user_id', user.id);
        }).catchError((_) {});
      }

      final resolvedImageUrl = imageUrl ?? _existingImageUrl;
      final updateData = {
        'id': user.id,
        'user_id': user.id,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'pin_code': _pincodeController.text.trim(),
        if (resolvedImageUrl != null) 'profile_image_url': resolvedImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Perform auth metadata and database upsert in parallel for instant sub-second response
      await Future.wait([
        Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': _nameController.text.trim(),
              'phone_number': _phoneController.text.trim(),
              'address': _addressController.text.trim(),
              'pin_code': _pincodeController.text.trim(),
              if (resolvedImageUrl != null) 'profile_image_url': resolvedImageUrl,
            },
          ),
        ).then((_) => null).catchError((_) => null),
        Supabase.instance.client.from('users').upsert(updateData).then((_) => null).catchError((_) => null),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Profile updated successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: const Color(0xFF43A047),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to update profile. Please try again.'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade100,
                            border: Border.all(color: const Color(0xFFF15A24).withValues(alpha: 0.3), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _buildAvatarPreview(),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF15A24),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x3DF15A24),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
                  decoration: InputDecoration(hintText: "Enter your full name", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 24),
                const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(hintText: "Enter your email address", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
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
                  decoration: InputDecoration(hintText: "Enter your phone number", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 24),
                const Text('Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: "Enter your full address", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 24),
                const Text('Pin Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pincodeController,
                  decoration: InputDecoration(hintText: "Enter your pin code", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSaving
                          ? const SizedBox(
                              key: ValueKey('saving_indicator'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Save Changes',
                              key: ValueKey('saving_text'),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
