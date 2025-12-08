// FILE: lib/app/services/supabase_service.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/room_model.dart';
import '../models/tenant_model.dart';
import '../models/bill_model.dart';

/// Supabase service for Kos Bae
/// Handles all database and storage operations
class SupabaseService extends GetxService {
  late final SupabaseClient _client;

  // Getters
  SupabaseClient get client => _client;
  GoTrueClient get auth => _client.auth;

  /// Initialize Supabase service (async version)
  Future<SupabaseService> init() async {
    _client = Supabase.instance.client;
    print('🔌 SupabaseService initialized');
    return this;
  }

  /// Initialize Supabase service (sync version)
  /// Use this when Supabase.initialize() has already been called
  void initSync() {
    _client = Supabase.instance.client;
    print('🔌 SupabaseService initialized (sync)');
  }

  // ==================== ROOMS CRUD ====================

  /// Fetch all rooms with optional filtering and sorting
  Future<List<Room>> fetchRooms({
    String? status,
    String sortBy = 'room_number',
    String? searchQuery,
  }) async {
    try {
      print(
        '🔍 Fetching rooms: status=$status, sortBy=$sortBy, search=$searchQuery',
      );

      // Build filter query
      PostgrestFilterBuilder query = _client.from('rooms').select();

      // Apply status filter
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'room_number.ilike.%$searchQuery%,description.ilike.%$searchQuery%',
        );
      }

      // Apply sorting and execute
      final ascending = sortBy != 'price';
      final response = await query.order(sortBy, ascending: ascending);

