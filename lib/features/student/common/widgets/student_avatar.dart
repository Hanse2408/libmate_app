import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Same photo and fallback initials everywhere the student is shown.
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({super.key, required this.name, this.photoUrl, this.preview, this.size = 48});
  final String name;
  final String? photoUrl;
  final Uint8List? preview;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty)
        .take(2).map((part) => part[0]).join().toUpperCase();
    final fallback = Center(child: Text(initials.isEmpty ? 'S' : initials,
      style: TextStyle(color: Colors.white, fontSize: size * .32, fontWeight: FontWeight.w700)));
    final url = photoUrl?.trim() ?? '';
    final image = preview != null
        ? Image.memory(preview!, fit: BoxFit.cover, width: size, height: size,
          errorBuilder: (_, _, _) => fallback)
        : url.isNotEmpty
          ? Image.network(url, fit: BoxFit.cover, width: size, height: size,
              errorBuilder: (_, _, _) => fallback)
          : fallback;
    return Semantics(label: 'Profile photo', image: true,
      child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Theme.of(context).colorScheme.primary, const Color(0xFF1E40AF)])),
        child: ClipOval(child: image)),
    );
  }
}
