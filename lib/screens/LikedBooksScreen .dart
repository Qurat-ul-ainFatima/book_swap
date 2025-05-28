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
        title: const Text('Liked Books'),
        backgroundColor: const Color(0xFF23D7BC),
        foregroundColor: Colors.white,
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
            return const Center(child: Text('No liked books found.'));
          }

          final likedBookIds =
              snapshot.data!.docs.map((doc) => doc.id).toList();

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
                return const Center(child: Text('No liked books found.'));
              }

              return ListView.builder(
                itemCount: booksSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final book = booksSnapshot.data!.docs[index];
                  final bookData = book.data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(bookData['title'] ?? 'Untitled'),
                    subtitle: Text(bookData['author'] ?? 'Unknown Author'),
                    trailing: Text('₹${bookData['price'] ?? '0'}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetails(bookId: book.id),
                        ),
                      );
                    },
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
