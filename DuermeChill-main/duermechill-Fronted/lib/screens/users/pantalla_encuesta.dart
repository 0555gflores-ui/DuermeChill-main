import 'package:flutter/material.dart';
import '../../services/datos_service.dart';
import '../pantalla_principal.dart';

class PantallaEncuesta extends StatefulWidget {
  const PantallaEncuesta({super.key});

  @override
  State<PantallaEncuesta> createState() => _PantallaEncuestaState();
}

class _PantallaEncuestaState extends State<PantallaEncuesta> {
  String r1 = "¿Qué esperas de nuestra aplicación?";
  String r2 = "¿Cómo es tu noche típica?";
  String r3 = "¿A qué hora te sueles ir a la cama?";
  String r4 = "¿Qué edad tienes?";

  void _seleccionarOpcion(String titulo, List<String> opciones, Function(String) alSeleccionar) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
              const Divider(),
              ...opciones.map((opc) => ListTile(
                title: Text(opc, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                onTap: () {
                  alSeleccionar(opc);
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width > 600 ? 60.0 : (screenSize.width > 400 ? 40.0 : 24.0);
    final titleFontSize = screenSize.width > 600 ? 56.0 : (screenSize.width > 400 ? 50.0 : 40.0);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            children: [
              Text('DuermeChill', style: TextStyle(fontSize: titleFontSize, color: const Color(0xFF6EADD8))),
              const SizedBox(height: 20),
              Text('¿Podemos saber más sobre ti?', style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)),
              SizedBox(height: screenSize.height > 800 ? 40 : 25),
              _burbuja(r1, () => _seleccionarOpcion("Expectativas", ["Dormirme más rápido", "Mejorar calidad del sueño", "Regular mi vida"], (val) => setState(() => r1 = val)), isDark),
              _burbuja(r2, () => _seleccionarOpcion("Tu noche", ["Duermo bastante bien", "Sueño normal", "No duermo lo suficiente", "No estoy seguro"], (val) => setState(() => r2 = val)), isDark),
              _burbuja(r3, () => _seleccionarOpcion("Horario", ["21:00 - 22:00", "22:00 - 23:00", "23:00 - 00:00", "Más tarde"], (val) => setState(() => r3 = val)), isDark),
              _burbuja(r4, () => _seleccionarOpcion("Edad", ["18-25", "26-40", "41-60", "+60"], (val) => setState(() => r4 = val)), isDark),
              SizedBox(height: screenSize.height > 800 ? 50 : 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: Text('Cancelar', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16))
                    ),
                  ),
                  SizedBox(width: screenSize.width > 400 ? 16 : 8),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () {
                        DatosService.guardarDatosEncuesta({"expectativa": r1, "noche": r2, "hora": r3, "edad": r4});
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaPrincipal()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF333333),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _burbuja(String texto, VoidCallback accion, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: accion,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(30)
          ),
          child: Text(texto, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
        ),
      ),
    );
  }
}