import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  final Completer<GoogleMapController> _gcontroller = Completer();

  static final CameraPosition _googlemap = const CameraPosition(
    target: LatLng(22.29941000, 73.20812000),
    zoom: 12,
  );

  final Set<Marker> _markers = <Marker>{};
  String _address = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final position = await _getUserCurrentLocation();
      final address = await _getAddressFromLatLng(position.latitude, position.longitude);
      setState(() {
        _address = address;
        _addMarker(position, address);
        _animateCamera(position);
      });
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading location data')),
      );
    }
  }

  Future<Position> _getUserCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return Future.error('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  void _addMarker(Position position, String address) {
    final marker = Marker(
      markerId: MarkerId('1'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(title: address),
    );
    setState(() {
      _markers.clear();
      _markers.add(marker);
    });
  }

  void _animateCamera(Position position) async {
    final cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 14,
    );
    final controller = await _gcontroller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final placemark = placemarks.first;
      return '${placemark.name}, ${placemark.locality}';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown address';
    }
  }

  void _selectLocation(LatLng location) {
    Navigator.pop(context, location);
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _googlemap,
              markers: _markers,
              compassEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _gcontroller.complete(controller);
              },
              onTap: (LatLng latLng) async {
                final address = await _getAddressFromLatLng(latLng.latitude, latLng.longitude);
                setState(() {
                  _address = address;
                  _markers.clear();
                  _markers.add(
                    Marker(
                      markerId: MarkerId(_markers.length.toString()),
                      position: latLng,
                      infoWindow: InfoWindow(
                        title: address,
                      ),
                    ),
                  );
                });
              },
            ),
            Positioned(
              bottom: 100.0,
              right: 20.0,
              child: FloatingActionButton(
                onPressed: () async {
                  try {
                    final position = await _getUserCurrentLocation();
                    final address = await _getAddressFromLatLng(position.latitude, position.longitude);
                    setState(() {
                      _address = address;
                      _addMarker(position, address);
                    });
                    final controller = await _gcontroller.future;
                    controller.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(position.latitude, position.longitude),
                        zoom: 18,
                      ),
                    ));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error retrieving location')),
                    );
                  }
                },
                child: Icon(Icons.my_location),
              ),
            ),
            Positioned(
              bottom: 20.0,
              left: 20.0,
              right: 20.0,
              child: ElevatedButton(
                onPressed: () {
                  if (_markers.isNotEmpty) {
                    Navigator.pop(context, _markers.first.position);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a location')),
                    );
                  }
                },
                child: Text('Select Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
