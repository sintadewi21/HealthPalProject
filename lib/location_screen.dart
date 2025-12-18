import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  LatLng? _currentPosition;

  final _supabase = Supabase.instance.client;
  final Distance _distance = const Distance();

  List<Clinic> _clinics = [];
  bool _loadingClinics = true;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    await Geolocator.requestPermission();

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentPosition = LatLng(position.latitude, position.longitude);

    await _fetchClinics();
  }

  Future<void> _fetchClinics() async {
    final data = await _supabase
        .from('clinics')
        .select('clinic_id, clinic_name, latitude, longitude')
        .not('latitude', 'is', null);

    final userPos = _currentPosition!;

    final clinics = data.map<Clinic>((c) {
      final lat = c['latitude'] as double;
      final lng = c['longitude'] as double;

      final km = _distance.as(
        LengthUnit.Kilometer,
        userPos,
        LatLng(lat, lng),
      );

      return Clinic(
        id: c['clinic_id'],
        name: c['clinic_name'],
        lat: lat,
        lng: lng,
        distanceKm: km,
      );
    }).toList();

    clinics.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

    setState(() {
      _clinics = clinics.take(10).toList();
      _loadingClinics = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.healthpal.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // USER MARKER
                        Marker(
                          point: _currentPosition!,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),

                        // CLINIC MARKERS
                        ..._clinics.map(
                          (c) => Marker(
                            point: LatLng(c.lat, c.lng),
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.local_hospital,
                              color: Colors.blue,
                              size: 34,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // SEARCH BAR (UI ready)
                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari Rumah Sakit',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // BOTTOM CARD
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: _loadingClinics
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _clinics.length,
                            itemBuilder: (context, index) {
                              final clinic = _clinics[index];
                              return HospitalCard(
                                name: clinic.name,
                                distance:
                                    '${clinic.distanceKm!.toStringAsFixed(1)} km',
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* =======================
   MODELS & WIDGETS
======================= */

class Clinic {
  final String id;
  final String name;
  final double lat;
  final double lng;
  double? distanceKm;

  Clinic({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.distanceKm,
  });
}

class HospitalCard extends StatelessWidget {
  final String name;
  final String distance;

  const HospitalCard({
    super.key,
    required this.name,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Icon(Icons.local_hospital, size: 60),
            ),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(distance),
          ],
        ),
      ),
    );
  }
}
