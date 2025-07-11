import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/memory_bloc.dart';
import '../widgets/memory_card.dart';
import 'memory_detail_screen.dart';
import 'memories_screen.dart';
import 'photo_view_screen.dart';
import '../models/memory.dart';
import '../data/demo_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'ChronoLapse',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<MemoryBloc, MemoryState>(
        builder: (context, state) {
          if (state is MemoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MemoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (state is MemoryLoaded) {
            if (state.memories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No memories yet.\nTap the camera to create one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Smart logic for main card
            final Memory? featuredMemory = _getFeaturedMemory(state.memories);
            final String cardTitle = _getCardTitle(featuredMemory);

            // Get recent memories for horizontal list
            final List<Memory> recentMemories = state.memories
                .take(7)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Featured Memory Card
                  if (featuredMemory != null) ...[
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                                      children: [
                                        // Background Image
                            DEMO_MODE
                                ? Hero(
                                    tag: 'memory_image_${featuredMemory.id}',
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(featuredMemory.imagePath),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  )
                                : FutureBuilder<bool>(
                                    future: File(featuredMemory.imagePath).exists(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data == true) {
                                        return Hero(
                                          tag: 'memory_image_${featuredMemory.id}',
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: FileImage(File(featuredMemory.imagePath)),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                        // Gradient Overlay
                            Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.8),
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ),
                                            ),
                            ),
                            // Content
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        cardTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                                Text(
                                      featuredMemory.note.isNotEmpty 
                                          ? featuredMemory.note 
                                          : 'A special moment captured',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                    const SizedBox(height: 8),
                                                Text(
                                      featuredMemory.formattedDate,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                        fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                            // Tap Gesture
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MemoryDetailScreen(memory: featuredMemory),
                                      ),
                                    );
                                  },
                                  onLongPress: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PhotoViewScreen(memory: featuredMemory),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                            ),
                          ],
                        ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ],
                  
                  // Recently Added Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recently Added',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (state.memories.length > 7)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MemoriesScreen()),
                            );
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Horizontal List of Recent Memories
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentMemories.length,
                      itemBuilder: (context, index) {
                        final memory = recentMemories[index];
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 16),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemoryDetailScreen(memory: memory),
                              ),
                            );
                          },
                              onLongPress: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PhotoViewScreen(memory: memory),
                                  ),
                        );
                      },
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: DEMO_MODE
                                        ? Hero(
                                            tag: 'memory_image_${memory.id}',
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                                image: DecorationImage(
                                                  image: AssetImage(memory.imagePath),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          )
                                        : FutureBuilder<bool>(
                                            future: File(memory.imagePath).exists(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return Container(
                                                  decoration: const BoxDecoration(
                                                    borderRadius: BorderRadius.vertical(
                                                      top: Radius.circular(16),
                                                    ),
                                                  ),
                                                  child: const Center(
                                                    child: CircularProgressIndicator(),
                                                  ),
                                                );
                                              }
                                              
                                              if (snapshot.hasData && snapshot.data == true) {
                                                return Hero(
                                                  tag: 'memory_image_${memory.id}',
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: const BorderRadius.vertical(
                                                        top: Radius.circular(16),
                                                      ),
                                                      image: DecorationImage(
                                                        image: FileImage(File(memory.imagePath)),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return Container(
                                                  decoration: const BoxDecoration(
                                                    borderRadius: BorderRadius.vertical(
                                                      top: Radius.circular(16),
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          memory.note.isNotEmpty ? memory.note : 'No note',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          memory.formattedTime,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Memory? _getFeaturedMemory(List<Memory> memories) {
    if (memories.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // First, try to find "On This Day" memory
    for (final memory in memories) {
      final memoryDate = DateTime(
        memory.timestamp.year,
        memory.timestamp.month,
        memory.timestamp.day,
      );
      if (memoryDate == today) {
        return memory;
      }
    }
    
    // If no "On This Day" memory, find a "Forgotten Gem" (older than 3 months)
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    final forgottenGems = memories.where((memory) => 
      memory.timestamp.isBefore(threeMonthsAgo)
    ).toList();
    
    if (forgottenGems.isNotEmpty) {
      // Return a random forgotten gem
      final random = Random();
      return forgottenGems[random.nextInt(forgottenGems.length)];
    }
    
    // If no forgotten gems, return the most recent memory
    return memories.first;
  }

  String _getCardTitle(Memory? memory) {
    if (memory == null) return 'Welcome';
    
    final now = DateTime.now();
    final memoryDate = DateTime(
      memory.timestamp.year,
      memory.timestamp.month,
      memory.timestamp.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    
    if (memoryDate == today) {
      return 'On This Day';
    }
    
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    if (memory.timestamp.isBefore(threeMonthsAgo)) {
      return 'Rediscover This Memory';
    }
    
    return 'Recent Memory';
  }
} 