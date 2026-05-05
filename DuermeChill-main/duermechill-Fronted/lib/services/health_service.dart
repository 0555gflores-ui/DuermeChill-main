import 'package:health/health.dart';
import 'config_api.dart';
import 'reloj_service.dart';

class HealthService {
  static final Health _health = Health();

  static final List<HealthDataType> _healthTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
  ];

  static Future<bool> solicitarPermisos() async {
    try {
      await _health.configure();
      return await _health.requestAuthorization(_healthTypes);
    } catch (e) {
      print('Error solicitando permisos: $e');
      return false;
    }
  }

  static Future<bool> sincronizarDesdeGoogleFit() async {
    if (ConfigApi.usuarioActual == null) return false;

    final permisos = await solicitarPermisos();
    if (!permisos) return false;

    final now = DateTime.now();
    final desde = now.subtract(const Duration(hours: 24));

    try {
      final pulsaciones = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: desde,
        endTime: now,
      );
      final sleepData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_IN_BED,
        ],
        startTime: desde,
        endTime: now,
      );

      final pulsacionesUnicas = _health.removeDuplicates(pulsaciones);
      final sleepUnique = _health.removeDuplicates(sleepData);

      final datosPulsaciones = pulsacionesUnicas.map((evento) {
        final minuto = evento.dateFrom.difference(desde).inMinutes;
        final valorString = evento.value.toString();
        final valor = int.tryParse(valorString) ?? 0;
        return {
          'minuto': minuto < 0 ? 0 : minuto,
          'valor': valor,
        };
      }).toList();

      final Map<String, double> acumuladoFases = {
        'awake': 0.0,
        'light': 0.0,
        'deep': 0.0,
        'rem': 0.0,
      };

      for (var evento in sleepUnique) {
        final tipo = evento.type;
        final duracion = evento.dateTo.difference(evento.dateFrom).inMinutes / 60.0;
        switch (tipo) {
          case HealthDataType.SLEEP_AWAKE:
            acumuladoFases['awake'] = acumuladoFases['awake']! + duracion;
            break;
          case HealthDataType.SLEEP_ASLEEP:
            acumuladoFases['light'] = acumuladoFases['light']! + duracion;
            break;
          case HealthDataType.SLEEP_IN_BED:
            // No se usa directamente en las fases dinámicas, se puede usar para diagnóstico.
            break;
          default:
            break;
        }
      }

      final fasesSueno = acumuladoFases.entries
          .map((entry) => {'fase': entry.key, 'horas': double.parse(entry.value.toStringAsFixed(2))})
          .toList();

      await RelojService.enviarDatosRelojAlBackend(
        fecha: now,
        pulsaciones: datosPulsaciones,
        fasesSueno: fasesSueno,
      );

      return true;
    } catch (e) {
      print('Error leyendo datos de Google Fit: $e');
      return false;
    }
  }
}
