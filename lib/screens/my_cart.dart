import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_service.dart';

class MyCart extends StatefulWidget {
  final List<Map<String, dynamic>>? initialItems;

  const MyCart({super.key, this.initialItems});

  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  String selectedPaymentMethod = 'Cash on Delivery';
  String address = '';

  Future<List<Map<String, dynamic>>> fetchCartItems() async {
    try {
      final cartSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('cart')
              .get();

      List<Map<String, dynamic>> items = [];

      for (var cartDoc in cartSnapshot.docs) {
        String bookId = cartDoc.id;
        int quantity = cartDoc['quantity'];

        final bookSnapshot =
            await FirebaseFirestore.instance
                .collection('books')
                .doc(bookId)
                .get();

        if (bookSnapshot.exists) {
          final bookData = bookSnapshot.data();
          if (bookData != null) {
            items.add({
              'bookId': bookId,
              'title': bookData['title'] ?? 'Untitled',
              'price': bookData['price'] ?? 0,
              'quantity': quantity,
              'sellerEmail': bookData['sellerEmail'] ?? '',
              'sellerName': bookData['sellerName'] ?? '',
              'image_url':
                  (bookData['images'] as List).isNotEmpty
                      ? bookData['images'][0] // ✅ Get first image from Firestore
                      : '',
            });
          }
        }
      }

      return items;
    } catch (e) {
      return [];
    }
  }

  Future<void> updateQuantity(String bookId, int currentQty, int delta) async {
    final newQty = (currentQty + delta).clamp(1, 99);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(bookId)
        .update({'quantity': newQty});
    setState(() {});
  }

  Future<void> removeItem(String bookId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(bookId)
        .delete();
    setState(() {});
  }

  double getTotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }

  void _checkout(List<Map<String, dynamic>> items) async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Confirm Checkout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Shipping Address',
                ),
                onChanged: (value) => address = value,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedPaymentMethod,
                isExpanded: true,
                items:
                    ['Cash on Delivery', 'Credit Card', 'Easypaisa']
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() => selectedPaymentMethod = value!);
                  Navigator.of(context).pop();
                  _checkout(items);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () async {
                Navigator.of(context).pop();

                final groupedBySeller = <String, List<Map<String, dynamic>>>{};
                for (var item in items) {
                  final sellerEmail = item['sellerEmail'];
                  if (!groupedBySeller.containsKey(sellerEmail)) {
                    groupedBySeller[sellerEmail] = [];
                  }
                  groupedBySeller[sellerEmail]!.add(item);
                }

                for (var entry in groupedBySeller.entries) {
                  final sellerEmail = entry.key;
                  final sellerName = entry.value.first['sellerName'];
                  final sellerItems = entry.value;

                  await sendOrderToSeller(
                    toEmail: sellerEmail,
                    sellerName: sellerName,
                    orderId: DateTime.now().millisecondsSinceEpoch.toString(),
                    buyerAddress: address,
                    buyerContact: "123",
                    orders:
                        sellerItems
                            .map(
                              (item) => {
                                'name': item['title'],
                                'price': item['price'],
                                'units': item['quantity'],
                                'image_url': item['image_url'] ?? '',
                              },
                            )
                            .toList(),
                    cost: {
                      'shipping': 100,
                      'tax': 0,
                      'total': getTotal(sellerItems).toStringAsFixed(2),
                    },
                  );
                }

                final buyer = FirebaseAuth.instance.currentUser;
                final buyerEmail = buyer?.email ?? '';
                final buyerNameSnapshot =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get();
                final buyerName = buyerNameSnapshot['username'] ?? 'Buyer';

                await sendOrderToBuyer(
                  toEmail: buyerEmail,
                  buyerName: buyerName,
                  orderId: DateTime.now().millisecondsSinceEpoch.toString(),
                  orders:
                      items
                          .map(
                            (item) => {
                              'name': item['title'],
                              'price': item['price'],
                              'units': item['quantity'],
                              'image_url': 'https://via.placeholder.com/64',
                            },
                          )
                          .toList(),
                  cost: {
                    'shipping': 100,
                    'tax': 0,
                    'total': getTotal(items).toStringAsFixed(2),
                  },
                  shippingAddress: address,
                );

                Future.delayed(Duration.zero, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checkout confirmed! Email sent.'),
                    ),
                  );
                });

                final cartRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('cart');
                final cartDocs = await cartRef.get();
                for (var doc in cartDocs.docs) {
                  await doc.reference.delete();
                }

                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print("🛒 DEBUG - initialItems: ${widget.initialItems}");
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future:
            widget.initialItems != null
                ? Future.value(widget.initialItems!)
                : fetchCartItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cartItems = snapshot.data ?? [];

          if (cartItems.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...cartItems.map(
                (item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(item['title']),
                    subtitle: Text('Price: Rs ${item['price']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed:
                              () => updateQuantity(
                                item['bookId'],
                                item['quantity'],
                                -1,
                              ),
                        ),
                        Text('${item['quantity']}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed:
                              () => updateQuantity(
                                item['bookId'],
                                item['quantity'],
                                1,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeItem(item['bookId']),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Total: Rs ${getTotal(cartItems).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _checkout(cartItems),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                ),
                child: const Text('Proceed to Checkout'),
              ),
            ],
          );
        },
      ),
    );
  }
}
