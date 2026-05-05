import 'package:flutter/material.dart';
import '/services/config_api.dart';
import '../services/auth_service.dart';
import '../screens/pantalla_login.dart';

class MiDrawer extends StatelessWidget {
  const MiDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    String nombreUsuario = ConfigApi.usuarioActual ?? "Usuario";
    // Detectamos si el modo oscuro está activo
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF6EADD8)),
            accountName: Text(nombreUsuario, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            accountEmail: const Text('DuermeChill Premium', style: TextStyle(color: Colors.white70)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF6EADD8)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.language, color: isDark ? Colors.white70 : Colors.black54),
            title: Text('Cambiar Idioma', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            trailing: const Text('ES', style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Idiomas próximamente...')));
            },
          ),
          ListTile(
            leading: Icon(Icons.dark_mode, color: isDark ? Colors.white70 : Colors.black54),
            title: Text('Modo Oscuro', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            trailing: ValueListenableBuilder<bool>(
              valueListenable: ConfigApi.isDarkMode,
              builder: (context, modoOscuro, child) {
                return Switch(
                  value: modoOscuro,
                  activeColor: const Color(0xFF6EADD8),
                  onChanged: (val) {
                    ConfigApi.cambiarTema(val);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              AuthService.cerrarSesion();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const PantallaLogin()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}