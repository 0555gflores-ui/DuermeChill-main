import 'package:flutter/material.dart';

class ConfigApi {
  // Como estás probando en Windows directamente, usamos localhost
  static const String urlServidor = 'http://localhost:8080/api';
  
  static String? usuarioActual;
  static bool encuestaCompletada = false; 
  static ValueNotifier<bool> isDarkMode = ValueNotifier(false);
  static Map<String, dynamic>? datosUsuarioCache;
  static Map<String, dynamic>? datosRelojCache;

  static void cargarDatosGenerales() {
    isDarkMode.value = false;
  }

  static void cambiarTema(bool oscuro) {
    isDarkMode.value = oscuro;
  }
}