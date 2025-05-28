import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'about_me.dart'; // Import the AboutMeScreen

import 'my_cart.dart';
import 'LikedBooksScreen .dart';
import 'menu.dart';
import 'selling_page.dart';
import 'BookDetails.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'HISTORY';
  bool isNew = true;
  int currentIndex = 0;

  final List<String> categories = [
    'ROMANCE',
    'HISTORY',
    'GROWTH',
    'ACADEMICS',
    'GEOGRAPHY',
    'EARNING',
  ];

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive dimensions
    final double gridHeight = screenHeight * 0.55;
    final bool isSmallScreen = screenWidth < 400;
    final double cardPadding = isSmallScreen ? 8 : 10;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top bar with profile icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF23D7BC), Color(0xFF1CA885)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                          child: const Text(
                            'Explore',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        String userId = FirebaseAuth.instance.currentUser!.uid;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutMeScreen(userId: userId),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: const AssetImage('assets/images/user.png'),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Icons
              Container(
                height: 95,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    String category = categories[index];
                    bool isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => selectedCategory = category),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(colors: [Color(0xFF23D7BC), Color(0xFF1CA885)])
                                    : null,
                                color: isSelected ? null : Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  if (isSelected)
                                    const BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                ],
                              ),
                              child: const Icon(
                                Icons.menu_book,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF23D7BC) : Colors.black87,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Toggle New / Old
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => isNew = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            decoration: BoxDecoration(
                              color: isNew ? const Color(0xFF23D7BC) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                color: isNew ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => isNew = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            decoration: BoxDecoration(
                              color: !isNew ? const Color(0xFF23D7BC) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'OLD',
                              style: TextStyle(
                                color: !isNew ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Category Title and "More ➔"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCategory,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F1B2B),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Optional: add more action here
                      },
                      child: const Text(
                        'MORE ➔',
                        style: TextStyle(
                          color: Color(0xFF23D7BC),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Book Grid from Firestore
              SizedBox(
                height: gridHeight,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('books')
                      .where('category', isEqualTo: selectedCategory)
                      .where('condition', isEqualTo: isNew ? 'NEW' : 'OLD')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No books available in this category',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final books = snapshot.data!.docs;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: isSmallScreen ? 0.68 : 0.65, // Slightly taller for small screens
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index].data() as Map<String, dynamic>;
                        final bookId = books[index].id;

                        String? imageBase64;
                        if (book['images'] != null && (book['images'] as List).isNotEmpty) {
                          imageBase64 = book['images'][0] as String;
                        }

                        final bookTitle = book['title'] ?? 'Untitled';
                        final bookPrice = book['price'] ?? '0';
                        final bookRating = book['rating'] ?? 0;

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetails(bookId: bookId),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image container with flexible height
                                  Expanded(
                                    flex: 7, // Takes up most of the card space
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            child: imageBase64 != null
                                                ? Image.memory(
                                                    base64Decode(imageBase64),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                          Icons.book,
                                                          size: 60,
                                                          color: Colors.grey,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.book,
                                                      size: 60,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 8,
                                          bottom: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.add, 
                                              size: isSmallScreen ? 16 : 18, 
                                              color: Color(0xFF23D7BC)
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Content section with fixed space
                                  Expanded(
                                    flex: 3, // Fixed space for text content
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              bookTitle,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 12 : 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  '\$ $bookPrice',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: isSmallScreen ? 14 : 16,
                                                    color: Color(0xFF23D7BC),
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.star, 
                                                    color: Colors.orangeAccent, 
                                                    size: isSmallScreen ? 12 : 14
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    bookRating.toString(),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600, 
                                                      fontSize: isSmallScreen ? 11 : 13
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF23D7BC),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SellingPage()),
          );
        },
        child: const Icon(Icons.sell, size: 28),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home,
                  size: 28,
                  color: currentIndex == 0 ? const Color(0xFF23D7BC) : Colors.grey[600],
                ),
                onPressed: () {
                  setState(() => currentIndex = 0);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  size: 28,
                  color: currentIndex == 1 ? const Color(0xFF23D7BC) : Colors.grey[600],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCart()),
                  );
                },
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  size: 28,
                  color: currentIndex == 2 ? const Color(0xFF23D7BC) : Colors.grey[600],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LikedBooksScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.menu,
                  size: 28,
                  color: currentIndex == 3 ? const Color(0xFF23D7BC) : Colors.grey[600],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}