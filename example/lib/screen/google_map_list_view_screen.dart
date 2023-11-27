import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:simple_platform_view_example/android/clone_google_maps_flutter_android.dart';
import 'package:simple_platform_view_example/screen/select_screen.dart';

class GoogleMapListViewScreen extends StatefulWidget {
  const GoogleMapListViewScreen({super.key});

  @override
  State<GoogleMapListViewScreen> createState() => _GoogleMapListViewScreenState();
}

class _GoogleMapListViewScreenState extends State<GoogleMapListViewScreen> {

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    CloneGoogleMapsFlutterAndroid.useVirtualDisplay = false;
    if (Platform.isAndroid) {
      CloneGoogleMapsFlutterAndroid.registerWith();
    } else if (Platform.isIOS) {
      // CloneGoogleMapsFlutterIOS.registerWith();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
      ),
      body: CustomScrollView(
        slivers: [SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 15) {
                return SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: GoogleMap(
                      initialCameraPosition: _kGooglePlex,
                      onMapCreated: (GoogleMapController controller) {
                        print("onMapCreated mapId: ${controller.mapId}");
                      }
                  ),
                );
              }
              return const SizedBox(
                  height: 100,
                  child: Placeholder());
            },
          childCount: 120,
        ))],
      ),
    );
  }
}
