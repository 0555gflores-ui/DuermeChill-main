import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_api.dart';

class AdminService {
  static Future<List<dynamic>> obtenerTodosLosUsuarios() async {
    try {
      final respuesta = await http.get(Uri.parse('${ConfigApi.urlServidor}/admin/usuarios'));
      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body);
      }
      return [];
    } catch (e) {
      print("Error obteniendo usuarios admin: $e");
      return [];
    }
  }

  static Future<bool> bloquearUsuario(int id, bool bloquear) async {
    try {
      final respuesta = await http.put(
        Uri.parse('${ConfigApi.urlServidor}/admin/usuarios/$id/bloquear'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bloquear': bloquear}),
      );
      return respuesta.statusCode == 200;
    } catch (e) {
      print("Error bloqueando: $e");
      return false;
    }
  }

  static Future<bool> eliminarUsuario(int id) async {
    try {
      final respuesta = await http.delete(Uri.parse('${ConfigApi.urlServidor}/admin/usuarios/$id'));
      return respuesta.statusCode == 200;
    } catch (e) {
      print("Error eliminando: $e");
      return false;
    }
  }
}