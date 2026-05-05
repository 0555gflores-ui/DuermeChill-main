import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_api.dart';
import 'reloj_service.dart';

class DatosService {
  static Future<void> sincronizarDatosDesdeServidor() async {
    if (ConfigApi.usuarioActual == null) return;
    try {
      final respuesta = await http.get(Uri.parse('${ConfigApi.urlServidor}/usuario/${ConfigApi.usuarioActual}'));
      if (respuesta.statusCode == 200) {
        ConfigApi.datosUsuarioCache = jsonDecode(respuesta.body);
      }
    } catch (e) {
      print("Error sincronizando: $e");
    }
  }

  static Future<void> guardarDatosEncuesta(Map<String, String> datos) async {
    if (ConfigApi.usuarioActual == null) return;
    try {
      datos['nombre'] = ConfigApi.usuarioActual!;
      await http.post(
        Uri.parse('${ConfigApi.urlServidor}/encuesta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );
      ConfigApi.encuestaCompletada = true;
    } catch (e) {
      print("Error guardando encuesta: $e");
    }
  }

  static Future<void> guardarDatosRegistro(Map<String, String> datos) async {
    if (ConfigApi.usuarioActual == null) return;
    try {
      datos['nombre'] = ConfigApi.usuarioActual!;
      await http.post(
        Uri.parse('${ConfigApi.urlServidor}/registro_diario'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );
      // Sincronizar tanto datos diarios como del reloj
      await sincronizarDatosDesdeServidor();
      await RelojService.obtenerDatosRelojServidor();
    } catch (e) {
      print("Error guardando registro: $e");
    }
  }

  static Future<void> guardarAlarmas(List<Map<String, dynamic>> listaAlarmas) async {
    if (ConfigApi.usuarioActual == null) return;
    try {
      List<Map<String, dynamic>> alarmasFormateadas = listaAlarmas.map((a) {
        return {
          'hora': "${a['hora'].hour.toString().padLeft(2, '0')}:${a['hora'].minute.toString().padLeft(2, '0')}",
          'activada': a['activada']
        };
      }).toList();

      await http.post(
        Uri.parse('${ConfigApi.urlServidor}/alarmas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': ConfigApi.usuarioActual, 'alarmas': alarmasFormateadas}),
      );
      await sincronizarDatosDesdeServidor();
    } catch (e) {
      print("Error guardando alarmas: $e");
    }
  }
}