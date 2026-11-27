// Modelo de una habitación tal como la devuelve hotel-backend
class Room {
  final int? idHabitacion;
  final String numeroHabitacion;
  final String tipoHabitacion;
  final int? idHotel;
  final String? imageUrl;
  final double precio;
  final int stock;

  const Room({
    this.idHabitacion,
    required this.numeroHabitacion,
    required this.tipoHabitacion,
    this.idHotel,
    this.imageUrl,
    required this.precio,
    required this.stock,
  });

  // JSON de Spring Boot -> objeto de Dart
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      idHabitacion: json['idHabitacion'] as int?,
      numeroHabitacion: (json['numeroHabitacion'] ?? '').toString(),
      tipoHabitacion: (json['tipoHabitacion'] ?? 'No type').toString(),
      idHotel: json['idHotel'] as int?,
      imageUrl: json['imageUrl'] as String?,
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  // Objeto de Dart -> JSON para POST / PUT
  Map<String, dynamic> toJson() {
    return {
      'numeroHabitacion': numeroHabitacion,
      'tipoHabitacion': tipoHabitacion,
      'idHotel': idHotel,
      'imageUrl': imageUrl,
      'precio': precio,
      'stock': stock,
    };
  }
}