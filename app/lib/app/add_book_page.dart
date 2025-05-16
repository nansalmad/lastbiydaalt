import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final titleCtrl = TextEditingController();
  final authorCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController();

  String? base64Image;
  File? selectedImage;

  final picker = ImagePicker();

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        selectedImage = File(picked.path);
        base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> submit() async {
    final res = await http.post(
      Uri.parse('http://localhost:3000/api/books'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "title": titleCtrl.text,
        "author": authorCtrl.text,
        "description": descriptionCtrl.text,
        "price": double.parse(priceCtrl.text),
        "stock": int.parse(stockCtrl.text),
        "photo_base64": base64Image ?? '',
      }),
    );

    if (res.statusCode == 201) {
      Navigator.pop(context, true); // return to HomePage and trigger refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add book: ${res.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: authorCtrl,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              TextField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              selectedImage != null
                  ? Image.file(selectedImage!, height: 150)
                  : const Text('No image selected'),
              ElevatedButton(
                onPressed: pickImage,
                child: const Text('Pick Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: submit, child: const Text('Add Book')),
            ],
          ),
        ),
      ),
    );
  }
}
