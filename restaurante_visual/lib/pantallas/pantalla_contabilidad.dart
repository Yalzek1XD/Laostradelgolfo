import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../responsive.dart';

class PantallaContabilidad extends StatefulWidget {
  const PantallaContabilidad({super.key});

  @override
  State<PantallaContabilidad> createState() => _PantallaContabilidadState();
}

class _PantallaContabilidadState extends State<PantallaContabilidad> {
  String _filtroTiempo = 'Día';
  double _fondoInicial = 0.0;
  final TextEditingController _fondoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarFondo();
  }

  void _cargarFondo() async {
    var doc = await FirebaseFirestore.instance
        .collection('configuracion')
        .doc('caja_hoy')
        .get();
    if (doc.exists) {
      setState(() {
        _fondoInicial = (doc.data()?['fondo'] ?? 0).toDouble();
        _fondoCtrl.text = _fondoInicial.toStringAsFixed(2);
      });
    }
  }

  void _guardarFondo(String val) async {
    double nuevoFondo = double.tryParse(val) ?? 0.0;
    await FirebaseFirestore.instance
        .collection('configuracion')
        .doc('caja_hoy')
        .set({'fondo': nuevoFondo});
    setState(() => _fondoInicial = nuevoFondo);
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Fondo Guardado')));
  }

  DateTime _obtenerFechaFiltro() {
    DateTime hoy = DateTime.now();
    if (_filtroTiempo == 'Semana') return hoy.subtract(const Duration(days: 7));
    if (_filtroTiempo == 'Mes') return hoy.subtract(const Duration(days: 30));
    return DateTime(hoy.year, hoy.month, hoy.day);
  }

  Future<void> _generarPDF(
    double ventas,
    double gastos,
    double cajaReal,
    List<MapEntry<String, int>> top,
  ) async {
    final pdf = pw.Document();
    DateTime ahora = DateTime.now();
    String fechaHora =
        "${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year} ${ahora.hour}:${ahora.minute.toString().padLeft(2, '0')}";

    pw.MemoryImage? logoImage;
    try {
      // 👇 CAMBIADO A LOGO.JPG
      final ByteData bytes = await rootBundle.load('assets/logo.jpg');
      final Uint8List logoBytes = bytes.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      debugPrint("Aviso: No se localizó assets/logo.jpg en tu proyecto: $e");
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xff0f172a),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    if (logoImage != null) ...[
                      pw.Image(logoImage, width: 50, height: 50),
                      pw.SizedBox(width: 15),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MR. PULPO',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Marisquería y Restaurante',
                          style: pw.TextStyle(
                            color: PdfColors.grey300,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Dirección: Anastacio Bustamante 10,',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                        pw.Text(
                          'Zona Centro, Centro, 91000 Xalapa-Enríquez, Ver.',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ESTADO DE RESULTADOS',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Periodo: $_filtroTiempo',
                      style: pw.TextStyle(
                        color: PdfColors.amber,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Impreso el: $fechaHora',
                      style: pw.TextStyle(
                        color: PdfColors.grey300,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          pw.Text(
            'RESUMEN FINANCIERO',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xff0f172a),
            ),
          ),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _pdfTarjeta(
                'Fondo Inicial',
                _fondoInicial,
                PdfColors.grey200,
                PdfColors.black,
              ),
              _pdfTarjeta(
                'Ingresos (+)',
                ventas,
                PdfColors.green100,
                PdfColors.green800,
              ),
              _pdfTarjeta(
                'Costos/Gastos (-)',
                gastos,
                PdfColors.red100,
                PdfColors.red800,
              ),
              _pdfTarjeta(
                'FLUJO DE CAJA (=)',
                cajaReal,
                const PdfColor.fromInt(0xff0f172a),
                PdfColors.white,
              ),
            ],
          ),
          pw.SizedBox(height: 40),

          pw.Text(
            'RANKING: PRODUCTOS MÁS VENDIDOS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xff0f172a),
            ),
          ),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          top.isEmpty
              ? pw.Text(
                  'No hay ventas registradas en este periodo.',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                )
              : pw.TableHelper.fromTextArray(
                  context: context,
                  headers: ['#', 'Platillo / Bebida', 'Unidades Vendidas'],
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xff5a7081),
                  ),
                  rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 0.5,
                      ),
                    ),
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellAlignments: {
                    0: pw.Alignment.center,
                    2: pw.Alignment.center,
                  },
                  data: List<List<String>>.generate(
                    top.length,
                    (i) => [
                      (i + 1).toString(),
                      top[i].key,
                      '${top[i].value} uds',
                    ],
                  ),
                ),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _mostrarFacturaResumen(
    double ventas,
    double gastos,
    double cajaReal,
  ) async {
    final numero = DateTime.now().millisecondsSinceEpoch.toString();
    final fecha = DateTime.now();
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'FACTURA / COMPROBANTE DE OPERACIÓN',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xff0f172a),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('MR. PULPO - Marisquería y Restaurante'),
            pw.Text('Folio: $numero'),
            pw.Text(
              'Fecha: ${fecha.day.toString().padLeft(2, '0')}/'
              '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
            ),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Concepto', 'Importe'],
              data: [
                [
                  'Ingresos por ventas ($_filtroTiempo)',
                  '\$${ventas.toStringAsFixed(2)}',
                ],
                [
                  'Costos y gastos ($_filtroTiempo)',
                  '\$${gastos.toStringAsFixed(2)}',
                ],
                ['Flujo de caja real', '\$${cajaReal.toStringAsFixed(2)}'],
              ],
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xff0f172a),
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {1: pw.Alignment.centerRight},
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Documento generado desde el módulo de Contabilidad.',
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _pdfTarjeta(
    String titulo,
    double monto,
    PdfColor bgColor,
    PdfColor textColor,
  ) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(titulo, style: pw.TextStyle(fontSize: 10, color: textColor)),
          pw.SizedBox(height: 8),
          pw.Text(
            '\$${monto.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime fechaFiltro = _obtenerFechaFiltro();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('comandas')
                .snapshots(),
            builder: (context, comandasSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('compras')
                    .snapshots(),
                builder: (context, comprasSnap) {
                  if (!comandasSnap.hasData || !comprasSnap.hasData)
                    return const Center(child: CircularProgressIndicator());

                  double totalVentas = 0;
                  double totalCompras = 0;
                  Map<String, int> conteoProductos = {};

                  for (var doc in comandasSnap.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (data['fecha'] != null && data['estado'] == 'PAGADO') {
                      DateTime fecha = (data['fecha'] as Timestamp).toDate();
                      if (fecha.isAfter(fechaFiltro)) {
                        totalVentas += (data['total'] ?? 0).toDouble();
                        for (var item in (data['items'] ?? [])) {
                          conteoProductos[item['nombre']] =
                              (conteoProductos[item['nombre']] ?? 0) +
                              (item['cantidad'] as int);
                        }
                      }
                    }
                  }

                  for (var doc in comprasSnap.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (data['fecha_compra'] != null) {
                      DateTime fecha = (data['fecha_compra'] as Timestamp)
                          .toDate();
                      if (fecha.isAfter(fechaFiltro))
                        totalCompras += (data['total'] ?? 0).toDouble();
                    }
                  }

                  double cajaReal = _fondoInicial + totalVentas - totalCompras;
                  var topProductos = conteoProductos.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final compacto =
                      MediaQuery.sizeOf(context).width <
                      Responsive.tabletBreakpoint;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flex(
                          direction: compacto ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment: compacto
                              ? CrossAxisAlignment.stretch
                              : CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: ['Día', 'Semana', 'Mes']
                                    .map(
                                      (p) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(
                                            p,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          selected: _filtroTiempo == p,
                                          selectedColor: const Color(
                                            0xFF0F172A,
                                          ),
                                          labelStyle: TextStyle(
                                            color: _filtroTiempo == p
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                          onSelected: (val) =>
                                              setState(() => _filtroTiempo = p),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: compacto
                                  ? WrapAlignment.start
                                  : WrapAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _generarPDF(
                                    totalVentas,
                                    totalCompras,
                                    cajaReal,
                                    topProductos,
                                  ),
                                  icon: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'IMPRIMIR REPORTE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _mostrarFacturaResumen(
                                    totalVentas,
                                    totalCompras,
                                    cajaReal,
                                  ),
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('GENERAR FACTURA'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 15,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF0F172A),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: compacto
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.savings,
                                          color: Colors.amber,
                                          size: 28,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Fondo de Caja (Editable)',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF5A7081),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _fondoCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        prefixText: '\$ ',
                                        filled: true,
                                        fillColor: const Color(0xFFF4F6F8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onSubmitted: _guardarFondo,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    const Icon(
                                      Icons.savings,
                                      color: Colors.amber,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Fondo de Caja (Editable): \$',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5A7081),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 120,
                                      child: TextField(
                                        controller: _fondoCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        onSubmitted: _guardarFondo,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 20),

                        Flex(
                          direction: compacto ? Axis.vertical : Axis.horizontal,
                          children: [
                            compacto
                                ? SizedBox(
                                    width: double.infinity,
                                    child: _tarjetaUI(
                                      'Ingresos por Ventas (+)',
                                      totalVentas,
                                      const Color(0xFF4CAF50),
                                    ),
                                  )
                                : Expanded(
                                    child: _tarjetaUI(
                                      'Ingresos por Ventas (+)',
                                      totalVentas,
                                      const Color(0xFF4CAF50),
                                    ),
                                  ),
                            SizedBox(
                              width: compacto ? 0 : 15,
                              height: compacto ? 10 : 0,
                            ),
                            compacto
                                ? SizedBox(
                                    width: double.infinity,
                                    child: _tarjetaUI(
                                      'Costos y Gastos (-)',
                                      totalCompras,
                                      const Color(0xFFE53935),
                                    ),
                                  )
                                : Expanded(
                                    child: _tarjetaUI(
                                      'Costos y Gastos (-)',
                                      totalCompras,
                                      const Color(0xFFE53935),
                                    ),
                                  ),
                            SizedBox(
                              width: compacto ? 0 : 15,
                              height: compacto ? 10 : 0,
                            ),
                            compacto
                                ? SizedBox(
                                    width: double.infinity,
                                    child: _tarjetaUI(
                                      'Flujo de Caja Real',
                                      cajaReal,
                                      const Color(0xFF0F172A),
                                    ),
                                  )
                                : Expanded(
                                    child: _tarjetaUI(
                                      'Flujo de Caja Real',
                                      cajaReal,
                                      const Color(0xFF0F172A),
                                    ),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        const Text(
                          'Ranking de Ventas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A7081),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...topProductos.asMap().entries.map((entry) {
                          final i = entry.key;
                          final producto = entry.value;
                          return Card(
                            elevation: 2,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 5,
                              ),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: i == 0
                                    ? Colors.amber
                                    : const Color(0xFF0F172A),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                producto.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: Text(
                                '${producto.value} uds',
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tarjetaUI(String titulo, double monto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${monto.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
