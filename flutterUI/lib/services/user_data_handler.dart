import 'dart:convert';

import 'package:flutter/services.dart';

class UserDataHandler {
  const UserDataHandler();

  Future<Map<String, dynamic>> loadUserData({
    String assetPath = 'lib/data/example_user_data.json',
  }) async {
    final jsonText = await rootBundle.loadString(assetPath);
    final data = jsonDecode(jsonText);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('User data must be a JSON object.');
    }
    return data;
  }
}
