import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>(); //using to trigger validation later
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  Uint8List? _avatarBytes;
  String _completePhone = '';

  static const _blue = Color(0xFF2B3CF3);
  static const _lightBlue = Color(0xFFE8EAFF);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _avatarBytes = bytes); //reading as bytes to work on chrome and phone
  }

  Future<void> _signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
      );
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone=_phoneController.text.trim();

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      if (!mounted) return; //if this widget was removed return early to avoid errors
      Navigator.pushReplacementNamed(context, '/home'); //pushes home screen and destroys current,,context marks where we are in widget tree
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Decorative blobs ──────────────────────────────────────────
          // Lavender shape — top left corner
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          // Large blue circle — right side, bleeds off screen
          Positioned(
            top: 100,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      'Create\nAccount',
                      style: GoogleFonts.poppins(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Avatar / Camera Picker ────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CustomPaint(
                          painter: _DashedCirclePainter(color: _blue),
                          child: SizedBox(
                            width: 90,
                            height: 90,
                            child: _avatarBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _avatarBytes!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: _blue,
                                      size: 32,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Email Field ───────────────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF1F1F1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Password Field ────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF1F1F1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Phone Field ───────────────────────────────────────
                    IntlPhoneField(
                      controller: _phoneController,
                      initialCountryCode: 'GB',
                      decoration: InputDecoration(
                        hintText: 'Your number',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF1F1F1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (phone) => _completePhone = phone.completeNumber,
                      validator: (phone) {
                        if (phone == null || phone.number.isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),

                    // ── Done Button ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Done',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── OR Divider ────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Google Button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                                  TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
                                  TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
                                  TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
                                  TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
                                  TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Cancel / Back ─────────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'I have an account, Sign In',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;
    final circumference = 2 * math.pi * radius;

    const dashLength = 8.0;
    const gapLength = 5.0;
    final totalDash = dashLength + gapLength;
    final dashCount = (circumference / totalDash).floor();
    final dashAngle = (dashLength / circumference) * 2 * math.pi;
    final gapAngle = (gapLength / circumference) * 2 * math.pi;

    double startAngle = -math.pi / 2;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}