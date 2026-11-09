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
      appBar: AppBar(title: const Text('Personal Information')),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name != null) Text('Name: $name'),
            if (age != null) Text('Age: $age'),
            if (phone != null) Text('Phone: $phone'),
            if (email != null) Text('Email: $email'),
            if (occupation != null) Text('Occupation: $occupation'),
            if (address != null) Text('Address: $address'),
            if (hobbies != null)
              Container(
                margin: const EdgeInsets.only(top: 5),
                child: Text(
                  'Hobbies:',
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
