import 'dart:convert';
import 'package:app/model/book_model.dart';
import 'package:http/http.dart' as http;

Future<List<Book>> fetchBooks() async {
  final res = await http.get(Uri.parse('http://localhost:3000/api/books'));

  if (res.statusCode == 200) {
    List<dynamic> jsonList = jsonDecode(res.body);
    return jsonList.map((json) => Book.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load books');
  }
}
