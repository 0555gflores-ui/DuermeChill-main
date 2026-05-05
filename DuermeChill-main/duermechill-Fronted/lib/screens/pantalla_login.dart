import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/config_api.dart';
import 'admin/pantalla_admin.dart'; 
import '../widgets/entrada_de_texto.dart';
import 'pantalla_de_registro.dart';
import 'pantalla_principal.dart';
import 'users/pantalla_encuesta.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _controladorUsuario = TextEditingController();
  final _controladorContrasena = TextEditingController();

  void _intentarLogin() async {
    String usuario = _controladorUsuario.text;
    String contrasena = _controladorContrasena.text;

    if (usuario.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, rellena todos los campos')));
      return;
    }

    if (usuario == 'admin' && contrasena == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaAdmin()));
      return; 
    }

    bool exito = await AuthService.iniciarSesion(usuario, contrasena);

    if (!mounted) return;

    if (exito) {
      final historial = (ConfigApi.datosUsuarioCache?['historial_registros'] as List?) ?? [];
      if (historial.isEmpty) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaEncuesta()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaPrincipal()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario o contraseña incorrectos')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final horizontalPadding = screenSize.width > 600 ? 80.0 : (screenSize.width > 400 ? 40.0 : 24.0);
    final titleFontSize = screenSize.width > 600 ? 56.0 : (screenSize.width > 400 ? 50.0 : 40.0);
    final buttonWidth = screenSize.width > 600 ? 250.0 : (screenSize.width > 400 ? 200.0 : double.infinity);
    final buttonMaxWidth = screenSize.width - (horizontalPadding * 2) - 40;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DuermeChill',
                style: TextStyle(
                  fontSize: titleFontSize, 
                  color: const Color(0xFF3498DB), 
                  fontWeight: FontWeight.w400
                ),
              ),
              SizedBox(height: isLandscape ? 20 : 50),
              EntradaDeTexto(textoIndicador: 'Usuario:', controlador: _controladorUsuario),
              EntradaDeTexto(textoIndicador: 'Contraseña:', controlador: _controladorContrasena, ocultarTexto: true),
              SizedBox(height: isLandscape ? 10 : 20),
              SizedBox(
                width: buttonWidth > buttonMaxWidth ? buttonMaxWidth : buttonWidth, 
                child: ElevatedButton(
                  onPressed: _intentarLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              SizedBox(height: isLandscape ? 8 : 15),
              SizedBox(
                width: buttonWidth > buttonMaxWidth ? buttonMaxWidth : buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaDeRegistro()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222222), 
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Registrarse', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}