import 'dart:convert';

import 'package:flutter/services.dart';

class NearbyPlace {
  const NearbyPlace({
    required this.name,
    required this.location,
    required this.category,
  });

  final String name;
  final String location;
  final String category;

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      name: json['name'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
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
