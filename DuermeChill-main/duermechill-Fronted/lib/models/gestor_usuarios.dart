import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GestorUsuarios {
  static String? usuarioActual;
  static bool encuestaCompletada = false; 
  static ValueNotifier<bool> isDarkMode = ValueNotifier(false);
  
  // Memoria temporal para las gráficas y alarmas
  static Map<String, dynamic>? datosUsuarioCache;

  // Si usas Chrome o Windows para probar, déjalo en 'localhost'.
  static const String urlServidor = 'http://localhost:8080/api';

  static Future<void> cargarDatos() async {
    isDarkMode.value = false;
  }

  static Future<void> cambiarTema(bool oscuro) async {
    isDarkMode.value = oscuro;
  }

  // registrarse
  static Future<bool> registrarUsuario(String nombre, String edad, String correo, String contrasena) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$urlServidor/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre, 'edad': int.parse(edad), 'correo': correo, 'contrasena': contrasena}),
      );
      return respuesta.statusCode == 200;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  // login
  static Future<bool> iniciarSesion(String nombre, String contrasena) async {
  try {
    final respuesta = await http.post(
      Uri.parse('$urlServidor/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'contrasena': contrasena}),
    );

    if (respuesta.statusCode == 200) {
      final datos = jsonDecode(respuesta.body);
      usuarioActual = datos['usuario']['nombre'];
      
      // MEJORA AQUÍ: Comprobamos si es 1 (int) o si es true (bool)
      var valorEncuesta = datos['usuario']['encuesta_completada'];
      encuestaCompletada = (valorEncuesta == 1 || valorEncuesta == true);
      
      print("Usuario: $usuarioActual - ¿Encuesta hecha?: $encuestaCompletada");

      await sincronizarDatosDesdeServidor();
      return true;
    }
    return false;
  } catch (e) {
    print("Error en login: $e");
    return false;
  }
}

  static bool yaHizoLaEncuesta() {
    return encuestaCompletada;
  }

  // descargar los datos al iniciar sesion
  static Future<void> sincronizarDatosDesdeServidor() async {
    if (usuarioActual == null) return;
    try {
      final respuesta = await http.get(Uri.parse('$urlServidor/usuario/$usuarioActual'));
      if (respuesta.statusCode == 200) {
        datosUsuarioCache = jsonDecode(respuesta.body);
      }
    } catch (e) {
      print("Error sincronizando: $e");
    }
  }

  // guardar encuesta
  static Future<void> guardarDatosEncuesta(Map<String, String> datos) async {
    if (usuarioActual == null) return;
    try {
      datos['nombre'] = usuarioActual!;
      await http.post(
        Uri.parse('$urlServidor/encuesta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );
      encuestaCompletada = true;
    } catch (e) {
      print("Error: $e");
    }
  }

  // guardar registro diario
  static Future<void> guardarDatosRegistro(Map<String, String> datos) async {
    if (usuarioActual == null) return;
    try {
      datos['nombre'] = usuarioActual!;
      await http.post(
        Uri.parse('$urlServidor/registro_diario'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );
      // Volvemos a descargar los datos y también los del reloj
      await sincronizarDatosDesdeServidor();
      // Sincronizar también los datos del reloj
      await _obtenerDatosReloj();
    } catch (e) {
      print("Error: $e");
    }
  }

  static Future<void> _obtenerDatosReloj() async {
    if (usuarioActual == null) return;
    try {
      await http.get(Uri.parse('$urlServidor/reloj/$usuarioActual'));
    } catch (e) {
      print("Error obteniendo datos de reloj: $e");
    }
  }

  // guardar alarmas
  static Future<void> guardarAlarmas(List<Map<String, dynamic>> listaAlarmas) async {
    if (usuarioActual == null) return;
    try {
      List<Map<String, dynamic>> alarmasFormateadas = listaAlarmas.map((a) {
        return {
          'hora': "${a['hora'].hour.toString().padLeft(2, '0')}:${a['hora'].minute.toString().padLeft(2, '0')}",
          'activada': a['activada']
        };
      }).toList();

      await http.post(
        Uri.parse('$urlServidor/alarmas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': usuarioActual, 'alarmas': alarmasFormateadas}),
      );
      await sincronizarDatosDesdeServidor();
    } catch (e) {
      print("Error: $e");
    }
  }

  // Enviar datos a la UI
  static Map<String, dynamic>? obtenerDatosUsuarioActual() {
    return datosUsuarioCache;
  }

static Future<bool> bloquearUsuario(int id, bool bloquear) async {
    try {
      final respuesta = await http.put(
        Uri.parse('$urlServidor/admin/usuarios/$id/bloquear'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bloquear': bloquear}),
      );
      return respuesta.statusCode == 200;
    } catch (e) {
      print("Error bloqueando: $e");
      return false;
    }
  }

  // Nuevo: Eliminar permanentemente
  static Future<bool> eliminarUsuario(int id) async {
    try {
      final respuesta = await http.delete(Uri.parse('$urlServidor/admin/usuarios/$id'));
      return respuesta.statusCode == 200;
    } catch (e) {
      print("Error eliminando: $e");
      return false;
    }
  }

  static Future<List<dynamic>> obtenerTodosLosUsuarios() async {
    try {
      final respuesta = await http.get(Uri.parse('$urlServidor/admin/usuarios'));
      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body);
      }
      return [];
    } catch (e) {
      print("Error obteniendo usuarios: $e");
      return [];
    }
  }
  //FUNCIONES DEL COACH AI
  
  
  // Obtiene la lista de chats pasados
  static Future<List<Map<String, dynamic>>> obtenerSesionesCoach() async {
    if (usuarioActual == null) return [];
    try {
      final respuesta = await http.get(Uri.parse('$urlServidor/coach/$usuarioActual/sesiones'));
      if (respuesta.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(respuesta.body));
      }
    } catch (e) {
      print("Error obteniendo sesiones: $e");
    }
    return [];
  }

  // Obtiene los mensajes de un chat específico
  static Future<List<Map<String, String>>> obtenerMensajesSesion(String sessionId) async {
    if (usuarioActual == null) return [];
    try {
      final respuesta = await http.get(Uri.parse('$urlServidor/coach/$usuarioActual/sesion/$sessionId'));
      if (respuesta.statusCode == 200) {
        final List datos = jsonDecode(respuesta.body);
        return datos.map((m) => {"rol": m["rol"].toString(), "texto": m["texto"].toString()}).toList();
      }
    } catch (e) {
      print("Error obteniendo chat: $e");
    }
    return [];
  }

  // Guarda el mensaje asociándolo a una sesión
  static Future<void> guardarMensajeCoach(String rol, String texto, String sessionId) async {
    if (usuarioActual == null) return;
    try {
      await http.post(
        Uri.parse('$urlServidor/coach'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': usuarioActual, 'rol': rol, 'texto': texto, 'session_id': sessionId}),
      );
    } catch (e) {
      print("Error guardando mensaje: $e");
    }
  }
}