import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl =
    'http://localhost:3000/api'; // change to your backend URL

Future<Map<String, dynamic>> registerUser(
  String name,
  String email,
  String password,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'name': name, 'email': email, 'password': password}),
  );
  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> loginUser(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  return jsonDecode(response.body);
}
