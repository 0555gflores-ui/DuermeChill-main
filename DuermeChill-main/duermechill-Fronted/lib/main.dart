import 'package:flutter/material.dart';
import 'screens/pantalla_login.dart';
import 'services/config_api.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ConfigApi.cargarDatosGenerales();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConfigApi.isDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'DuermeChill',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF6EADD8),
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: const Color(0xFF6EADD8),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
          ),
          home: const PantallaLogin(),
        );
      },
    );
  }
}