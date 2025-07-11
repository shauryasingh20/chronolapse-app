import 'package:flutter/material.dart';
import 'package:google_static_maps_controller/google_static_maps_controller.dart';

class StaticMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final double width;
  final double height;

  const StaticMap({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.zoom = 15,
    this.width = double.infinity,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = width == double.infinity ? constraints.maxWidth : width;
        final mapHeight = height;
        
    final controller = StaticMapController(
          width: mapWidth.toInt(),
          height: mapHeight.toInt(),
      zoom: zoom.toInt(),
      center: Location(latitude, longitude),
      markers: [
        Marker(
          color: Colors.red,
          locations: [Location(latitude, longitude)],
        ),
      ],
      googleApiKey: "YOUR-API-KEY", // Your Google Maps API key
    );

    return Container(
          width: mapWidth,
          height: mapHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        controller.url.toString(),
            width: mapWidth,
            height: mapHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.map_outlined, size: 48, color: Colors.grey),
          );
        },
      ),
        );
      },
    );
  }
} 