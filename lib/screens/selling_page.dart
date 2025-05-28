import 'package:flutter/material.dart';
import 'main_scaffold.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final TextEditingController copiesController = TextEditingController();

class SellingPage extends StatefulWidget {
  const SellingPage({super.key});

  @override
  State<SellingPage> createState() => _SellingPageState();
}

class _SellingPageState extends State<SellingPage> {
  int _currentStep = 1;

  List<String> uploadedImages = [];
  final TextEditingController bookNameController = TextEditingController();
  final TextEditingController authorNameController = TextEditingController();
  final TextEditingController bookDescController = TextEditingController();
  String selectedCategory = '';
  final TextEditingController priceController = TextEditingController();
  bool isFixedPrice = true;

  String sellerName = '';
  String sellerPhone = '';
  String sellerAddress = '';
  String sellerEmail = '';
  bool isNew = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    bookNameController.dispose();
    authorNameController.dispose();
    bookDescController.dispose();
    priceController.dispose();
    copiesController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userData.exists) {
          setState(() {
            sellerName = userData['username'] ?? '';
            sellerPhone = userData['contact'] ?? '';
            sellerAddress = userData['address'] ?? '';
            sellerEmail = userData['email'] ?? '';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() => uploadedImages.add(image.path));
    }
  }

  Future<String> convertImageToBase64(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> publishBook() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (sellerName.isEmpty ||
          sellerPhone.isEmpty ||
          sellerAddress.isEmpty ||
          sellerEmail.isEmpty) {
        await _fetchUserData();
        if (sellerName.isEmpty ||
            sellerPhone.isEmpty ||
            sellerAddress.isEmpty ||
            sellerEmail.isEmpty) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Please update your profile.')),
          );
          return;
        }
      }

      if (bookNameController.text.trim().isEmpty ||
          priceController.text.trim().isEmpty ||
          selectedCategory.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields.')),
        );
        return;
      }

      if (int.tryParse(copiesController.text) == null ||
          int.parse(copiesController.text) <= 0) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid number of copies.'),
          ),
        );
        return;
      }

      List<String> imageBase64List = [];
      for (String path in uploadedImages) {
        final base64Image = await convertImageToBase64(path);
        imageBase64List.add(base64Image);
      }

      await FirebaseFirestore.instance.collection('books').add({
        'title': bookNameController.text,
        'author': authorNameController.text,
        'description': bookDescController.text,
        'category': selectedCategory.toUpperCase(),
        'price': priceController.text,
        'isFixedPrice': isFixedPrice,
        'sellerName': sellerName,
        'sellerPhone': sellerPhone,
        'sellerAddress': sellerAddress,
        'images': imageBase64List,
        'condition': isNew ? 'NEW' : 'OLD',
        'rating': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'sellerId': FirebaseAuth.instance.currentUser?.uid,
        'sellerEmail': FirebaseAuth.instance.currentUser?.email,
        'number_of_copies': int.parse(copiesController.text),
      });

      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder:
            (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF23D7BC), Color(0xFF1CA885)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Thank you!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your book has been published.',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Color(0xFF1CA885),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Sell',
      currentIndex: -1,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Please fill out the following steps to list your book. ',
                                    ),
                                    const TextSpan(
                                      text: 'Make sure your images are clear. ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          'The publish button will be available at the final step.',
                                      style: TextStyle(color: Colors.grey[800]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(),
                            getCurrentForm(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget getCurrentForm() {
    switch (_currentStep) {
      case 1:
        return imageUploadStep();
      case 2:
        return bookDetailsStep();
      case 3:
        return categoryPricingStep();
      case 4:
        return summaryStep();
      default:
        return const Center(child: Text("Invalid Step"));
    }
  }

  Widget imageUploadStep() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library, size: 40),
              onPressed: () => pickImage(ImageSource.gallery),
            ),
            const SizedBox(width: 5),
            IconButton(
              icon: const Icon(Icons.camera_alt, size: 40),
              onPressed: () => pickImage(ImageSource.camera),
            ),
          ],
        ),
        const Text('Tap an icon to add book images'),
        SizedBox(
          height: 200,
          child:
              uploadedImages.isEmpty
                  ? const Center(child: Text("No images added"))
                  : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: uploadedImages.length,
                    itemBuilder: (context, index) {
                      return Image.file(
                        File(uploadedImages[index]),
                        fit: BoxFit.cover,
                      );
                    },
                  ),
        ),
        stepControls(),
      ],
    );
  }

  Widget bookDetailsStep() {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: bookNameController,
            decoration: inputDecoration.copyWith(labelText: 'Book Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: authorNameController,
            decoration: inputDecoration.copyWith(labelText: 'Author Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bookDescController,
            decoration: inputDecoration.copyWith(labelText: 'Description'),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          const Text(
            'Condition',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Radio(
                value: true,
                groupValue: isNew,
                onChanged: (val) => setState(() => isNew = val!),
              ),
              const Text('New'),
              Radio(
                value: false,
                groupValue: isNew,
                onChanged: (val) => setState(() => isNew = val!),
              ),
              const Text('Old'),
            ],
          ),
          stepControls(),
        ],
      ),
    );
  }

  Widget categoryPricingStep() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📚 Category & Pricing',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1CA885),
          ),
        ),
        const SizedBox(height: 16),

        // Category Dropdown
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: DropdownButtonFormField<String>(
            value: selectedCategory.isEmpty ? null : selectedCategory,
            decoration: const InputDecoration.collapsed(hintText: ''),
            hint: const Text('Select Category'),
            items: ['Romance', 'History', 'Growth', 'Academics']
                .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    ))
                .toList(),
            onChanged: (val) => setState(() => selectedCategory = val!),
          ),
        ),
        const SizedBox(height: 16),

        // Price Field
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '💰 Price',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.attach_money),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Copies Field
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: TextField(
            controller: copiesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '📦 Number of Copies',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.format_list_numbered),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Price Type
        const Text(
          'Pricing Type:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  value: true,
                  groupValue: isFixedPrice,
                  title: const Text('Fixed'),
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => isFixedPrice = val!),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  value: false,
                  groupValue: isFixedPrice,
                  title: const Text('Negotiable'),
                  activeColor: Colors.orange,
                  onChanged: (val) => setState(() => isFixedPrice = val!),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        stepControls(),
      ],
),
);
}

 Widget summaryStep() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Book Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow('📘 Book Title', bookNameController.text),
                infoRow('✍ Author', authorNameController.text),
                infoRow('📝 Description', bookDescController.text),
                infoRow('📚 Category', selectedCategory),
                infoRow('💰 Price', '${priceController.text} (${isFixedPrice ? 'Fixed' : 'Negotiable'})'),
                infoRow('📦 Copies', copiesController.text),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          '🙋 Seller Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow('👤 Name', sellerName),
                infoRow('📞 Phone', sellerPhone),
                infoRow('📍 Address', sellerAddress),
                infoRow('📧 Email', sellerEmail),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF23D7BC),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
            onPressed: publishBook,
            icon: const Icon(Icons.publish),
            label: const Text(
              'Publish Book',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget infoRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
),
);
}


  Widget stepControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (_currentStep > 1)
            ElevatedButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Previous'),
            ),
          if (_currentStep < 4)
            ElevatedButton(
              onPressed: () => setState(() => _currentStep++),
              child: const Text('Next'),
            ),
        ],
),
);
}
}
