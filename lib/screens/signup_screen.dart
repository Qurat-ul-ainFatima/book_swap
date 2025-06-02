import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  // Country code related variables
  String _selectedCountryCode = '+92'; // Default to Pakistan
  String _selectedCountryName = 'Pakistan';
  int _expectedDigits = 10; // Default for Pakistan

  // Country codes with their expected digit counts
  final Map<String, Map<String, dynamic>> _countryCodes = {
    '+1': {'name': 'USA/Canada', 'digits': 10},
    '+44': {'name': 'UK', 'digits': 10},
    '+91': {'name': 'India', 'digits': 10},
    '+92': {'name': 'Pakistan', 'digits': 10},
    '+971': {'name': 'UAE', 'digits': 9},
    '+966': {'name': 'Saudi Arabia', 'digits': 9},
    '+49': {'name': 'Germany', 'digits': 11},
    '+33': {'name': 'France', 'digits': 10},
    '+86': {'name': 'China', 'digits': 11},
    '+81': {'name': 'Japan', 'digits': 10},
  };

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Navigate to email verification screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              userData: {
                'username': _usernameController.text.trim(),
                'email': _emailController.text.trim(),
                'address': _addressController.text.trim(),
                'contact': '$_selectedCountryCode${_contactController.text.trim()}',
                'createdAt': Timestamp.now(),
              },
              uid: userCredential.user!.uid,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already in use.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password should be at least 6 characters.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Country Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _countryCodes.length,
                  itemBuilder: (context, index) {
                    String code = _countryCodes.keys.elementAt(index);
                    Map<String, dynamic> countryData = _countryCodes[code]!;
                    
                    return ListTile(
                      title: Text('${countryData['name']} ($code)'),
                      subtitle: Text('Expected digits: ${countryData['digits']}'),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = code;
                          _selectedCountryName = countryData['name'];
                          _expectedDigits = countryData['digits'];
                          _contactController.clear(); // Clear previous input
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/bookswap_logo.png', height: 100),
                  const SizedBox(height: 4),
                  const Text(
                    "revolutionizing book exchange",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildLabeledField("Username", _usernameController, 'Enter a username'),
                        const SizedBox(height: 8),
                        _buildLabeledField("Email", _emailController, 'Enter a valid email',
                            keyboardType: TextInputType.emailAddress, emailValidation: true),
                        const SizedBox(height: 8),
                        _buildLabeledField("Password", _passwordController, 'Min 6 characters required',
                            obscureText: true),
                        const SizedBox(height: 8),
                        _buildLabeledField("Address", _addressController, 'Enter your address'),
                        const SizedBox(height: 8),
                        _buildContactField(),
                        const SizedBox(height: 12),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Sign Up & Verify Email', style: TextStyle(color: Colors.white)),
                              ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account? '),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                              child: const Text('Login', style: TextStyle(color: Colors.blue)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Contact:", style: TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Row(
          children: [
            // Country code selector button
            GestureDetector(
              onTap: _showCountryCodePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountryCode,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Phone number input field
            Expanded(
              child: TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_expectedDigits),
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[300],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter phone number ($_expectedDigits digits)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your contact number';
                  }
                  if (value.length != _expectedDigits) {
                    return 'Must be exactly $_expectedDigits digits for $_selectedCountryName';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabeledField(
    String label,
    TextEditingController controller,
    String errorMsg, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool emailValidation = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label:", style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        TextFormField(
          controller: controller,
          obscureText: (label == "Password") ? _isPasswordObscured : false,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[300],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            suffixIcon: label == "Password"
                ? IconButton(
                    icon: Icon(
                      _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                  )
                : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return errorMsg;
            if (emailValidation && !value.contains('@')) return errorMsg;
            if (label == "Password" && value.length < 6) return errorMsg;
            return null;
          },
        ),
      ],
    );
  }
}