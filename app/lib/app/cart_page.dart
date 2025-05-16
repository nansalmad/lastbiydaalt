import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CartPage extends StatefulWidget {
  final int userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> cartItems = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final url = Uri.parse('http://localhost:3000/api/cart/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          cartItems = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return ListTile(
                    leading:
                        item['photo_base64'] != null
                            ? Image.memory(
                              base64Decode(item['photo_base64']),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : null,
                    title: Text(item['title'] ?? 'No title'),
                    subtitle: Text(
                      'Author: ${item['author']}\nQuantity: ${item['quantity']}',
                    ),
                    trailing: Text(
                      '\$${(item['price'] ?? 0).toStringAsFixed(2)}',
                    ),
                  );
                },
              ),
    );
  }
}
