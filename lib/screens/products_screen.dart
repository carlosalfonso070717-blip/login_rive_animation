import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// C. Cerrar sesión
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../models/room.dart';
import '../services/room_api.dart';
import 'room_form_screen.dart';

// Catálogo de habitaciones: tarjetas en GridView, buscador, filtros por tipo,
// CRUD conectado a Spring Boot y vista "Server unavailable" con Retry.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _api = RoomApi();
  final _searchCtrl = TextEditingController();
  final _money = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  List<Room> _rooms = [];
  Map<int, String> _hotels = {};
  bool _loading = true;
  bool _serverDown = false;
  String? _error;

  String _query = '';
  String? _selectedType; // null = "All"

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // GET de habitaciones y hoteles (también lo usa el botón "Retry")
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _serverDown = false;
      _error = null;
    });
    try {
      final results = await Future.wait([_api.getRooms(), _api.getHotels()]);
      if (!mounted) return;
      setState(() {
        _rooms = results[0] as List<Room>;
        _hotels = results[1] as Map<int, String>;
        _loading = false;
      });
    } on ServerUnavailableException {
      if (!mounted) return;
      setState(() {
        _serverDown = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  // Tipos únicos para los chips de filtro
  List<String> get _types {
    final set = _rooms.map((r) => r.tipoHabitacion).toSet().toList();
    set.sort();
    return set;
  }

  // Aplica buscador (número, tipo u hotel) + chip de tipo seleccionado
  List<Room> get _filteredRooms {
    final q = _query.trim().toLowerCase();
    return _rooms.where((r) {
      final hotel = (_hotels[r.idHotel] ?? '').toLowerCase();
      final matchesQuery = q.isEmpty ||
          r.numeroHabitacion.toLowerCase().contains(q) ||
          r.tipoHabitacion.toLowerCase().contains(q) ||
          hotel.contains(q);
      final matchesType =
          _selectedType == null || r.tipoHabitacion == _selectedType;
      return matchesQuery && matchesType;
    }).toList();
  }

  Future<void> _openForm([Room? room]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomFormScreen(room: room, hotels: _hotels),
      ),
    );
    if (saved == true) _loadData();
  }

  Future<void> _confirmDelete(Room room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete room'),
        content: Text(
            'Are you sure you want to delete room ${room.numeroHabitacion}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.deleteRoom(room.idHabitacion!); // DELETE
      messenger.showSnackBar(const SnackBar(
        content: Text('Room deleted'),
        backgroundColor: Colors.green,
      ));
      _loadData();
    } on ServerUnavailableException {
      messenger.showSnackBar(
          const SnackBar(content: Text('Server unavailable')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          // C. Cerrar sesión: signOut y regresar al LoginScreen sin poder volver atrás
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: (_loading || _serverDown)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('New'),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_serverDown) {
      return _ServerDownView(onRetry: _loadData);
    }
    if (_error != null) {
      return _ServerDownView(onRetry: _loadData, message: _error);
    }

    final rooms = _filteredRooms;

    return Column(
      children: [
        // Buscador
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by number, type or hotel',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              isDense: true,
            ),
          ),
        ),
        // Chips de categoría (tipo de habitación)
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedType == null,
                  onSelected: (_) => setState(() => _selectedType = null),
                ),
              ),
              for (final type in _types)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: _selectedType == type,
                    onSelected: (_) => setState(() =>
                        _selectedType = _selectedType == type ? null : type),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: rooms.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No matching rooms')),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      // Altura fija: la imagen ocupa lo que sobra y el texto nunca se desborda
                      mainAxisExtent: 320,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return _RoomCard(
                        room: room,
                        hotelName: _hotels[room.idHotel] ?? 'Hotel ${room.idHotel}',
                        price: _money.format(room.precio),
                        onEdit: () => _openForm(room),
                        onDelete: () => _confirmDelete(room),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// Tarjeta de una habitación
class _RoomCard extends StatelessWidget {
  final Room room;
  final String hotelName;
  final String price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomCard({
    required this.room,
    required this.hotelName,
    required this.price,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen desde Supabase (imageUrl) con errorBuilder
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _RoomImage(url: room.imageUrl),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.white70,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: onDelete,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room ${room.numeroHabitacion}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hotelName,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Categoría
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      room.tipoHabitacion,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Precio formateado
                  Text(
                    '$price / night',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StockBadge(stock: room.stock),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Indicador de stock: "Low stock" en naranja si stock < 50
class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;
    if (stock == 0) {
      color = Colors.red;
      text = 'Sold out';
    } else if (stock < 50) {
      color = Colors.orange;
      text = 'Low stock ($stock)';
    } else {
      color = Colors.green;
      text = 'Stock: $stock';
    }
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Imagen con loading y errorBuilder
class _RoomImage extends StatelessWidget {
  final String? url;
  const _RoomImage({this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.bed, size: 40, color: Colors.grey),
    );
    if (url == null || url!.isEmpty) return placeholder;

    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }
}

// Vista amigable cuando Spring Boot está apagado
class _ServerDownView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  const _ServerDownView({required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Server unavailable',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'We could not reach the server. Make sure Spring Boot is running and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}