import 'package:flutter/material.dart';
import 'pantalla_gerente.dart';
import 'pantalla_mesero.dart';
import 'pantalla_cocina.dart';
import 'carga_masiva.dart';
import '../responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _codigoController = TextEditingController();

  void _verificarAcceso() {
    String codigo = _codigoController.text.trim();

    if (codigo == "010") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PantallaGerente()),
      );
    } else if (codigo == "01") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PantallaMesero()),
      );
    } else if (codigo == "011") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PantallaCocina()),
      );
    } else if (codigo == "999") {
      // <--- EL PIN SECRETO
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CargaMasiva()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código incorrecto. Intenta con 01, 010 o 011'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11B7E4),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoSize = constraints.maxWidth < Responsive.phoneBreakpoint
                  ? 140.0
                  : 200.0;
              return SingleChildScrollView(
                padding: Responsive.pagePadding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/logo_nuevo.jpg',
                        height: logoSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: Colors.white54,
                            ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'La Ostra Del Golfo',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: TextField(
                        controller: _codigoController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu PIN',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _verificarAcceso,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'ENTRAR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
