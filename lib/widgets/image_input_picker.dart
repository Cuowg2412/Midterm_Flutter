import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';

class ImageInputPicker extends StatefulWidget {
  final Color accentColor;
  final String initialImageUrl;
  final ValueChanged<(Uint8List? bytes, String? fileName, String imageUrl)>
      onChanged;

  const ImageInputPicker({
    super.key,
    required this.accentColor,
    this.initialImageUrl = '',
    required this.onChanged,
  });

  @override
  State<ImageInputPicker> createState() => _ImageInputPickerState();
}

class _ImageInputPickerState extends State<ImageInputPicker> {
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  late TextEditingController _urlController;
  bool _useUrlInput = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialImageUrl);
    if (widget.initialImageUrl.startsWith('http')) {
      _useUrlInput = true;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged((
      _selectedBytes,
      _selectedFileName,
      _urlController.text.trim(),
    ));
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedBytes = bytes;
          _selectedFileName = file.name;
          _useUrlInput = false;
        });
        _emitChange();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn hình: $e')),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedBytes = null;
      _selectedFileName = null;
      _urlController.clear();
    });
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = _urlController.text.trim();
    final resolvedUrl = UserService.getImageUrl(currentUrl);
    final hasAnyImage = _selectedBytes != null || resolvedUrl.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: widget.accentColor, width: 2.5),
            ),
            child: ClipOval(
              child: _buildPreviewContent(resolvedUrl),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            FilledButton.tonalIcon(
              onPressed: _pickFile,
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('Chọn ảnh từ máy'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _useUrlInput = !_useUrlInput);
              },
              icon: const Icon(Icons.link, size: 18),
              label: Text(_useUrlInput ? 'Ẩn ô link' : 'Dán link URL'),
            ),
            if (hasAnyImage)
              TextButton.icon(
                onPressed: _clearImage,
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.red),
                label: const Text('Xóa ảnh',
                    style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        if (_useUrlInput) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Đường dẫn / URL hình ảnh',
              hintText: 'https://example.com/avatar.png',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              setState(() {
                _selectedBytes = null;
                _selectedFileName = null;
              });
              _emitChange();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewContent(String resolvedUrl) {
    if (_selectedBytes != null) {
      return Image.memory(_selectedBytes!, fit: BoxFit.cover);
    }
    if (resolvedUrl.isNotEmpty) {
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 32, color: Colors.grey),
            SizedBox(height: 4),
            Text('Ảnh lỗi', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, size: 32, color: Colors.grey),
        SizedBox(height: 4),
        Text('Chọn ảnh', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
