import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../admin_theme.dart';
import '../pages_management_view.dart';
import '../services/api_client.dart';

class AppSettingsView extends StatefulWidget {
  const AppSettingsView({super.key});

  @override
  State<AppSettingsView> createState() => _AppSettingsViewState();
}

class _AppSettingsViewState extends State<AppSettingsView> {
  bool _isLoading = true;
  String _videoUrl = '';
  final _urlController = TextEditingController();
  bool _showHeroBanner = true;
  final _badgeController = TextEditingController();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _buttonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _badgeController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    final data = await ApiClient.fetchSettings();
    if (mounted) {
      setState(() {
        _videoUrl = data?['home_video_url']?.toString() ?? '';
        _urlController.text = _videoUrl;
        _showHeroBanner = data?['show_hero_banner'] ?? true;
        _badgeController.text = data?['hero_badge_text']?.toString() ?? '🔥 Fresh Meat Daily';
        _titleController.text = data?['hero_title']?.toString() ?? 'Your Daily Meat,\nDelivered Fresh & Fast!';
        _subtitleController.text = data?['hero_subtitle']?.toString() ?? 'Farm-fresh cuts, delivered to your door';
        _buttonController.text = data?['hero_button_text']?.toString() ?? 'Order Now';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final url = _urlController.text.trim();
      final payload = {
        'home_video_url': url,
        'show_hero_banner': _showHeroBanner,
        'hero_badge_text': _badgeController.text.trim(),
        'hero_title': _titleController.text.trim(),
        'hero_subtitle': _subtitleController.text.trim(),
        'hero_button_text': _buttonController.text.trim(),
      };
      await ApiClient.saveSettings(payload);
      if (mounted) {
        setState(() { _videoUrl = url; _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Settings saved!'), backgroundColor: AdminTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() => _isLoading = true);
        _urlController.text = video.path;
        await _saveSettings();
      }
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: $e'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AdminTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AdminTheme.primary, strokeWidth: 2)),
      );
    }
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: Column(
        children: [
          AdminTheme.pageHeader(context: context, title: 'Settings'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Video Section ───────────────────────────────────────
                  _sectionHeader(Icons.video_library_outlined, 'Home Video', 'Background video for the hero section (MP4)'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AdminTheme.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_videoUrl.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: AdminTheme.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: AdminTheme.success.withValues(alpha: 0.20))),
                            child: Row(children: [
                              const Icon(Icons.check_circle_rounded, color: AdminTheme.success, size: 14),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_videoUrl, style: AdminTheme.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ]),
                          ),
                          const SizedBox(height: 10),
                        ],
                        AdminTheme.sectionLabel('Video URL'),
                        TextField(
                          controller: _urlController,
                          style: const TextStyle(fontSize: 12),
                          decoration: AdminTheme.inputDecoration('https://...'),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickAndUploadVideo,
                              icon: const Icon(Icons.upload_rounded, size: 14),
                              label: const Text('Upload', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                foregroundColor: AdminTheme.primary,
                                side: const BorderSide(color: AdminTheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Save URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Hero Banner Section ─────────────────────────────────
                  _sectionHeader(Icons.text_fields_rounded, 'Hero Banner', 'Text shown on the customer app home screen'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AdminTheme.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show toggle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(color: AdminTheme.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AdminTheme.border, width: 0.8)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Show Hero Banner', style: AdminTheme.cardTitle),
                            Switch(value: _showHeroBanner, onChanged: (v) => setState(() => _showHeroBanner = v), activeTrackColor: AdminTheme.primary.withValues(alpha: 0.5), activeThumbColor: AdminTheme.primary),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        AdminTheme.sectionLabel('Badge Text'),
                        TextField(controller: _badgeController, style: const TextStyle(fontSize: 12), decoration: AdminTheme.inputDecoration('e.g. 🔥 Fresh Meat Daily')),
                        const SizedBox(height: 10),
                        AdminTheme.sectionLabel('Title'),
                        TextField(controller: _titleController, maxLines: 2, style: const TextStyle(fontSize: 12), decoration: AdminTheme.inputDecoration('Main headline…')),
                        const SizedBox(height: 10),
                        AdminTheme.sectionLabel('Subtitle'),
                        TextField(controller: _subtitleController, style: const TextStyle(fontSize: 12), decoration: AdminTheme.inputDecoration('Short description…')),
                        const SizedBox(height: 10),
                        AdminTheme.sectionLabel('Button Text'),
                        TextField(controller: _buttonController, style: const TextStyle(fontSize: 12), decoration: AdminTheme.inputDecoration('e.g. Order Now')),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _saveSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Save Hero Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Footer Pages Section ────────────────────────────────
                  _sectionHeader(Icons.description_outlined, 'Footer Pages', 'Manage Privacy Policy, Help Center, and more'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PagesManagementView())),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: AdminTheme.cardDecoration(),
                      child: const Row(children: [
                        Icon(Icons.description_outlined, color: AdminTheme.primary, size: 18),
                        SizedBox(width: 12),
                        Expanded(child: Text('Manage Footer Pages Content', style: AdminTheme.cardTitle)),
                        Icon(Icons.chevron_right_rounded, color: AdminTheme.textMuted, size: 18),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: AdminTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AdminTheme.primary, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AdminTheme.sectionTitle),
              const SizedBox(height: 2),
              Text(subtitle, style: AdminTheme.body),
            ],
          ),
        ),
      ],
    );
  }
}
