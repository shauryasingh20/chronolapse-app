import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/memory.dart';
import '../services/database_service.dart';
import '../services/geofence_service.dart';
import 'package:flutter/foundation.dart';
import '../data/demo_data.dart';

// Events
abstract class MemoryEvent {}

class LoadMemories extends MemoryEvent {}

class AddMemory extends MemoryEvent {
  final Memory memory;
  AddMemory(this.memory);
}

class UpdateMemory extends MemoryEvent {
  final Memory memory;
  UpdateMemory(this.memory);
}

class DeleteMemory extends MemoryEvent {
  final int id;
  DeleteMemory(this.id);
}

// States
abstract class MemoryState {}

class MemoryInitial extends MemoryState {}

class MemoryLoading extends MemoryState {}

class MemoryLoaded extends MemoryState {
  final List<Memory> memories;
  MemoryLoaded(this.memories);
}

class MemoryError extends MemoryState {
  final String message;
  MemoryError(this.message);
}

// BLoC
class MemoryBloc extends Bloc<MemoryEvent, MemoryState> {
  final DatabaseService _databaseService = DatabaseService();
  final GeofenceService _geofenceService = GeofenceService();

  MemoryBloc() : super(MemoryInitial()) {
    on<LoadMemories>((event, emit) async {
      emit(MemoryLoading());
      try {
        if (DEMO_MODE) {
          // Use demo data
          final memories = generateDemoMemories();
          emit(MemoryLoaded(memories));
        } else {
          final memories = await _databaseService.getMemories();
          emit(MemoryLoaded(memories));
        }
      } catch (e) {
        emit(MemoryError('Failed to load memories: $e'));
      }
    });
    on<AddMemory>(_onAddMemory);
    on<UpdateMemory>(_onUpdateMemory);
    on<DeleteMemory>(_onDeleteMemory);
  }

  Future<void> _onLoadMemories(LoadMemories event, Emitter<MemoryState> emit) async {
    try {
      emit(MemoryLoading());
      final memories = await _databaseService.getMemories();
      emit(MemoryLoaded(memories));
    } catch (e) {
      emit(MemoryError('Failed to load memories: $e'));
    }
  }

  Future<void> _onAddMemory(AddMemory event, Emitter<MemoryState> emit) async {
    try {
      emit(MemoryLoading());
      await _databaseService.insertMemory(event.memory);
      final memories = await _databaseService.getMemories();
      emit(MemoryLoaded(memories));
      
      // Register geofence for the new memory
      try {
        await _geofenceService.onMemoryAdded(event.memory);
      } catch (e) {
        debugPrint('Error registering geofence for new memory: $e');
      }
    } catch (e) {
      emit(MemoryError('Failed to add memory: $e'));
    }
  }

  Future<void> _onUpdateMemory(UpdateMemory event, Emitter<MemoryState> emit) async {
    try {
      emit(MemoryLoading());
      await _databaseService.updateMemoryNote(event.memory.id!, event.memory.note);
      final memories = await _databaseService.getMemories();
      emit(MemoryLoaded(memories));
    } catch (e) {
      emit(MemoryError('Failed to update memory: $e'));
    }
  }

  Future<void> _onDeleteMemory(DeleteMemory event, Emitter<MemoryState> emit) async {
    try {
      debugPrint('DeleteMemory event received for id: \\${event.id}');
      emit(MemoryLoading());
      await _databaseService.deleteMemory(event.id);
      debugPrint('DatabaseService.deleteMemory called for id: \\${event.id}');
      final memories = await _databaseService.getMemories();
      emit(MemoryLoaded(memories));
      
      // Remove geofence for the deleted memory
      try {
        await _geofenceService.onMemoryDeleted(event.id);
      } catch (e) {
        debugPrint('Error removing geofence for deleted memory: $e');
      }
    } catch (e) {
      debugPrint('Error in _onDeleteMemory: \\${e.toString()}');
      emit(MemoryError('Failed to delete memory: $e'));
    }
  }
} 