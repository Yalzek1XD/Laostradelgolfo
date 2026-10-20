import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../responsive.dart';

class PantallaCompras extends StatefulWidget {
  const PantallaCompras({super.key});

  @override
  State<PantallaCompras> createState() => _PantallaComprasState();
}

class _PantallaComprasState extends State<PantallaCompras> {
  bool _editandoCompra = false;
  final TextEditingController _idCompraController = TextEditingController();
  final TextEditingController _facturaController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _costoUniController = TextEditingController();

  String? _proveedorSeleccionado;
  String? _insumoSeleccionado;
  String? _unidadSeleccionada;
  DateTime _fechaSeleccionada = DateTime.now();
  final List<Map<String, dynamic>> _insumosAgregados = [];

  @override
  void initState() {
    super.initState();
    _generarFoliosAuto();
  }

  void _generarFoliosAuto() {
    String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    _idCompraController.text = "C-${stamp.substring(5)}";
    _facturaController.text = "F-${stamp.substring(5)}";
  }

  void _agregarInsumo() {
    if (_insumoSeleccionado != null &&
        _cantidadController.text.isNotEmpty &&
        _costoUniController.text.isNotEmpty &&
        _unidadSeleccionada != null) {
      setState(() {
        double cant = double.parse(_cantidadController.text);
        double costo = double.parse(_costoUniController.text);
        _insumosAgregados.add({
          'insumo': _insumoSeleccionado,
          'cantidad': cant,
          'unidad': _unidadSeleccionada,
          'costo_unitario': costo,
          'subtotal': cant * costo,
        });
        _insumoSeleccionado = null;
        _unidadSeleccionada = null;
        _cantidadController.clear();
        _costoUniController.clear();
        _calcularTotal();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Llena todos los campos del insumo y unidad'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calcularTotal() {
    double total = 0;
    for (var item in _insumosAgregados) {
      total += item['subtotal'] ?? 0;
    }
    _totalController.text = total.toStringAsFixed(2);
  }

  Future<void> _guardarCompra() async {
    if (_proveedorSeleccionado == null || _insumosAgregados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faltan datos o insumos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    var firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();

    DocumentReference compraRef = firestore
        .collection('compras')
        .doc(_idCompraController.text);
    batch.set(compraRef, {
      'id_compra': _idCompraController.text,
      'factura': _facturaController.text,
      'proveedor': _proveedorSeleccionado,
      'fecha_compra': _fechaSeleccionada,
      'total': double.parse(_totalController.text),
      'insumos': _insumosAgregados,
    });

    if (!_editandoCompra) {
      for (var item in _insumosAgregados) {
        QuerySnapshot insumoSnap = await firestore
            .collection('insumos')
            .where('nom', isEqualTo: item['insumo'])
            .limit(1)
            .get();
        if (insumoSnap.docs.isNotEmpty) {
          DocumentReference insumoRef = insumoSnap.docs.first.reference;
          double stockActual =
              double.tryParse(
                (insumoSnap.docs.first.data()
                            as Map<String, dynamic>)['stockAct']
                        ?.toString() ??
                    '0',
              ) ??
              0.0;
          batch.update(insumoRef, {
            'stockAct': (stockActual + item['cantidad']).toString(),
          });
        }
      }
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Compra Guardada'),
          backgroundColor: Colors.green,
        ),
      );
      _limpiarFormulario();
    }
  }

  void _editarCompra(Map<String, dynamic> data, String idDoc) {
    setState(() {
      _editandoCompra = true;
      _idCompraController.text = idDoc;
      _facturaController.text = data['factura'] ?? '';
      _proveedorSeleccionado = data['proveedor'];
      _totalController.text = (data['total'] ?? 0).toString();
      _fechaSeleccionada = (data['fecha_compra'] as Timestamp).toDate();
      _insumosAgregados.clear();
      for (var insumo in (data['insumos'] ?? [])) {
        _insumosAgregados.add({
          'insumo': insumo['insumo'],
          'cantidad': insumo['cantidad'] ?? 0,
          'unidad': insumo['unidad'] ?? '',
          'costo_unitario': insumo['costo_unitario'] ?? 0.0,
          'subtotal': insumo['subtotal'] ?? 0.0,
        });
      }
    });
  }

  void _limpiarFormulario() {
    setState(() {
      _editandoCompra = false;
      _proveedorSeleccionado = null;
      _insumoSeleccionado = null;
      _unidadSeleccionada = null;
      _totalController.clear();
      _cantidadController.clear();
      _costoUniController.clear();
      _insumosAgregados.clear();
      _fechaSeleccionada = DateTime.now();
      _generarFoliosAuto();
    });
  }

  void _verDetalleCompra(List insumos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Detalle de Insumos Comprados',
          style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: insumos.length,
            itemBuilder: (context, i) {
              String costoU = (insumos[i]['costo_unitario'] ?? 0).toString();
              String subt = (insumos[i]['subtotal'] ?? 0).toString();
              String unidad = insumos[i]['unidad'] ?? '';
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  insumos[i]['insumo'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${insumos[i]['cantidad']} $unidad a \$$costoU c/u',
                ),
                trailing: Text(
                  '\$$subt',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final apilado = constraints.maxWidth < Responsive.tabletBreakpoint;
        return Flex(
          direction: apilado ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: ConstrainedBox(
                constraints: apilado
                    ? const BoxConstraints(minHeight: 480)
                    : const BoxConstraints(),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editandoCompra
                              ? 'Editando Factura'
                              : 'Datos de la Factura',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A7081),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _idCompraController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'ID de Compra (Auto)',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _facturaController,
                                readOnly: _editandoCompra,
                                decoration: InputDecoration(
                                  labelText: 'Factura (Auto)',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('proveedores')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData)
                                    return const CircularProgressIndicator();
                                  var proveedores = snapshot.data!.docs
                                      .map((doc) => doc['nom'].toString())
                                      .toList();
                                  return DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Proveedor',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _proveedorSeleccionado,
                                    items: proveedores
                                        .map(
                                          (p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(
                                              p,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(
                                      () => _proveedorSeleccionado = val,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _totalController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Total Factura Auto (\$)',
                                  filled: true,
                                  fillColor: Colors.grey.shade200,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(_fechaSeleccionada),
                              style: const TextStyle(fontSize: 16),
                            ),
                            TextButton(
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _fechaSeleccionada,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null)
                                  setState(() => _fechaSeleccionada = picked);
                              },
                              child: const Text('Cambiar Fecha'),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        const Text(
                          'Insumos de esta compra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A7081),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            // 👇 isExpanded: true (Evita errores de texto largo en Insumos)
                            Expanded(
                              flex: 2,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('insumos')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData)
                                    return const CircularProgressIndicator();
                                  var insumos = snapshot.data!.docs
                                      .map((doc) => doc['nom'].toString())
                                      .toList();
                                  return DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Insumo',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 15,
                                      ),
                                    ),
                                    value: _insumoSeleccionado,
                                    items: insumos
                                        .map(
                                          (i) => DropdownMenuItem(
                                            value: i,
                                            child: Text(
                                              i,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(
                                      () => _insumoSeleccionado = val,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _cantidadController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Cant',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            // 👇 isExpanded: true (Evita errores de texto largo en Unidad)
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Unid',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 15,
                                  ),
                                ),
                                value: _unidadSeleccionada,
                                items:
                                    [
                                          'Kilos',
                                          'Gramos',
                                          'Litros',
                                          'Mililitros',
                                          'Piezas',
                                          'Porciones',
                                        ]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              e,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) =>
                                    setState(() => _unidadSeleccionada = val),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _costoUniController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Costo',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                                size: 35,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: _agregarInsumo,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        ..._insumosAgregados.map(
                          (item) => ListTile(
                            dense: true,
                            title: Text(
                              item['insumo'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Cant: ${item['cantidad']} ${item['unidad'] ?? ''} | Precio: \$${item['costo_unitario'] ?? 0}',
                            ),
                            trailing: Text(
                              '\$${item['subtotal'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _guardarCompra,
                                icon: const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _editandoCompra
                                      ? 'ACTUALIZAR'
                                      : 'GUARDAR COMPRA',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _limpiarFormulario,
                                icon: const Icon(
                                  Icons.cleaning_services,
                                  color: Colors.white,
                                ),
                                label: const Text('LIMPIAR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9800),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('compras')
                      .orderBy('fecha_compra', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    var docs = snapshot.data!.docs;
                    if (docs.isEmpty)
                      return const Center(
                        child: Text('No hay compras registradas'),
                      );
                    return ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        List insumos = data['insumos'] ?? [];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(
                              Icons.receipt,
                              color: Color(0xFF2C3E50),
                            ),
                            title: Text(
                              'Factura: ${data['factura']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Proveedor: ${data['proveedor']}\n${DateFormat('dd/MM/yyyy').format((data['fecha_compra'] as Timestamp).toDate())}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${data['total']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(
                                    Icons.folder,
                                    color: Colors.amber,
                                    size: 30,
                                  ),
                                  tooltip: 'Ver Detalle',
                                  onPressed: () => _verDetalleCompra(insumos),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Editar',
                                  onPressed: () =>
                                      _editarCompra(data, docs[index].id),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Eliminar',
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('compras')
                                        .doc(docs[index].id)
                                        .delete();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
