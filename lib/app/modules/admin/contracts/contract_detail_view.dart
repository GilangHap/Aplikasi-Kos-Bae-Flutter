import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/contract_model.dart';
import '../../../theme/app_theme.dart';
import 'contracts_controller.dart';

/// Contract Detail View
class ContractDetailView extends StatefulWidget {
  const ContractDetailView({Key? key}) : super(key: key);

  @override
  State<ContractDetailView> createState() => _ContractDetailViewState();
}

class _ContractDetailViewState extends State<ContractDetailView> {
  Contract? _contract;
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadArguments();
  }

  void _loadArguments() {
    final args = Get.arguments;
    if (args != null && args is Contract) {
      _contract = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_contract == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kontrak')),
        body: const Center(child: Text('Kontrak tidak ditemukan')),
      );
    }

    final contract = _contract!;

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: CustomScrollView(
        slivers: [
          // App Bar
          _buildSliverAppBar(contract),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tenant Info Card
                  _buildTenantInfoCard(contract),
                  const SizedBox(height: 16),

                  // Contract Period Card
                  _buildContractPeriodCard(contract),
                  const SizedBox(height: 16),

                  // Financial Info Card
                  _buildFinancialCard(contract),
                  const SizedBox(height: 16),

                  // Document Card
                  _buildDocumentCard(contract),
                  const SizedBox(height: 16),

                  // Notes Card
                  if (contract.notes != null && contract.notes!.isNotEmpty)
                    _buildNotesCard(contract),

                  // Action Buttons
                  const SizedBox(height: 24),
                  _buildActionButtons(contract),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Contract contract) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
        ),
        onPressed: () => Get.back(result: true),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.pastelBlue.withOpacity(0.3),
                AppTheme.softGreen.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.description,
                size: 48,
                color: AppTheme.pastelBlue.withOpacity(0.7),
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(contract.status),
            ],
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.more_vert, size: 20, color: Colors.black87),
          ),
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(contract);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Hapus Kontrak', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'aktif':
        bgColor = AppTheme.softGreen;
        textColor = Colors.green.shade800;
        label = 'Aktif';
        icon = Icons.check_circle;
        break;
      case 'akan_habis':
        bgColor = AppTheme.warmPeach;
        textColor = Colors.orange.shade800;
        label = 'Akan Habis';
        icon = Icons.warning;
        break;
      case 'berakhir':
        bgColor = AppTheme.softPink;
        textColor = Colors.red.shade700;
        label = 'Berakhir';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantInfoCard(Contract contract) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.pastelBlue.withOpacity(0.2),
            child: Text(
              contract.tenantName?.substring(0, 1).toUpperCase() ?? '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.pastelBlue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.tenantName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.meeting_room, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Kamar ${contract.roomNumber ?? '-'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (contract.tenantPhone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        contract.tenantPhone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractPeriodCard(Contract contract) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.date_range, color: AppTheme.pastelBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Periode Kontrak',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDateBox(
                  'Mulai',
                  contract.formattedStartDate,
                  AppTheme.softGreen,
                  Icons.play_arrow,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: Colors.grey.shade400),
              ),
              Expanded(
                child: _buildDateBox(
                  'Berakhir',
                  contract.formattedEndDate,
                  AppTheme.softPink,
                  Icons.stop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getExpiryColor(contract).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getExpiryIcon(contract),
                  size: 20,
                  color: _getExpiryColor(contract),
                ),
                const SizedBox(width: 8),
                Text(
                  _getExpiryText(contract),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getExpiryColor(contract),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(String label, String date, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(Contract contract) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.payments, color: Colors.green.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Keuangan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFinancialRow('Sewa per Bulan', contract.formattedMonthlyRent),
          const Divider(height: 24),
          _buildFinancialRow('Durasi Kontrak', '${contract.durationMonths} bulan'),
          const Divider(height: 24),
          _buildFinancialRow(
            'Total Nilai Kontrak',
            contract.formattedTotalValue,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 18 : 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(Contract contract) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.picture_as_pdf, color: Colors.red.shade400, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dokumen Kontrak',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (contract.hasDocument) ...[
            InkWell(
              onTap: () => _openDocument(contract.documentUrl!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red.shade400, size: 40),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dokumen Kontrak.pdf',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ketuk untuk membuka',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, color: AppTheme.pastelBlue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _replaceDocument(contract),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Ganti Dokumen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.pastelBlue,
                side: BorderSide(color: AppTheme.pastelBlue),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.file_present, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada dokumen',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _uploadDocument(contract),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Dokumen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pastelBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard(Contract contract) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warmPeach.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.note, color: Colors.orange.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Catatan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contract.notes!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Contract contract) {
    // Only show renew button for active or expiring contracts
    if (contract.status == 'berakhir') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA9C9FF), Color(0xFFB9F3CC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA9C9FF).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showRenewDialog(contract),
        icon: const Icon(Icons.autorenew, color: Colors.white),
        label: const Text(
          'Perpanjang Kontrak',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Color _getExpiryColor(Contract contract) {
    if (contract.status == 'berakhir') return Colors.red.shade400;
    if (contract.daysUntilExpiry <= 30) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  IconData _getExpiryIcon(Contract contract) {
    if (contract.status == 'berakhir') return Icons.event_busy;
    if (contract.daysUntilExpiry <= 30) return Icons.warning_amber;
    return Icons.check_circle;
  }

  String _getExpiryText(Contract contract) {
    if (contract.status == 'berakhir') {
      return 'Kontrak telah berakhir';
    }
    final days = contract.daysUntilExpiry;
    if (days <= 0) return 'Kontrak berakhir hari ini';
    if (days == 1) return 'Kontrak berakhir besok';
    return 'Kontrak berakhir dalam $days hari';
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Error',
        'Tidak dapat membuka dokumen',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
      );
    }
  }

  Future<void> _uploadDocument(Contract contract) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final xFile = XFile(file.path!);

        if (!Get.isRegistered<ContractsController>()) {
          Get.put(ContractsController());
        }
        final controller = Get.find<ContractsController>();

        final success = await controller.updateContractDocument(
          contractId: contract.id,
          newDocument: xFile,
        );

        if (success) {
          Get.back(result: true);
        }
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

  Future<void> _replaceDocument(Contract contract) async {
    await _uploadDocument(contract);
  }

  void _showRenewDialog(Contract contract) {
    DateTime newEndDate = contract.endDate.add(const Duration(days: 365));
    XFile? newDocument;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.autorenew, color: AppTheme.pastelBlue),
                const SizedBox(width: 12),
                const Text('Perpanjang Kontrak'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kontrak akan diperpanjang mulai dari ${DateFormat('dd MMM yyyy', 'id_ID').format(contract.endDate.add(const Duration(days: 1)))}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tanggal Berakhir Baru',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: newEndDate,
                        firstDate: contract.endDate.add(const Duration(days: 30)),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          newEndDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppTheme.pastelBlue),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMMM yyyy', 'id_ID').format(newEndDate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dokumen Baru (Opsional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() {
                          newDocument = XFile(result.files.first.path!);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            newDocument != null ? Icons.picture_as_pdf : Icons.upload_file,
                            color: newDocument != null ? Colors.red.shade400 : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              newDocument?.name ?? 'Upload dokumen PDF',
                              style: TextStyle(
                                color: newDocument != null ? Colors.black87 : Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.softGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tagihan bulanan baru akan otomatis digenerate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Get.back();

                  if (!Get.isRegistered<ContractsController>()) {
                    Get.put(ContractsController());
                  }
                  final controller = Get.find<ContractsController>();

                  final success = await controller.renewContract(
                    oldContract: contract,
                    newEndDate: newEndDate,
                    newDocument: newDocument,
                  );

                  if (success) {
                    Get.back(result: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pastelBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Perpanjang'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Contract contract) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: const Text(
          'Anda yakin ingin menghapus kontrak ini?\n\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              if (!Get.isRegistered<ContractsController>()) {
                Get.put(ContractsController());
              }
              final controller = Get.find<ContractsController>();
              final success = await controller.deleteContract(contract);
              if (success) {
                Get.back(result: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
