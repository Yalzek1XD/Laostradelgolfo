import 'package:flutter/material.dart';

// --- PANTALLA INVENTARIO ---
class PantallaInventario extends StatelessWidget {
  const PantallaInventario({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Módulo de Inventario en Construcción 📦',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// --- PANTALLA GRUPOS ---
class PantallaGrupos extends StatelessWidget {
  const PantallaGrupos({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Gestión de Grupos y Categorías 📁',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// --- PANTALLA EMPLEADOS ---
class PantallaEmpleados extends StatelessWidget {
  const PantallaEmpleados({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Control de Empleados y Meseros 👥',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// --- PANTALLA SUCURSAL (Solo hay una, información estática) ---
class PantallaSucursal extends StatelessWidget {
  const PantallaSucursal({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.store, size: 80, color: Colors.teal),
              SizedBox(height: 20),
              Text(
                'Mr. Pulpo - Matriz',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                'Única Sucursal Activa',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
