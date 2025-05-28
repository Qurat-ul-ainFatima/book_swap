import 'package:flutter/material.dart';
import 'my_cart.dart';
import 'LikedBooksScreen .dart';
import 'menu.dart';
import 'selling_page.dart';
import 'home_screen.dart';

class MainScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF23D7BC),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF23D7BC),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SellingPage()),
          );
        },
        child: const Icon(Icons.sell, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.home,
                    color: currentIndex == 0 ? const Color(0xFF23D7BC) : Colors.grey),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.shopping_cart,
                    color: currentIndex == 1 ? const Color(0xFF23D7BC) : Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCart()),
                  );
                },
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: Icon(Icons.favorite,
                    color: currentIndex == 2 ? const Color(0xFF23D7BC) : Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LikedBooksScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.menu,
                    color: currentIndex == 3 ? const Color(0xFF23D7BC) : Colors.grey),
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
