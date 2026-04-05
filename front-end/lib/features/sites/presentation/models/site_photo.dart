class SitePhoto {
  final String id;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? caption;
  final bool isPrimary;

  const SitePhoto({
    required this.id,
    required this.imageUrl,
    this.thumbnailUrl,
    this.caption,
    this.isPrimary = false,
  });

  factory SitePhoto.fromJson(Map<String, dynamic> json) {
    final rawPrimary = json['is_primary'];

    return SitePhoto(
      id: '${json['id']}',
      imageUrl: json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      isPrimary: rawPrimary == true || rawPrimary == 1 || rawPrimary == '1',
    );
  }
}
