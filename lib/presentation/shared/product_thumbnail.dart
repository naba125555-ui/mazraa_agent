import 'package:flutter/material.dart';

import '../../domain/api_origin.dart';
import '../../domain/models.dart';

List<String> productImages(Json row) {
  final base = Uri.parse(apiBaseUrl);
  final urls = <String>{};
  final product = obj(row['product']);
  Iterable<Object?> gallery(Object? data) => maps(data).expand((image) =>
      [image['thumbnailUrl'], image['imageUrl'], image['mediaUrl'], image['url']]);
  for (final candidate in [
    if (row['imageUrls'] is List) ...(row['imageUrls'] as List),
    row['variantImageUrl'], row['thumbnailUrl'], row['thumbnail'],
    ...gallery(row['thumbnails']), ...gallery(row['images']),
    row['imageUrl'], row['mainImageUrl'], row['productImageUrl'],
    ...gallery(row['productImages']),
    product['thumbnailUrl'], product['imageUrl'], product['mainImageUrl'],
    ...gallery(product['thumbnails']), ...gallery(product['images']),
  ]) {
    if (candidate is! String || candidate.trim().isEmpty) continue;
    final parsed = Uri.tryParse(candidate.trim());
    if (parsed == null) continue;
    final uri = base.resolveUri(parsed);
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.hasAuthority && uri.origin == base.origin && uri.userInfo.isEmpty) {
      urls.add(uri.toString());
    }
  }
  return urls.toList(growable: false);
}

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({super.key, required this.urls, this.size = 54, this.icon = Icons.inventory_2_outlined});

  final List<String> urls;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget fallback() => ColoredBox(color: c.primaryContainer, child: Center(child: Icon(icon, color: c.primary, size: 23)));
    Widget load(int index) {
      if (index >= urls.length) return fallback();
      return Image.network(
        urls[index],
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        excludeFromSemantics: true,
        frameBuilder: (context, image, frame, synchronous) => synchronous || frame != null ? image : fallback(),
        errorBuilder: (context, error, trace) => load(index + 1),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: size,
        child: load(0),
      ),
    );
  }
}
