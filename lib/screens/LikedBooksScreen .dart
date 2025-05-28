import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'BookDetails.dart';

class LikedBooksScreen extends StatelessWidget {
  const LikedBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(' Liked Books',style:TextStyle(fontWeight:FontWeight.bold),),
        backgroundColor: const Color(0xFF23D7BC),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('liked_books')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You haven\'t liked any books yet.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          final likedBookIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('books')
                .where(FieldPath.documentId, whereIn: likedBookIds)
                .get(),
            builder: (context, booksSnapshot) {
              if (booksSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!booksSnapshot.hasData || booksSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No liked books found.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                );
              }

              final books = booksSnapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final book = books[index];
                  final bookData = book.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetails(bookId: book.id),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F8F4),
                                borderRadius: BorderRadius.circular(10),
                                image: bookData['coverUrl'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(bookData['coverUrl']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: bookData['coverUrl'] == null
                                  ? const Icon(Icons.book, size: 40, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bookData['title'] ?? 'Untitled',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bookData['author'] ?? 'Unknown Author',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${bookData['price'] ?? '0'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF23D7BC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
