import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SoldBooksScreen extends StatelessWidget {
  final String userId;

  const SoldBooksScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final soldBooksRef = FirebaseFirestore.instance
        .collection('books')
        .where('sellerId', isEqualTo: userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sold Books'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: soldBooksRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final books = snapshot.data!.docs;

          if (books.isEmpty) {
            return const Center(child: Text('No books sold yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              var book = books[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(book['title'] ?? 'Unknown Title',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Author: ${book['author'] ?? 'N/A'}\n"
                    "Category: ${book['category'] ?? 'N/A'}\n"
                    "Condition: ${book['condition'] ?? 'N/A'}\n"
                    "Price: \$${book['price'] ?? '0'}\n"
                    "Rating: ${book['rating'] ?? 'N/A'}\n"
                    "Description: ${book['description'] ?? 'No description'}",
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}