import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';
import 'tenant_complaint_detail_view.dart';

class TenantComplaintsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  final _authService = Get.find<AuthService>();

  final complaints = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final tenantId = await _authService.getCurrentTenantId();
      if (tenantId == null) {
        errorMessage.value = 'Data penghuni tidak ditemukan';
        return;
      }

      final response = await _supabaseService.client
          .from('complaints')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      complaints.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      errorMessage.value = 'Gagal memuat keluhan: $e';
      print('❌ Error fetching complaints: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createComplaint({
    required String title,
    required String description,
    XFile? photo,
  }) async {
    try {
      isSubmitting.value = true;

      final tenantId = await _authService.getCurrentTenantId();
      if (tenantId == null) throw Exception('Tenant ID not found');

      // Get tenant's contract_id
      final tenantData = await _supabaseService.client
          .from('tenants')
          .select('contract_id')
          .eq('id', tenantId)
          .single();
      
      final contractId = tenantData['contract_id'];
      if (contractId == null) throw Exception('Anda belum memiliki kontrak aktif');

      // Get room_id from contract
      final contractData = await _supabaseService.client
          .from('contracts')
          .select('room_id')
          .eq('id', contractId)
          .single();
      
      final roomId = contractData['room_id'];
      if (roomId == null) throw Exception('Data kamar tidak ditemukan dalam kontrak');

      // Upload photo if provided
      List<String> mediaUrls = [];
      if (photo != null) {
        final photoUrl = await _supabaseService.uploadFile(photo, folder: 'complaints');
        if (photoUrl != null) {
          mediaUrls.add(photoUrl);
        }
      }

      // Insert complaint
      await _supabaseService.client.from('complaints').insert({
        'tenant_id': tenantId,
        'room_id': roomId,
        'title': title,
        'description': description,
        'media': mediaUrls, // Store as JSON array
        'status': 'submitted', // submitted, in_progress, resolved
        'created_at': DateTime.now().toIso8601String(),
      });

      await fetchComplaints();
      
      Get.snackbar(
        'Sukses',
        'Keluhan berhasil dikirim',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal mengirim keluhan: $e',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
  void showComplaintDetail(Map<String, dynamic> complaint) {
    Get.to(() => TenantComplaintDetailView(complaint: complaint));
  }
}
