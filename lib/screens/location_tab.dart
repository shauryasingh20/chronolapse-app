import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // TEMPORARILY DISABLED
import '../services/location_service.dart';
import '../blocs/memory_bloc.dart';
import '../models/memory.dart';
import '../widgets/static_map.dart';
import 'memory_detail_screen.dart';
import '../data/demo_data.dart';

class LocationTab extends StatefulWidget {
  const LocationTab({Key? key}) : super(key: key);

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {
  // GoogleMapController? _mapController; // TEMPORARILY DISABLED
  Position? _currentPosition;
  List<Memory> _nearbyMemories = [];
  bool _loading = true;
  String? _error;
  String? _staticMapUrl;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled. Please enable location services.';
          _loading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied.';
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied. Please enable them in settings.';
          _loading = false;
        });
        return;
      }

      // Get current location
      final position = await LocationService().getCurrentLocation();
      if (position == null) {
        setState(() {
          _error = 'Could not get current location. Please try again.';
          _loading = false;
        });
        return;
      }
      
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _loading = false;
      });

      // Load nearby memories and generate static map
      await _loadNearbyMemoriesAndGenerateMap();

    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error initializing location: $e');
      setState(() {
        _error = 'Error initializing location: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadNearbyMemoriesAndGenerateMap() async {
    if (!mounted || _currentPosition == null) return;

    try {
      // Get memories from BLoC
      final bloc = context.read<MemoryBloc>();
      final state = bloc.state;
      
      if (state is MemoryLoaded) {
        final allMemories = state.memories;
        final List<Memory> nearby = [];
      
      // Calculate nearby memories (within 1 km)
      for (final memory in allMemories) {
          try {
        final distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
          memory.latitude,
          memory.longitude,
        );
        if (distance <= 1000) { // 1 km
          nearby.add(memory);
            }
          } catch (e) {
            debugPrint('Error calculating distance for memory ${memory.id}: $e');
        }
      }
      
        if (mounted) {
      // Sort nearby by distance (nearest first)
      nearby.sort((a, b) {
        final da = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude,
          a.longitude,
        );
        final db = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude,
          b.longitude,
        );
        return da.compareTo(db);
      });
      setState(() {
        _nearbyMemories = nearby;
      });
          
          // Generate static map URL
          _generateStaticMapUrl();
        }
      }
    } catch (e) {
      debugPrint('Error loading nearby memories: $e');
    }
  }

  void _generateStaticMapUrl() {
    if (_currentPosition == null) return;

    final baseUrl = "https://maps.googleapis.com/maps/api/staticmap";
    
    // Start building the URL
    final urlBuffer = StringBuffer();
    urlBuffer.write("$baseUrl?");
    urlBuffer.write("center=${_currentPosition!.latitude},${_currentPosition!.longitude}");
    urlBuffer.write("&zoom=14");
    urlBuffer.write("&size=600x300");
    urlBuffer.write("&maptype=roadmap");
    
    // Create markers list for nearby memories
    final List<String> markerList = [];
    
    // Add markers for nearby memories with proper URL encoding
    for (final memory in _nearbyMemories) {
      final markerString = "markers=color:0xD4AF37%7Clabel:M%7C${memory.latitude},${memory.longitude}";
      markerList.add(markerString);
    }
    
    // Add user location marker (blue dot)
    final userMarkerString = "markers=color:blue%7Clabel:U%7C${_currentPosition!.latitude},${_currentPosition!.longitude}";
    markerList.add(userMarkerString);
    
    // Join all markers and append to URL
    if (markerList.isNotEmpty) {
      final allMarkers = markerList.join('&');
      urlBuffer.write("&$allMarkers");
    }

    final apiKey = "YOUR-API-KEY"; // Google Static Maps API key
    urlBuffer.write("&key=$apiKey");

    setState(() {
      _staticMapUrl = urlBuffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
          title: const Text('Location'),
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text('Location'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
              onPressed: _initializeLocation,
          ),
        ],
      ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                  onPressed: _initializeLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Location'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              _initializeLocation();
            },
          ),
        ],
      ),
      body: BlocListener<MemoryBloc, MemoryState>(
        listener: (context, state) {
          // Refresh nearby memories when new memories are added
          if (state is MemoryLoaded && _currentPosition != null) {
            _loadNearbyMemoriesAndGenerateMap();
          }
        },
        child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              // Dynamic Static Map Section
              if (_currentPosition != null) ...[
                        Text(
                  'Your Area',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                    child: _staticMapUrl != null
                        ? Image.network(
                            _staticMapUrl!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.map, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Map unavailable',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                              height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your location',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                        Text(
                      'Memory locations',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                        ),
                        const SizedBox(height: 24),
                      ],

              // Nearby Memories Section
                      Text(
                        'Nearby Memories (within 1 km)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
              
                      if (_nearbyMemories.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                        'No memories found nearby',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                      const SizedBox(height: 8),
                      Text(
                        'Capture memories to see them here!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _nearbyMemories.length,
                          itemBuilder: (context, index) {
                            final memory = _nearbyMemories[index];
                            final distance = Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                              memory.latitude,
                              memory.longitude,
                            );
                    
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: DEMO_MODE
                                        ? Image.asset(
                                            memory.imagePath,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          )
                                        : FutureBuilder<bool>(
                                            future: File(memory.imagePath).exists(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: CircularProgressIndicator(),
                                                  ),
                                                );
                                              }
                                              
                                              if (snapshot.hasData && snapshot.data == true) {
                                                return Image.file(
                                                  File(memory.imagePath),
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                );
                                              } else {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                  ),
                                title: Text(
                                  memory.note.isNotEmpty ? memory.note : 'No note',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(memory.formattedDate),
                                    Text('${distance.toStringAsFixed(0)}m away'),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemoryDetailScreen(memory: memory),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                                                ),
                      ],
                    ),
                  ),
      ),
    );
  }

  @override
  void dispose() {
    // _mapController?.dispose(); // TEMPORARILY DISABLED
    super.dispose();
  }
} 