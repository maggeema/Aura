import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'home_page.dart' as home;
import 'settings_page.dart';
import 'package:flutter/foundation.dart'; 
import 'reviews_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  static const LatLng manhattan = LatLng(40.7588, -73.9851);
  LatLng? _currentP;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
    loadCsvData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true, // ✅ Only works on Android/iOS (not Web)
            myLocationButtonEnabled: true, // ✅ Allows recentering
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(40.768034137130904, -73.96454910893894), // Hunter College Starbucks
              zoom: 17, // Adjust zoom for visibility
            ),
            markers: _markers,
            circles: _circles, // ✅ Ensure the blue circle is included
          ),
          Positioned(
            bottom: 80,
            right: 10,
            child: Column(
              children: [
              FloatingActionButton(
                heroTag: "current_location_btn",
                onPressed: () async {
                  final GoogleMapController controller = await _mapController.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLng(LatLng(40.768034137130904, -73.96454910893894)), // Move to Blue Dot
                  );
                },
                child: Icon(Icons.my_location), // Standard "current location" icon
              ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () async {
                    _currentP = LatLng(40.768034137130904, -73.96454910893894); // ✅ Set "current location" to Hunter College Starbucks

                    final result = await showDialog<Map<String, String>>(
                      context: context,
                      builder: (context) => CafeInfoDialog(), // ✅ Opens dialog for user to enter details
                    );

                    if (result != null && result.isNotEmpty) {
                      final marker = Marker(
                        markerId: MarkerId(DateTime.now().toString()), // ✅ Unique marker ID
                        position: _currentP!, // ✅ Uses Hunter College Starbucks as location
                        infoWindow: InfoWindow(
                          title: result['name'], // ✅ Uses user input as title
                          snippet: result['address'], // ✅ Uses user input as address
                          onTap: () {
                            Navigator.pushNamed(context, '/reviews'); // ✅ Navigates to reviews page
                          },
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // ✅ Green Marker
                      );

                      setState(() {
                        _markers.add(marker); // ✅ Adds new marker to the map
                      });
                    }
                  },
                  child: Icon(Icons.add_location), // ✅ "Add Location" Icon
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.1,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home),
                onPressed: () {
                  Navigator.pushNamed(context, '/home');
                },
              ),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              IconButton(
                icon: Icon(Icons.reviews),
                onPressed: () {
                  Navigator.pushNamed(context, '/reviews');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: 11,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        print("⚠️ Location services are disabled.");
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        print("⚠️ Location permission denied.");
        return;
      }
    }

    print("✅ Location permission granted!");
  }

  Set<Circle> _circles = {}; // ✅ Define a Set to store the blue circle

  Future<void> loadCsvData() async {
    final rawData = await rootBundle.loadString('assets/locations.csv');
    List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);

    for (var row in rows.skip(1)) {
      try {
        final double lat = double.parse(row[3].toString());
        final double lon = double.parse(row[4].toString());
        final LatLng position = LatLng(lat, lon);

        final marker = Marker(
          markerId: MarkerId(row[0].toString() + "_" + row[1]), // Unique marker ID
          position: position,
          infoWindow: InfoWindow(
            title: row[1],
            snippet: row[2],
          ),
        );

        setState(() {
          _markers.add(marker);
        });
      } catch (e) {
        print("⚠️ Error parsing row: $row - Error: $e");
      }
    }

    // ✅ Add a Blue Circle Instead of a Marker for "Current Location" on Web
    if (kIsWeb) {
      print("🌍 Running on Flutter Web - Adding a manual blue circle!");

      final LatLng hunterCollegeLocation = LatLng(40.768034137130904, -73.96454910893894);

      // Small Blue Circle for Current Location
      final Circle smallBlueDotCircle = Circle(
        circleId: CircleId("small_user_location"),
        center: hunterCollegeLocation,
        radius: 15, // 🔵 Small circle for precise location
        fillColor: Color.fromARGB(100, 66, 133, 244), // ✅ Semi-transparent blue
        strokeColor: Color.fromARGB(255, 66, 133, 244), // ✅ Strong blue outline
        strokeWidth: 2, // ✅ Thin outline
      );

      // Large Search Area Circle
      final Circle searchRadiusCircle = Circle(
        circleId: CircleId("search_radius"),
        center: hunterCollegeLocation,
        radius: 800, // 🔵 Large search area radius (adjust as needed)
        fillColor: Color.fromARGB(50, 66, 133, 244), // ✅ More transparent blue
        strokeColor: Color.fromARGB(150, 66, 133, 244), // ✅ Semi-bold blue outline
        strokeWidth: 2, // ✅ Thin outline
        consumeTapEvents: false,
      );

      // Add both circles to `_circles`
      setState(() {
        _circles.add(smallBlueDotCircle);
        _circles.add(searchRadiusCircle);
        print("📍 Small blue dot & search radius circle added at $hunterCollegeLocation");
      });
    }

    adjustCameraToMarkers(); // Ensure all markers & circle are visible
  }

  Future<void> adjustCameraToMarkers() async {
    if (_markers.isEmpty) return;

    final GoogleMapController controller = await _mapController.future;
    LatLngBounds bounds = _createBounds(_markers);
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);
    controller.animateCamera(cameraUpdate);
  }

  LatLngBounds _createBounds(Set<Marker> markers) {
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (Marker marker in markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class CafeInfoDialog extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cafe Info'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Cafe Name'),
          ),
          TextField(
            controller: addressController,
            decoration: InputDecoration(labelText: 'Address'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (nameController.text.isNotEmpty &&
                addressController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'name': nameController.text,
                'address': addressController.text,
              });
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
