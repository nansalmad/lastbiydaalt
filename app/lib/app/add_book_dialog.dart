import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddBookDialog extends StatefulWidget {
  final VoidCallback onBookAdded;
  const AddBookDialog({super.key, required this.onBookAdded});

  @override
  State<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final authorCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? photoBase64;
  bool loading = false;

  Future<void> pickAndConvertImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        photoBase64 = base64Encode(bytes);
      });
    } else {
      // User canceled picking image
    }
  }

  Future<void> addBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final url = Uri.parse('http://localhost:3000/api/books');
    final body = json.encode({
      'title': titleCtrl.text,
      'author': authorCtrl.text,
      'description': descCtrl.text,
      'price': double.tryParse(priceCtrl.text) ?? 0.0,
      'stock': int.tryParse(stockCtrl.text) ?? 0,
      'photo_base64': photoBase64 ?? '',
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 201) {
        widget.onBookAdded();
        Navigator.pop(context);
      } else {
        // handle error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add book')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Book'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: authorCtrl,
                decoration: const InputDecoration(labelText: 'Author'),
                validator: (v) => v!.isEmpty ? 'Enter author' : null,
              ),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator:
                    (v) =>
                        double.tryParse(v ?? '') == null
                            ? 'Enter valid price'
                            : null,
              ),
              TextFormField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator:
                    (v) =>
                        int.tryParse(v ?? '') == null
                            ? 'Enter valid stock'
                            : null,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickAndConvertImage,
                child: Text(
                  photoBase64 == null ? 'Pick Image' : 'Change Image',
                ),
              ),
              if (photoBase64 != null)
                SizedBox(
                  height: 100,
                  child: Image.memory(base64Decode(photoBase64!)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: loading ? null : addBook,
          child:
              loading ? const CircularProgressIndicator() : const Text('Add'),
        ),
      ],
    );
  }
}
