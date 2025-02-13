import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'home_page.dart' as home;
import 'settings_page.dart';
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
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            initialCameraPosition: CameraPosition(
              target: manhattan,
              zoom: 13,
            ),
            markers: _markers,
          ),
          Positioned(
            bottom: 80,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    if (_currentP != null) {
                      _cameraToPosition(_currentP!);
                    }
                  },
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () async {
                    if (_currentP != null) {
                      final result = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (context) => BathroomInfoDialog(),
                      );
                      if (result != null && result.isNotEmpty) {
                        final marker = Marker(
                          markerId: MarkerId(DateTime.now().toString()),
                          position: _currentP!,
                          infoWindow: InfoWindow(
                            title: result['name'],
                            snippet: result['address'],
                            onTap: () {
                              Navigator.pushNamed(context, '/reviews');
                            },
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        );
                        setState(() {
                          _markers.add(marker);
                        });
                      }
                    }
                  },
                  child: Icon(Icons.add_location),
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
      zoom: 13,
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
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
      }
    });
  }

  Future<void> loadCsvData() async {
    final rawData = await rootBundle.loadString('assets/locations.csv');
    List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);

    for (var row in rows.skip(1)) {
      final LatLng position = LatLng(row[3], row[4]);
      final marker = Marker(
        markerId: MarkerId(row[0].toString()),
        position: position,
        infoWindow: InfoWindow(
          title: row[1],
          snippet: row[2],
        ),
      );
      setState(() {
        _markers.add(marker);
      });
    }
  }
}

class BathroomInfoDialog extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bathroom Info'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Bathroom Name'),
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
