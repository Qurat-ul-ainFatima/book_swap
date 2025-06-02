import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String uid;

  const EmailVerificationScreen({
    super.key,
    required this.userData,
    required this.uid,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isVerified = false;
  bool _isLoading = false;
  Timer? _timer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  Future<void> _checkEmailVerification() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      
      if (user != null && user.emailVerified && !_isVerified) {
        setState(() => _isVerified = true);
        _timer?.cancel();
        
        // Save user data to Firestore after email verification
        await _saveUserDataToFirestore();
        
        // Navigate to home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
    }
  }

  Future<void> _saveUserDataToFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set(widget.userData);
    } catch (e) {
      print('Error saving user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving user data. Please try again.')),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);

    try {
      await _auth.currentUser?.sendEmailVerification();
      
      // Start countdown for resend button
      setState(() => _resendCountdown = 60);
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCountdown > 0) {
          setState(() => _resendCountdown--);
        } else {
          timer.cancel();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send verification email';
      if (e.code == 'too-many-requests') {
        errorMessage = 'Too many requests. Please wait before trying again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeEmail() async {
    // Show dialog to get new email
    String? newEmail = await _showChangeEmailDialog();
    if (newEmail == null || newEmail.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Delete current user and let them sign up again with new email
      await _auth.currentUser?.delete();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signup');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign up again with the new email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error changing email. Please try again.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showChangeEmailDialog() async {
    final TextEditingController emailController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'New Email Address',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, emailController.text.trim()),
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/bookswap_logo.png', height: 100),
              const SizedBox(height: 32),
              
              Icon(
                _isVerified ? Icons.check_circle : Icons.email_outlined,
                size: 80,
                color: _isVerified ? Colors.green : Colors.blue,
              ),
              
              const SizedBox(height: 24),
              
              Text(
                _isVerified ? 'Email Verified!' : 'Check Your Email',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _isVerified 
                    ? 'Your email has been verified successfully!'
                    : 'We\'ve sent a verification link to\n${widget.userData['email']}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 32),
              
              if (!_isVerified) ...[
                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _resendCountdown > 0 ? null : _resendVerificationEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _resendCountdown > 0 
                                  ? 'Resend in ${_resendCountdown}s'
                                  : 'Resend Verification Email',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: _changeEmail,
                            child: const Text(
                              'Wrong email? Change it',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: () async {
                              await _auth.signOut();
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            child: const Text(
                              'Back to Login',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
              ],
              
              if (_isVerified)
                const Text(
                  'Redirecting to home...',
                  style: TextStyle(color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}