// FILE: lib/app/modules/admin/contracts/contract_form_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/tenant_model.dart';
import '../../../models/room_model.dart';
import '../../../theme/app_theme.dart';
import 'contracts_controller.dart';

/// Contract Form View for creating new contracts
class ContractFormView extends StatefulWidget {
  const ContractFormView({Key? key}) : super(key: key);

  @override
  State<ContractFormView> createState() => _ContractFormViewState();
}

class _ContractFormViewState extends State<ContractFormView> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyRentController = TextEditingController();
  final _notesController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Tenant? _selectedTenant;
  Room? _selectedRoom;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  XFile? _document;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ensureController();
  }

  void _ensureController() {
    if (!Get.isRegistered<ContractsController>()) {
      Get.put(ContractsController());
    }
  }

  @override
  void dispose() {
    _monthlyRentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ContractsController>();

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tenant Selection
              _buildSectionLabel('Pilih Penghuni', true),
              const SizedBox(height: 8),
              _buildTenantDropdown(controller),
              const SizedBox(height: 24),

              // Room Selection
              _buildSectionLabel('Pilih Kamar', true),
              const SizedBox(height: 8),
              _buildRoomDropdown(controller),
              const SizedBox(height: 24),

              // Monthly Rent
              _buildSectionLabel('Biaya Sewa per Bulan', true),
              const SizedBox(height: 8),
              _buildMonthlyRentField(),
              const SizedBox(height: 24),

              // Date Range
              _buildSectionLabel('Periode Kontrak', true),
              const SizedBox(height: 8),
              _buildDateRangePicker(),
              const SizedBox(height: 24),

              // Contract Duration Info
              _buildDurationInfo(),
              const SizedBox(height: 24),

              // Document Upload
              _buildSectionLabel('Dokumen Kontrak (PDF)', false),
              const SizedBox(height: 8),
              _buildDocumentPicker(),
              const SizedBox(height: 24),

              // Notes
              _buildSectionLabel('Catatan (Opsional)', false),
              const SizedBox(height: 8),
              _buildNotesField(),
              const SizedBox(height: 32),

              // Info box about bill generation
              _buildInfoBox(),
              const SizedBox(height: 24),

              // Submit button
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
        ),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        'Buat Kontrak Baru',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSectionLabel(String label, bool required) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTenantDropdown(ContractsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final tenants = controller.tenants.toList();
        return DropdownButtonFormField<Tenant>(
          value: _selectedTenant,
          decoration: InputDecoration(
            hintText: 'Pilih penghuni',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: Icon(Icons.person, color: AppTheme.pastelBlue),
          ),
          items: tenants.map((tenant) {
            return DropdownMenuItem<Tenant>(
              value: tenant,
              child: Text('${tenant.name} - ${tenant.phone}'),
            );
          }).toList(),
          onChanged: (tenant) {
            setState(() {
              _selectedTenant = tenant;
            });
          },
          validator: (value) {
            if (value == null) return 'Pilih penghuni';
            return null;
          },
        );
      }),
    );
  }

  Widget _buildRoomDropdown(ContractsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final rooms = controller.rooms.toList();
        return DropdownButtonFormField<Room>(
          value: _selectedRoom,
          decoration: InputDecoration(
            hintText: 'Pilih kamar',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: Icon(Icons.meeting_room, color: AppTheme.pastelBlue),
          ),
          items: rooms.map((room) {
            return DropdownMenuItem<Room>(
              value: room,
              child: Text(
                'Kamar ${room.roomNumber} - ${_currencyFormat.format(room.price)}',
              ),
            );
          }).toList(),
          onChanged: (room) {
            setState(() {
              _selectedRoom = room;
              if (room != null) {
                _monthlyRentController.text = room.price.toStringAsFixed(0);
              }
            });
          },
          validator: (value) {
            if (value == null) return 'Pilih kamar';
            return null;
          },
        );
      }),
    );
  }

  Widget _buildMonthlyRentField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _monthlyRentController,
        keyboardType: TextInputType.number,
        readOnly: true, // Make it read-only, auto-filled from room price
        decoration: InputDecoration(
          hintText: 'Pilih kamar untuk mengisi harga',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50, // Slight gray to indicate read-only
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(Icons.payments, color: AppTheme.pastelBlue),
          prefixText: 'Rp ',
          suffixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade400,
            size: 18,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Pilih kamar terlebih dahulu';
          }
          final amount = double.tryParse(
            value.replaceAll(RegExp(r'[^0-9]'), ''),
          );
          if (amount == null || amount <= 0) {
            return 'Harga sewa tidak valid';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Start Date
          InkWell(
            onTap: () => _selectDate(isStart: true),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.softGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Mulai',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMMM yyyy', 'id_ID').format(_startDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // End Date
          InkWell(
            onTap: () => _selectDate(isStart: false),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.softPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Berakhir',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMMM yyyy', 'id_ID').format(_endDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInfo() {
    final months = ((_endDate.difference(_startDate).inDays) / 30).round();
    final monthlyRent =
        double.tryParse(
          _monthlyRentController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final totalValue = monthlyRent * months;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pastelBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.pastelBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: AppTheme.pastelBlue,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  '$months bulan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Durasi Kontrak',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppTheme.pastelBlue.withOpacity(0.3),
          ),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.receipt_long, color: AppTheme.pastelBlue, size: 28),
                const SizedBox(height: 8),
                Text(
                  '$months tagihan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Akan Digenerate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppTheme.pastelBlue.withOpacity(0.3),
          ),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.payments, color: AppTheme.pastelBlue, size: 28),
                const SizedBox(height: 8),
                Text(
                  _currencyFormat.format(totalValue),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Total Nilai',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _pickDocument,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.pastelBlue.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.pastelBlue.withOpacity(0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, color: AppTheme.pastelBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Upload Dokumen PDF',
                    style: TextStyle(
                      color: AppTheme.pastelBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_document != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red.shade400,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _document!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Siap diupload',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade400),
                    onPressed: () {
                      setState(() {
                        _document = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Tambahkan catatan...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softGreen.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.green.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Info Pembuatan Kontrak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Hanya kamar kosong yang ditampilkan\n• Harga sewa otomatis diambil dari data kamar\n• Tagihan bulanan akan otomatis dibuat untuk seluruh periode kontrak\n• Status kamar akan berubah menjadi "Terisi"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _isLoading
            ? null
            : const LinearGradient(
                colors: [Color(0xFFA9C9FF), Color(0xFFB9F3CC)],
              ),
        color: _isLoading ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFA9C9FF).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Buat Kontrak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime(2020) : _startDate;
    final lastDate = DateTime(2030);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Adjust end date if needed
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 365));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _document = XFile(file.path!);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memilih file: $e',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = Get.find<ContractsController>();
      final monthlyRent = double.parse(
        _monthlyRentController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      final success = await controller.createContract(
        tenantId: _selectedTenant!.id,
        roomId: _selectedRoom!.id,
        monthlyRent: monthlyRent,
        startDate: _startDate,
        endDate: _endDate,
        document: _document,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (success) {
        Get.back(result: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
