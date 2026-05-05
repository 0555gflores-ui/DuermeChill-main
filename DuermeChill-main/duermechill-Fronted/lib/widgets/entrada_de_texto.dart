import 'package:flutter/material.dart';

class EntradaDeTexto extends StatelessWidget {
  final String textoIndicador;
  final TextEditingController controlador;
  final bool ocultarTexto;

  const EntradaDeTexto({
    super.key,
    required this.textoIndicador,
    required this.controlador,
    this.ocultarTexto = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controlador,
        obscureText: ocultarTexto,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87), // Letras al escribir
        decoration: InputDecoration(
          hintText: textoIndicador,
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black87),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFCCCCCC), // Fondo de la caja
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        ),
      ),
    );
  }
}