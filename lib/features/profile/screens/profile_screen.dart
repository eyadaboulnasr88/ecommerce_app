import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/core/routes/app_routes.dart';

class ProfileColors {
  static const Color primary = Color(0xFF1100FF);
  static const Color primaryLight = Color(0xFF4436FF);
  static const Color accentPink = Color(0xFFF43F5E);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String userEmail = '';
  String userUsername = '';
  String userPhone = '';
  String userLocation = '';
  String userSubscription = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!mounted) return;
    setState(() {
      userName = user.displayName ?? '';
      userEmail = user.email ?? '';
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          if (userName.isEmpty) userName = data['name'] ?? '';
          userUsername = data['username'] ?? '';
          userPhone = data['phone'] ?? '';
          userLocation = data['location'] ?? '';
          userSubscription = data['subscription'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      if (user.displayName != userName) {
        await user.updateDisplayName(userName);
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': userName,
        'email': userEmail,
        'username': userUsername,
        'phone': userPhone,
        'location': userLocation,
        'subscription': userSubscription,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _updateUserData(Map<String, dynamic> data) {
    setState(() {
      if (data.containsKey('name')) userName = data['name'];
      if (data.containsKey('email')) userEmail = data['email'];
      if (data.containsKey('username')) userUsername = data['username'];
      if (data.containsKey('phone')) userPhone = data['phone'];
      if (data.containsKey('location')) userLocation = data['location'];
      if (data.containsKey('subscription')) userSubscription = data['subscription'];
    });
    _saveToFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: ProfileColors.textPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: ProfileColors.primary),
            onPressed: () => _showEditProfileDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(name: userName, username: userUsername),
            const SizedBox(height: 16),
            SettingsMenu(
              userName: userName,
              userEmail: userEmail,
              userUsername: userUsername,
              userPhone: userPhone,
              userLocation: userLocation,
              userSubscription: userSubscription,
              onDataUpdated: _updateUserData,
            ),
            const SizedBox(height: 30),
            const LogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: const ProfileBottomNavBar(),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: userName);
    final TextEditingController emailController = TextEditingController(text: userEmail);
    final TextEditingController usernameController = TextEditingController(text: userUsername.replaceAll('@', ''));
    final TextEditingController phoneController = TextEditingController(text: userPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: ProfileColors.primary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(controller: nameController, label: 'Full Name', icon: Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(controller: emailController, label: 'Email', icon: Icons.email_outlined),
              const SizedBox(height: 12),
              _buildTextField(controller: usernameController, label: 'Username', icon: Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(controller: phoneController, label: 'Phone Number', icon: Icons.phone_outlined),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: ProfileColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                userName = nameController.text;
                userEmail = emailController.text;
                userUsername = usernameController.text.startsWith('@')
                    ? usernameController.text
                    : '@${usernameController.text}';
                userPhone = phoneController.text;
              });
              _saveToFirebase();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: ProfileColors.textSecondary),
        prefixIcon: Icon(icon, color: ProfileColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ProfileColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ProfileColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ProfileColors.primary, width: 2),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final String name;
  final String username;

  const ProfileHeader({super.key, required this.name, required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [ProfileColors.primary, ProfileColors.primaryLight],
              ),
            ),
            child: const Center(
              child: Icon(Icons.person, size: 45, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name.isEmpty ? 'User' : name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ProfileColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (username.isNotEmpty)
            Text(
              username,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: ProfileColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsMenu extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userUsername;
  final String userPhone;
  final String userLocation;
  final String userSubscription;
  final Function(Map<String, dynamic>) onDataUpdated;

  const SettingsMenu({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userUsername,
    required this.userPhone,
    required this.userLocation,
    required this.userSubscription,
    required this.onDataUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuItem(
            context,
            Icons.person_outline,
            'Name',
            userName,
            (value) => onDataUpdated({
              'name': value,
              'email': userEmail,
              'username': userUsername,
              'phone': userPhone,
              'location': userLocation,
              'subscription': userSubscription,
            }),
          ),
          const Divider(height: 1, indent: 56, color: ProfileColors.border),
          _buildMenuItem(
            context,
            Icons.email_outlined,
            'Email address',
            userEmail,
            (value) => onDataUpdated({
              'name': userName,
              'email': value,
              'username': userUsername,
              'phone': userPhone,
              'location': userLocation,
              'subscription': userSubscription,
            }),
          ),
          const Divider(height: 1, indent: 56, color: ProfileColors.border),
          _buildMenuItem(
            context,
            Icons.person_outline,
            'Username',
            userUsername,
            (value) => onDataUpdated({
              'name': userName,
              'email': userEmail,
              'username': value,
              'phone': userPhone,
              'location': userLocation,
              'subscription': userSubscription,
            }),
          ),
          const Divider(height: 1, indent: 56, color: ProfileColors.border),
          _buildMenuItem(
            context,
            Icons.location_on_outlined,
            'Location',
            userLocation.isEmpty ? 'Not set' : userLocation,
            (value) => onDataUpdated({
              'name': userName,
              'email': userEmail,
              'username': userUsername,
              'phone': userPhone,
              'location': value,
              'subscription': userSubscription,
            }),
          ),
          const Divider(height: 1, indent: 56, color: ProfileColors.border),
          _buildMenuItem(
            context,
            Icons.credit_card_outlined,
            'Subscription',
            userSubscription.isEmpty ? 'Not subscribed' : userSubscription,
            (value) => onDataUpdated({
              'name': userName,
              'email': userEmail,
              'username': userUsername,
              'phone': userPhone,
              'location': userLocation,
              'subscription': value,
            }),
          ),
          const Divider(height: 1, indent: 56, color: ProfileColors.border),
          _buildPasswordItem(context),
          const Divider(height: 1, indent: 56, color: ProfileColors.border),
          _buildMenuItem(
            context,
            Icons.phone_outlined,
            'Phone number',
            userPhone,
            (value) => onDataUpdated({
              'name': userName,
              'email': userEmail,
              'username': userUsername,
              'phone': value,
              'location': userLocation,
              'subscription': userSubscription,
            }),
          ),
          const Divider(height: 1, indent: 56, color: ProfileColors.border),
          _buildSimpleMenuItem(
            context,
            Icons.delete_outline,
            'Clear cache',
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cache cleared!')),
            ),
          ),
          const Divider(height: 1, indent: 56, color: ProfileColors.border),
          _buildSimpleMenuItem(
            context,
            Icons.history_outlined,
            'Clear history',
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('History cleared!')),
            ),
          ),
          // ==================== HELP & SUPPORT ====================
          const Divider(height: 1, indent: 56, color: ProfileColors.border),
          _buildSimpleMenuItem(
            context,
            Icons.help_outline,
            'Help & Support',
            () => Navigator.pushNamed(context, AppRoutes.helpSupport),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Function(String) onSave,
  ) {
    return GestureDetector(
      onTap: () => _editField(context, title, subtitle, onSave),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              child: Icon(icon, color: ProfileColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ProfileColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: ProfileColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ProfileColors.textLight, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              child: Icon(icon, color: ProfileColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ProfileColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: ProfileColors.textLight, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordItem(BuildContext context) {
    return GestureDetector(
      onTap: () => _changePassword(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              child: Icon(Icons.lock_outline, color: ProfileColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ProfileColors.textPrimary,
                    ),
                  ),
                  Text(
                    '********',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: ProfileColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ProfileColors.textLight, size: 22),
          ],
        ),
      ),
    );
  }

  void _editField(
    BuildContext context,
    String fieldName,
    String currentValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(
      text: currentValue == 'Not set' ? '' : currentValue,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit $fieldName',
          style: GoogleFonts.poppins(color: ProfileColors.primary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $fieldName',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: ProfileColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) onSave(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$fieldName updated!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: ProfileColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context) {
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPass.text.isEmpty || newPass.text != confirmPass.text) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match!')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              // Capture messenger before the await so context is never used across async gaps
              final messenger = ScaffoldMessenger.of(context);
              try {
                await FirebaseAuth.instance.currentUser
                    ?.updatePassword(newPass.text);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Password updated successfully!')),
                );
              } on FirebaseAuthException catch (e) {
                final message = e.code == 'requires-recent-login'
                    ? 'Please sign out and sign back in, then try again.'
                    : 'Failed to update password. Please try again.';
                messenger.showSnackBar(SnackBar(content: Text(message)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: ProfileColors.primary),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ProfileColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: ProfileColors.accentPink, size: 20),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ProfileColors.accentPink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: ProfileColors.textLight)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              messenger.showSnackBar(
                const SnackBar(content: Text('Logging out...')),
              );
              try {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.signIn,
                  (route) => false,
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Logout', style: TextStyle(color: ProfileColors.accentPink)),
          ),
        ],
      ),
    );
  }
}

class ProfileBottomNavBar extends StatelessWidget {
  const ProfileBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: ProfileColors.primary,
      unselectedItemColor: ProfileColors.textSecondary,
      currentIndex: 4,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            break;
          case 1:
            Navigator.pushNamed(context, AppRoutes.search);
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.favorite);
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.cart);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favorite'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}