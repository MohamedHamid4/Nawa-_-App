import 'package:metadata_fetch/metadata_fetch.dart';

import '../utils/app_logger.dart';

class LinkPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  const LinkPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });
}

class LinkPreviewService {
  Future<LinkPreviewData> fetch(String url) async {
    try {
      final data = await MetadataFetch.extract(url);
      return LinkPreviewData(
        url: url,
        title: data?.title,
        description: data?.description,
        imageUrl: data?.image,
      );
    } catch (e) {
      AppLogger.w('link preview failed: $e');
      return LinkPreviewData(url: url);
    }
  }
}
