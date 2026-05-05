import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_api.dart';

class RelojService {
  static Future<void> enviarDatosRelojAlBackend({
    required DateTime fecha,
    required List<Map<String, dynamic>> pulsaciones,
    required List<Map<String, dynamic>> fasesSueno,
  }) async {
    if (ConfigApi.usuarioActual == null) return;

    try {
      await http.post(
        Uri.parse('${ConfigApi.urlServidor}/reloj/ingestar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': ConfigApi.usuarioActual,
          'fecha': fecha.toIso8601String().split('T').first,
          'pulsaciones': pulsaciones,
          'fases_sueno': fasesSueno,
        }),
      );
      // Actualizar datos después de enviar
      await obtenerDatosRelojServidor();
    } catch (e) {
      print('Error enviando datos de reloj al backend: $e');
    }
  }

  static Future<void> obtenerDatosRelojServidor() async {
    if (ConfigApi.usuarioActual == null) return;
    try {
      final respuesta = await http.get(Uri.parse('${ConfigApi.urlServidor}/reloj/${ConfigApi.usuarioActual}'));
      if (respuesta.statusCode == 200) {
        ConfigApi.datosRelojCache = jsonDecode(respuesta.body);
      }
    } catch (e) {
      print('Error obteniendo datos de reloj del servidor: $e');
    }
  }
}
