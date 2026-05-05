import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/config_api.dart';
import '../../services/datos_service.dart';
import '../../services/health_service.dart';
import '../../services/reloj_service.dart';
import '../../widgets/mi_drawer.dart';

class PantallaEstadisticas extends StatefulWidget {
  const PantallaEstadisticas({super.key});

  @override
  State<PantallaEstadisticas> createState() => _PantallaEstadisticasState();
}

class _PantallaEstadisticasState extends State<PantallaEstadisticas> {
  late Future<void> _cargaDatosFuture;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _cargaDatosFuture = _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await DatosService.sincronizarDatosDesdeServidor();
    await RelojService.obtenerDatosRelojServidor();
  }

  Future<void> _sincronizarDesdeReloj() async {
    setState(() => _isSyncing = true);
    await HealthService.sincronizarDesdeGoogleFit();
    await RelojService.obtenerDatosRelojServidor();
    setState(() => _isSyncing = false);
  }

  int _filtroHistorial = 0; // 0: 7 días, 1: 14 días, 2: mes

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600; // Consider mobile if width < 600px
    final padding = isMobile ? 12.0 : 16.0;
    final titleFontSize = isMobile ? 16.0 : 18.0;
    final chartHeight = isMobile ? 200.0 : 250.0;
    final heartRateChartHeight = isMobile ? 220.0 : 280.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6EADD8),
        title: Text('Estadísticas', style: TextStyle(fontSize: isMobile ? 18 : 22, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MiDrawer(),
      body: FutureBuilder(
        future: _cargaDatosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6EADD8)));
          }

          final datosUsuario = ConfigApi.datosUsuarioCache;
          final reloj = ConfigApi.datosRelojCache ?? {};
          final List fasesSueno = (reloj['fases_sueno'] as List<dynamic>?) ?? [];
          final List pulsaciones = (reloj['pulsaciones'] as List<dynamic>?) ?? [];
          final resumen = reloj['ultimo_reloj'] as Map<String, dynamic>?;

          final List historial = (datosUsuario?['historial_registros'] as List?) ?? [];
          final ultimoRegistro = historial.isNotEmpty ? historial.last : null;

          final horasAwake = _sumFase(fasesSueno, 'awake');
          final horasLight = _sumFase(fasesSueno, 'light');
          final horasDeep = _sumFase(fasesSueno, 'deep');
          final horasRem = _sumFase(fasesSueno, 'rem');
          final horasDormidas = ultimoRegistro != null ? '${ultimoRegistro['horas_dormidas']}h' : 'Sin datos';
          final calidadSueno = ultimoRegistro != null ? ultimoRegistro['como_dormido'] : 'Sin datos';
          final nivelCansancio = ultimoRegistro != null ? ultimoRegistro['cansado'] : 'Sin datos';
          final despertares = ultimoRegistro != null ? '${ultimoRegistro['despertares']} veces' : 'Sin datos';

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: isMobile
              ? _buildMobileLayout(
                  isDark, historial, pulsaciones, horasAwake, horasLight, horasDeep, horasRem,
                  horasDormidas, calidadSueno, nivelCansancio, despertares, chartHeight, heartRateChartHeight
                )
              : _buildTabletLayout(
                  isDark, historial, pulsaciones, horasAwake, horasLight, horasDeep, horasRem,
                  horasDormidas, calidadSueno, nivelCansancio, despertares, chartHeight, heartRateChartHeight
                ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    bool isDark, List historial, List pulsaciones, double horasAwake, double horasLight,
    double horasDeep, double horasRem, String horasDormidas, dynamic calidadSueno,
    dynamic nivelCansancio, String despertares, double chartHeight, double heartRateChartHeight
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SECCIÓN 1: Datos del usuario
        Text('Tu progreso de sueño', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54))),
        const SizedBox(height: 12),
        SizedBox(height: chartHeight, child: _buildUserSleepChart(historial, isDark)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFilterButton('7 días', 0, isDark),
            _buildFilterButton('14 días', 1, isDark),
            _buildFilterButton('Mes', 2, isDark),
          ],
        ),
        const SizedBox(height: 16),
        Text('Última noche registrada', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54))),
        const SizedBox(height: 10),
        _tarjetaEstadistica('Horas dormidas', horasDormidas, Icons.bedtime, Colors.indigo, isDark),
        _tarjetaEstadistica('Calidad del sueño', calidadSueno.toString(), Icons.star_border, Colors.teal, isDark),
        _tarjetaEstadistica('Nivel de cansancio', nivelCansancio.toString(), Icons.battery_alert, Colors.orange, isDark),
        _tarjetaEstadistica('Despertares', despertares, Icons.notifications_active, Colors.deepPurple, isDark),
        const SizedBox(height: 24),

        // SECCIÓN 2: Datos del reloj
        Text('Datos del reloj inteligente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54))),
        const SizedBox(height: 12),
        if (pulsaciones.isNotEmpty)
          SizedBox(height: heartRateChartHeight, child: _buildHeartRateChart(pulsaciones, isDark))
        else
          _buildHeartRateChart(pulsaciones, isDark),
        const SizedBox(height: 14),
        Text('Datos de pulsaciones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54))),
        const SizedBox(height: 10),
        _buildHeartRateTable(pulsaciones, isDark),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _isSyncing ? null : _sincronizarDesdeReloj,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6EADD8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: _isSyncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Icon(Icons.sync),
          label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar reloj'),
        ),
        const SizedBox(height: 14),
        Text('Fases del sueño', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54))),
        const SizedBox(height: 10),
        _buildSleepPhasesTable(horasAwake, horasLight, horasDeep, horasRem, isDark),
      ],
    );
  }

  Widget _buildTabletLayout(
    bool isDark, List historial, List pulsaciones, double horasAwake, double horasLight,
    double horasDeep, double horasRem, String horasDormidas, dynamic calidadSueno,
    dynamic nivelCansancio, String despertares, double chartHeight, double heartRateChartHeight
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // COLUMNA IZQUIERDA: Datos del usuario
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tu progreso de sueño', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54))),
                const SizedBox(height: 12),
                SizedBox(height: chartHeight, child: _buildUserSleepChart(historial, isDark)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterButton('7 días', 0, isDark),
                    _buildFilterButton('14 días', 1, isDark),
                    _buildFilterButton('Mes', 2, isDark),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Última noche registrada', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54))),
                const SizedBox(height: 10),
                _tarjetaEstadistica('Horas dormidas', horasDormidas, Icons.bedtime, Colors.indigo, isDark),
                _tarjetaEstadistica('Calidad del sueño', calidadSueno.toString(), Icons.star_border, Colors.teal, isDark),
                _tarjetaEstadistica('Nivel de cansancio', nivelCansancio.toString(), Icons.battery_alert, Colors.orange, isDark),
                _tarjetaEstadistica('Despertares', despertares, Icons.notifications_active, Colors.deepPurple, isDark),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // COLUMNA DERECHA: Datos del reloj
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pulsaciones.isNotEmpty)
                  SizedBox(height: heartRateChartHeight, child: _buildHeartRateChart(pulsaciones, isDark))
                else
                  _buildHeartRateChart(pulsaciones, isDark),
                const SizedBox(height: 14),
                Text('Datos de pulsaciones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54))),
                const SizedBox(height: 10),
                _buildHeartRateTable(pulsaciones, isDark),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _sincronizarDesdeReloj,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6EADD8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isSyncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Icon(Icons.sync),
                  label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar reloj'),
                ),
                const SizedBox(height: 14),
                Text('Fases del sueño', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2A3F54))),
                const SizedBox(height: 10),
                _buildSleepPhasesTable(horasAwake, horasLight, horasDeep, horasRem, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, int index, bool isDark) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => setState(() => _filtroHistorial = index),
          style: ElevatedButton.styleFrom(
            backgroundColor: _filtroHistorial == index ? const Color(0xFF6EADD8) : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]),
            foregroundColor: _filtroHistorial == index ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            elevation: _filtroHistorial == index ? 4 : 0,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildUserSleepChart(List historial, bool isDark) {
    if (historial.isEmpty) {
      return Center(child: Text('Sin datos de sueño registrados', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
    }

    final filteredData = _filtrarHistorial(historial, _filtroHistorial);
    if (filteredData.isEmpty) {
      return Center(child: Text('Sin datos para este período', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < filteredData.length; i++) {
      final double horas = double.tryParse(filteredData[i]['horas_dormidas'].toString()) ?? 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: horas, color: const Color(0xFF6EADD8), width: 12)],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _getDateLabel(filteredData[value.toInt()]),
                  style: TextStyle(fontSize: 9, color: isDark ? Colors.white70 : Colors.black87),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}h', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 2, drawVerticalLine: false),
        borderData: FlBorderData(show: true, border: Border.all(color: isDark ? Colors.white24 : Colors.black12)),
      ),
    );
  }

  List<dynamic> _filtrarHistorial(List historial, int filtro) {
    final now = DateTime.now();
    List<dynamic> filtered = [];

    for (var item in historial) {
      try {
        final fecha = DateTime.parse(item['fecha'] ?? '');
        final diff = now.difference(fecha).inDays;

        switch (filtro) {
          case 0: // 7 días
            if (diff >= 0 && diff < 7) filtered.add(item);
            break;
          case 1: // 14 días
            if (diff >= 0 && diff < 14) filtered.add(item);
            break;
          case 2: // 30 días (Mes)
            if (diff >= 0 && diff < 30) filtered.add(item);
            break;
        }
      } catch (e) {
        // Ignorar fechas inválidas
      }
    }

    return filtered;
  }

  String _getDateLabel(dynamic registro) {
    try {
      final fecha = DateTime.parse(registro['fecha'] ?? '');
      return '${fecha.day}/${fecha.month}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildSleepPhasesTable(double awake, double light, double deep, double rem, bool isDark) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final fontSize = isMobile ? 12.0 : 14.0;

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
          border: TableBorder.symmetric(inside: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
          children: [
            _buildRow('Despierto', '${awake.toStringAsFixed(1)}h', isDark, fontSize),
            _buildRow('Sueño ligero', '${light.toStringAsFixed(1)}h', isDark, fontSize),
            _buildRow('Sueño profundo', '${deep.toStringAsFixed(1)}h', isDark, fontSize),
            _buildRow('REM', '${rem.toStringAsFixed(1)}h', isDark, fontSize),
          ],
        ),
      ),
    );
  }

  double _sumFase(List fases, String fase) {
    double total = 0;
    for (var item in fases) {
      if (item['fase']?.toString().toLowerCase() == fase) {
        total += double.tryParse(item['horas'].toString()) ?? 0.0;
      }
    }
    return total;
  }

  Widget _buildHeartRateChart(List pulsaciones, bool isDark) {
    if (pulsaciones.isEmpty) {
      return Card(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              'Sin datos de pulso.\nSincroniza Google Fit.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (var item in pulsaciones) {
      final x = double.tryParse(item['minuto'].toString()) ?? 0.0;
      final y = double.tryParse(item['valor'].toString()) ?? 0.0;
      spots.add(FlSpot(x, y));
      if (y > maxY) maxY = y;
    }

    final double maxGraph = (maxY + 20).clamp(80, 140).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.isNotEmpty ? spots.last.x : 0,
        minY: 40,
        maxY: maxGraph,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF6EADD8),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF6EADD8).withOpacity(0.2)),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 30,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}m', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 10, drawVerticalLine: false),
        borderData: FlBorderData(show: true, border: Border.all(color: isDark ? Colors.white24 : Colors.black12)),
      ),
    );
  }

  TableRow _buildRow(String label, String value, bool isDark, double fontSize) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: fontSize))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontSize: fontSize))),
      ],
    );
  }

  Widget _buildHeartRateTable(List pulsaciones, bool isDark) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final fontSize = isMobile ? 12.0 : 14.0;

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
        child: Column(
          children: [
            Table(
              columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
              border: TableBorder.symmetric(inside: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: fontSize)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Pulsaciones', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: fontSize)),
                    ),
                  ],
                ),
                if (pulsaciones.isEmpty)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('--:--', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: fontSize)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('-- bpm', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: fontSize)),
                      ),
                    ],
                  )
                else
                  ...pulsaciones.take(isMobile ? 3 : 5).map((item) {
                    final minuto = int.tryParse(item['minuto'].toString()) ?? 0;
                    final hora = '${(minuto ~/ 60).toString().padLeft(2, '0')}:${(minuto % 60).toString().padLeft(2, '0')}';
                    final valor = item['valor'].toString();
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(hora, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: fontSize)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text('$valor bpm', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: fontSize)),
                        ),
                      ],
                    );
                  }),
              ],
            ),
            if (pulsaciones.length > (isMobile ? 3 : 5))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '... y ${pulsaciones.length - (isMobile ? 3 : 5)} más',
                  style: TextStyle(fontSize: isMobile ? 10 : 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaEstadistica(String titulo, String valor, IconData icono, Color color, bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icono, color: color),
        ),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
        subtitle: Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      ),
    );
  }
}
