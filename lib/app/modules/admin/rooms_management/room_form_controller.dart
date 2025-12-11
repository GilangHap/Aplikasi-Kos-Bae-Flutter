import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/room_model.dart';
import '../../../services/supabase_service.dart';

/// Controller for Room Form (Add/Edit)
class RoomFormController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final ImagePicker _picker = ImagePicker();

  // Form key
  final formKey = GlobalKey<FormState>();

  // Text controllers
  final roomNumberController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  final RxString selectedStatus = 'kosong'.obs;
  final RxList<String> selectedFacilities = <String>[].obs;
  final RxList<String> existingPhotos = <String>[].obs;
  final RxList<XFile> newPhotos = <XFile>[].obs;
  final RxList<String> removedPhotos = <String>[].obs;

  // Original room for edit mode
  Room? _originalRoom;

  @override
  void onInit() {
    super.onInit();

    // Check if editing existing room
    if (Get.arguments != null && Get.arguments is Room) {
      _originalRoom = Get.arguments as Room;
      _populateForm(_originalRoom!);
      isEditMode.value = true;
    }
  }

  @override
  void onClose() {
    roomNumberController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Populate form with existing room data
  void _populateForm(Room room) {
    roomNumberController.text = room.roomNumber;
    priceController.text = room.price.toInt().toString();
    descriptionController.text = room.description;
    selectedStatus.value = room.status;
    selectedFacilities.value = List.from(room.facilities);
    existingPhotos.value = List.from(room.photos);
  }

  /// Toggle facility selection
  void toggleFacility(String facility) {
    if (selectedFacilities.contains(facility)) {
      selectedFacilities.remove(facility);
    } else {
      selectedFacilities.add(facility);
    }
  }

  /// Pick image from camera or gallery
  Future<void> pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        // Allow multiple images from gallery
        final images = await _picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (images.isNotEmpty) {
          newPhotos.addAll(images);
        }
      } else {
        // Single image from camera
        final image = await _picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (image != null) {
          newPhotos.add(image);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil foto: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  /// Remove existing photo (mark for deletion)
  void removeExistingPhoto(String url) {
    existingPhotos.remove(url);
    removedPhotos.add(url);
  }

  /// Remove new photo from list
  void removeNewPhoto(XFile file) {
    newPhotos.remove(file);
  }

  /// Save room (create or update)
  Future<void> saveRoom() async {
    // Validate form
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Check if at least one photo
    if (existingPhotos.isEmpty && newPhotos.isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Tambahkan minimal 1 foto kamar',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Build room object
      final room = Room(
        id: _originalRoom?.id ?? '',
        roomNumber: roomNumberController.text.trim(),
        price: double.parse(priceController.text),
        status: selectedStatus.value,
        photos: existingPhotos.toList(),
        facilities: selectedFacilities.toList(),
        description: descriptionController.text.trim(),
        createdAt: _originalRoom?.createdAt ?? DateTime.now(),
      );

      Room savedRoom;

      if (isEditMode.value) {
        // Update existing room
        savedRoom = await _supabaseService.updateRoom(
          room,
          newPhotos: newPhotos.isNotEmpty ? newPhotos.toList() : null,
          removedPhotoUrls: removedPhotos.isNotEmpty
              ? removedPhotos.toList()
              : null,
        );

        Get.snackbar(
          'Berhasil',
          'Kamar ${savedRoom.roomNumber} berhasil diperbarui',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
        );
      } else {
        // Create new room
        savedRoom = await _supabaseService.createRoom(
          room,
          photos: newPhotos.isNotEmpty ? newPhotos.toList() : null,
        );

        Get.snackbar(
          'Berhasil',
          'Kamar ${savedRoom.roomNumber} berhasil ditambahkan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
        );
      }

      // Go back and refresh list
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan kamar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
