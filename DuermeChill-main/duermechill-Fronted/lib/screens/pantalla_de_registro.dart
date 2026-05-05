import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/config_api.dart';
import '../widgets/entrada_de_texto.dart'; 
import 'users/pantalla_encuesta.dart'; 

class PantallaDeRegistro extends StatefulWidget {
  const PantallaDeRegistro({super.key});

  @override
  State<PantallaDeRegistro> createState() => _PantallaDeRegistroState();
}

class _PantallaDeRegistroState extends State<PantallaDeRegistro> {
  final _controladorNombre = TextEditingController();
  final _controladorEdad = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();

  Future<void> _guardarUsuario() async {
    if (_controladorNombre.text.isNotEmpty && _controladorContrasena.text.isNotEmpty) {
      
      bool guardado = await AuthService.registrarUsuario(
        _controladorNombre.text,
        _controladorEdad.text,
        _controladorCorreo.text,
        _controladorContrasena.text,
      );
      
      if (!mounted) return;
      
      if (guardado) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Usuario guardado correctamente!')));
        ConfigApi.usuarioActual = _controladorNombre.text;
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PantallaEncuesta()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa al menos nombre y contraseña')));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width > 600 ? 80.0 : (screenSize.width > 400 ? 40.0 : 24.0);
    final titleFontSize = screenSize.width > 600 ? 60.0 : (screenSize.width > 400 ? 55.0 : 45.0);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Registro', style: TextStyle(fontSize: titleFontSize, color: const Color(0xFF6EADD8), fontWeight: FontWeight.w400)),
              SizedBox(height: screenSize.height > 800 ? 50 : 30),
              EntradaDeTexto(textoIndicador: 'Nombre:', controlador: _controladorNombre),
              EntradaDeTexto(textoIndicador: 'Edad:', controlador: _controladorEdad),
              EntradaDeTexto(textoIndicador: 'Correo:', controlador: _controladorCorreo),
              EntradaDeTexto(textoIndicador: 'Contraseña:', controlador: _controladorContrasena, ocultarTexto: true),
              SizedBox(height: screenSize.height > 800 ? 30 : 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Atrás', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
                    ),
                  ),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _guardarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF333333),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Registrarse', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}