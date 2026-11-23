import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// C. Cerrar sesión
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  // 6.1 URL base de hotel-backend (Spring Boot usa el puerto 8080 por defecto)
  // - Web / iOS Simulator / macOS: http://localhost:8080
  // - Emulador Android: http://10.0.2.2:8080
  // - Celular físico: http://IP_DE_TU_PC:8080
  static const String baseUrl = 'http://localhost:8080';

  // Pide una lista a la API y la convierte de JSON a List
  Future<List<dynamic>> _getList(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Error ${response.statusCode} al cargar $path');
  }

  // 6.2 Pide habitaciones y hoteles al mismo tiempo, para mostrar el nombre del hotel
  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final results = await Future.wait([
      _getList('/api/habitaciones'),
      _getList('/api/hoteles'),
    ]);
    final rooms = results[0];
    final hotels = {for (final h in results[1]) h['idHotel']: h['nombre']};

    return rooms
        .map<Map<String, dynamic>>((r) => {
              'numero': r['numeroHabitacion'],
              'tipo': r['tipoHabitacion'],
              'hotel': hotels[r['idHotel']] ?? 'Hotel ${r['idHotel']}',
              // Hito 2 A. URL pública de Supabase Storage guardada en PostgreSQL
              'imageUrl': r['imageUrl'],
            })
        .toList();
  }

  // Hito 2 A. Imagen de la habitación desde Supabase, con errorBuilder si falla
  Widget _roomImage(String? url) {
    const placeholder = SizedBox(
      width: 64,
      height: 64,
      child: Icon(Icons.bed, size: 32, color: Colors.grey),
    );

    if (url == null || url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        // Mientras descarga, un circulito
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        // Si la URL está mal o no carga, ícono de imagen rota
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          width: 64,
          height: 64,
          child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitaciones'),
        actions: [
          // C. Cerrar sesión: signOut y regresar al LoginScreen sin poder volver atrás
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      // 6.3 FutureBuilder: espera la respuesta de la API y dibuja el resultado
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rooms = snapshot.data ?? [];

          // 6.4 Lista de habitaciones: imagen, número, tipo (categoría) y hotel
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ListTile(
                leading: _roomImage(room['imageUrl'] as String?),
                title: Text('Habitación ${room['numero']}'),
                subtitle: Text('Tipo: ${room['tipo']}\nHotel: ${room['hotel']}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}