import 'package:flutter/material.dart';

Widget destinationCard(String name) {
  return SizedBox(
    width: 140,
    child: Card(
      child: Center(child: Text(name)),
    ),
  );
}