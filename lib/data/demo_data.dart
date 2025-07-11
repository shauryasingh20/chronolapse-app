import 'dart:math';
import 'package:chronolapse_final/models/memory.dart';

// DEMO MODE flag for global use
const bool DEMO_MODE = false;

// Local LatLng class for demo data
class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

// --- This is our hard-coded source data ---
final List<Map<String, String>> _demoSourceData = [
  {'image': '1.png', 'note': 'Amazing coffee to start the day.'},
  {'image': '2.png', 'note': 'Morning walk through the park.'},
  {'image': '3.png', 'note': 'Finally finished this great book.'},
  {'image': '4.png', 'note': 'Lunch with the team.'},
  {'image': '5.png', 'note': 'Found this hidden little alleyway.'},
  {'image': '6.png', 'note': 'Beautiful sunset from the office.'},
  {'image': '7.png', 'note': 'Caught up on some work emails.'},
  {'image': '8.png', 'note': 'Great dinner at that new restaurant.'},
  {'image': '9.png', 'note': 'Evening stroll with some music.'},
  {'image': '10.png', 'note': 'A quick sketch during my break.'},
  {'image': '11.png', 'note': 'Planning out the week.'},
  {'image': '12.png', 'note': 'That quiet moment before the day begins.'},
];

// --- Central point for generating nearby locations, set to user's home ---
const LatLng _myHomeLocation = LatLng(28.6851402, 77.3127066);

// --- Main function to generate the list of demo memories ---
List<Memory> generateDemoMemories() {
  final List<Memory> demoMemories = [];
  final random = Random();

  for (int i = 0; i < _demoSourceData.length; i++) {
    final data = _demoSourceData[i];
    
    // Create a random date within the last 365 days
    final randomDaysAgo = random.nextInt(365); 
    final randomDateTime = DateTime.now().subtract(Duration(days: randomDaysAgo));
    
    // Create a random distance between 500m (0.5km) and 2000m (2km)
    final radiusInMeters = 500 + random.nextInt(1501); // 500 base + random number up to 1500 = max 2000

    // Get random coordinates based on home location and random radius
    final randomCoords = _getRandomCoordinates(
      _myHomeLocation,
      radiusInMeters,
    );

    // Create the Memory object
    demoMemories.add(
      Memory(
        id: null, // Demo memories have no DB id
        note: data['note']!,
        imagePath: 'assets/demo_images/${data['image']}', // Use ASSET path
        timestamp: randomDateTime,
        latitude: randomCoords.latitude,
        longitude: randomCoords.longitude,
      ),
    );
  }

  return demoMemories;
}

// --- Helper function to calculate random coordinates within a radius ---
LatLng _getRandomCoordinates(LatLng center, int radiusInMeters) {
  final random = Random();

  // Convert radius from meters to degrees
  double radiusInDegrees = radiusInMeters / 111320.0;

  // Get random distance and angle
  double u = random.nextDouble();
  double v = random.nextDouble();
  double w = radiusInDegrees * sqrt(u);
  double t = 2 * pi * v;
  double x = w * cos(t);
  double y = w * sin(t);

  // Adjust the x-coordinate for the shrinking of the east-west distances
  double newX = x / cos(center.latitude * pi / 180);

  double foundLongitude = newX + center.longitude;
  double foundLatitude = y + center.latitude;
  
  return LatLng(foundLatitude, foundLongitude);
} 