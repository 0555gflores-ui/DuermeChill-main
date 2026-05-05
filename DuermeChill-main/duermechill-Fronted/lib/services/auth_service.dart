import 'dart:convert';
import 'package:proyecto_intermodular/services/datos_service.dart';
import 'package:http/http.dart' as http;
import 'config_api.dart';

class AuthService {
  static Future<bool> registrarUsuario(String nombre, String edad, String correo, String contrasena) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${ConfigApi.urlServidor}/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre, 'edad': int.parse(edad), 'correo': correo, 'contrasena': contrasena}),
      );
      return respuesta.statusCode == 200;
    } catch (e) {
      print("Error en registro: $e");
      return false;
    }
  }

  static Future<bool> iniciarSesion(String nombre, String contrasena) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${ConfigApi.urlServidor}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre, 'contrasena': contrasena}),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        ConfigApi.usuarioActual = datos['usuario']['nombre'];
        
        var valorEncuesta = datos['usuario']['encuesta_completada'];
        ConfigApi.encuestaCompletada = (valorEncuesta == 1 || valorEncuesta == true);
        
        await DatosService.sincronizarDatosDesdeServidor();
        return true;
      }
      return false;
    } catch (e) {
      print("Error en login: $e");
      return false;
    }
  }

  static void cerrarSesion() {
    ConfigApi.usuarioActual = null;
    ConfigApi.datosUsuarioCache = null;
  }
}