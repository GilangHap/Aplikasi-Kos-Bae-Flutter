// FILE: lib/app/modules/admin/announcements/announcements_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/announcement_model.dart';
import '../../../models/tenant_model.dart';
import '../../../services/supabase_service.dart';

/// Controller for Announcements Management
class AnnouncementsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

  // Observables
  final announcements = <Announcement>[].obs;
  final filteredAnnouncements = <Announcement>[].obs;
  final tenants = <Tenant>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  // Filters
  final selectedFilter = 'all'.obs; // all, required, optional
  final searchQuery = ''.obs;

  // Search controller
  final searchController = TextEditingController();

  // Realtime subscription
  RealtimeChannel? _announcementsChannel;

  // Statistics
  final statistics = <String, dynamic>{
    'total': 0,
    'required': 0,
    'optional': 0,
    'thisMonth': 0,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements();
    fetchTenants();
    _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    searchController.dispose();
    _announcementsChannel?.unsubscribe();
    super.onClose();
  }

  /// Setup realtime subscription
  void _setupRealtimeSubscription() {
    _announcementsChannel = _supabaseService.client
        .channel('public:announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            print('🔄 Announcements changed: ${payload.eventType}');
            fetchAnnouncements();
          },
        )
        .subscribe();

    print('📡 Realtime subscription active for announcements');
  }

  /// Fetch all announcements
  Future<void> fetchAnnouncements() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📥 Fetching announcements...');

      final response = await _supabaseService.client
          .from('announcements')
          .select('''
            *,
            announcement_reads(
              id,
              announcement_id,
              tenant_id,
              read_at,
              tenants(id, name, photo_url, rooms(room_number))
            )
          ''')
          .order('created_at', ascending: false);

      print('📦 Response: $response');

      final result = (response as List)
          .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ Parsed ${result.length} announcements');

      announcements.value = result;
      _applyFilters();
      _calculateStatistics();
    } catch (e, stackTrace) {
      errorMessage.value = 'Gagal memuat data pengumuman: ${e.toString()}';
      print('❌ Error fetching announcements: $e');
      print('❌ Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch tenants for displaying unread list
  Future<void> fetchTenants() async {
    try {
      final result = await _supabaseService.fetchTenants(status: 'aktif');
      tenants.value = result;
    } catch (e) {
      print('❌ Error fetching tenants: $e');
    }
  }

  /// Calculate statistics
  void _calculateStatistics() {
    final allAnnouncements = announcements.toList();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    int required = 0;
    int optional = 0;
    int thisMonth = 0;

    for (final announcement in allAnnouncements) {
      if (announcement.isRequired) {
        required++;
      } else {
        optional++;
      }

      if (announcement.createdAt.isAfter(startOfMonth)) {
        thisMonth++;
      }
    }

    statistics.value = {
      'total': allAnnouncements.length,
      'required': required,
      'optional': optional,
      'thisMonth': thisMonth,
    };
  }

  /// Apply local filters
  void _applyFilters() {
    var result = announcements.toList();

    // Apply filter
    if (selectedFilter.value == 'required') {
      result = result.where((a) => a.isRequired).toList();
    } else if (selectedFilter.value == 'optional') {
      result = result.where((a) => !a.isRequired).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.content.toLowerCase().contains(q);
      }).toList();
    }

    filteredAnnouncements.value = result;
  }

  /// Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  /// Handle search
  void onSearchChanged(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    selectedFilter.value = 'all';
    clearSearch();
  }

  /// Refresh data
  Future<void> refreshData() async {
    await fetchAnnouncements();
  }

  /// Create new announcement
  Future<bool> createAnnouncement({
    required String title,
    required String content,
    bool isRequired = false,
    List<XFile>? attachments,
  }) async {
    try {
      isSaving.value = true;

      // Upload attachments first
      List<String> attachmentUrls = [];
      if (attachments != null && attachments.isNotEmpty) {
        for (final file in attachments) {
          final url = await _supabaseService.uploadFile(
            file,
            folder: 'announcements',
          );
          attachmentUrls.add(url);
        }
      }

      // Insert announcement
      await _supabaseService.client.from('announcements').insert({
        'title': title,
        'content': content,
        'is_required': isRequired,
        'attachments': attachmentUrls,
        'created_at': DateTime.now().toIso8601String(),
        'created_by': _supabaseService.auth.currentUser?.id,
      });

      await fetchAnnouncements();

      Get.snackbar(
        'Sukses',
        'Pengumuman berhasil dibuat',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal membuat pengumuman: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Update announcement
  Future<bool> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    bool isRequired = false,
    List<String>? existingAttachments,
    List<XFile>? newAttachments,
    List<String>? removedAttachments,
  }) async {
    try {
      isSaving.value = true;

      // Delete removed attachments
      if (removedAttachments != null && removedAttachments.isNotEmpty) {
        for (final url in removedAttachments) {
          await _supabaseService.deleteFile(url);
        }
      }

      // Upload new attachments
      List<String> newUrls = [];
      if (newAttachments != null && newAttachments.isNotEmpty) {
        for (final file in newAttachments) {
          final url = await _supabaseService.uploadFile(
            file,
            folder: 'announcements',
          );
          newUrls.add(url);
        }
      }

      // Combine attachments
      List<String> allAttachments = [];
      if (existingAttachments != null) {
        allAttachments.addAll(
          existingAttachments.where(
            (url) => !(removedAttachments?.contains(url) ?? false),
          ),
        );
      }
      allAttachments.addAll(newUrls);

      // Update announcement
      await _supabaseService.client
          .from('announcements')
          .update({
            'title': title,
            'content': content,
            'is_required': isRequired,
            'attachments': allAttachments,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      await fetchAnnouncements();

      Get.snackbar(
        'Sukses',
        'Pengumuman berhasil diupdate',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal mengupdate pengumuman: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Delete announcement
  Future<bool> deleteAnnouncement(Announcement announcement) async {
    try {
      // Delete attachments first
      if (announcement.hasAttachments) {
        for (final url in announcement.attachments) {
          await _supabaseService.deleteFile(url);
        }
      }

      // Delete read records
      await _supabaseService.client
          .from('announcement_reads')
          .delete()
          .eq('announcement_id', announcement.id);

      // Delete announcement
      await _supabaseService.client
          .from('announcements')
          .delete()
          .eq('id', announcement.id);

      await fetchAnnouncements();

      Get.snackbar(
        'Sukses',
        'Pengumuman berhasil dihapus',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal menghapus pengumuman: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Get announcement by ID
  Announcement? getAnnouncementById(String id) {
    try {
      return announcements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get unread tenants for an announcement
  List<Tenant> getUnreadTenants(Announcement announcement) {
    final readTenantIds = announcement.readBy.map((r) => r.tenantId).toSet();
    return tenants.where((t) => !readTenantIds.contains(t.id)).toList();
  }

  /// Filter options
  List<Map<String, String>> get filterOptions => [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'required', 'label': 'Wajib Dibaca'},
    {'value': 'optional', 'label': 'Opsional'},
  ];
}
