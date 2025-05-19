// map_page.dart

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
  bool streakLoaded = false;
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
          streakLoaded = true;
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
          // Streak Button
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                if (streakLoaded) {
                  AuraStreakPopup.show(context, streakCount);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      streakLoaded ? '$streakCount day streak' : 'Loading...',
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
            ),
          ),


          // Account Button
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/account');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      "Account",
                      style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendRow('assets/green.png', 'Seating Available'),
                  SizedBox(height: 6),
                  _buildLegendRow('assets/red.png', 'Grab-and-Go Only'),
                  SizedBox(height: 6),
                  _buildLegendRow('assets/grey.png', 'No Check-Ins Yet'),
                ],
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
          markerIcon = yesCount > noCount ? greenMarker : redMarker;
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
        .get();

    final reviews = snapshot.docs;
    final totalReviews = reviews.length;

    final hasNoCheckIns = totalReviews == 0;
    final allNoSeating = reviews.isNotEmpty && reviews.every((doc) => doc['seatingOffered'] == 'No');

    // Check for 3 most recent reviews with seating == Yes
    final recentWithSeating = reviews.take(3).where((doc) => doc['seatingOffered'] == 'Yes').length;
    final showReviews = recentWithSeating == 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _launchMapsSearch(address),
                  child: Text('Get Directions on Google Maps', style: TextStyle(color: Colors.blue)),
                ),
                SizedBox(height: 8),
                Text(hours, style: TextStyle(fontStyle: FontStyle.italic)),
                const Divider(height: 20),

                if (hasNoCheckIns)
                  Text(
                    "No one has checked in at this café yet.\nYou could be the trendstarter — add a check-in to attract the right crowd and set the tone for the vibe!",
                    style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  )
                else if (allNoSeating)
                  Text(
                    "Many have reported this is a grab-and-go spot with no seating.\nAdd a check-in to confirm this, or keep others in the loop if seating is now available!",
                    style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  )
                else if (showReviews) ...[
                  // Extract amenities from the recent 3 reviews
                  Builder(
                    builder: (context) {
                      final Set<String> amenitiesSet = {};
                      final iconMap = {
                        "WiFi Available": Icons.wifi,
                        "Bathroom": Icons.wc,
                        "Power Outlets": Icons.power,
                      };

                      for (var doc in reviews.take(3)) {
                        final amenities = (doc['amenities'] as String?)?.split(', ') ?? [];
                        amenitiesSet.addAll(amenities);
                      }

                      return amenitiesSet.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                alignment: WrapAlignment.start,
                                children: amenitiesSet.map((a) {
                                  final icon = iconMap[a];
                                  return icon != null
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(icon, size: 18, color: Colors.grey[800]),
                                            SizedBox(width: 6),
                                            Text(a, style: TextStyle(fontSize: 13, color: Color(0xFF333333))),
                                          ],
                                        )
                                      : SizedBox.shrink();
                                }).toList(),
                              ),
                            )
                          : SizedBox.shrink();
                    },
                  ),

                  ...reviews.take(5).map((doc) {
                    final review = doc.data();
                    final avatar = review['avatar'] ?? 'assets/coffee_logo.png';
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(backgroundImage: AssetImage(avatar), radius: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formattedTime, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                SizedBox(height: 4),
                                Text(
                                  "$availability | $noise | $seating | $vibe",
                                  style: TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Text(
                    "Maintain your streak by checking in daily! Your check-ins help others find a space that matches their vib, whether it’s quiet for work or lively for conversation. Let’s make sure everyone feels like they belong.",
                    style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  ),
                ],

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text("Add Check-In", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    
  Widget _buildLegendRow(String assetPath, String label) {
    return Row(
      children: [
        Image.asset(assetPath, width: 32, height: 32),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333), // Dark grey for non-clickable
          ),
        ),
      ],
    );
  }


}
