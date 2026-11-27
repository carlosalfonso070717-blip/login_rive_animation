import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/room.dart';

// Error de red: el servidor está apagado o no se puede alcanzar
class ServerUnavailableException implements Exception {
  @override
  String toString() => 'Server unavailable';
}

class RoomApi {
  // URL base de hotel-backend:
  // - Emulador Android: 10.0.2.2 apunta a la computadora donde corre Spring Boot
  // - Web / iOS Simulator / escritorio: localhost
  // - Celular físico: cambia por la IP de tu PC (ej. http://192.168.1.50:8080)
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const _timeout = Duration(seconds: 8);
  static const _jsonHeaders = {'Content-Type': 'application/json'};

  // Envuelve cada petición: si no hay conexión, lanza ServerUnavailableException
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } catch (e) {
      debugPrint('Network error: $e');
      throw ServerUnavailableException();
    }
  }

  // GET /api/habitaciones
  Future<List<Room>> getRooms() async {
    final res = await _send(() => http.get(Uri.parse('$baseUrl/api/habitaciones')));
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} loading rooms');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/hoteles -> {idHotel: nombre}
  Future<Map<int, String>> getHotels() async {
    final res = await _send(() => http.get(Uri.parse('$baseUrl/api/hoteles')));
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} loading hotels');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return {
      for (final h in list)
        (h['idHotel'] as num).toInt(): (h['nombre'] ?? '').toString(),
    };
  }

  // POST /api/habitaciones
  Future<Room> createRoom(Room room) async {
    final res = await _send(() => http.post(
          Uri.parse('$baseUrl/api/habitaciones'),
          headers: _jsonHeaders,
          body: jsonEncode(room.toJson()),
        ));
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} creating the room');
    }
    return Room.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // PUT /api/habitaciones/{id}
  Future<Room> updateRoom(int id, Room room) async {
    final res = await _send(() => http.put(
          Uri.parse('$baseUrl/api/habitaciones/$id'),
          headers: _jsonHeaders,
          body: jsonEncode(room.toJson()),
        ));
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} updating the room');
    }
    return Room.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // DELETE /api/habitaciones/{id}
  Future<void> deleteRoom(int id) async {
    final res = await _send(
        () => http.delete(Uri.parse('$baseUrl/api/habitaciones/$id')));
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} deleting the room');
    }
  }
}