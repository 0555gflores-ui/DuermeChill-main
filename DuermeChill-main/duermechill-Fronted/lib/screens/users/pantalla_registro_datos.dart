import 'package:flutter/material.dart';
import '../../services/datos_service.dart';
import '../../widgets/mi_drawer.dart';

class PantallaRegistroDatos extends StatefulWidget {
  const PantallaRegistroDatos({super.key});

  @override
  State<PantallaRegistroDatos> createState() => _PantallaRegistroDatosState();
}

class _PantallaRegistroDatosState extends State<PantallaRegistroDatos> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _horasController = TextEditingController();
  final TextEditingController _comoController = TextEditingController();
  final TextEditingController _cansadoController = TextEditingController();
  final TextEditingController _despertaresController = TextEditingController();

  @override
  void dispose() {
    _horasController.dispose();
    _comoController.dispose();
    _cansadoController.dispose();
    _despertaresController.dispose();
    super.dispose();
  }

  void _guardarDatos() {
    if (_formKey.currentState!.validate()) {
      Map<String, String> datos = {
        'horas_dormidas': _horasController.text,
        'como_dormido': _comoController.text,
        'cansado': _cansadoController.text,
        'despertares': _despertaresController.text, 
      };
      DatosService.guardarDatosRegistro(datos);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados correctamente')),
      );
      
      _horasController.clear();
      _comoController.clear();
      _cansadoController.clear();
      _despertaresController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6EADD8),
        title: const Text('Registro de datos', style: TextStyle(fontSize: 22, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MiDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Registro de datos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Responde las preguntas con total sinceridad',
                style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildPregunta('¿Cuántas horas has dormido hoy?', _horasController, isDark),
                    _buildPregunta('¿Cómo has dormido?', _comoController, isDark),
                    _buildPregunta('¿Qué tan cansado te sientes hoy?', _cansadoController, isDark),
                    _buildPregunta('¿Cuántas veces te despertaste por la noche?', _despertaresController, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarDatos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6EADD8),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPregunta(String pregunta, TextEditingController controller, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pregunta,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF2A3F54)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0), 
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, responde esta pregunta';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}