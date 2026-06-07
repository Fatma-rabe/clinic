import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Interactive X-ray viewer with zoom and rotate.
class XrayViewerPanel extends StatefulWidget {
  const XrayViewerPanel({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  State<XrayViewerPanel> createState() => _XrayViewerPanelState();
}

class _XrayViewerPanelState extends State<XrayViewerPanel> {
  double _rotation = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked),
                const SizedBox(width: 8),
                const Text('X-Ray Viewer'),
                const Spacer(),
                IconButton(
                  tooltip: 'Rotate 90°',
                  onPressed: () =>
                      setState(() => _rotation += 1.5708),
                  icon: const Icon(Icons.rotate_90_degrees_cw),
                ),
                IconButton(
                  tooltip: 'Reset rotation',
                  onPressed: () => setState(() => _rotation = 0),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Transform.rotate(
              angle: _rotation,
              child: PhotoView(
                backgroundDecoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
                imageProvider: CachedNetworkImageProvider(widget.imageUrl),
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorBuilder: (context, error, stack) => Center(
                  child: Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.red[200]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
