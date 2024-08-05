import 'dart:async';
import 'package:flutter/cupertino.dart';
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

  void _loadData() async {
    try {
      final position = await _getUserCurrentLocation();
      _addMarker(position);
      _animateCamera(position);
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<Position> _getUserCurrentLocation() async {
    await Geolocator.requestPermission();
    return await Geolocator.getCurrentPosition();
  }

  void _addMarker(Position position) {
    final marker = Marker(
      markerId: MarkerId('1'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(title: _address),
    );
    setState(() {
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
      final placemark = placemarks[0];
      return '${placemark.name}, ${placemark.locality}';
    } catch (e) {
      print('Error getting address: $e');
      return '';
    }
  }

  void _selectLocation(LatLng location) {
    Navigator.pop(context, location);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadData();
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
                markers: Set<Marker>.of(_markers),
                compassEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  _gcontroller.complete(controller);
                },
                onTap: (LatLng latLng) {
                  print('Tapped at ${latLng.latitude}, ${latLng.longitude}');
                  _getAddressFromLatLng(latLng.latitude, latLng.longitude).then((address){
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
                  });
                },
            ),
            Positioned(
              bottom: 100.0,
              right: 20.0,
              child: FloatingActionButton(
                onPressed: () async {
                  _getUserCurrentLocation().then((value) async {
                    _getAddressFromLatLng(value.latitude, value.longitude).then((address){
                      setState(() {
                        _address = address; // Update _address here
                        _markers.clear();
                        _markers.add(
                          Marker(
                            markerId: MarkerId('1'),
                            position: LatLng(value.latitude, value.longitude),
                            infoWindow: InfoWindow(
                              title: _address,
                            ),
                          ),
                        );
                      });
                    });
                    CameraPosition cameraPosition = CameraPosition(
                      target: LatLng(value.latitude, value.longitude),
                      zoom: 18,
                    );

                    final GoogleMapController controller = await _gcontroller
                        .future;

                    controller.animateCamera(
                        CameraUpdate.newCameraPosition(cameraPosition));
                    // setState(() {
                    //   _getAddressFromLatLng(value.latitude, value.longitude);
                    // });
                  });
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
                  if (_address.isNotEmpty) {
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