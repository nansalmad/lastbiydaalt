import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrdersPage extends StatefulWidget {
  final int userId;
  const OrdersPage({super.key, required this.userId});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    // Replace with your computer's local IP if testing on device/emulator
    final apiHost = 'localhost'; // <<<< CHANGE THIS to your actual IP address
    final url = Uri.parse('http://$apiHost:3000/api/orders/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      print('Fetch orders error: $e');
      setState(() {
        loading = false;
      });
    }
  }

  Widget base64ImageWidget(String base64Str) {
    if (base64Str.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
        ),
      );
    }
    try {
      String cleanedBase64 = base64Str;
      if (cleanedBase64.startsWith('data:image')) {
        cleanedBase64 = cleanedBase64.split(',').last;
      }
      final bytes = base64Decode(cleanedBase64);
      return Image.memory(bytes, width: 50, height: 50, fit: BoxFit.cover);
    } catch (e) {
      print('Base64 decode error: $e');
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        centerTitle: true,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : orders.isEmpty
              ? Center(
                child: Text(
                  'No orders found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final items = order['items'] as List<dynamic>? ?? [];
                  final date =
                      DateTime.tryParse(order['created_at'] ?? '') ??
                      DateTime.now();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      backgroundColor: Colors.white,
                      collapsedBackgroundColor: Colors.grey[100],
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order['id']}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple[700],
                            ),
                          ),
                          Text(
                            '${date.toLocal().toString().split(' ')[0]}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      children:
                          items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: base64ImageWidget(
                                    item['photo_base64'] ?? '',
                                  ),
                                ),
                                title: Text(
                                  item['title'] ?? 'No title',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Author: ${item['author'] ?? "Unknown"}\nQuantity: ${item['quantity'] ?? 0}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                trailing: Text(
                                  '\$${(item['price'] != null ? double.tryParse(item['price'].toString())?.toStringAsFixed(2) : '0.00')}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  );
                },
              ),
    );
  }
}
