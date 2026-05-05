import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_api.dart';

class CoachService {
  static Future<List<Map<String, dynamic>>> obtenerSesionesCoach() async {
    if (ConfigApi.usuarioActual == null) return [];
    try {
      final respuesta = await http.get(Uri.parse('${ConfigApi.urlServidor}/coach/${ConfigApi.usuarioActual}/sesiones'));
      if (respuesta.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(respuesta.body));
      }
    } catch (e) {
      print("Error obteniendo sesiones AI: $e");
    }
    return [];
  }

  static Future<List<Map<String, String>>> obtenerMensajesSesion(String sessionId) async {
    if (ConfigApi.usuarioActual == null) return [];
    try {
      final respuesta = await http.get(Uri.parse('${ConfigApi.urlServidor}/coach/${ConfigApi.usuarioActual}/sesion/$sessionId'));
      if (respuesta.statusCode == 200) {
        final List datos = jsonDecode(respuesta.body);
        return datos.map((m) => {"rol": m["rol"].toString(), "texto": m["texto"].toString()}).toList();
      }
    } catch (e) {
      print("Error obteniendo chat AI: $e");
    }
    return [];
  }

  static Future<void> guardarMensajeCoach(String rol, String texto, String sessionId) async {
    if (ConfigApi.usuarioActual == null) return;
    try {
      await http.post(
        Uri.parse('${ConfigApi.urlServidor}/coach'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': ConfigApi.usuarioActual, 'rol': rol, 'texto': texto, 'session_id': sessionId}),
      );
    } catch (e) {
      print("Error guardando mensaje AI: $e");
    }
  }
}