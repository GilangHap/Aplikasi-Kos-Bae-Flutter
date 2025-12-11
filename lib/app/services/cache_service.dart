// FILE: lib/app/services/cache_service.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/logger/app_logger.dart';
import '../models/room_model.dart';
import '../models/tenant_model.dart';

/// Service for local data caching using Hive
/// Enables offline support and faster data loading
class CacheService extends GetxService {
  static const String _roomsBoxName = 'rooms_cache';
  static const String _tenantsBoxName = 'tenants_cache';
  static const String _metaBoxName = 'cache_meta';
  
  /// Cache expiry duration (in hours)
  static const int cacheExpiryHours = 24;
  
  late Box<dynamic> _roomsBox;
  late Box<dynamic> _tenantsBox;
  late Box<dynamic> _metaBox;

  /// Initialize cache service
  Future<CacheService> init() async {
    try {
      await Hive.initFlutter();
      
      _roomsBox = await Hive.openBox(_roomsBoxName);
      _tenantsBox = await Hive.openBox(_tenantsBoxName);
      _metaBox = await Hive.openBox(_metaBoxName);
      
      AppLogger.success('Cache service initialized', tag: 'CacheService');
      return this;
    } catch (e) {
      AppLogger.error('Failed to initialize cache', error: e, tag: 'CacheService');
      rethrow;
    }
  }

  // ==================== ROOMS ====================

  /// Cache rooms data
  void cacheRooms(List<Room> rooms) {
    try {
      final jsonList = rooms.map((r) => r.toJson()).toList();
      _roomsBox.put('data', jsonEncode(jsonList));
      _metaBox.put('rooms_cached_at', DateTime.now().toIso8601String());
      AppLogger.debug('Cached ${rooms.length} rooms', tag: 'CacheService');
    } catch (e) {
      AppLogger.error('Failed to cache rooms', error: e, tag: 'CacheService');
    }
  }

  /// Get cached rooms
  List<Room>? getCachedRooms() {
    try {
      if (!_isRoomsCacheValid()) {
        return null;
      }
      
      final data = _roomsBox.get('data');
      if (data == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(data);
      final rooms = jsonList.map((json) => Room.fromJson(json)).toList();
      AppLogger.debug('Retrieved ${rooms.length} rooms from cache', tag: 'CacheService');
      return rooms;
    } catch (e) {
      AppLogger.error('Failed to get cached rooms', error: e, tag: 'CacheService');
      return null;
    }
  }

  /// Check if rooms cache is valid
  bool _isRoomsCacheValid() {
    final cachedAt = _metaBox.get('rooms_cached_at');
    if (cachedAt == null) return false;
    
    final cachedTime = DateTime.parse(cachedAt);
    final now = DateTime.now();
    return now.difference(cachedTime).inHours < cacheExpiryHours;
  }

  /// Clear rooms cache
  void clearRoomsCache() {
    _roomsBox.clear();
    _metaBox.delete('rooms_cached_at');
    AppLogger.debug('Rooms cache cleared', tag: 'CacheService');
  }

  // ==================== TENANTS ====================

  /// Cache tenants data
  void cacheTenants(List<Tenant> tenants) {
    try {
      final jsonList = tenants.map((t) => t.toJson()).toList();
      _tenantsBox.put('data', jsonEncode(jsonList));
      _metaBox.put('tenants_cached_at', DateTime.now().toIso8601String());
      AppLogger.debug('Cached ${tenants.length} tenants', tag: 'CacheService');
    } catch (e) {
      AppLogger.error('Failed to cache tenants', error: e, tag: 'CacheService');
    }
  }

  /// Get cached tenants
  List<Tenant>? getCachedTenants() {
    try {
      if (!_isTenantsCacheValid()) {
        return null;
      }
      
      final data = _tenantsBox.get('data');
      if (data == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(data);
      final tenants = jsonList.map((json) => Tenant.fromJson(json)).toList();
      AppLogger.debug('Retrieved ${tenants.length} tenants from cache', tag: 'CacheService');
      return tenants;
    } catch (e) {
      AppLogger.error('Failed to get cached tenants', error: e, tag: 'CacheService');
      return null;
    }
  }

  /// Check if tenants cache is valid
  bool _isTenantsCacheValid() {
    final cachedAt = _metaBox.get('tenants_cached_at');
    if (cachedAt == null) return false;
    
    final cachedTime = DateTime.parse(cachedAt);
    final now = DateTime.now();
    return now.difference(cachedTime).inHours < cacheExpiryHours;
  }

  /// Clear tenants cache
  void clearTenantsCache() {
    _tenantsBox.clear();
    _metaBox.delete('tenants_cached_at');
    AppLogger.debug('Tenants cache cleared', tag: 'CacheService');
  }

  // ==================== GENERAL ====================

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _roomsBox.clear();
    await _tenantsBox.clear();
    await _metaBox.clear();
    AppLogger.info('All cache cleared', tag: 'CacheService');
  }

  /// Get cache status information
  Map<String, dynamic> getCacheStatus() {
    return {
      'roomsCachedAt': _metaBox.get('rooms_cached_at'),
      'tenantsCachedAt': _metaBox.get('tenants_cached_at'),
      'isRoomsCacheValid': _isRoomsCacheValid(),
      'isTenantsCacheValid': _isTenantsCacheValid(),
    };
  }
}
