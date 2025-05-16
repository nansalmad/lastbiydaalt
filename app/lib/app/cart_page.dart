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
  bool placingOrder = false;

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

  Future<void> updateQuantity(int bookId, int change) async {
    // change = +1 or -1
    final url = Uri.parse('http://localhost:3000/api/cart/add');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.userId,
          'bookId': bookId,
          'quantity': change, // Always 1 or -1
        }),
      );
      if (response.statusCode == 200) {
        await fetchCartItems(); // Refresh cart
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update quantity')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating quantity')));
    }
  }

  Future<void> removeItem(int bookId) async {
    final url = Uri.parse('http://localhost:3000/api/cart/remove');
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': widget.userId, 'bookId': bookId}),
      );
      if (response.statusCode == 200) {
        await fetchCartItems();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove item')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing item')));
    }
  }

  double getTotalPrice() {
    double total = 0;
    for (var item in cartItems) {
      final price = double.tryParse(item['price'].toString()) ?? 0;
      final quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  Future<void> placeOrder() async {
    setState(() {
      placingOrder = true;
    });
    final url = Uri.parse('http://localhost:3000/api/orders/place');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': widget.userId}),
      );

      if (response.statusCode == 201) {
        setState(() {
          cartItems = [];
          placingOrder = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order placed successfully!')));
      } else {
        setState(() {
          placingOrder = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to place order')));
      }
    } catch (e) {
      setState(() {
        placingOrder = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error placing order')));
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
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final quantity = item['quantity'] ?? 1;
                        final price =
                            double.tryParse(item['price'].toString()) ?? 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Author: ${item['author'] ?? 'Unknown'}'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed:
                                          quantity > 1
                                              ? () =>
                                                  updateQuantity(item['id'], -1)
                                              : null,
                                    ),
                                    Text(
                                      quantity.toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed:
                                          () => updateQuantity(item['id'], 1),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => removeItem(item['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Text(
                              '\$${(price * quantity).toStringAsFixed(2)}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: \$${getTotalPrice().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              cartItems.isEmpty || placingOrder
                                  ? null
                                  : showPaymentDialog,
                          child:
                              placingOrder
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text('Place Order'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  void showPaymentDialog() {
    final _formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    String selectedPaymentMethod = 'Card'; // Default payment method

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> handlePlaceOrder() async {
              if (selectedPaymentMethod == 'Card' &&
                  !_formKey.currentState!.validate())
                return;

              setState(() {
                loading = true;
              });

              await placeOrder();

              setState(() {
                loading = false;
              });

              Navigator.of(context).pop();
            }

            Widget paymentFields() {
              switch (selectedPaymentMethod) {
                case 'Card':
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStyledTextField(
                          controller: cardNumberController,
                          label: 'Card Number',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.length < 16) {
                              return 'Please enter a valid card number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildStyledTextField(
                          controller: expiryController,
                          label: 'Expiry Date (MM/YY)',
                          keyboardType: TextInputType.datetime,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter expiry date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildStyledTextField(
                          controller: cvvController,
                          label: 'CVV',
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.length < 3) {
                              return 'Please enter CVV';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  );
                case 'QR':
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan the QR code using your banking app to complete the payment.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                default:
                  return const SizedBox.shrink();
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed:
                        loading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPaymentMethod,
                          items:
                              <String>['Card', 'QR'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                );
                              }).toList(),
                          onChanged: (newMethod) {
                            setState(() {
                              selectedPaymentMethod = newMethod!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    paymentFields(),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : handlePlaceOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child:
                      loading
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper widget to create styled TextFields
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
