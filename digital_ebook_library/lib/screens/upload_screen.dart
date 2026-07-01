import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

const _bgDark = Color(0xFF2B1A0E);
const _bgDarkLight = Color(0xFF4A2F18);
const _brown = Color(0xFF6B4226);
const _gold = Color(0xFFD9A05B);
const _cream = Color(0xFFF7EFE3);
const _ink = Color(0xFF3A2A1A);

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final ApiService _api = ApiService();

  PlatformFile? _pickedFile;
  PlatformFile? _pickedCover;
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        if (_titleController.text.isEmpty) {
          _titleController.text =
              _pickedFile!.name.replaceAll(RegExp(r'\.\w+$'), '');
        }
      });
    }
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedCover = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null || _pickedFile!.path == null) {
      setState(() => _errorMessage = 'Please choose a PDF or EPUB file');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      await _api.uploadEbook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        filePath: _pickedFile!.path!,
        fileName: _pickedFile!.name,
        coverPath: _pickedCover?.path,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, {bool optional = false}) {
    return InputDecoration(
      labelText: optional ? label : '$label *',
      labelStyle: const TextStyle(color: Color(0xFF8A7B6C)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brown, width: 1.5),
      ),
    );
  }

  Widget _pickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool picked,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: picked ? _brown.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: picked ? _brown : const Color(0xFFD8C9B4),
            width: picked ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: _brown),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink,
                  fontWeight: picked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (picked) const Icon(Icons.check_circle_rounded, color: _brown, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgDark, _bgDarkLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Upload Ebook', style: TextStyle(color: Colors.white)),
      ),
      body: AbsorbPointer(
        absorbing: _isUploading,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _pickerButton(
                  icon: Icons.upload_file_rounded,
                  label: _pickedFile == null
                      ? 'Choose PDF or EPUB file'
                      : _pickedFile!.name,
                  onTap: _pickFile,
                  picked: _pickedFile != null,
                ),
                const SizedBox(height: 10),
                _pickerButton(
                  icon: Icons.image_outlined,
                  label: _pickedCover == null
                      ? 'Choose cover image (optional)'
                      : _pickedCover!.name,
                  onTap: _pickCover,
                  picked: _pickedCover != null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: _ink),
                  decoration: _fieldDecoration('Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorController,
                  style: const TextStyle(color: _ink),
                  decoration: _fieldDecoration('Author', optional: true),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isUploading ? null : _submit,
                    child: _isUploading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Upload',
                            style: TextStyle(fontWeight: FontWeight.w600)),
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