      final rooms = (response as List)
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ Fetched ${rooms.length} rooms');
      return rooms;
    } catch (e) {
      print('❌ Error fetching rooms: $e');
      rethrow;
    }
  }

  /// Get single room by ID
  Future<Room?> getRoomById(String roomId) async {
    try {
      final response = await _client
          .from('rooms')
          .select()
          .eq('id', roomId)
          .maybeSingle();

      if (response == null) return null;
      return Room.fromJson(response);
    } catch (e) {
      print('❌ Error getting room: $e');
      rethrow;
    }
  }

  /// Create new room
  Future<Room> createRoom(Room room, {List<XFile>? photos}) async {
    try {
      print('➕ Creating room: ${room.roomNumber}');

      // Upload photos first if provided
      List<String> photoUrls = [];
      if (photos != null && photos.isNotEmpty) {
        photoUrls = await uploadMultipleFiles(photos, folder: 'rooms');
      }

      // Insert room with photo URLs
      final data = room.toJson();
      data['photos'] = photoUrls;
      data['created_by'] = auth.currentUser?.id;

      final response = await _client
          .from('rooms')
          .insert(data)
          .select()
          .single();

      print('✅ Room created successfully');
      return Room.fromJson(response);
    } catch (e) {
      print('❌ Error creating room: $e');
      rethrow;
    }
  }

  /// Update existing room
  Future<Room> updateRoom(
    Room room, {
    List<XFile>? newPhotos,
    List<String>? removedPhotoUrls,
  }) async {
    try {
      print('✏️ Updating room: ${room.roomNumber}');

      // Delete removed photos from storage
      if (removedPhotoUrls != null && removedPhotoUrls.isNotEmpty) {
        await deleteMultipleFiles(removedPhotoUrls);
      }

      // Upload new photos
      List<String> newPhotoUrls = [];
      if (newPhotos != null && newPhotos.isNotEmpty) {
        newPhotoUrls = await uploadMultipleFiles(newPhotos, folder: 'rooms');
      }

      // Combine existing photos (minus removed) with new photos
      final existingPhotos = room.photos
          .where((url) => !(removedPhotoUrls?.contains(url) ?? false))
          .toList();
      final allPhotos = [...existingPhotos, ...newPhotoUrls];

      final data = room.toJson();
      data['photos'] = allPhotos;

      final response = await _client
          .from('rooms')
          .update(data)
          .eq('id', room.id)
          .select()
          .single();

      print('✅ Room updated successfully');
      return Room.fromJson(response);
    } catch (e) {
      print('❌ Error updating room: $e');
      rethrow;
    }
  }

  /// Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      print('🗑️ Deleting room: $roomId');

      // Get room first to delete its photos
      final room = await getRoomById(roomId);
      if (room != null && room.photos.isNotEmpty) {
        await deleteMultipleFiles(room.photos);
      }

      // Delete room record
      await _client.from('rooms').delete().eq('id', roomId);

      print('✅ Room deleted successfully');
    } catch (e) {
      print('❌ Error deleting room: $e');
      rethrow;
    }
  }

  /// Get room statistics
  Future<Map<String, int>> getRoomStatistics() async {
    try {
      final rooms = await fetchRooms();

      return {
        'total': rooms.length,
        'empty': rooms.where((r) => r.status == 'kosong').length,
        'occupied': rooms.where((r) => r.status == 'terisi').length,
        'maintenance': rooms.where((r) => r.status == 'maintenance').length,
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      rethrow;
    }
  }

  // ==================== ROOM HISTORY ====================

  /// Fetch room history (past tenants)
  Future<List<Map<String, dynamic>>> fetchRoomHistory(String roomId) async {
    try {
      print('📜 Fetching history for room: $roomId');

      final response = await _client
          .from('room_history')
          .select('*, profiles!room_history_tenant_id_fkey(full_name, phone)')
          .eq('room_id', roomId)
          .order('contract_start', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching room history: $e');
      return [];
    }
  }

  // ==================== COMPLAINTS ====================

  /// Fetch complaints by room
  Future<List<Map<String, dynamic>>> fetchComplaintsByRoom(
    String roomId,
  ) async {
    try {
      print('📋 Fetching complaints for room: $roomId');

      final response = await _client
          .from('complaints')
          .select('*, profiles!complaints_tenant_id_fkey(full_name)')
          .eq('room_id', roomId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching complaints: $e');
      return [];
    }
  }

  // ==================== STORAGE ====================

  /// Upload single file to Supabase Storage
  Future<String> uploadFile(XFile file, {String folder = 'rooms'}) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = '$folder/$fileName';

      print('📤 Uploading file: $filePath');

      final bytes = await file.readAsBytes();

      await _client.storage
          .from('kos-bae-storage')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: file.mimeType ?? 'image/jpeg',
            ),
          );

      final publicUrl = _client.storage
          .from('kos-bae-storage')
          .getPublicUrl(filePath);

      print('✅ File uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload multiple files
  Future<List<String>> uploadMultipleFiles(
    List<XFile> files, {
    String folder = 'rooms',
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadFile(file, folder: folder);
      urls.add(url);
    }
    return urls;
  }

  /// Delete file from Supabase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      final bucketIndex = pathSegments.indexOf('kos-bae-storage');
      if (bucketIndex == -1) return;

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      print('🗑️ Deleting file: $filePath');

      await _client.storage.from('kos-bae-storage').remove([filePath]);

      print('✅ File deleted');
    } catch (e) {
      print('❌ Error deleting file: $e');
    }
  }

  /// Delete multiple files
  Future<void> deleteMultipleFiles(List<String> fileUrls) async {
    for (final url in fileUrls) {
      await deleteFile(url);
    }
  }

  // ==================== TENANTS CRUD ====================

  /// Fetch all tenants with optional filtering and sorting
  Future<List<Tenant>> fetchTenants({
    String? status,
    String sortBy = 'name',
    String? searchQuery,
  }) async {
    try {
      print(
        '🔍 Fetching tenants: status=$status, sortBy=$sortBy, search=$searchQuery',
      );

      // First, check raw data count for debugging
      try {
        final countResponse = await _client.from('tenants').select('id');
        print(
          '📊 Total rows in tenants table: ${(countResponse as List).length}',
        );
      } catch (countError) {
        print('⚠️ Error checking tenants table: $countError');
        print(
          '💡 Make sure tenants table exists in Supabase. Run the SQL schema first.',
        );
      }

      // Build filter query with contracts and rooms join
      PostgrestFilterBuilder query = _client
          .from('tenants')
          .select('*, contracts!tenants_contract_id_fkey(id, room_id, start_date, end_date, rooms!contracts_room_id_fkey(room_number))');

      // Apply status filter
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      //Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%,nik.ilike.%$searchQuery%',
        );
      }

      // Apply sorting and execute
      final ascending = sortBy != 'created_at';
      final response = await query.order(sortBy, ascending: ascending);
      print('📋 Raw response: $response');

      final tenants = (response as List)
          .map((json) => Tenant.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ Fetched ${tenants.length} tenants');
      return tenants;
    } catch (e) {
      print('❌ Error fetching tenants: $e');
      rethrow;
    }
  }

  /// Get single tenant by ID
  Future<Tenant?> getTenantById(String tenantId) async {
    try {
      print('🔍 Fetching tenant by ID: $tenantId');

      final response = await _client
          .from('tenants')
          .select('*, contracts!tenants_contract_id_fkey(id, room_id, start_date, end_date, rooms!contracts_room_id_fkey(room_number))')
          .eq('id', tenantId)
          .maybeSingle();

      if (response == null) return null;
      return Tenant.fromJson(response);
    } catch (e) {
      print('❌ Error fetching tenant: $e');
      rethrow;
    }
  }

  /// Create new tenant
  Future<Tenant> createTenant(Tenant tenant, {XFile? photo}) async {
    try {
      print('➕ Creating tenant: ${tenant.name}');

      // Upload photo first if provided
      String? photoUrl;
      if (photo != null) {
        photoUrl = await uploadFile(photo, folder: 'tenants');
      }

      // Insert tenant with photo URL
      final data = tenant.toJson();
      
      // Remove ID if it's empty (let Supabase generate it)
      if (data['id'] == '') {
        data.remove('id');
      }

      if (photoUrl != null) {
        data['photo_url'] = photoUrl;
      }
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('tenants')
          .insert(data)
          .select('*, contracts!tenants_contract_id_fkey(id, room_id, start_date, end_date, rooms!contracts_room_id_fkey(room_number))')
          .single();

      // Update room status if tenant has a contract
      if (tenant.contractId != null && tenant.status == TenantStatus.active) {
        // Get the contract to find the room
        final contract = await _client
            .from('contracts')
            .select('room_id')
            .eq('id', tenant.contractId!)
            .single();
        
        if (contract['room_id'] != null) {
          await _client
              .from('rooms')
              .update({'status': 'terisi', 'current_tenant_name': tenant.name})
              .eq('id', contract['room_id']);
        }
      }

      print('✅ Tenant created successfully');
      return Tenant.fromJson(response);
    } catch (e) {
      print('❌ Error creating tenant: $e');
      rethrow;
    }
  }

  /// Update existing tenant
  Future<Tenant> updateTenant(
    Tenant tenant, {
    XFile? newPhoto,
    bool removePhoto = false,
  }) async {
    try {
      print('✏️ Updating tenant: ${tenant.name}');

      // Get existing tenant to check contract changes
      final existingTenant = await getTenantById(tenant.id);

      // Handle photo changes
      String? photoUrl = tenant.photoUrl;
      if (removePhoto && photoUrl != null) {
        await deleteFile(photoUrl);
        photoUrl = null;
      } else if (newPhoto != null) {
        if (photoUrl != null) {
          await deleteFile(photoUrl);
        }
        photoUrl = await uploadFile(newPhoto, folder: 'tenants');
      }

      final data = tenant.toJson();
      data['photo_url'] = photoUrl;
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('tenants')
          .update(data)
          .eq('id', tenant.id)
          .select('*, contracts!tenants_contract_id_fkey(id, room_id, start_date, end_date, rooms!contracts_room_id_fkey(room_number))')
          .single();

      // Handle room status updates based on contract changes
      if (existingTenant != null) {
        // Get old room from old contract if exists
        if (existingTenant.contractId != null && 
            (existingTenant.contractId != tenant.contractId ||
                tenant.status == TenantStatus.left)) {
          final oldContract = await _client
              .from('contracts')
              .select('room_id')
              .eq('id', existingTenant.contractId!)
              .single();
          
          if (oldContract['room_id'] != null) {
            await _client
                .from('rooms')
                .update({'status': 'kosong', 'current_tenant_name': null})
                .eq('id', oldContract['room_id']);
          }
        }

        // Update new room if there's a new contract and tenant is active
        if (tenant.contractId != null && tenant.status == TenantStatus.active) {
          final newContract = await _client
              .from('contracts')
              .select('room_id')
              .eq('id', tenant.contractId!)
              .single();
              
          if (newContract['room_id'] != null) {
            await _client
                .from('rooms')
                .update({'status': 'terisi', 'current_tenant_name': tenant.name})
                .eq('id', newContract['room_id']);
          }
        }
      }

      print('✅ Tenant updated successfully');
      return Tenant.fromJson(response);
    } catch (e) {
      print('❌ Error updating tenant: $e');
      rethrow;
    }
  }

  /// Delete tenant
  Future<void> deleteTenant(String tenantId) async {
    try {
      print('🗑️ Deleting tenant: $tenantId');

      final tenant = await getTenantById(tenantId);
      if (tenant != null) {
        // Delete photo if exists
        if (tenant.photoUrl != null) {
          await deleteFile(tenant.photoUrl!);
        }
        
        // Update room status if tenant had a contract
        if (tenant.contractId != null && tenant.status == TenantStatus.active) {
          final contract = await _client
              .from('contracts')
              .select('room_id')
              .eq('id', tenant.contractId!)
              .single();
              
          if (contract['room_id'] != null) {
            await _client
                .from('rooms')
                .update({'status': 'kosong', 'current_tenant_name': null})
                .eq('id', contract['room_id']);
          }
        }
      }

      await _client.from('tenants').delete().eq('id', tenantId);

      print('✅ Tenant deleted successfully');
    } catch (e) {
      print('❌ Error deleting tenant: $e');
      rethrow;
    }
  }

  /// Get tenant statistics
  Future<Map<String, int>> getTenantStatistics() async {
    try {
      final tenants = await fetchTenants();

      return {
        'total': tenants.length,
        'active': tenants.where((t) => t.status == 'aktif').length,
        'inactive': tenants.where((t) => t.status == 'nonaktif').length,
        'left': tenants.where((t) => t.status == 'keluar').length,
      };
    } catch (e) {
      print('❌ Error getting tenant statistics: $e');
      rethrow;
    }
  }

  /// Get available rooms (empty rooms)
  Future<List<Room>> getAvailableRooms() async {
    try {
      final response = await _client
          .from('rooms')
          .select()
          .eq('status', 'kosong')
          .order('room_number', ascending: true);

      return (response as List)
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting available rooms: $e');
      rethrow;
    }
  }

  // ==================== BILLS CRUD ====================

  /// Fetch all bills with optional filtering
  Future<List<Bill>> fetchBills({
    String? status,
    String? type,
    DateTime? month,
    String? searchQuery,
  }) async {
    try {
      print('🔍 Fetching bills: status=$status, type=$type, month=$month');

      // Build query with joins
      PostgrestFilterBuilder query = _client
          .from('bills')
          .select('*, tenants(name), rooms(room_number), payments(*)');

      // Apply status filter
      if (status != null) {
        query = query.eq('status', status);
      }

      // Apply type filter
      if (type != null) {
        query = query.eq('type', type);
      }

      // Apply month filter
      if (month != null) {
        final startOfMonth = DateTime(month.year, month.month, 1);
        final endOfMonth = DateTime(month.year, month.month + 1, 0);
        query = query
            .gte(
              'billing_period_start',
              startOfMonth.toIso8601String().split('T').first,
            )
            .lte(
              'billing_period_start',
              endOfMonth.toIso8601String().split('T').first,
            );
      }

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search in tenant name is handled after fetch
      }

      final response = await query.order('due_date', ascending: true);

      var bills = (response as List)
          .map((json) => Bill.fromJson(json as Map<String, dynamic>))
          .toList();

      // Apply search filter locally
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        bills = bills
            .where(
              (b) =>
                  (b.tenantName?.toLowerCase().contains(q) ?? false) ||
                  (b.roomNumber?.toLowerCase().contains(q) ?? false),
            )
            .toList();
      }

      print('✅ Fetched ${bills.length} bills');
      return bills;
    } catch (e) {
      print('❌ Error fetching bills: $e');
      rethrow;
    }
  }

  /// Get single bill by ID
  Future<Bill?> getBillById(String billId) async {
    try {
      final response = await _client
          .from('bills')
          .select('*, tenants(name), rooms(room_number), payments(*)')
          .eq('id', billId)
          .maybeSingle();

      if (response == null) return null;
      return Bill.fromJson(response);
    } catch (e) {
      print('❌ Error getting bill: $e');
      rethrow;
    }
  }

  /// Create new bill
  Future<Bill> createBill(Bill bill) async {
    try {
      print('➕ Creating bill for tenant: ${bill.tenantId}');

      final data = bill.toJson();
      data['created_at'] = DateTime.now().toIso8601String();
      data['created_by'] = auth.currentUser?.id;

      final response = await _client
          .from('bills')
          .insert(data)
          .select('*, tenants(name), rooms(room_number), payments(*)')
          .single();

      print('✅ Bill created successfully');
      return Bill.fromJson(response);
    } catch (e) {
      print('❌ Error creating bill: $e');
      rethrow;
    }
  }

  /// Update existing bill
  Future<Bill> updateBill(Bill bill) async {
    try {
      print('✏️ Updating bill: ${bill.id}');

      final data = bill.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('bills')
          .update(data)
          .eq('id', bill.id)
          .select('*, tenants(name), rooms(room_number), payments(*)')
          .single();

      print('✅ Bill updated successfully');
      return Bill.fromJson(response);
    } catch (e) {
      print('❌ Error updating bill: $e');
      rethrow;
    }
  }

  /// Update bill status
  Future<void> updateBillStatus(String billId, String status) async {
    try {
      await _client
          .from('bills')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', billId);
      print('✅ Bill status updated to $status');
    } catch (e) {
      print('❌ Error updating bill status: $e');
      rethrow;
    }
  }

  /// Update bill admin notes
  Future<void> updateBillAdminNotes(String billId, String notes) async {
    try {
      await _client
          .from('bills')
          .update({
            'admin_notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', billId);
      print('✅ Bill admin notes updated');
    } catch (e) {
      print('❌ Error updating admin notes: $e');
      rethrow;
    }
  }

  /// Delete bill
  Future<void> deleteBill(String billId) async {
    try {
      print('🗑️ Deleting bill: $billId');

      // Delete related payments first
      await _client.from('payments').delete().eq('bill_id', billId);

      // Delete bill
      await _client.from('bills').delete().eq('id', billId);

      print('✅ Bill deleted successfully');
    } catch (e) {
      print('❌ Error deleting bill: $e');
      rethrow;
    }
  }

  // ==================== PAYMENTS ====================

  /// Add payment to bill
  Future<Payment> addPayment({
    required String billId,
    required double amount,
    required String method,
    String? notes,
    String? proofUrl,
  }) async {
    try {
      print('💰 Adding payment to bill: $billId');

      final data = {
        'bill_id': billId,
        'amount': amount,
        'method': method,
        'status': 'verified', // Admin creates as verified
        'notes': notes,
        'proof_url': proofUrl,
        'payment_date': DateTime.now().toIso8601String().split('T').first,
        'created_at': DateTime.now().toIso8601String(),
        'verified_at': DateTime.now().toIso8601String(),
        'verified_by': auth.currentUser?.id,
      };

      final response = await _client
          .from('payments')
          .insert(data)
          .select()
          .single();

      // Check if bill is fully paid and update status
      await _checkAndUpdateBillStatus(billId);

      print('✅ Payment added successfully');
      return Payment.fromJson(response);
    } catch (e) {
      print('❌ Error adding payment: $e');
      rethrow;
    }
  }

  /// Submit payment from tenant (Pending Verification)
  Future<void> submitTenantPayment({
    required String billId,
    required double amount,
    required String method,
    required XFile proofFile,
    String? notes,
  }) async {
    try {
      print('💰 Submitting payment for bill: $billId');

      // Upload proof
      final proofUrl = await uploadFile(proofFile, folder: 'payments');
      if (proofUrl == null) throw Exception('Gagal mengupload bukti pembayaran');

      final data = {
        'bill_id': billId,
        'amount': amount,
        'method': method,
        'status': 'pending', // Tenant submits as pending
        'notes': notes,
        'proof_url': proofUrl,
        'payment_date': DateTime.now().toIso8601String().split('T').first,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from('payments').insert(data);

      print('✅ Payment submitted successfully');
    } catch (e) {
      print('❌ Error submitting payment: $e');
      rethrow;
    }
  }

  /// Check if bill is fully paid and update status
  Future<void> _checkAndUpdateBillStatus(String billId) async {
    try {
      final bill = await getBillById(billId);
      if (bill == null) return;

      if (bill.isFullyPaid && bill.status != 'paid') {
        await updateBillStatus(billId, 'paid');
      }
    } catch (e) {
      print('⚠️ Error checking bill status: $e');
    }
  }

  /// Verify payment
  Future<void> verifyPayment(String paymentId) async {
    try {
      final response = await _client
          .from('payments')
          .update({
            'status': 'verified',
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': auth.currentUser?.id,
          })
          .eq('id', paymentId)
          .select('bill_id')
          .single();

      // Check and update bill status
      await _checkAndUpdateBillStatus(response['bill_id']);

      print('✅ Payment verified');
    } catch (e) {
      print('❌ Error verifying payment: $e');
      rethrow;
    }
  }

  /// Reject payment
  Future<void> rejectPayment(String paymentId) async {
    try {
      await _client
          .from('payments')
          .update({'status': 'rejected'})
          .eq('id', paymentId);

      print('✅ Payment rejected');
    } catch (e) {
      print('❌ Error rejecting payment: $e');
      rethrow;
    }
  }

  /// Get bill statistics
  Future<Map<String, dynamic>> getBillStatistics({DateTime? month}) async {
    try {
      final bills = await fetchBills(month: month);

      int pending = 0;
      int verified = 0;
      int paid = 0;
      int overdue = 0;
      double totalAmount = 0.0;
      double totalPaid = 0.0;

      for (final bill in bills) {
        totalAmount += bill.amount;

        switch (bill.status) {
          case 'pending':
            pending++;
            break;
          case 'verified':
            verified++;
            break;
          case 'paid':
            paid++;
            totalPaid += bill.amount;
            break;
          case 'overdue':
            overdue++;
            break;
        }
      }

      return {
        'total': bills.length,
        'pending': pending,
        'verified': verified,
        'paid': paid,
        'overdue': overdue,
        'totalAmount': totalAmount,
        'totalPaid': totalPaid,
        'totalPending': totalAmount - totalPaid,
      };
    } catch (e) {
      print('❌ Error getting bill statistics: $e');
      rethrow;
    }
  }
}
