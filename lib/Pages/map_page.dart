import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'aura_system.dart';

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
  int streakCount = 0;
  late BitmapDescriptor redMarker;
  late BitmapDescriptor greenMarker;
  late BitmapDescriptor greyMarker;

  @override
  void initState() {
    super.initState();
    loadCustomMarkers();
    initAppFlow();
  }

  Future<void> initAppFlow() async {
    await getLocationUpdates();
    await loadCsvData();
    await loadStreakCount();
  }

  Future<void> loadCustomMarkers() async {
    redMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(72, 72)),
      'assets/red.png',
    );
    greenMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(72, 72)),
      'assets/green.png',
    );
    greyMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(72, 72)),
      'assets/grey.png',
    );
  }

  Future<void> loadStreakCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && data.containsKey('streak')) {
        setState(() {
          streakCount = data['streak'] ?? 0;
        });
      }
    }
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
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/account');
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFFFFACD),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.black, size: 22),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => AuraStreakPopup.show(context, streakCount),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFFFFACD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$streakCount day streak',
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
        final markerId = '${row[3]}_${row[4]}';
        final name = row[1];
        final address = row[1];
        final hours = row[2];
        final position = LatLng(lat, lon);

        final snapshot = await FirebaseFirestore.instance
            .collection('cafes')
            .doc(markerId)
            .collection('reviews')
            .get();

        final docs = snapshot.docs;
        BitmapDescriptor markerIcon = greyMarker;

        if (docs.isNotEmpty) {
          final yesCount = docs.where((doc) => doc['seatingOffered'] == 'Yes').length;
          final noCount = docs.length - yesCount;
          markerIcon = yesCount >= noCount ? greenMarker : redMarker;
        }

        final marker = Marker(
          markerId: MarkerId(markerId),
          position: position,
          icon: markerIcon,
          onTap: () => _showCafeDetails(context, name, address, hours, markerId),
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

  Future<void> _showCafeDetails(BuildContext context, String name, String address, String hours, String markerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('cafes')
        .doc(markerId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    final reviews = snapshot.docs.map((doc) => doc.data()).toList();

    final recentCheckins = reviews.map((review) {
      final availability = review['availability'] ?? '';
      final noise = review['noiseLevel'] ?? '';
      final seating = review['seatingType'] ?? '';
      final vibe = review['vibes'] ?? '';
      final timestamp = review['timestamp'] != null ? (review['timestamp'] as Timestamp).toDate() : null;
      final formattedTime = timestamp != null
          ? DateFormat('MM/dd/yyyy hh:mm a').format(timestamp)
          : 'Unknown date';
      return "$formattedTime - $availability | $noise | $seating | $vibe";
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.51,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _launchMapsSearch(address),
                  child: Text('Get Directions on Google Maps', style: TextStyle(color: Colors.blue)),
                ),
                const Divider(height: 20),
                ...recentCheckins.map((entry) => Text("• $entry")),
                const SizedBox(height: 16),
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
