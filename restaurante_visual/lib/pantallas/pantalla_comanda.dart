import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../responsive.dart';
import '../ui/brand.dart';

class PantallaComanda extends StatefulWidget {
  final String nombreMesa;
  const PantallaComanda({super.key, required this.nombreMesa});

  @override
  State<PantallaComanda> createState() => _PantallaComandaState();
}

class _PantallaComandaState extends State<PantallaComanda> {
  List<Map<String, dynamic>> _carrito = [];
  String? _categoriaActiva;
  Stream<QuerySnapshot>? _productosStream;
  bool _procesando = false;

  final List<Map<String, dynamic>> _secciones = [
    {
      'nombre': 'ENTRADAS',
      'icono': Icons.restaurant_menu,
      'color': Colors.orange,
    },
    {'nombre': 'COCTELES', 'icono': Icons.local_bar, 'color': Colors.redAccent},
    {
      'nombre': 'SOPAS Y CHILPACHOLES',
      'icono': Icons.soup_kitchen,
      'color': Colors.deepOrange,
    },
    {
      'nombre': 'ESPECIALIDADES',
      'icono': Icons.star,
      'color': Colors.amber[700],
    },
    {
      'nombre': 'CAMARONES CONCHA',
      'icono': Icons.set_meal,
      'color': Colors.teal,
    },
    {
      'nombre': 'CAMARONES PULPA',
      'icono': Icons.set_meal_outlined,
      'color': Colors.cyan,
    },
    {'nombre': 'PULPOS', 'icono': Icons.waves, 'color': Colors.indigo},
    {
      'nombre': 'ROBALO Y PESCADOS',
      'icono': Icons.sailing,
      'color': Colors.blue,
    },
    {'nombre': 'ENSALADAS', 'icono': Icons.eco, 'color': Colors.green},
    {'nombre': 'CARNES', 'icono': Icons.lunch_dining, 'color': Colors.brown},
    {
      'nombre': 'INFANTILES',
      'icono': Icons.child_care,
      'color': Colors.pinkAccent,
    },
    {
      'nombre': 'POSTRES',
      'icono': Icons.icecream,
      'color': Colors.purpleAccent,
    },
    {'nombre': 'CAFE', 'icono': Icons.coffee, 'color': Colors.brown[800]},
    {
      'nombre': 'BEBIDAS',
      'icono': Icons.local_drink,
      'color': Colors.lightBlue,
    },
    {
      'nombre': 'BAR Y LICORES',
      'icono': Icons.wine_bar,
      'color': Colors.deepPurple,
    },
  ];

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      int index = _carrito.indexWhere(
        (item) => item['clave'] == producto['clave'],
      );
      if (index != -1) {
        _carrito[index]['cantidad']++;
      } else {
        _carrito.add({
          'clave': producto['clave'] ?? 'S/C',
          'nombre': producto['nombre'] ?? 'Sin nombre',
          'precio': (producto['precio'] ?? 0).toDouble(),
          'cantidad': 1,
          'comentario': '',
        });
      }
    });
  }

  double get _totalCuenta => _carrito.fold(
    0,
    (suma, item) => suma + (item['precio'] * item['cantidad']),
  );

  void _mostrarTicketModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              minHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _construirTicket(esCelular: true),
          ),
        );
      },
    );
  }

  void _solicitarPinParaEliminar(int index) {
    TextEditingController pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Autorización Requerida',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Ingresa PIN (123)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (pinCtrl.text == '123') {
                Navigator.pop(context);
                setState(() {
                  if (_carrito[index]['cantidad'] > 1) {
                    _carrito[index]['cantidad']--;
                  } else {
                    _carrito.removeAt(index);
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Platillo cancelado con éxito'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ PIN Incorrecto'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('AUTORIZAR'),
          ),
        ],
      ),
    );
  }

  void _agregarNota(int index) {
    TextEditingController notaCtrl = TextEditingController(
      text: _carrito[index]['comentario'],
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Nota Especial al Platillo',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        content: TextField(
          controller: notaCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Ej. SIN CEBOLLA, ALERGIA AL MARISCO...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit_note),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(
                () =>
                    _carrito[index]['comentario'] = notaCtrl.text.toUpperCase(),
              );
              Navigator.pop(context);
            },
            child: const Text('GUARDAR NOTA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool esCelular = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Brand.background,
      appBar: AppBar(
        title: Text(
          'Comanda - Mesa ${widget.nombreMesa}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Brand.navy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: esCelular
            ? _construirMenu(esCelular)
            : Row(
                children: [
                  Expanded(flex: 6, child: _construirMenu(esCelular)),
                  Expanded(flex: 4, child: _construirTicket(esCelular: false)),
                ],
              ),
      ),

      floatingActionButton: esCelular
          ? FloatingActionButton.extended(
              onPressed: _mostrarTicketModal,
              backgroundColor: Brand.coral,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.receipt_long),
              label: Text(
                'Ver Cuenta (\$${_totalCuenta.toStringAsFixed(2)})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _construirMenu(bool esCelular) {
    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_categoriaActiva != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF0F172A),
                    ),
                    onPressed: () => setState(() {
                      _categoriaActiva = null;
                      _productosStream = null;
                    }),
                  ),
                ),
              Expanded(
                child: Text(
                  _categoriaActiva == null
                      ? 'Secciones del Menú'
                      : _categoriaActiva!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: Brand.panel(color: Brand.cream),
            child: Row(
              children: [
                const Icon(Icons.touch_app, color: Brand.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _categoriaActiva == null
                        ? 'Elige una sección para comenzar'
                        : 'Toca un platillo para agregarlo a la cuenta',
                    style: const TextStyle(
                      color: Brand.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_carrito.isNotEmpty)
                  Text(
                    '${_carrito.length} productos',
                    style: const TextStyle(color: Brand.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _categoriaActiva == null
                ? _construirVistaSecciones(esCelular)
                : _construirVistaProductos(esCelular),
          ),
        ],
      ),
    );
  }

  Widget _construirTicket({required bool esCelular}) {
    return Container(
      color: Brand.cream,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Brand.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cuenta · Mesa ${widget.nombreMesa}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Brand.ink,
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 2),
          const Text(
            'PEDIDOS ENVIADOS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(flex: 1, child: _construirHistorial()),
          const Divider(thickness: 2, color: Colors.orangeAccent),
          const Text(
            'ORDEN ACTUAL',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            flex: 1,
            child: _carrito.isEmpty
                ? const Center(
                    child: Text(
                      'Agrega platillos aquí...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      var item = _carrito[index];
                      bool tieneNota =
                          item['comentario'] != null &&
                          item['comentario'].toString().isNotEmpty;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Brand.navy,
                          child: Text(
                            '${item['cantidad']}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          item['nombre'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '\$${item['precio']} c/u${tieneNota ? '\n📝 Nota: ${item['comentario']}' : ''}',
                          style: TextStyle(
                            color: tieneNota
                                ? Colors.redAccent
                                : Colors.grey[700],
                            fontWeight: tieneNota
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_note,
                                color: Brand.teal,
                                size: 28,
                              ),
                              tooltip: 'Alergias / Notas',
                              onPressed: () => _agregarNota(index),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Brand.danger,
                                size: 28,
                              ),
                              tooltip: 'Cancelar Platillo',
                              onPressed: () => _solicitarPinParaEliminar(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(thickness: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_totalCuenta.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Brand.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: (_carrito.isEmpty || _procesando)
                  ? null
                  : () async {
                      setState(() => _procesando = true);
                      try {
                        WriteBatch batch = FirebaseFirestore.instance.batch();
                        DocumentReference comandaRef = FirebaseFirestore
                            .instance
                            .collection('comandas')
                            .doc();
                        batch.set(comandaRef, {
                          'mesa': widget.nombreMesa,
                          'items': _carrito,
                          'total': _totalCuenta,
                          'estado': 'PENDIENTE',
                          'fecha': DateTime.now(),
                        });

                        // Obtenemos todos los insumos directos para compararlos
                        var todosLosInsumosSnap = await FirebaseFirestore
                            .instance
                            .collection('insumos')
                            .get();

                        for (var item in _carrito) {
                          String nombreItem = item['nombre']
                              .toString()
                              .toUpperCase();

                          // PASO 1: Verificar si es un platillo preparado con Receta
                          var recetaSnap = await FirebaseFirestore.instance
                              .collection('recetas')
                              .where('nom_busqueda', isEqualTo: nombreItem)
                              .get();

                          if (recetaSnap.docs.isNotEmpty) {
                            // Tiene receta: Descuenta ingredientes gramo a gramo
                            var ingredientes =
                                recetaSnap.docs.first['ingredientes'] as List;
                            for (var ing in ingredientes) {
                              DocumentReference insumoRef = FirebaseFirestore
                                  .instance
                                  .collection('insumos')
                                  .doc(ing['idInsumo']);
                              DocumentSnapshot snap = await insumoRef.get();
                              if (snap.exists) {
                                double stockAct =
                                    double.tryParse(
                                      snap['stockAct'].toString(),
                                    ) ??
                                    0.0;
                                double cantADescontar =
                                    (double.tryParse(ing['cant'].toString()) ??
                                        1.0) *
                                    item['cantidad'];
                                double nuevoStock = stockAct - cantADescontar;
                                batch.update(insumoRef, {
                                  'stockAct': nuevoStock % 1 == 0
                                      ? nuevoStock.toInt().toString()
                                      : nuevoStock.toString(),
                                });
                              }
                            }
                          } else {
                            // PASO 2: Verificar si es un producto directo (Cerveza, Refresco, etc.) sin receta
                            var insumoDirecto = todosLosInsumosSnap.docs
                                .where(
                                  (doc) =>
                                      doc['nom'].toString().toUpperCase() ==
                                      nombreItem,
                                )
                                .firstOrNull;

                            if (insumoDirecto != null) {
                              DocumentReference insumoRef = FirebaseFirestore
                                  .instance
                                  .collection('insumos')
                                  .doc(insumoDirecto.id);
                              DocumentSnapshot snap = await insumoRef.get();
                              if (snap.exists) {
                                double stockAct =
                                    double.tryParse(
                                      snap['stockAct'].toString(),
                                    ) ??
                                    0.0;
                                double cantADescontar = (item['cantidad'])
                                    .toDouble();
                                double nuevoStock = stockAct - cantADescontar;
                                batch.update(insumoRef, {
                                  'stockAct': nuevoStock % 1 == 0
                                      ? nuevoStock.toInt().toString()
                                      : nuevoStock.toString(),
                                });
                              }
                            }
                          }
                        }
                        await batch.commit();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '¡Inventario Descontado y Pedido a Cocina! 🍳🔥',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() {
                            _carrito.clear();
                            _procesando = false;
                          });
                          if (esCelular) Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _procesando = false);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Brand.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _procesando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _procesando ? 'PROCESANDO...' : 'ENVIAR A COCINA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirHistorial() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comandas')
          .where('mesa', isEqualTo: widget.nombreMesa)
          .where('estado', whereIn: ['PENDIENTE', 'LISTO'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(
            child: Text('Mesa limpia.', style: TextStyle(color: Colors.grey)),
          );
        List<dynamic> itemsHistorial = [];
        double granTotalPrevio = 0;
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          granTotalPrevio += (data['total'] ?? 0).toDouble();
          itemsHistorial.addAll(data['items'] as List<dynamic>? ?? []);
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: itemsHistorial.length,
                itemBuilder: (context, index) {
                  var item = itemsHistorial[index];
                  bool tieneNota =
                      item['comentario'] != null &&
                      item['comentario'].toString().isNotEmpty;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        '${item['cantidad']}x',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item['nombre'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    subtitle: tieneNota
                        ? Text(
                            '📝 Nota: ${item['comentario']}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                            ),
                          )
                        : null,
                    trailing: Text(
                      '\$${item['precio']} c/u',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL PREVIO:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  Text(
                    '\$${granTotalPrevio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _construirVistaSecciones(bool esCelular) {
    int columnas = Responsive.gridColumns(
      MediaQuery.sizeOf(context).width,
      phone: 2,
      tablet: 3,
      wide: 4,
      minItemWidth: 180,
    );
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnas,
        childAspectRatio: 1.3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: _secciones.length,
      itemBuilder: (context, index) {
        final sec = _secciones[index];
        return InkWell(
          onTap: () => setState(() {
            _categoriaActiva = sec['nombre'];
            _productosStream = FirebaseFirestore.instance
                .collection('productos')
                .where('categoria', isEqualTo: _categoriaActiva)
                .snapshots();
          }),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (sec['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(sec['icono'], size: 40, color: sec['color']),
                ),
                const SizedBox(height: 12),
                Text(
                  sec['nombre'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirVistaProductos(bool esCelular) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productosStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text('No hay platillos en esta sección'));
        int columnas = Responsive.gridColumns(
          MediaQuery.sizeOf(context).width,
          phone: 2,
          tablet: 3,
          wide: 4,
          minItemWidth: 180,
        );
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var prod = doc.data() as Map<String, dynamic>;
            return InkWell(
              onTap: () {
                _agregarAlCarrito(prod);
                if (esCelular)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${prod['nombre']} agregado a la cuenta'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
              },
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_circle,
                        color: Colors.green,
                        size: 28,
                      ),
                      const Spacer(),
                      Text(
                        prod['nombre'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '\$${prod['precio']}',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
