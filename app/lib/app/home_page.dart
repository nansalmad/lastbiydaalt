import 'package:app/app/add_book_dialog.dart';
import 'package:app/app/book_detail_page.dart';
import 'package:app/app/cart_page.dart';
import 'package:app/app/orders_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final int userId;

  const HomePage({super.key, required this.userName, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> books = [];
  bool loading = true;
  int cartCount = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchBooks();
    fetchCartCount();
  }

  Future<void> fetchBooks() async {
    final url = Uri.parse('http://localhost:3000/api/books');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          books = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
        print('Failed to fetch books. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      print('Error fetching books: $e');
    }
  }

  Future<void> fetchCartCount() async {
    final url = Uri.parse(
      'http://localhost:3000/api/cart/count/${widget.userId}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cartCount = data['count'] ?? 0;
        });
      } else {
        print('Failed to fetch cart count. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching cart count: $e');
    }
  }

  Future<void> addToCart(int bookId, {int quantity = 1}) async {
    final url = Uri.parse('http://localhost:3000/api/cart/add');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.userId,
          'bookId': bookId,
          'quantity': quantity,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Book added to cart')));
        fetchCartCount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add book to cart')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error adding to cart')));
      print('Error adding to cart: $e');
    }
  }

  Widget buildCarousel() {
    if (books.isEmpty) return const SizedBox.shrink();
    // Take first 5 books or less for carousel
    final featuredBooks = books.take(5).toList();

    return SizedBox(
      height: 400,
      child: CarouselSlider.builder(
        itemCount: featuredBooks.length,
        itemBuilder: (context, index, realIndex) {
          final book = featuredBooks[index];
          return GestureDetector(
            onTap: () {
              if (book['id'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BookDetailPage(
                          bookId: book['id'],
                          userId: widget.userId,
                        ),
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image:
                    book['photo_base64'] != null
                        ? DecorationImage(
                          image: MemoryImage(
                            base64Decode(book['photo_base64']),
                          ),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
                          ),
                        )
                        : null,
                color: Colors.grey.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    book['title'] ?? 'No title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        options: CarouselOptions(
          height: 380,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.75,
        ),
      ),
    );
  }

  Widget buildBooksList() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (books.isEmpty) {
      return const Center(child: Text('No books available'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final bookId = book['id'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (bookId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BookDetailPage(
                          bookId: bookId,
                          userId: widget.userId,
                        ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (book['photo_base64'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(book['photo_base64']),
                        width: 70,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 70,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.book,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['title'] ?? 'No title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book['author'] ?? 'Unknown author',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${(book['price'] != null ? double.tryParse(book['price'].toString())?.toStringAsFixed(2) : '0.00') ?? '0.00'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.blueAccent,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () {
                                if (bookId != null) {
                                  addToCart(bookId);
                                }
                              },
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pages to switch between
    final pages = [
      Scaffold(
        appBar: AppBar(
          title: Text('Welcome, ${widget.userName}'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),
            buildCarousel(),
            const SizedBox(height: 12),
            Expanded(child: buildBooksList()),
          ],
        ),
        floatingActionButton:
            _selectedIndex == 0
                ? FloatingActionButton(
                  onPressed:
                      () => showDialog(
                        context: context,
                        builder:
                            (context) => AddBookDialog(
                              onBookAdded: () {
                                fetchBooks();
                              },
                            ),
                      ),
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.add),
                )
                : null,
      ),
      Scaffold(body: CartPage(userId: widget.userId)),
      Scaffold(body: OrdersPage(userId: widget.userId)),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: WaterDropNavBar(
        backgroundColor: Colors.white,
        waterDropColor: Colors.blueAccent,
        onItemSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            fetchCartCount(); // Refresh cart count if needed when switching tab
          }
        },
        selectedIndex: _selectedIndex,
        barItems: [
          BarItem(filledIcon: Icons.book, outlinedIcon: Icons.book_outlined),
          BarItem(
            filledIcon: Icons.shopping_cart,
            outlinedIcon: Icons.shopping_cart_outlined,
          ),
          BarItem(
            filledIcon: Icons.history,
            outlinedIcon: Icons.history_outlined,
          ),
        ],
      ),
    );
  }
}
