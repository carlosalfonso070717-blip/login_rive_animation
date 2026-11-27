import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';

// Pantalla de Configuración con el gafete de perfil del usuario autenticado
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM d, yyyy · HH:mm').format(date.toLocal());
  }

  // Proveedor con el que inició sesión (correo o Google)
  String _providerName(User user) {
    final ids = user.providerData.map((p) => p.providerId).toList();
    if (ids.contains('google.com')) return 'Google';
    if (ids.contains('password')) return 'Email and password';
    return ids.isEmpty ? 'Unknown' : ids.join(', ');
  }

  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: user == null
          ? const Center(child: Text('No user signed in'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileBadge(
                  user: user,
                  createdAt: _formatDate(user.metadata.creationTime),
                  lastSignIn: _formatDate(user.metadata.lastSignInTime),
                  provider: _providerName(user),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
    );
  }
}

// Gafete de perfil: foto o avatar, correo, UID y fecha de creación
class _ProfileBadge extends StatelessWidget {
  final User user;
  final String createdAt;
  final String lastSignIn;
  final String provider;

  const _ProfileBadge({
    required this.user,
    required this.createdAt,
    required this.lastSignIn,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = user.email ?? 'No email';
    final name = (user.displayName?.isNotEmpty ?? false)
        ? user.displayName!
        : email.split('@').first;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final photo = user.photoURL;

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          // Encabezado del gafete
          Container(
            width: double.infinity,
            color: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'PROFILE BADGE',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Foto de Google o avatar con la inicial
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundImage:
                      photo != null ? NetworkImage(photo) : null,
                  child: Text(
                    initial,
                    style: theme.textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(email, style: theme.textTheme.bodyMedium),
                const Divider(height: 32),
                _BadgeRow(
                  icon: Icons.fingerprint,
                  label: 'UID',
                  value: user.uid,
                  copyable: true,
                ),
                _BadgeRow(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: createdAt,
                ),
                _BadgeRow(
                  icon: Icons.access_time,
                  label: 'Last sign-in',
                  value: lastSignIn,
                ),
                _BadgeRow(
                  icon: Icons.verified_user,
                  label: 'Provider',
                  value: provider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _BadgeRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon),
      title: Text(label),
      subtitle: SelectableText(value),
      trailing: copyable
          ? IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('UID copied')),
                );
              },
            )
          : null,
    );
  }
}