import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';

class TenantHelpView extends StatelessWidget {
  const TenantHelpView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B8EFF), Color(0xFF4A6FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A6FFF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Butuh Bantuan?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kami siap membantu Anda 24/7. Temukan jawaban atau hubungi kami langsung.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Contact Support Section
            const Text(
              'Hubungi Kami',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.chat_bubble_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () => _launchUrl('https://wa.me/6281234567890'), // Replace with actual number
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    color: Colors.orange,
                    onTap: () => _launchUrl('mailto:support@kosbae.com'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // FAQ Section
            const Text(
              'Pertanyaan Umum (FAQ)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'Bagaimana cara membayar tagihan?',
              'Anda dapat membayar tagihan melalui menu "Bayar" di dashboard. Pilih metode pembayaran (Transfer/E-Wallet), upload bukti transfer, dan tunggu verifikasi admin.',
            ),
            _buildFaqItem(
              'Apa yang harus dilakukan jika ada kerusakan?',
              'Gunakan menu "Lapor" atau "Keluhan" untuk melaporkan kerusakan. Sertakan foto dan deskripsi jelas agar kami bisa segera menanganinya.',
            ),
            _buildFaqItem(
              'Kapan jatuh tempo pembayaran sewa?',
              'Jatuh tempo pembayaran biasanya tanggal 5 setiap bulannya. Anda akan mendapatkan notifikasi tagihan sebelum jatuh tempo.',
            ),
            _buildFaqItem(
              'Bagaimana jika saya ingin pindah kamar?',
              'Silakan hubungi admin secara langsung melalui WhatsApp atau datang ke kantor pengelola untuk mendiskusikan ketersediaan kamar lain.',
            ),
            const SizedBox(height: 32),

            // Emergency Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_rounded, color: Colors.red.shade400),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Darurat?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hubungi Keamanan: 0811-0000-1111',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.call, color: Colors.red.shade400),
                    onPressed: () => _launchUrl('tel:081100001111'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      Get.snackbar('Error', 'Could not launch $urlString');
    }
  }
}
