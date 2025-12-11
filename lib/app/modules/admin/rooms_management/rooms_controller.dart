import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/room_model.dart';
import '../../../services/supabase_service.dart';
import '../../../routes/app_routes.dart';

/// Controller for Rooms Management
class RoomsController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxList<Room> rooms = <Room>[].obs;
  final RxString filterStatus = 'all'.obs;
  final RxString sortBy = 'room_number'.obs;
  final RxString searchQuery = ''.obs;

  // Debounce timer for search
  Timer? _debounce;
  
  // Realtime subscription
  RealtimeChannel? _roomsChannel;

  @override
  void onInit() {
    super.onInit();
    fetchRooms();
    _setupRealtimeSubscription();
    
    // Listen to search query changes with debounce
    debounce(
      searchQuery,
      (_) => fetchRooms(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _roomsChannel?.unsubscribe();
    super.onClose();
  }
  
  /// Setup realtime subscription for rooms table
  void _setupRealtimeSubscription() {
    _roomsChannel = _supabaseService.client
        .channel('rooms_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',
          callback: (payload) {
            print('🔄 Realtime update received: ${payload.eventType}');
            _handleRealtimeUpdate(payload);
          },
        )
        .subscribe();
    
    print('📡 Realtime subscription started for rooms table');
  }
  
  /// Handle realtime updates from Supabase
  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        // Add new room to list
        final newRoom = Room.fromJson(payload.newRecord);
        rooms.add(newRoom);
        _sortRooms();
        break;
        
      case PostgresChangeEvent.update:
        // Update existing room
        final updatedRoom = Room.fromJson(payload.newRecord);
        final index = rooms.indexWhere((r) => r.id == updatedRoom.id);
        if (index != -1) {
          rooms[index] = updatedRoom;
          _sortRooms();
        }
        break;
        
      case PostgresChangeEvent.delete:
        // Remove deleted room
        final deletedId = payload.oldRecord['id'] as String;
        rooms.removeWhere((r) => r.id == deletedId);
        break;
        
      default:
        // Refresh all data for other events
        fetchRooms();
    }
  }
  
  /// Sort rooms based on current sort setting
  void _sortRooms() {
    rooms.sort((a, b) {
      switch (sortBy.value) {
        case 'price':
          return b.price.compareTo(a.price); // descending
        case 'status':
          return a.status.compareTo(b.status);
        case 'room_number':
        default:
          return a.roomNumber.compareTo(b.roomNumber);
      }
    });
  }
  
  /// Show snackbar for realtime updates
  void _showUpdateSnackbar(String message, {bool isNew = false, bool isDelete = false}) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    if (isDelete) {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
      icon = Icons.delete;
    } else if (isNew) {
      bgColor = Colors.blue.shade100;
      textColor = Colors.blue.shade900;
      icon = Icons.add_circle;
    } else {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
      icon = Icons.refresh;
    }
    
    Get.snackbar(
      '🔄 Update Realtime',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: bgColor,
      colorText: textColor,
      icon: Icon(icon, color: textColor),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }

  /// Fetch rooms from Supabase with current filters
  Future<void> fetchRooms() async {
    try {
      isLoading.value = true;

      final fetchedRooms = await _supabaseService.fetchRooms(
        status: filterStatus.value == 'all' ? null : filterStatus.value,
        sortBy: sortBy.value,
        searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      rooms.value = fetchedRooms;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data kamar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Set status filter
  void setFilter(String status) {
    filterStatus.value = status;
    fetchRooms();
  }

  /// Set sort order
  void setSort(String sort) {
    sortBy.value = sort;
    fetchRooms();
  }

  /// Set search query (with debounce)
  void setSearch(String query) {
    searchQuery.value = query;
  }

  /// Delete room with confirmation
  Future<void> deleteRoom(Room room) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Kamar?'),
        content: Text('Apakah Anda yakin ingin menghapus kamar ${room.roomNumber}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      isLoading.value = true;

      await _supabaseService.deleteRoom(room.id);

      Get.snackbar(
        'Berhasil',
        'Kamar ${room.roomNumber} berhasil dihapus',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );

      // Refresh list
      fetchRooms();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus kamar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to add room page
  void openAddRoom() {
    Get.toNamed(AppRoutes.ADMIN_ROOM_ADD);
  }

  /// Navigate to edit room page
  void openEditRoom(Room room) {
    Get.toNamed(
      AppRoutes.ADMIN_ROOM_EDIT,
      arguments: room,
    );
  }

  /// Navigate to room detail page
  void openDetail(Room room) {
    Get.toNamed(
      AppRoutes.ADMIN_ROOM_DETAIL,
      arguments: room,
    );
  }

  /// Refresh rooms
  Future<void> refresh() async {
    await fetchRooms();
  }

  /// Get filtered room count
  int get totalRooms => rooms.length;
  
  int get emptyRooms => rooms.where((r) => r.isEmpty).length;
  
  int get occupiedRooms => rooms.where((r) => r.isOccupied).length;
  
  int get maintenanceRooms => rooms.where((r) => r.isUnderMaintenance).length;
}
