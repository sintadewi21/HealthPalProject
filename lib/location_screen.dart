import 'package:flutter/material.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Nanti di sini kamu bisa taruh Google Maps + list dokter/RS terdekat.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
