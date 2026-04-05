part of 'api_service.dart';

Future<List<Site>> _fetchSites(
  ApiService service, {
  Map<String, dynamic>? queryParameters,
}) async {
  final items = await service._fetchAllPaginatedItems(
    '/sites',
    queryParameters: queryParameters,
  );

  return items.map(Site.fromJson).toList();
}

Future<List<SiteCategory>> _fetchCategories(
  ApiService service, {
  bool topLevelOnly = false,
  bool includeChildren = true,
  Map<String, dynamic>? queryParameters,
}) async {
  final response = await service.get(
    '/categories',
    queryParameters: <String, dynamic>{
      ...?queryParameters,
      if (topLevelOnly) 'top_level': 'true',
      if (!includeChildren) 'include_children': 'false',
    },
  );
  final items = service._extractList(response.data);

  return items.whereType<Map>().map((item) {
    final rawMap = item;
    return SiteCategory.fromJson(
      rawMap.map((key, value) => MapEntry(key.toString(), value)),
    );
  }).toList();
}

Future<List<ProfessionalSite>> _fetchProfessionalSites(
  ApiService service, {
  Map<String, dynamic>? queryParameters,
}) async {
  final items = await service._fetchAllPaginatedItems(
    '/sites/mine',
    queryParameters: queryParameters,
  );

  return items.map(ProfessionalSite.fromJson).toList();
}

Future<ProfessionalSiteDetail> _fetchProfessionalSiteDetail(
  ApiService service,
  String siteId,
) async {
  final response = await service.get('/sites/mine/$siteId');
  final data = service._asStringKeyedMap(service._extractData(response.data));
  return ProfessionalSiteDetail.fromJson(data);
}

Future<ProfessionalSiteDetail> _claimProfessionalSite(
  ApiService service,
  String siteId,
) async {
  final response = await service.post('/sites/$siteId/claim');
  final data = service._asStringKeyedMap(service._extractData(response.data));
  return ProfessionalSiteDetail.fromJson(data);
}

Future<ProfessionalSite> _createSite(
  ApiService service, {
  required String name,
  required int categoryId,
  required double latitude,
  required double longitude,
  String? nameAr,
  String? description,
  String? descriptionAr,
  String? subcategory,
  String? address,
  String? city,
  String? region,
  String? postalCode,
  String? phoneNumber,
  String? email,
  String? website,
  String? priceRange,
  List<String>? amenities,
  String? coverPhoto,
  bool acceptsCardPayment = false,
  bool hasWifi = false,
  bool hasParking = false,
  bool isAccessible = false,
}) async {
  final response = await service.post(
    '/sites',
    data: <String, dynamic>{
      'name': name,
      'category_id': categoryId,
      'latitude': latitude,
      'longitude': longitude,
      if (nameAr != null && nameAr.isNotEmpty) 'name_ar': nameAr,
      if (description != null && description.isNotEmpty) 'description': description,
      if (descriptionAr != null && descriptionAr.isNotEmpty)
        'description_ar': descriptionAr,
      if (subcategory != null && subcategory.isNotEmpty) 'subcategory': subcategory,
      if (address != null && address.isNotEmpty) 'address': address,
      if (city != null && city.isNotEmpty) 'city': city,
      if (region != null && region.isNotEmpty) 'region': region,
      if (postalCode != null && postalCode.isNotEmpty) 'postal_code': postalCode,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phone_number': phoneNumber,
      if (email != null && email.isNotEmpty) 'email': email,
      if (website != null && website.isNotEmpty) 'website': website,
      if (priceRange != null && priceRange.isNotEmpty) 'price_range': priceRange,
      if (amenities != null && amenities.isNotEmpty) 'amenities': amenities,
      if (coverPhoto != null && coverPhoto.isNotEmpty) 'cover_photo': coverPhoto,
      'accepts_card_payment': acceptsCardPayment,
      'has_wifi': hasWifi,
      'has_parking': hasParking,
      'is_accessible': isAccessible,
      'country': 'MA',
    },
  );

  final data = service._asStringKeyedMap(service._extractData(response.data));
  final siteData = service._asStringKeyedMap(data['site'] ?? data);
  return ProfessionalSite.fromJson(siteData);
}

Future<ProfessionalSite> _updateSite(
  ApiService service, {
  required String siteId,
  required String name,
  required int categoryId,
  required double latitude,
  required double longitude,
  String? nameAr,
  String? description,
  String? descriptionAr,
  String? subcategory,
  String? address,
  String? city,
  String? region,
  String? postalCode,
  String? phoneNumber,
  String? email,
  String? website,
  String? priceRange,
  List<String>? amenities,
  String? coverPhoto,
  bool acceptsCardPayment = false,
  bool hasWifi = false,
  bool hasParking = false,
  bool isAccessible = false,
}) async {
  final response = await service.put(
    '/sites/$siteId',
    data: <String, dynamic>{
      'name': name,
      'category_id': categoryId,
      'latitude': latitude,
      'longitude': longitude,
      'name_ar': nameAr,
      'description': description,
      'description_ar': descriptionAr,
      'subcategory': subcategory,
      'address': address,
      'city': city,
      'region': region,
      'postal_code': postalCode,
      'phone_number': phoneNumber,
      'email': email,
      'website': website,
      'price_range': priceRange,
      'amenities': amenities,
      'cover_photo': coverPhoto,
      'accepts_card_payment': acceptsCardPayment,
      'has_wifi': hasWifi,
      'has_parking': hasParking,
      'is_accessible': isAccessible,
    },
  );

  final data = service._asStringKeyedMap(service._extractData(response.data));
  final siteData = service._asStringKeyedMap(data['site'] ?? data);
  return ProfessionalSite.fromJson(siteData);
}

Future<Site> _fetchSiteDetail(ApiService service, String siteId) async {
  final response = await service.get('/sites/$siteId');
  final data = service._asStringKeyedMap(service._extractData(response.data));
  final siteData = service._asStringKeyedMap(data['site'] ?? data);
  final enrichedSiteData = <String, dynamic>{
    ...siteData,
    'opening_hours': data['opening_hours'],
    'recent_reviews': data['recent_reviews'],
  };
  return Site.fromJson(enrichedSiteData);
}

Future<List<SitePhoto>> _fetchSitePhotos(
  ApiService service,
  String siteId, {
  Map<String, dynamic>? queryParameters,
}) async {
  final items = await service._fetchAllPaginatedItems(
    '/sites/$siteId/photos',
    queryParameters: queryParameters,
  );

  return items.map(SitePhoto.fromJson).toList();
}
