import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../ui/brand.dart';

class PantallaCajero extends StatelessWidget {
  const PantallaCajero({super.key});

  Future<void> _imprimirTicket(
    String folio,
    String mesa,
    double total,
    List items,
  ) async {
    final pdf = pw.Document();
    DateTime ahora = DateTime.now();
    String fecha =
        "${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}";
    String hora =
        "${ahora.hour > 12 ? ahora.hour - 12 : ahora.hour}:${ahora.minute.toString().padLeft(2, '0')} ${ahora.hour >= 12 ? 'p. m.' : 'a. m.'}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              '   *** MR. PULPO POS *** ',
              style: pw.TextStyle(
                font: pw.Font.courier(),
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              ' Punto de Venta Profesional',
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
            ),
            pw.Text(
              '       Xalapa, Veracruz     ',
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
            ),
            pw.Text(
              '--------------------------------',
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Folio: ${folio.substring(0, 6).toUpperCase()}',
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Mesa: $mesa',
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
                ),
                pw.Text(
                  'Mesero: Admin',
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Fecha: $fecha $hora',
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
                ),
              ],
            ),
            pw.Text(
              '--------------------------------',
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
            ),
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'Cant',
                    style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'Platillo',
                    style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Importe',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
                  ),
                ),
              ],
            ),
            pw.Text(
              '--------------------------------',
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
            ),
            ...items.map((item) {
              double cant = (item['cantidad'] ?? 1).toDouble();
              double precio = (item['precio'] ?? (item['subtotal'] ?? 0) / cant)
                  .toDouble();
              double subtotal = cant * precio;
              return pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${cant.toInt()}x',
                      style: pw.TextStyle(
                        font: pw.Font.courier(),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      '${item['nombre']}',
                      style: pw.TextStyle(
                        font: pw.Font.courier(),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${subtotal.toStringAsFixed(2)}',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        font: pw.Font.courier(),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              );
            }),
            pw.Text(
              '--------------------------------',
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL:',
                  style: pw.TextStyle(
                    font: pw.Font.courier(),
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    font: pw.Font.courier(),
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Text(
              '    ¡Gracias por su visita!   ',
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
            ),
            pw.Text(
              '    *** Fin de Ticket *** ',
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
            ),
            pw.SizedBox(height: 20),
          ],
        ),
      ),
    );

    // 🔥 REVERTIDO: Se regresa a tu línea original para Windows
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _generarFactura(
    String folio,
    String mesa,
    double total,
    List items,
  ) async {
    final pdf = pw.Document();
    final ahora = DateTime.now();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'FACTURA',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xff0f172a),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('MR. PULPO - Marisquería y Restaurante'),
            pw.Text('Folio: ${folio.substring(0, 8).toUpperCase()}'),
            pw.Text('Mesa: $mesa'),
            pw.Text(
              'Fecha: ${ahora.day.toString().padLeft(2, '0')}/'
              '${ahora.month.toString().padLeft(2, '0')}/${ahora.year}',
            ),
            pw.Divider(),
            pw.Table.fromTextArray(
              headers: const ['Cantidad', 'Concepto', 'Importe'],
              data: items.map<List<String>>((item) {
                final cantidad = (item['cantidad'] ?? 1).toDouble();
                final precio =
                    (item['precio'] ?? (item['subtotal'] ?? 0) / cantidad)
                        .toDouble();
                return [
                  cantidad.toInt().toString(),
                  item['nombre'].toString(),
                  '\$${(cantidad * precio).toStringAsFixed(2)}',
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xff0f172a),
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              cellAlignments: {2: pw.Alignment.centerRight},
            ),
            pw.SizedBox(height: 18),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TOTAL: \$${total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _cobrar(
    BuildContext context,
    String idComanda,
    String mesa,
    double total,
    List items,
  ) async {
    try {
      await _imprimirTicket(idComanda, mesa, total, items);

      await FirebaseFirestore.instance
          .collection('comandas')
          .doc(idComanda)
          .update({
            'estado': 'PAGADO',
            'fecha': FieldValue.serverTimestamp(),
            'total': total,
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cobrado e Impreso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al procesar cobro: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Brand.background,
      child: StreamBuilder<QuerySnapshot>(
        // Se filtra en memoria para que Caja no dependa de la consulta
        // indexada cuando se muestra dentro de un TabBarView de tableta.
        stream: FirebaseFirestore.instance.collection('comandas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudieron cargar las mesas.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final estado = data['estado']?.toString().trim().toUpperCase();
            return estado == 'LISTO';
          }).toList();
          if (docs.isEmpty) {
            return const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No hay mesas pendientes 🏖️'),
                ),
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey<String>('caja-mesas'),
            shrinkWrap: false,
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              final total = (data['total'] ?? 0).toDouble();
              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE4E7EC)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compacto = constraints.maxWidth < 420;
                      return Flex(
                        direction: compacto ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: compacto
                            ? CrossAxisAlignment.stretch
                            : CrossAxisAlignment.center,
                        children: [
                          if (compacto)
                            Row(
                              children: [
                                const Icon(
                                  Icons.point_of_sale,
                                  color: Brand.teal,
                                  size: 30,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'MESA ${data['mesa']}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.point_of_sale,
                                    color: Brand.teal,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'MESA ${data['mesa']}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!compacto) const Spacer(),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            textAlign: compacto
                                ? TextAlign.center
                                : TextAlign.end,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Brand.teal,
                            ),
                          ),
                          const SizedBox(width: 15, height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: compacto
                                ? WrapAlignment.center
                                : WrapAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _generarFactura(
                                  docs[index].id,
                                  data['mesa'].toString(),
                                  total,
                                  data['items'] ?? [],
                                ),
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('FACTURA'),
                              ),
                              ElevatedButton(
                                onPressed: () => _cobrar(
                                  context,
                                  docs[index].id,
                                  data['mesa'].toString(),
                                  total,
                                  data['items'] ?? [],
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Brand.navy,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('COBRAR'),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
