import 'package:flutter/material.dart';
import '../services/config_api.dart';
import 'users/pantalla_estadisticas.dart';
import 'users/pantalla_registro_datos.dart';
import 'users/pantalla_alarmas.dart';
import 'users/pantalla_coach.dart'; 
import '../widgets/mi_drawer.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedIndex = 0;

  final List<Widget> _pantallas = [
    const PantallaYo(),
    const PantallaEstadisticas(),
    const PantallaRegistroDatos(),
    const PantallaAlarmas(),
    const PantallaCoach(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pantallas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, 
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        selectedItemColor: const Color(0xFF6EADD8),
        unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Yo'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Registro'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarmas'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Coach'), 
        ],
      ),
    );
  }
}

class PantallaYo extends StatelessWidget {
  const PantallaYo({super.key});

  @override
  Widget build(BuildContext context) {
    String nombreUsuario = ConfigApi.usuarioActual ?? "Usuario";
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final avatarRadius = screenSize.width > 600 ? 80.0 : (screenSize.width > 400 ? 60.0 : 50.0);
    final titleFontSize = screenSize.width > 600 ? 36.0 : (screenSize.width > 400 ? 30.0 : 24.0);
    final subtitleFontSize = screenSize.width > 400 ? 16.0 : 14.0;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        backgroundColor: const Color(0xFF6EADD8),
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MiDrawer(), 
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: avatarRadius, 
                backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0), 
                child: Icon(Icons.person, size: avatarRadius * 1.2, color: Colors.white)
              ),
              SizedBox(height: screenSize.height > 800 ? 30 : 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '¡Hola, $nombreUsuario!', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: titleFontSize, color: isDark ? Colors.white : const Color(0xFF2A3F54), fontWeight: FontWeight.bold)
                ),
              ),
              SizedBox(height: screenSize.height > 800 ? 15 : 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '¿Listo para mejorar tu sueño hoy?', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: subtitleFontSize, color: isDark ? Colors.white70 : Colors.black54)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}