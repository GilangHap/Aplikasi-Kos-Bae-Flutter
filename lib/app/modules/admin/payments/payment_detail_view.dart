import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/payment_detail_model.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import 'payments_controller.dart';

/// Payment Detail Page - Shows full payment info, proof preview, verification actions
class PaymentDetailView extends StatefulWidget {
  const PaymentDetailView({super.key});

  @override
  State<PaymentDetailView> createState() => _PaymentDetailViewState();
}

class _PaymentDetailViewState extends State<PaymentDetailView> {
  late PaymentDetail payment;
  final _supabase = Get.find<SupabaseService>();
  final RxBool isLoading = false.obs;
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    payment = Get.arguments as PaymentDetail;
  }

  Future<void> _refreshPaymentData() async {
    try {
      isLoading.value = true;
      final response = await _supabase.client
          .from('payments')
          .select('''
            *,
            bills(
              id, amount, type, status, due_date, billing_period_start,
              tenants(id, name, phone, photo_url),
              rooms(id, room_number)
            )
          ''')
          .eq('id', payment.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          payment = PaymentDetail.fromJson(response as Map<String, dynamic>);
        });
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPaymentAmountCard(),
                const SizedBox(height: 20),
                _buildTenantInfoCard(),
                const SizedBox(height: 20),
                _buildBillInfoCard(),
                const SizedBox(height: 20),
                if (payment.hasProof) ...[
                  _buildProofCard(),
                  const SizedBox(height: 20),
                ],
                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  _buildTenantNotesCard(),
                  const SizedBox(height: 20),
                ],
                if (payment.isRejected && payment.rejectionReason != null) ...[
                  _buildRejectionReasonCard(),
                  const SizedBox(height: 20),
                ],
                _buildPaymentDetailsCard(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: payment.isPending ? _buildActionBar() : null,
    );
  }

  Widget _buildSliverAppBar() {
    final statusColors = _getStatusGradient(payment.status);

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: statusColors[0],
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: statusColors,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getStatusIcon(payment.status),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.statusLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              payment.formattedCreatedAt,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'verified':
        return [const Color(0xFF4CAF50), const Color(0xFF81C784)];
      case 'pending':
        return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
      case 'rejected':
        return [const Color(0xFFE91E63), const Color(0xFFF48FB1)];
      default:
        return [const Color(0xFF5B8DB8), const Color(0xFF7BA9CC)];
    }
  }

  Widget _buildPaymentAmountCard() {
    const darkCream = Color(0xFFE8D4BA);
    const primaryBlue = Color(0xFF5B8DB8);
    const charcoal = Color(0xFF2D3436);

    final statusColors = _getStatusGradient(payment.status);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: darkCream.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Nominal Pembayaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: charcoal.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: statusColors).createShader(bounds),
            child: Text(
              payment.formattedAmount,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMethodBadge(),
              const SizedBox(width: 12),
              _buildDateBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge() {
    const cream = Color(0xFFF5E6D3);
    const darkCream = Color(0xFFE8D4BA);
    const charcoal = Color(0xFF2D3436);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cream, darkCream.withOpacity(0.5)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: darkCream),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMethodIcon(payment.method),
            size: 16,
            color: charcoal.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            payment.methodLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge() {
    const cream = Color(0xFFF5E6D3);
    const darkCream = Color(0xFFE8D4BA);
    const charcoal = Color(0xFF2D3436);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cream, darkCream.withOpacity(0.5)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: darkCream),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: charcoal.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            payment.formattedPaymentDate,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantInfoCard() {
    const cream = Color(0xFFF5E6D3);
    const darkCream = Color(0xFFE8D4BA);
    const primaryBlue = Color(0xFF5B8DB8);
    const lightBlue = Color(0xFF7BA9CC);
    const deepBlue = Color(0xFF2C3E50);
    const charcoal = Color(0xFF2D3436);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: darkCream.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tenant Photo with premium styling
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cream, darkCream],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: darkCream),
            ),
            child: payment.tenantPhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: CachedNetworkImage(
                      imageUrl: payment.tenantPhoto!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(
                        Icons.person_rounded,
                        color: primaryBlue,
                        size: 28,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: primaryBlue,
                        size: 28,
                      ),
                    ),
                  )
                : Icon(Icons.person_rounded, color: primaryBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.tenantName ?? 'Unknown',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cream.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.meeting_room_rounded,
                        size: 14,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kamar ${payment.roomNumber ?? '-'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: deepBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (payment.tenantPhone != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 14,
                        color: charcoal.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        payment.tenantPhone!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: charcoal.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryBlue, lightBlue]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (payment.tenantId != null) {
                    Get.toNamed(
                      AppRoutes.ADMIN_TENANT_DETAIL,
                      arguments: {'tenantId': payment.tenantId},
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillInfoCard() {
    const darkCream = Color(0xFFE8D4BA);
    const primaryBlue = Color(0xFF5B8DB8);
    const charcoal = Color(0xFF2D3436);
    const gold = Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: darkCream.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gold.withOpacity(0.2), gold.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.receipt_long_rounded, color: gold, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                'Informasi Tagihan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Jenis Tagihan', payment.billTypeLabel),
          if (payment.billingPeriod != null)
            _buildInfoRow('Periode', payment.billingPeriod!),
          _buildInfoRow('Total Tagihan', payment.formattedBillAmount),
          if (payment.billDueDate != null)
            _buildInfoRow(
              'Jatuh Tempo',
              DateFormat('dd MMM yyyy', 'id_ID').format(payment.billDueDate!),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    const cream = Color(0xFFF5E6D3);
    const deepBlue = Color(0xFF2C3E50);
    const charcoal = Color(0xFF2D3436);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: cream.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: charcoal.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofCard() {
    const darkCream = Color(0xFFE8D4BA);
    const primaryBlue = Color(0xFF5B8DB8);
    const lightBlue = Color(0xFF7BA9CC);
    const charcoal = Color(0xFF2D3436);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: darkCream.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.2),
                      lightBlue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.image_rounded, color: primaryBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Bukti Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: charcoal,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showFullProof(),
                icon: const Icon(Icons.fullscreen, size: 18),
                label: const Text('Lihat'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showFullProof,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: payment.proofUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gagal memuat gambar',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantNotesCard() {
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
                  color: AppTheme.softGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.message, color: AppTheme.softGreen, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Catatan Penghuni',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              payment.notes!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReasonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.softPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.softPink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softPink.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cancel, color: Colors.red.shade400, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Alasan Penolakan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            payment.rejectionReason!,
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

  Widget _buildPaymentDetailsCard() {
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detail Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('ID Pembayaran', payment.id.substring(0, 8)),
          _buildInfoRow('Tanggal Upload', payment.formattedCreatedAt),
          _buildInfoRow('Metode', payment.methodLabel),
          _buildInfoRow('Status', payment.statusLabel),
          if (payment.formattedVerifiedAt != null)
            _buildInfoRow('Diverifikasi', payment.formattedVerifiedAt!),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    const primaryBlue = Color(0xFF5B8DB8);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE91E63).withOpacity(0.4),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _showRejectDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFE91E63),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tolak',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE91E63),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _showVerifyDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verifikasi Pembayaran',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'transfer':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.money_rounded;
      case 'ewallet':
        return Icons.phone_android_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  void _showFullProof() {
    if (payment.proofUrl == null) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: payment.proofUrl!,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifyDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verifikasi Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verifikasi pembayaran dari ${payment.tenantName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.formattedAmount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        payment.billTypeLabel,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await _supabase.verifyPayment(payment.id);
                await _refreshPaymentData();

                // Refresh parent list if controller exists
                if (Get.isRegistered<PaymentsController>()) {
                  Get.find<PaymentsController>().refreshData();
                }

                Get.snackbar(
                  'Sukses',
                  'Pembayaran berhasil diverifikasi',
                  backgroundColor: AppTheme.softGreen,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Gagal',
                  'Gagal memverifikasi: ${e.toString()}',
                  backgroundColor: AppTheme.softPink,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.softGreen,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak pembayaran dari ${payment.tenantName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alasan Penolakan *',
                hintText: 'Masukkan alasan penolakan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar(
                  'Error',
                  'Alasan penolakan harus diisi',
                  backgroundColor: AppTheme.softPink,
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              Get.back();
              try {
                await _supabase.client
                    .from('payments')
                    .update({
                      'status': 'rejected',
                      'rejection_reason': reasonController.text.trim(),
                    })
                    .eq('id', payment.id);

                await _refreshPaymentData();

                // Refresh parent list if controller exists
                if (Get.isRegistered<PaymentsController>()) {
                  Get.find<PaymentsController>().refreshData();
                }

                Get.snackbar(
                  'Info',
                  'Pembayaran ditolak',
                  backgroundColor: AppTheme.softPink,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Gagal',
                  'Gagal menolak: ${e.toString()}',
                  backgroundColor: AppTheme.softPink,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.softPink,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}
