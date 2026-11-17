import 'package:flutter/material.dart';

import '../../domain/api_origin.dart';
import '../../domain/models.dart';

String? productImage(Json row) {
  final product = obj(row['product']);
  for (final data in [row, product]) {
    final pictures = maps(data['thumbnails']) + maps(data['images']);
    for (final candidate in [
      data['thumbnailUrl'], data['imageUrl'], data['mainImageUrl'],
      ...pictures.expand((image) => [image['thumbnailUrl'], image['imageUrl'], image['url']]),
    ]) {
      final value = str(candidate).trim();
      if (value.isEmpty) continue;
      final base = Uri.parse(apiBaseUrl);
      final uri = base.resolve(value);
      if ((uri.scheme == 'https' || uri.scheme == 'http') && uri.hasAuthority && uri.origin == base.origin) return uri.toString();
    }
  }
  return null;
}

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({super.key, required this.url, this.size = 54, this.icon = Icons.inventory_2_outlined});

  final String? url;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget fallback() => ColoredBox(color: c.primaryContainer, child: Center(child: Icon(icon, color: c.primary, size: 23)));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: size,
        child: url == null ? fallback() : Image.network(
          url!,
          fit: BoxFit.cover,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          excludeFromSemantics: true,
          frameBuilder: (context, image, frame, synchronous) => synchronous || frame != null ? image : fallback(),
          errorBuilder: (context, error, trace) => fallback(),
        ),
      ),
    );
  }
}
