import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/smart_image.dart';

String? _getStoragePath(String url) {
  try {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    final publicIndex = pathSegments.indexOf('public');
    if (publicIndex != -1 && pathSegments.length > publicIndex + 2) {
      return pathSegments.sublist(publicIndex + 2).join('/');
    }
  } catch (_) {}
  return null;
}

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
      debugPrint('Fetch profile Database bypassed natively: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() { _imageFile = pickedFile; });
    }
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
          try {
            final oldPath = _getStoragePath(_existingImageUrl!);
            if (oldPath != null) {
              await Supabase.instance.client.storage.from('users').remove([oldPath]);
            }
          } catch (e) {
            debugPrint('Error deleting old image: $e');
          }
        }

        final path = 'profiles/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final bytes = await _imageFile!.readAsBytes();
        await Supabase.instance.client.storage.from('users').uploadBinary(path, bytes);
        imageUrl = Supabase.instance.client.storage.from('users').getPublicUrl(path);
      }

      final existingData = await Supabase.instance.client.from('users').select('id').eq('user_id', user.id).maybeSingle();
      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'pin_code': _pincodeController.text.trim(),
        if (imageUrl != null) 'profile_image_url': imageUrl,
      };

      if (existingData != null) {
        await Supabase.instance.client.from('users').update(updateData).eq('user_id', user.id);
      } else {
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'user_id': user.id,
          ...updateData,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Information updated successfully!'), backgroundColor: const Color(0xFF8CC63F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
      }
    } finally { if (mounted) setState(() => _isSaving = false); }
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
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _imageFile != null
                            ? (kIsWeb
                                ? NetworkImage(_imageFile!.path)
                                : SmartImage.provider(_imageFile!.path))
                            : (_existingImageUrl != null
                                ? SmartImage.provider(_existingImageUrl!)
                                : const AssetImage('assets/images/hero.png')),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFFF15A24), shape: BoxShape.circle),
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
                    onPressed: _saveCredentials,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF15A24), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isSaving
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF15A24)))
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
