import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // El archivo que se está creando justo ahora
import 'pantallas/login_screen.dart';
import 'ui/brand.dart';

void main() async {
  // Asegura que Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la conexión con Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MrPulpoApp());
}

class MrPulpoApp extends StatelessWidget {
  const MrPulpoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mr. Pulpo POS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Brand.teal,
          primary: Brand.teal,
          secondary: Brand.coral,
          surface: Brand.cream,
        ),
        scaffoldBackgroundColor: Brand.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Brand.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Brand.radius)),
            side: BorderSide(color: Color(0xFFE4E7EC)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
