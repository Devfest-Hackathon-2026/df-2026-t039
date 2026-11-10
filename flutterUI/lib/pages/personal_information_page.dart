import 'package:flutter/material.dart';

class PersonalInformationPage extends StatelessWidget {
  const PersonalInformationPage({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  Widget build(BuildContext context) {
    final age = userData['age'];
    final hobbies = userData['hobbies'];
    final address = userData['address'];
    final name = userData['name'];
    final phone = userData['phone'];
    final email = userData['email'];
    final occupation = userData['occupation'];

    return Scaffold(
      appBar: AppBar(title: const Text('個人情報')),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name != null) Text('名前: $name'),
            if (age != null) Text('年齢: $age'),
            if (phone != null) Text('電話番号: $phone'),
            if (email != null) Text('メールアドレス: $email'),
            if (occupation != null) Text('職業: $occupation'),
            if (address != null) Text('住所: $address'),
            if (hobbies != null)
              Container(
                margin: const EdgeInsets.only(top: 5),
                child: Text(
                  '趣味:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            for (final hobby in List<String>.from(hobbies as List)) Text(hobby),
          ],
        ),
      ),
    );
  }
}
