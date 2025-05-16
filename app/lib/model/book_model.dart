class Book {
  final int id;
  final String title;
  final String author;
  final String description;
  final double price;
  final int stock;
  final String photoBase64;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.price,
    required this.stock,
    required this.photoBase64,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      price: json['price'].toDouble(),
      stock: json['stock'],
      photoBase64: json['photo_base64'],
    );
  }
}
