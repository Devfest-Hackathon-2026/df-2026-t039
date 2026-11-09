import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/services/user_data_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the default example user', () async {
    final data = await const UserDataHandler().loadUserData();

    expect(data['name'], 'John Doe');
    expect(data['address'], 'Fukuoka');
    expect(data['history'], isA<List<dynamic>>());
  });

  test('loads another bundled user', () async {
    final data = await const UserDataHandler().loadUserData(
      assetPath: 'lib/data/example_user_data.json',
    );

    expect(data['occupation'], 'Software Engineer');
  });

  test('reports a missing asset', () async {
    expect(
      const UserDataHandler().loadUserData(assetPath: 'lib/data/missing.json'),
      throwsA(isA<FlutterError>()),
    );
  });
}
