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
  int auraPoints = 0;
  late BitmapDescriptor redMarker;
  late BitmapDescriptor greenMarker;
  late BitmapDescriptor greyMarker;

  @override
  void initState() {
    super.initState();
    loadCustomMarkers();
    initAppFlow(); // <- new wrapper function
  }

  Future<void> initAppFlow() async {
    await getLocationUpdates();      // requests location + permissions
    await loadCsvData();             // only runs if location is granted
    await loadAuraPoints();
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
                child: Icon(Icons.person, color: Colors.black, size: 22), // 👤 Instead of logout, use "person" icon
              ),
            ),
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
        final String hours = row[2];
        final position = LatLng(lat, lon);

        // 🔎 Check Firestore for seating data before assigning marker
        final snapshot = await FirebaseFirestore.instance
            .collection('cafes')
            .doc(markerId)
            .collection('reviews')
            .get();

        final docs = snapshot.docs;
        BitmapDescriptor markerIcon = greyMarker; // default

        if (docs.isNotEmpty) {
          final yesCount = docs.where((doc) => doc['seatingOffered'] == 'Yes').length;
          final noCount = docs.length - yesCount;

          if (yesCount >= noCount) {
            markerIcon = greenMarker;
          } else {
            markerIcon = redMarker;
          }
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

      final timestamp = review['timestamp'] != null
          ? (review['timestamp'] as Timestamp).toDate()
          : null;

      final formattedTime = timestamp != null
          ? DateFormat('MM/dd/yyyy hh:mm a').format(timestamp)
          : 'Unknown date';

      return "$formattedTime - $availability | $noise | $seating | $vibe";
    }).toList();

    final hasSeatingList = reviews.map((r) => r['seatingOffered'] ?? '').toList();
    final hasSeating = hasSeatingList.where((v) => v == 'Yes').length >= (hasSeatingList.length / 2);

    final amenityList = <String>[];
    for (var review in reviews) {
      if (review['amenities'] != null) {
        amenityList.addAll((review['amenities'] as String).split(', '));
      }
    }

    final Map<String, int> amenityCounts = {};
    for (var amenity in amenityList) {
      amenityCounts[amenity] = (amenityCounts[amenity] ?? 0) + 1;
    }
    final sortedAmenities = amenityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final commonAmenities = sortedAmenities
        .map((e) => e.key)
        .where((a) => a.trim().isNotEmpty)
        .take(3)
        .toList();

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
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _launchMapsSearch(address),
                  child: Text(
                    'Get Directions on Google Maps',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 8),
                Text(hours, style: TextStyle(fontStyle: FontStyle.italic)),
                const Divider(height: 20),
                if (reviews.isEmpty) ...[
                  Text("There have been no check-ins at this location lately! Be the first to contribute for 75 Aura Points instead of 50 :)")
                ] else ...[
                  Text("Based on recent trends, this location:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(hasSeating ? "- Offers seating" : "- Does not appear to offer seating"),
                  if (hasSeating && commonAmenities.isNotEmpty)
                    Text("- Amenities: ${commonAmenities.join(', ')}"),
                  const Divider(height: 20),
                  Text(
                    hasSeating
                        ? "Here is the vibes that people are reporting:"
                        : "Because there is no seating available at this location, there are no vibes available! But update the community below if you feel that this information is incorrect.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (hasSeating)
                    (recentCheckins.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: recentCheckins
                                .map((vibe) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text("• $vibe"),
                                    ))
                                .toList(),
                          )
                        : Text("No check-ins yet.")),
                ],
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
