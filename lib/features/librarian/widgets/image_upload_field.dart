import 'package:flutter/material.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../core/widgets/stored_image.dart';
import '../theme/librarian_theme.dart';

/// Image picker with preview, used for book covers and seat photos.
///
/// Shows the newly picked image ([picked]) or else the saved one
/// ([savedUrl]), or [placeholder] when there is none. The image is only
/// uploaded when the form is saved; [uploadProgress] shows that upload.
class ImageUploadField extends StatefulWidget {
  const ImageUploadField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.previewSize,
    required this.picked,
    required this.savedUrl,
    required this.onPicked,
    required this.onRemove,
    this.enabled = true,
    this.disabledReason,
    this.uploadProgress,
    this.chooseLabel = 'Choose Image',
    this.replaceLabel = 'Replace Image',
    this.hint = 'JPG, PNG or WebP, up to 5 MB. Optional.',
  });

  final String label;
  final Widget placeholder;
  final Size previewSize;
  final ImageUpload? picked;

  /// The image already saved for this item (null if none or removed).
  final String? savedUrl;
  final ValueChanged<ImageUpload> onPicked;
  final VoidCallback onRemove;

  /// False when images cannot be uploaded (e.g. demo data).
  final bool enabled;
  final String? disabledReason;

  /// 0.0–1.0 while uploading, otherwise null.
  final double? uploadProgress;

  final String chooseLabel;
  final String replaceLabel;
  final String hint;

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  String? _error;
  bool _picking = false;

  bool get _hasImage => widget.picked != null || widget.savedUrl != null;
  bool get _busy => _picking || widget.uploadProgress != null;

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final (image, error) = await ImagePickerService.instance.pickImage();
      if (!mounted) return;
      if (image != null) widget.onPicked(image);
      setState(() => _error = error);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the image picker.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.previewSize;
    final Widget preview = widget.picked != null
        ? Image.memory(
            widget.picked!.bytes,
            fit: BoxFit.cover,
            // A file that is not a readable image shows the placeholder.
            errorBuilder: (context, error, stackTrace) => widget.placeholder,
          )
        : StoredImage(url: widget.savedUrl, fallback: widget.placeholder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(LibrarianSpacing.radius),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: preview,
            ),
          ),
        ),
        if (widget.uploadProgress != null) ...[
          const SizedBox(height: LibrarianSpacing.sm),
          LinearProgressIndicator(
            value: widget.uploadProgress == 0 ? null : widget.uploadProgress,
          ),
          const SizedBox(height: 4),
          Text(
            widget.uploadProgress == 0
                ? 'Uploading image…'
                : 'Uploading image… ${(widget.uploadProgress! * 100).round()}%',
            textAlign: TextAlign.center,
            style: TextStyle(color: LibrarianColors.secondaryText),
          ),
        ],
        const SizedBox(height: LibrarianSpacing.md),
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LibrarianColors.text,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LibrarianSpacing.xs),
        Text(
          widget.enabled
              ? widget.hint
              : widget.disabledReason ?? 'Image upload is not available.',
          textAlign: TextAlign.center,
          style: TextStyle(color: LibrarianColors.secondaryText),
        ),
        if (_error != null) ...[
          const SizedBox(height: LibrarianSpacing.xs),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (widget.enabled) ...[
          const SizedBox(height: LibrarianSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: LibrarianSpacing.sm,
            runSpacing: LibrarianSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.upload_outlined),
                label: Text(_hasImage ? widget.replaceLabel : widget.chooseLabel),
              ),
              if (_hasImage)
                TextButton.icon(
                  onPressed: _busy ? null : widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Image'),
                  style: TextButton.styleFrom(
                    foregroundColor: LibrarianColors.unavailable,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
