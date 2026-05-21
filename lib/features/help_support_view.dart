import 'package:flutter/material.dart';
//import 'package:go_router/go_router.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF0D1C3C),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Color(0xFF0D1C3C),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              icon: Icons.support_agent_outlined,
              iconBg: const Color(0xFF0D1C3C),
              title: "We're Here to Help",
              subtitle:
                  "Need assistance with your order or have questions about our products? Our support team is ready to help you with any inquiries.",
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.phone_in_talk_outlined,
              title: 'Phone Support',
              subtitle:
                  'Call us directly for immediate assistance with your orders or questions.',
              extraText: '+20 123 456 7890',
              extraTextColor: const Color(0xFF0D1C3C),
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle:
                  "Send us an email and we'll get back to you within 24 hours.",
              extraText: 'support@mystore.com',
              extraTextColor: const Color(0xFF0D1C3C),
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.access_time,
              title: 'Support Hours',
              subtitle: 'Saturday - Thursday\n9:00 AM - 9:00 PM',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconBg = const Color(0xFF0D1C3C),
    String? extraText,
    Color? extraTextColor,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconBg,
                  radius: 18,
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1C3C),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
            if (extraText != null) ...[
              const SizedBox(height: 6),
              Text(
                extraText,
                style: TextStyle(
                  color: extraTextColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
