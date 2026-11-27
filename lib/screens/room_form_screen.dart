import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/room_api.dart';

// Formulario para crear (POST) o editar (PUT) una habitación.
// Devuelve true al cerrar si se guardó algo, para que el catálogo recargue.
class RoomFormScreen extends StatefulWidget {
  final Room? room; // null = nueva habitación
  final Map<int, String> hotels; // {idHotel: nombre}

  const RoomFormScreen({super.key, this.room, required this.hotels});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = RoomApi();

  late final TextEditingController _numeroCtrl;
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _imageCtrl;
  int? _idHotel;
  bool _saving = false;

  bool get _isEdit => widget.room != null;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _numeroCtrl = TextEditingController(text: r?.numeroHabitacion ?? '');
    _tipoCtrl = TextEditingController(text: r?.tipoHabitacion ?? '');
    _precioCtrl = TextEditingController(
        text: r != null ? r.precio.toStringAsFixed(2) : '');
    _stockCtrl = TextEditingController(text: r != null ? '${r.stock}' : '');
    _imageCtrl = TextEditingController(text: r?.imageUrl ?? '');
    _idHotel = r?.idHotel ??
        (widget.hotels.isNotEmpty ? widget.hotels.keys.first : null);
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _tipoCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required field' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final room = Room(
      numeroHabitacion: _numeroCtrl.text.trim(),
      tipoHabitacion: _tipoCtrl.text.trim(),
      idHotel: _idHotel,
      imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
      precio: double.parse(_precioCtrl.text.trim()),
      stock: int.parse(_stockCtrl.text.trim()),
    );

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (_isEdit) {
        await _api.updateRoom(widget.room!.idHabitacion!, room); // PUT
      } else {
        await _api.createRoom(room); // POST
      }
      messenger.showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Room updated' : 'Room created'),
        backgroundColor: Colors.green,
      ));
      navigator.pop(true);
    } on ServerUnavailableException {
      messenger.showSnackBar(const SnackBar(
        content: Text('Server unavailable. Please try again.'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit room' : 'New room'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vista previa de la imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _imageCtrl.text.trim().isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 48),
                          )
                        : Image.network(
                            _imageCtrl.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numeroCtrl,
                  decoration: _decoration('Room number', Icons.tag),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tipoCtrl,
                  decoration:
                      _decoration('Type (Single, Double, Suite...)', Icons.category),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _idHotel,
                  decoration: _decoration('Hotel', Icons.hotel),
                  items: widget.hotels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _idHotel = v),
                  validator: (v) => v == null ? 'Choose a hotel' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('Price per night', Icons.attach_money),
                  validator: (v) {
                    if (_required(v) != null) return 'Required field';
                    final n = double.tryParse(v!.trim());
                    if (n == null || n < 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Available stock', Icons.inventory_2),
                  validator: (v) {
                    if (_required(v) != null) return 'Required field';
                    final n = int.tryParse(v!.trim());
                    if (n == null || n < 0) return 'Enter a whole number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageCtrl,
                  keyboardType: TextInputType.url,
                  decoration: _decoration('Image URL (Supabase)', Icons.link),
                  onChanged: (_) => setState(() {}), // refresca la vista previa
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isEdit ? 'Save changes' : 'Create room'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}