

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:simple_platform_view_example/screen/expensive_widget.dart';
import 'package:simple_platform_view_example/android/clone_google_maps_flutter_android.dart';
import 'package:simple_platform_view_example/screen/select_screen.dart';

class CloneGoogleMapScreen extends StatefulWidget {
  const CloneGoogleMapScreen({Key? key, this.useOriginalMap = false, required this.title}) : super(key: key);

  final bool useOriginalMap;
  final String title;

  @override
  State<CloneGoogleMapScreen> createState() => _CloneGoogleMapScreenState();
}

class _CloneGoogleMapScreenState extends State<CloneGoogleMapScreen> {

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    /// Replace GoogleMapsFlutterPlatform.instance with the modified version
    if (Platform.isAndroid) {
      if (widget.useOriginalMap) {
        if (defaultMapInstance != null) {
          GoogleMapsFlutterPlatform.instance = defaultMapInstance!;
        }
      } else {
        CloneGoogleMapsFlutterAndroid.registerWith();
      }
    }
  }

  GoogleMapController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: GoogleMap(
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                print("onMapCreated mapId: ${controller.mapId}");
                this.controller = controller;
              }
            ),
          ),
          const ExpensiveWidget(),
          Center(
            child: FloatingActionButton(
              heroTag: "test",
              onPressed: () {
                controller?.moveCamera(CameraUpdate.newLatLng(const LatLng(12.263059, 109.187472)));
              },
              child: const Icon(Icons.abc),
            ),
          ),
        ],
      ),
    );
  }
}
