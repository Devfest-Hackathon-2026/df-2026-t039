import 'dart:convert';

import 'package:flutter/services.dart';

class NearbyPlace {
  const NearbyPlace({
    required this.name,
    required this.location,
    required this.category,
    this.id,
    this.googlePlaceId,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String location;
  final String category;
  final String? id;
  final String? googlePlaceId;
  final double? latitude;
  final double? longitude;

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      name: json['name'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      id: json['id'] as String?,
      googlePlaceId: json['google_place_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class NearbyPlacesHandler {
  const NearbyPlacesHandler();

  Future<List<NearbyPlace>> loadNearbyPlaces() async {
    final text = await rootBundle.loadString('lib/data/nearby_places.json');
    final data = jsonDecode(text) as List<dynamic>;
    return data
        .map((place) => NearbyPlace.fromJson(place as Map<String, dynamic>))
        .toList();
  }
}
