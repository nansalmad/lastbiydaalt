import 'package:app/app/add_book_dialog.dart';
import 'package:app/app/book_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    fetchBooks();
    fetchCartCount();
  }

  Future<void> fetchBooks() async {
    final url = Uri.parse(
      'http://localhost:3000/api/books',
    ); // Android emulator fix
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

  Future<void> addToCart(int bookId) async {
    final url = Uri.parse('http://localhost:3000/api/cart/add');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId, 'book_id': bookId}),
      );
      print('Add to cart status: ${response.statusCode}');
      print('Response body: ${response.body}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.userName}'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // TODO: Navigate to cart page
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : books.isEmpty
              ? const Center(child: Text('No books available'))
              : ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final bookId = book['id'];
                  return ListTile(
                    leading:
                        book['photo_base64'] != null
                            ? Image.memory(
                              base64Decode(book['photo_base64']),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : null,
                    title: Text(book['title'] ?? 'No title'),
                    subtitle: Text(book['author'] ?? 'Unknown author'),
                    trailing: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '\$${(book['price'] != null ? double.tryParse(book['price'].toString())?.toStringAsFixed(2) : '0.00') ?? '0.00'}',
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            if (bookId != null) {
                              addToCart(bookId);
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      if (bookId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => BookDetailPage(bookId: bookId),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
