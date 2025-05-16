import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookDetailPage extends StatefulWidget {
  final int bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  Map<String, dynamic>? book;
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    fetchBookDetail();
  }

  Future<void> fetchBookDetail() async {
    final url = Uri.parse('http://localhost:3000/api/books/${widget.bookId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          book = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          error = true;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          book != null ? book!['title'] ?? 'Book Detail' : 'Loading...',
        ),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error
              ? const Center(child: Text('Error loading book details'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    if (book?['photo_base64'] != null)
                      Image.memory(
                        base64Decode(book!['photo_base64']),
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      book?['title'] ?? 'No title',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Author: ${book?['author'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Price: \$${(book?['price'] != null ? double.tryParse(book!['price'].toString())?.toStringAsFixed(2) : '0.00') ?? '0.00'}',
                      style: const TextStyle(fontSize: 18, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stock: ${book?['stock'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      book?['description'] ?? 'No description available',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
    );
  }
}
