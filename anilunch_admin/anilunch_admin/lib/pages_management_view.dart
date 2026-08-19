import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/api_client.dart';

class PagesManagementView extends StatefulWidget {
  const PagesManagementView({super.key});

  @override
  State<PagesManagementView> createState() => _PagesManagementViewState();
}

class _PagesManagementViewState extends State<PagesManagementView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pages = [];

  @override
  void initState() {
    super.initState();
    _fetchPages();
  }

  Future<void> _fetchPages() async {
    setState(() => _isLoading = true);
    final data = await ApiClient.fetchPages();
    if (mounted) {
      setState(() {
        _pages = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePage(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: const Text('Are you sure you want to delete this page?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final ok = await ApiClient.deletePage(int.parse(id.toString()));
    await _fetchPages();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Page deleted successfully' : 'Error: could not delete page')));
    }
  }

  void _openPageForm([Map<String, dynamic>? page]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PageFormView(page: page)),
    ).then((_) => _fetchPages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Footer Pages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA6E21)))
          : _pages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined, size: 64, color: Colors.black26),
                      const SizedBox(height: 16),
                      const Text("No pages found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 8),
                      const Text("Create a page like 'Help Center' or 'Privacy Policy'.", style: TextStyle(color: Colors.black38)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _openPageForm,
                        icon: const Icon(Icons.add),
                        label: const Text("Create Page"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA6E21),
                          foregroundColor: Colors.white,
                        ),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(page['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Slug: ${page['slug']}", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _openPageForm(page),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deletePage(page['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _pages.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openPageForm,
              backgroundColor: const Color(0xFFEA6E21),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("New Page", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

class PageFormView extends StatefulWidget {
  final Map<String, dynamic>? page;
  const PageFormView({super.key, this.page});

  @override
  State<PageFormView> createState() => _PageFormViewState();
}

class _PageFormViewState extends State<PageFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.page != null) {
      _titleController.text = widget.page!['title'] ?? '';
      _contentController.text = widget.page!['content'] ?? '';
    }
  }

  Future<void> _savePage() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final title = _titleController.text.trim();
    final slug = title.toLowerCase().replaceAll(' ', '-');
    final content = _contentController.text.trim();

    try {
      final payload = <String, dynamic>{
        'title': title,
        'slug': slug,
        'content': content,
      };
      if (widget.page != null) payload['id'] = widget.page!['id'];
      await ApiClient.savePage(payload);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Page saved successfully')));
      }
    } catch (e) {
      debugPrint("Error saving page: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.page == null ? 'Create Page' : 'Edit Page', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA6E21)))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Page Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                      decoration: InputDecoration(
                        hintText: "e.g., Privacy Policy",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Slug will be automatically generated from the title (e.g., privacy-policy)", style: TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 24),
                    
                    const Text("Page Content", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 15,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Content is required' : null,
                      decoration: InputDecoration(
                        hintText: "Enter the page content here...",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savePage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA6E21),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(widget.page == null ? "Create Page" : "Save Changes", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
