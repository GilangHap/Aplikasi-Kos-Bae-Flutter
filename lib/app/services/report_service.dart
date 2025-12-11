// FILE: lib/app/services/report_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import '../models/tenant_model.dart';
import '../models/room_model.dart';
import '../core/logger/app_logger.dart';

/// Service for generating PDF reports
class ReportService {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  
  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  /// Generate bills report PDF
  static Future<Uint8List> generateBillsReport({
    required List<Bill> bills,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? title,
  }) async {
    AppLogger.info('Generating bills report PDF', tag: 'ReportService');
    
    final pdf = pw.Document();
    
    // Calculate totals
    final totalAmount = bills.fold<double>(0, (sum, b) => sum + b.amount);
    final totalPaid = bills.where((b) => b.status == 'paid').fold<double>(0, (sum, b) => sum + b.amount);
    final totalPending = bills.where((b) => b.status != 'paid').fold<double>(0, (sum, b) => sum + b.remainingAmount);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title ?? 'Laporan Tagihan',
          'Periode: ${_dateFormat.format(periodStart)} - ${_dateFormat.format(periodEnd)}',
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Tagihan', _currencyFormat.format(totalAmount)),
                _buildSummaryItem('Sudah Dibayar', _currencyFormat.format(totalPaid)),
                _buildSummaryItem('Belum Dibayar', _currencyFormat.format(totalPending)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Bills Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _buildTableHeader('Penyewa'),
                  _buildTableHeader('Kamar'),
                  _buildTableHeader('Tipe'),
                  _buildTableHeader('Jumlah'),
                  _buildTableHeader('Jatuh Tempo'),
                  _buildTableHeader('Status'),
                ],
              ),
              // Data rows
              ...bills.map((bill) => pw.TableRow(
                children: [
                  _buildTableCell(bill.tenantName ?? '-'),
                  _buildTableCell(bill.roomNumber ?? '-'),
                  _buildTableCell(bill.typeLabel),
                  _buildTableCell(bill.formattedAmount),
                  _buildTableCell(bill.formattedDueDate),
                  _buildTableCell(bill.statusLabel),
                ],
              )),
            ],
          ),
        ],
      ),
    );
    
    AppLogger.success('Bills report generated successfully', tag: 'ReportService');
    return pdf.save();
  }

  /// Generate tenants report PDF
  static Future<Uint8List> generateTenantsReport({
    required List<Tenant> tenants,
    String? title,
  }) async {
    AppLogger.info('Generating tenants report PDF', tag: 'ReportService');
    
    final pdf = pw.Document();
    
    // Group by status
    final active = tenants.where((t) => t.status == 'aktif').length;
    final inactive = tenants.where((t) => t.status == 'nonaktif').length;
    final left = tenants.where((t) => t.status == 'keluar').length;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title ?? 'Daftar Penghuni',
          'Dicetak: ${_dateFormat.format(DateTime.now())}',
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total', '${tenants.length}'),
                _buildSummaryItem('Aktif', '$active'),
                _buildSummaryItem('Nonaktif', '$inactive'),
                _buildSummaryItem('Keluar', '$left'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Tenants Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _buildTableHeader('Nama'),
                  _buildTableHeader('Telepon'),
                  _buildTableHeader('Kamar'),
                  _buildTableHeader('NIK'),
                  _buildTableHeader('Status'),
                ],
              ),
              // Data rows
              ...tenants.map((tenant) => pw.TableRow(
                children: [
                  _buildTableCell(tenant.name),
                  _buildTableCell(tenant.phone),
                  _buildTableCell(tenant.roomNumber ?? '-'),
                  _buildTableCell(tenant.nik ?? '-'),
                  _buildTableCell(tenant.statusLabel),
                ],
              )),
            ],
          ),
        ],
      ),
    );
    
    AppLogger.success('Tenants report generated successfully', tag: 'ReportService');
    return pdf.save();
  }

  /// Generate rooms report PDF
  static Future<Uint8List> generateRoomsReport({
    required List<Room> rooms,
    String? title,
  }) async {
    AppLogger.info('Generating rooms report PDF', tag: 'ReportService');
    
    final pdf = pw.Document();
    
    // Group by status
    final empty = rooms.where((r) => r.status == 'kosong').length;
    final occupied = rooms.where((r) => r.status == 'terisi').length;
    final maintenance = rooms.where((r) => r.status == 'maintenance').length;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title ?? 'Daftar Kamar',
          'Dicetak: ${_dateFormat.format(DateTime.now())}',
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total', '${rooms.length}'),
                _buildSummaryItem('Kosong', '$empty'),
                _buildSummaryItem('Terisi', '$occupied'),
                _buildSummaryItem('Maintenance', '$maintenance'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Rooms Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _buildTableHeader('No. Kamar'),
                  _buildTableHeader('Harga'),
                  _buildTableHeader('Fasilitas'),
                  _buildTableHeader('Penghuni'),
                  _buildTableHeader('Status'),
                ],
              ),
              // Data rows
              ...rooms.map((room) => pw.TableRow(
                children: [
                  _buildTableCell(room.roomNumber),
                  _buildTableCell(room.formattedPrice),
                  _buildTableCell(room.facilities.take(3).join(', ')),
                  _buildTableCell(room.currentTenantName ?? '-'),
                  _buildTableCell(room.statusLabel),
                ],
              )),
            ],
          ),
        ],
      ),
    );
    
    AppLogger.success('Rooms report generated successfully', tag: 'ReportService');
    return pdf.save();
  }

  /// Print report directly
  static Future<bool> printReport(Uint8List pdfBytes, {String? documentName}) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: documentName ?? 'Kos Bae Report',
      );
      return true;
    } catch (e) {
      AppLogger.error('Failed to print report', error: e, tag: 'ReportService');
      return false;
    }
  }

  /// Share report PDF
  static Future<void> shareReport(Uint8List pdfBytes, {String? filename}) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename ?? 'kos_bae_report.pdf',
    );
  }

  // ==================== HELPER WIDGETS ====================

  static pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KOS BAE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.Divider(color: PdfColors.blue800),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
