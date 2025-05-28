import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class BookDetails extends StatefulWidget {
  final String bookId;

  const BookDetails({super.key, required this.bookId});

  @override
  State<BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends State<BookDetails> {
  int selectedImageIndex = 0;
  bool isAddedToCart = false;
  bool isLiked = false;
  bool isSoldOut = false;
  int bookQuantity = 0;
 

  String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
void initState() {
  super.initState();
  _fetchBookInventoryAndCartStatus();
}

  Future<void> _fetchBookInventoryAndCartStatus() async {
    final bookDoc =
        await FirebaseFirestore.instance.collection('books').doc(widget.bookId).get();

    if (!bookDoc.exists) return;

    final bookData = bookDoc.data() as Map<String, dynamic>;
    final totalQuantity = int.tryParse(bookData['number_of_copies'].toString()) ?? 0;

    final cartSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .where('bookId', isEqualTo: widget.bookId)
        .get();

    final cartCount = cartSnapshot.docs.length;

    setState(() {
      bookQuantity = totalQuantity - cartCount;
      isAddedToCart = cartSnapshot.docs.any((doc) => doc.id == widget.bookId);
      isSoldOut = bookQuantity <= 0;
    });
  }

  Future<void> _addToCart() async {
    final bookDoc =
        await FirebaseFirestore.instance.collection('books').doc(widget.bookId).get();

    final bookData = bookDoc.data();
    if (bookData == null) return;

    final currentQuantity = bookData['number_of_copies'] ?? 0;

    if (currentQuantity > 0) {
      // Add book info to user's cart
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(widget.bookId)
          .set({
        'title': bookData['title'],
        'author': bookData['author'],
        'price': bookData['price'],
        'image': (bookData['images'] as List).isNotEmpty ? bookData['images'][0] : '',
        'quantity': 1, // or however many the user wants to buy
        'bookId': widget.bookId,
      });

      // Decrease the inventory
      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.bookId)
          .update({'number_of_copies': currentQuantity - 1});

      setState(() {
        isAddedToCart = true;
        bookQuantity--;
        isSoldOut = bookQuantity == 0;
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('This book is sold out!')));
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber, String sellerName) async {
    if (phoneNumber == 'Not provided' || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller phone number not provided.')),
        );
      }
      return;
    }

    String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanedPhoneNumber.startsWith('+')) {
      cleanedPhoneNumber = cleanedPhoneNumber.substring(1);
    }

    if (cleanedPhoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller phone number is invalid.')),
        );
      }
      return;
    }

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$cleanedPhoneNumber?text=${Uri.encodeComponent("Hello $sellerName, I am interested in your book '${widget.bookId}'.")}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Opening WhatsApp...')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error opening WhatsApp: $e')));
      }
    }
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF23D7BC).withOpacity(0.1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF23D7BC),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.black,
            ),
            onPressed: () async {
  setState(() => isLiked = !isLiked);

  final likedRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('liked_books');

  if (isLiked) {
  // Save to liked_books
  await likedRef.doc(widget.bookId).set({'bookId': widget.bookId});
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: const [
          Icon(Icons.favorite, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Added to favorites',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      duration: const Duration(seconds: 2),
    ),
  );
} else {
  // Remove from liked_books
  await likedRef.doc(widget.bookId).delete();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: const [
          Icon(Icons.favorite_border, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Removed from favorites',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      duration: const Duration(seconds: 2),
    ),
  );
}
            }

          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('books').doc(widget.bookId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Book not found.'));
          }

          final book = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> images = book['images'] as List<dynamic>? ?? [];
          final bookTitle = book['title'] ?? 'Untitled';
          final bookAuthor = book['author'] ?? 'Unknown Author';
          final bookDescription = book['description'] ?? 'No description available';
          final bookPrice = book['price']?.toString() ?? '0';
          final isFixedPrice = book['isFixedPrice'] as bool? ?? true;
          final bookCategory = book['category'] ?? 'Uncategorized';
          final bookCondition = book['condition'] ?? 'UNKNOWN';
          final sellerName = book['sellerName'] ?? 'Anonymous';
          final sellerPhone = book['sellerPhone'] ?? 'Not provided';
          final sellerAddress = book['sellerAddress'] ?? 'Not provided';
          final rating = (book['rating'] as num?)?.toInt() ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 300,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[200],
                    ),
                    child: images.isNotEmpty && images[selectedImageIndex] is String
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.memory(
                              base64Decode((images[selectedImageIndex] as String).split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.book,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => GestureDetector(
                            onTap: () {
                              setState(() => selectedImageIndex = index);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedImageIndex == index
                                    ? const Color(0xFF23D7BC)
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _tag(bookCategory),
                            const SizedBox(width: 10),
                            _tag(bookCondition),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          bookTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By $bookAuthor',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star,
                              size: 18,
                              color: i < rating ? Colors.amber : Colors.grey[300],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              '₹$bookPrice',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF23D7BC),
                              ),
                            ),
                            if (!isFixedPrice)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '(Negotiable)',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Description:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(bookDescription),
                        const SizedBox(height: 24),
                        const Text(
                          'Seller Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Name: $sellerName'),
                        Text('Address: $sellerAddress'),
                        Text('Phone: $sellerPhone'),
                        const SizedBox(height: 24),
                        Row(
  children: [
    ElevatedButton(
      onPressed: isSoldOut || isAddedToCart ? null : _addToCart,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF23D7BC),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      child: Text(
        isSoldOut
            ? 'Sold Out'
            : isAddedToCart
                ? 'Added to Cart'
                : 'Add to Cart',
      ),
    ),
    const SizedBox(width: 16),
    OutlinedButton(
      onPressed: () => _launchWhatsApp(sellerPhone, sellerName),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF23D7BC)),
        foregroundColor: const Color(0xFF23D7BC),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      child: const Text('Contact Seller'),
    ),
  ],
),
],
),
),
],
),
),
);
},
),
);
}
}