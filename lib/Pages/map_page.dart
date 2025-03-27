import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  static const LatLng defaultLocation = LatLng(40.768034137130904, -73.96454910893894);
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Map<String, List<String>> _reviews = {}; // Local reviews
  int auraPoints = 0;

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
    loadCsvData();
    loadAuraPoints();
  }

  Future<void> loadAuraPoints() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        auraPoints = doc.data()?['auraPoints'] ?? 0;
      });
    }
  }

  void _showAuraPopup(BuildContext context) {
    final progress = auraPoints.clamp(0, 1000) / 1000;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Aura Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('1000 points = Top Contributor!'),
            SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            SizedBox(height: 8),
            Text('${(progress * 100).round()}% complete'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            zoomGesturesEnabled: true,
            onMapCreated: (controller) => _mapController.complete(controller),
            initialCameraPosition: CameraPosition(target: defaultLocation, zoom: 17),
            markers: _markers,
            circles: _circles,
          ),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => _showAuraPopup(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFFFFACD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$auraPoints pts',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    if (kIsWeb) {
      final Circle currentLocationCircle = Circle(
        circleId: CircleId("current_location"),
        center: defaultLocation,
        radius: 15,
        fillColor: Color.fromARGB(100, 66, 133, 244),
        strokeColor: Color.fromARGB(255, 66, 133, 244),
        strokeWidth: 2,
      );

      final Circle searchRadiusCircle = Circle(
        circleId: CircleId("search_radius"),
        center: defaultLocation,
        radius: 800,
        fillColor: Color.fromARGB(50, 66, 133, 244),
        strokeColor: Color.fromARGB(150, 66, 133, 244),
        strokeWidth: 2,
      );

      setState(() {
        _circles.addAll([currentLocationCircle, searchRadiusCircle]);
      });
    }
  }

  Future<void> loadCsvData() async {
    final rawData = await rootBundle.loadString('assets/locations.csv');
    final rows = const CsvToListConverter().convert(rawData);

    for (var row in rows.skip(1)) {
      try {
        final lat = double.parse(row[3].toString());
        final lon = double.parse(row[4].toString());
        final String markerId = '${row[3]}_${row[4]}';
        final String name = row[1];
        final String address = row[1];
        final position = LatLng(lat, lon);

        final marker = Marker(
          markerId: MarkerId(markerId),
          position: position,
          onTap: () => _showCafeDetails(context, name, address, markerId),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );

        setState(() {
          _markers.add(marker);
        });
      } catch (e) {
        print("⚠️ Error parsing row: $row — $e");
      }
    }

    adjustCameraToMarkers();
  }

  Future<void> adjustCameraToMarkers() async {
    if (_markers.isEmpty) return;

    final controller = await _mapController.future;
    final bounds = _createBounds(_markers);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  LatLngBounds _createBounds(Set<Marker> markers) {
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _showCafeDetails(BuildContext context, String name, String address, String markerId) {
    final List<String> reviews = _reviews[markerId] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _launchMapsSearch(address),
                  child: Text(
                    'Get Directions on Google Maps',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
                SizedBox(height: 12),
                Text("Open daily: 8 AM – 8 PM", style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                Divider(height: 20),
                Text("Recent Check-Ins", style: TextStyle(fontWeight: FontWeight.bold)),
                if (reviews.isEmpty)
                  Text("No check-ins yet."),
                for (var review in reviews)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text("• $review"),
                  ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/reviews',
                      arguments: {
                        'cafeId': markerId,
                        'cafeName': name,
                        'address': address,
                      },
                    );
                  },
                  child: Text("Add Check-In"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _launchMapsSearch(String address) async {
    final Uri mapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    if (await canLaunchUrl(mapsUrl)) {
      await launchUrl(mapsUrl);
    } else {
      print("❌ Could not launch Google Maps");
    }
  }
}
