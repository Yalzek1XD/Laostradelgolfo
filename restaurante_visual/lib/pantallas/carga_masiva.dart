import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CargaMasiva extends StatelessWidget {
  CargaMasiva({super.key});

  // 👇 TU DESPENSA COMPLETA BASADA EN TU MENÚ
  final List<Map<String, dynamic>> misInsumos = [
    // --- MARISCOS ---
    {'id': 'INS-01', 'nom': 'CAMARÓN PULPA', 'uniMed': 'Kilos'},
    {'id': 'INS-02', 'nom': 'CAMARÓN CONCHA', 'uniMed': 'Kilos'},
    {'id': 'INS-03', 'nom': 'PULPO', 'uniMed': 'Piezas'},
    {'id': 'INS-04', 'nom': 'PULPA DE JAIBA', 'uniMed': 'Kilos'},
    {'id': 'INS-05', 'nom': 'OSTIÓN DESCONCHADO', 'uniMed': 'Kilos'},
    {'id': 'INS-06', 'nom': 'FILETE DE ROBALO', 'uniMed': 'Kilos'},
    {'id': 'INS-07', 'nom': 'REBANADA DE ROBALO', 'uniMed': 'Kilos'},
    {'id': 'INS-08', 'nom': 'MINILLA DE PESCADO', 'uniMed': 'Kilos'},
    {'id': 'INS-09', 'nom': 'MIX DE MARISCOS', 'uniMed': 'Kilos'},

    // --- CARNES Y AVES ---
    {'id': 'INS-10', 'nom': 'ARRACHERA', 'uniMed': 'Kilos'},
    {'id': 'INS-11', 'nom': 'PECHUGA DE POLLO', 'uniMed': 'Kilos'},
    {'id': 'INS-12', 'nom': 'RIBEYE', 'uniMed': 'Kilos'},
    {'id': 'INS-13', 'nom': 'NUGGETS DE POLLO', 'uniMed': 'Piezas'},

    // --- ABARROTES Y LÁCTEOS ---
    {'id': 'INS-14', 'nom': 'LECHE ENTERA', 'uniMed': 'Litros'},
    {'id': 'INS-15', 'nom': 'QUESO PHILADELPHIA', 'uniMed': 'Kilos'},
    {'id': 'INS-16', 'nom': 'MANTEQUILLA', 'uniMed': 'Kilos'},
    {'id': 'INS-17', 'nom': 'ARROZ', 'uniMed': 'Kilos'},
    {'id': 'INS-18', 'nom': 'EMPANIZADOR', 'uniMed': 'Kilos'},
    {'id': 'INS-19', 'nom': 'COCO RALLADO', 'uniMed': 'Kilos'},
    {'id': 'INS-20', 'nom': 'ACEITE PARA FREÍR', 'uniMed': 'Litros'},
    {'id': 'INS-21', 'nom': 'MASA DE MAÍZ', 'uniMed': 'Kilos'},
    {'id': 'INS-22', 'nom': 'PAN PARA TORTA', 'uniMed': 'Piezas'},

    // --- FRUTAS Y VERDURAS ---
    {'id': 'INS-23', 'nom': 'AGUACATE', 'uniMed': 'Kilos'},
    {'id': 'INS-24', 'nom': 'LIMÓN', 'uniMed': 'Kilos'},
    {'id': 'INS-25', 'nom': 'CHILE CHIPOTLE', 'uniMed': 'Kilos'},
    {'id': 'INS-26', 'nom': 'AJO PELADO', 'uniMed': 'Kilos'},
    {'id': 'INS-27', 'nom': 'PAPA FRANCESA (CONGELADA)', 'uniMed': 'Kilos'},
    {'id': 'INS-28', 'nom': 'PLÁTANO MACHO', 'uniMed': 'Kilos'},

    // --- BAR, LICORES Y MEZCLADORES ---
    {'id': 'INS-29', 'nom': 'AGUA MINERAL', 'uniMed': 'Litros'},
    {'id': 'INS-30', 'nom': 'REFRESCO DE TORONJA (SQUIRT)', 'uniMed': 'Litros'},
    {'id': 'INS-31', 'nom': 'REFRESCO DE COLA', 'uniMed': 'Litros'},
    {'id': 'INS-32', 'nom': 'WHISKY BUCHANANS 12', 'uniMed': 'Litros'},
    {'id': 'INS-33', 'nom': 'TEQUILA CENTENARIO', 'uniMed': 'Litros'},
    {'id': 'INS-34', 'nom': 'TEQUILA DON JULIO 70', 'uniMed': 'Litros'},
    {'id': 'INS-35', 'nom': 'LICOR 43 (CARAJILLO)', 'uniMed': 'Litros'},
    {'id': 'INS-36', 'nom': 'VINO TINTO (SANGRÍA)', 'uniMed': 'Litros'},
    {'id': 'INS-37', 'nom': 'RON BLANCO', 'uniMed': 'Litros'},
    {'id': 'INS-38', 'nom': 'CERVEZA', 'uniMed': 'Piezas'},
    {'id': 'INS-39', 'nom': 'SALSAS MICHE', 'uniMed': 'Litros'},
    {'id': 'INS-40', 'nom': 'CREMA DE COCO', 'uniMed': 'Litros'},
    {'id': 'INS-41', 'nom': 'JUGO DE PIÑA', 'uniMed': 'Litros'},
    {'id': 'INS-42', 'nom': 'CAFÉ EN GRANO', 'uniMed': 'Kilos'},

    // --- POSTRES ---
    {'id': 'INS-43', 'nom': 'HELADO DE VAINILLA', 'uniMed': 'Litros'},
    {'id': 'INS-44', 'nom': 'FLAN CASERO', 'uniMed': 'Porciones'},
  ];

  Future<void> _subirTodo(BuildContext context) async {
    var firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();

    for (var insumo in misInsumos) {
      DocumentReference ref = firestore.collection('insumos').doc(insumo['id']);
      batch.set(ref, {
        'id': insumo['id'],
        'nom': insumo['nom'],
        'stockAct': '15', // Stock inicial fijo
        'stockMin': '5', // Stock mínimo fijo
        'uniMed': insumo['uniMed'],
      });
    }

    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Toda la materia prima fue agregada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Inyección de Insumos'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _subirTodo(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.all(20),
          ),
          icon: const Icon(Icons.kitchen, color: Colors.black, size: 30),
          label: const Text(
            'INYECTAR MATERIA PRIMA',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
