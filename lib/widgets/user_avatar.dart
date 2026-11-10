import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UserAvatar extends StatelessWidget {
  final String imagePath;
  final double radius;
  final VoidCallback? onTap;
  final bool enableZoomPreview;
  final String? heroTitle;

  const UserAvatar({
    super.key,
    required this.imagePath,
    this.radius = 24,
    this.onTap,
    this.enableZoomPreview = false,
    this.heroTitle,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = UserService.getImageUrl(imagePath);
    final size = radius * 2;

    Widget avatarContent;
    if (resolvedUrl.isEmpty) {
      avatarContent = Icon(
        Icons.person,
        size: radius * 1.1,
        color: Colors.grey.shade600,
      );
    } else {
      avatarContent = ClipOval(
        child: Image.network(
          resolvedUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: radius * 0.8,
                height: radius * 0.8,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.broken_image_outlined,
              size: radius * 1.0,
              color: Colors.grey.shade500,
            );
          },
        ),
      );
    }

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(child: avatarContent),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: circle);
    }
    if (enableZoomPreview && resolvedUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => showImagePreviewDialog(
          context,
          resolvedUrl,
          title: heroTitle ?? 'Xem ảnh đại diện',
        ),
        child: circle,
      );
    }
    return circle;
  }
}

Future<void> showImagePreviewDialog(
  BuildContext context,
  String imageUrl, {
  String title = 'Xem ảnh',
}) async {
  await showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(title, style: const TextStyle(fontSize: 16)),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: Colors.white54),
                      SizedBox(height: 12),
                      Text(
                        'Không thể tải hình ảnh',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
