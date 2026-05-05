import 'package:flutter/material.dart';
import '../../services/config_api.dart';
import '../../services/datos_service.dart';
import '../../widgets/mi_drawer.dart';

class PantallaAlarmas extends StatefulWidget {
  const PantallaAlarmas({super.key});

  @override
  State<PantallaAlarmas> createState() => _PantallaAlarmasState();
}

class _PantallaAlarmasState extends State<PantallaAlarmas> {
  List<Map<String, dynamic>> _alarmas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAlarmasDesdeServidor();
  }

  Future<void> _cargarAlarmasDesdeServidor() async {
    await DatosService.sincronizarDatosDesdeServidor(); 
    final datos = ConfigApi.datosUsuarioCache;
    
    if (datos != null && datos['alarmas'] != null) {
      setState(() {
        _alarmas = (datos['alarmas'] as List).map((a) {
          final partesHora = a['hora'].split(':');
          return {
            'hora': TimeOfDay(hour: int.parse(partesHora[0]), minute: int.parse(partesHora[1])),
            'activada': a['activada'],
          };
        }).toList();
        _cargando = false;
      });
    } else {
      setState(() => _cargando = false);
    }
  }

  void _agregarAlarma() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'NUEVA ALARMA',
    );

    if (selectedTime != null) {
      setState(() {
        _alarmas.add({'hora': selectedTime, 'activada': true});
        _ordenarAlarmas();
      });
      DatosService.guardarAlarmas(_alarmas);
    }
  }

  void _editarAlarma(int index) async {
    TimeOfDay horaActual = _alarmas[index]['hora'];
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: horaActual,
      helpText: 'EDITAR ALARMA',
    );

    if (selectedTime != null) {
      setState(() {
        _alarmas[index]['hora'] = selectedTime;
        _alarmas[index]['activada'] = true; 
        _ordenarAlarmas();
      });
      DatosService.guardarAlarmas(_alarmas);
    }
  }

  void _toggleAlarma(int index) {
    setState(() {
      _alarmas[index]['activada'] = !_alarmas[index]['activada'];
    });
    DatosService.guardarAlarmas(_alarmas);
  }

  void _eliminarAlarma(int index) {
    final alarmaEliminada = _alarmas[index];
    setState(() {
      _alarmas.removeAt(index);
    });
    DatosService.guardarAlarmas(_alarmas);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Alarma eliminada'),
        action: SnackBarAction(
          label: 'DESHACER',
          textColor: const Color(0xFF6EADD8),
          onPressed: () {
            setState(() {
              _alarmas.insert(index, alarmaEliminada);
              _ordenarAlarmas();
            });
            DatosService.guardarAlarmas(_alarmas);
          },
        ),
      ),
    );
  }

  void _ordenarAlarmas() {
    _alarmas.sort((a, b) {
      final horaA = a['hora'] as TimeOfDay;
      final horaB = b['hora'] as TimeOfDay;
      if (horaA.hour != horaB.hour) {
        return horaA.hour.compareTo(horaB.hour);
      }
      return horaA.minute.compareTo(horaB.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6EADD8),
        title: const Text('Mis Alarmas', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MiDrawer(),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6EADD8)))
        : _alarmas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 80, color: isDark ? Colors.white24 : Colors.black12),
                  const SizedBox(height: 16),
                  Text('No tienes alarmas programadas.\nToca el botón + para crear una.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 80), 
              itemCount: _alarmas.length,
              itemBuilder: (context, index) {
                final alarma = _alarmas[index];
                final hora = alarma['hora'] as TimeOfDay;
                final activada = alarma['activada'] as bool;
                final horaStr = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
                
                return Dismissible(
                  key: Key(horaStr + index.toString()), 
                  direction: DismissDirection.endToStart, 
                  background: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                  onDismissed: (direction) => _eliminarAlarma(index),
                  child: Card(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: activada ? 4 : 1, 
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _editarAlarma(index), 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Text(
                            horaStr,
                            style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w300, 
                              color: activada ? (isDark ? Colors.white : const Color(0xFF2A3F54)) : (isDark ? Colors.white38 : Colors.black38) 
                            ),
                          ),
                          title: Text(activada ? 'Alarma activada' : 'Alarma desactivada',
                            style: TextStyle(fontSize: 12, color: activada ? const Color(0xFF6EADD8) : Colors.grey),
                          ),
                          trailing: Switch(
                            value: activada,
                            onChanged: (value) => _toggleAlarma(index),
                            activeColor: const Color(0xFF6EADD8),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarAlarma,
        backgroundColor: const Color(0xFF6EADD8),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}