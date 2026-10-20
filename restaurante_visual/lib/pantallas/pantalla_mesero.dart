import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../responsive.dart';
import '../ui/brand.dart';

class PantallaMesero extends StatefulWidget {
  const PantallaMesero({super.key});

  @override
  State<PantallaMesero> createState() => _PantallaMeseroState();
}

class _PantallaMeseroState extends State<PantallaMesero> {
  int _vistaActual = 0;
  String _mesaSeleccionada = '';
  String _categoriaSeleccionada = '';
  final List<Map<String, dynamic>> _carrito = [];

  Future<void> _descontarInventario(List carrito, String idComanda) async {
    var firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> detallesInforme = [];

    for (var item in carrito) {
      int cantPedida = item['cantidad'];
      String idPlatillo = item['id'];

      var recetaDoc = await firestore
          .collection('recetas')
          .doc(idPlatillo)
          .get();

      if (recetaDoc.exists) {
        List ingredientes = recetaDoc.data()?['ingredientes'] ?? [];

        for (var ing in ingredientes) {
          String idInsumo = ing['idInsumo'];
          String nomInsumo = ing['nomInsumo'] ?? 'Desconocido';
          double cantUsadaPorPlatillo =
              double.tryParse(ing['cant'].toString()) ?? 1.0;
          String uniMedReceta = ing['uniMed']?.toString().toLowerCase() ?? '';

          var insumoDoc = await firestore
              .collection('insumos')
              .doc(idInsumo)
              .get();
          if (insumoDoc.exists) {
            String uniMedInventario =
                insumoDoc.data()?['uniMed']?.toString().toLowerCase() ?? '';

            double cantidadCruda = cantPedida * cantUsadaPorPlatillo;
            double totalADescontar = cantidadCruda;

            if (uniMedReceta == 'gramos' && uniMedInventario == 'kilos') {
              totalADescontar = cantidadCruda / 1000.0;
            } else if (uniMedReceta == 'mililitros' &&
                uniMedInventario == 'litros') {
              totalADescontar = cantidadCruda / 1000.0;
            } else if (uniMedReceta == 'kilos' &&
                uniMedInventario == 'gramos') {
              totalADescontar = cantidadCruda * 1000.0;
            } else if (uniMedReceta == 'litros' &&
                uniMedInventario == 'mililitros') {
              totalADescontar = cantidadCruda * 1000.0;
            }

            double stockAntes =
                double.tryParse(
                  insumoDoc.data()?['stockAct'].toString() ?? '0',
                ) ??
                0.0;
            double stockDespues = stockAntes - totalADescontar;

            await firestore.collection('insumos').doc(idInsumo).update({
              'stockAct': stockDespues.toString(),
            });

            detallesInforme.add({
              'insumo': nomInsumo,
              'requerido_receta': totalADescontar,
              'unidad_medida': uniMedInventario,
              'stock_antes': stockAntes,
              'stock_despues': stockDespues,
            });
          }
        }
      }
    }

    if (detallesInforme.isNotEmpty) {
      await firestore.collection('informes_produccion').add({
        'id_comanda': idComanda,
        'fecha': FieldValue.serverTimestamp(),
        'detalles_concordancia': detallesInforme,
        'tipo': 'Producción / Venta',
      });
    }
  }

  Future<void> _enviarOrden() async {
    if (_carrito.isEmpty) return;

    double totalNuevaOrden = _carrito.fold<double>(
      0.0,
      (sum, item) => sum + (item['precio'] * item['cantidad']),
    );

    var comandaQuery = await FirebaseFirestore.instance
        .collection('comandas')
        .where('mesa', isEqualTo: _mesaSeleccionada)
        .get();

    // 🔥 CORRECCIÓN: Buscamos cualquier comanda que no esté pagada
    var docsActivos = comandaQuery.docs
        .where((d) => d['estado'] != 'PAGADO')
        .toList();
    String comandaId;

    if (docsActivos.isNotEmpty) {
      var docActiva = docsActivos.first;
      comandaId = docActiva.id;
      List itemsExistentes = docActiva['items'] ?? [];
      double totalExistente = (docActiva['total'] ?? 0).toDouble();

      for (var nuevoItem in _carrito) {
        if (nuevoItem.containsKey('nota') &&
            nuevoItem['nota'].toString().isNotEmpty) {
          itemsExistentes.add(nuevoItem);
        } else {
          int index = itemsExistentes.indexWhere(
            (item) =>
                item['id'] == nuevoItem['id'] &&
                (!item.containsKey('nota') || item['nota'] == ''),
          );
          if (index != -1) {
            itemsExistentes[index]['cantidad'] += nuevoItem['cantidad'];
          } else {
            itemsExistentes.add(nuevoItem);
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('comandas')
          .doc(comandaId)
          .update({
            'total': totalExistente + totalNuevaOrden,
            'items': itemsExistentes,
            'estado':
                'PENDIENTE', // 🔥 CORRECCIÓN: Se vuelve a poner pendiente para que cocina lo vea
            'fecha': FieldValue.serverTimestamp(),
          });
    } else {
      var nuevaComanda = await FirebaseFirestore.instance
          .collection('comandas')
          .add({
            'mesa': _mesaSeleccionada,
            'estado': 'PENDIENTE', // 🔥 CORRECCIÓN: Nace pendiente, no "LISTO"
            'total': totalNuevaOrden,
            'items': _carrito,
            'fecha': FieldValue.serverTimestamp(),
          });
      comandaId = nuevaComanda.id;
    }

    await _descontarInventario(_carrito, comandaId);

    setState(() {
      _carrito.clear();
      _mesaSeleccionada = '';
      _categoriaSeleccionada = '';
      _vistaActual = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Enviado a Cocina / Barra!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _agregarAlCarrito(DocumentSnapshot doc) {
    setState(() {
      var data = doc.data() as Map<String, dynamic>;
      int index = _carrito.indexWhere(
        (item) =>
            item['id'] == doc.id &&
            (!item.containsKey('nota') || item['nota'] == ''),
      );

      if (index != -1) {
        _carrito[index]['cantidad']++;
      } else {
        _carrito.add({
          'id': doc.id,
          'nombre': data['nombre'],
          'precio': (data['precio'] ?? 0).toDouble(),
          'cantidad': 1,
          'nota': '',
        });
      }
    });
  }

  void _quitarDelCarrito(int index) {
    setState(() {
      if (_carrito[index]['cantidad'] > 1) {
        _carrito[index]['cantidad']--;
      } else {
        _carrito.removeAt(index);
      }
    });
  }

  void _editarComentario(int index) {
    TextEditingController notaCtrl = TextEditingController(
      text: _carrito[index]['nota'],
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nota para ${_carrito[index]['nombre']}'),
        content: TextField(
          controller: notaCtrl,
          decoration: const InputDecoration(
            hintText: 'Ej. Sin cebolla, bien cocido...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _carrito[index]['nota'] = notaCtrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar Nota'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaMesas() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('comandas').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final mesasOcupadas = snapshot.data!.docs
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['estado'] != 'PAGADO',
            )
            .map(
              (doc) => (doc.data() as Map<String, dynamic>)['mesa'].toString(),
            )
            .toSet();

        Widget construirZona(String titulo, int inicio, int fin) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columnas = Responsive.gridColumns(
                    constraints.maxWidth,
                    phone: 2,
                    tablet: 4,
                    wide: 8,
                    minItemWidth: 90,
                  );
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnas,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: fin - inicio + 1,
                    itemBuilder: (context, index) {
                      final numMesa = (inicio + index).toString();
                      final ocupada = mesasOcupadas.contains(numMesa);
                      return InkWell(
                        onTap: () => setState(() {
                          _mesaSeleccionada = numMesa;
                          _vistaActual = 1;
                          _categoriaSeleccionada = '';
                          _carrito.clear();
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: ocupada
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: ocupada
                                  ? Colors.red.shade300
                                  : Colors.green.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_restaurant,
                                color: ocupada
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                size: 30,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Mesa $numMesa',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                ocupada ? 'OCUPADA' : 'LIBRE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: ocupada
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        }

        return ListView(
          children: [
            construirZona('ZONA FRENTE (1 al 16)', 1, 16),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(thickness: 2),
            ),
            construirZona('ZONA TRASERA (17 al 24)', 17, 24),
          ],
        );
      },
    );
  }

  IconData _getIconForCategory(String cat) {
    String c = cat.toLowerCase();
    if (c.contains('entrada')) return Icons.restaurant;
    if (c.contains('coctel')) return Icons.local_bar;
    if (c.contains('sopa') || c.contains('chilpachole'))
      return Icons.ramen_dining;
    if (c.contains('especialidad')) return Icons.star;
    if (c.contains('camaron') || c.contains('camarón')) return Icons.set_meal;
    if (c.contains('pulpo')) return Icons.water;
    if (c.contains('robalo') || c.contains('pescado')) return Icons.sailing;
    if (c.contains('ensalada')) return Icons.eco;
    return Icons.fastfood;
  }

  Color _getColorForCategory(String cat) {
    String c = cat.toLowerCase();
    if (c.contains('entrada')) return Colors.orange.shade300;
    if (c.contains('coctel')) return Colors.pink.shade200;
    if (c.contains('sopa') || c.contains('chilpachole'))
      return Colors.deepOrange.shade300;
    if (c.contains('especialidad')) return Colors.amber.shade400;
    if (c.contains('concha')) return Colors.teal.shade300;
    if (c.contains('pulpa')) return Colors.cyan.shade300;
    if (c.contains('pulpo')) return Colors.indigo.shade300;
    if (c.contains('pescado')) return Colors.blue.shade400;
    if (c.contains('ensalada')) return Colors.green.shade400;
    return Colors.grey.shade400;
  }

  Widget _buildGridCategorias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Secciones del Menú',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('productos')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final categorias = snapshot.data!.docs
                  .map(
                    (doc) =>
                        (doc.data() as Map<String, dynamic>)['categoria']
                            ?.toString() ??
                        '',
                  )
                  .where((categoria) => categoria.isNotEmpty)
                  .toSet()
                  .toList();
              return LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.gridColumns(
                      constraints.maxWidth,
                      phone: 2,
                      tablet: 3,
                      wide: 4,
                      minItemWidth: 150,
                    ),
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final cat = categorias[index];
                    return InkWell(
                      onTap: () => setState(() => _categoriaSeleccionada = cat),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: _getColorForCategory(
                                cat,
                              ).withOpacity(0.2),
                              child: Icon(
                                _getIconForCategory(cat),
                                color: _getColorForCategory(cat),
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              cat.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => setState(() => _categoriaSeleccionada = ''),
              ),
              Expanded(
                child: Text(
                  _categoriaSeleccionada.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('productos')
                .where('categoria', isEqualTo: _categoriaSeleccionada)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.gridColumns(
                      constraints.maxWidth,
                      phone: 2,
                      tablet: 3,
                      wide: 4,
                      minItemWidth: 160,
                    ),
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return InkWell(
                      onTap: () => _agregarAlCarrito(docs[index]),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(
                                Icons.add_circle,
                                color: Color(0xFF4CAF50),
                                size: 28,
                              ),
                              Text(
                                data['nombre']?.toString().toUpperCase() ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${data['precio']}',
                                style: const TextStyle(
                                  color: Colors.deepOrange,
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTomaPedidos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comandas')
          .where('mesa', isEqualTo: _mesaSeleccionada)
          .snapshots(),
      builder: (context, comandaSnap) {
        double totalPrevio = 0.0;
        List<dynamic> historialItems = [];

        // 🔥 CORRECCIÓN: Filtramos localmente para encontrar la que no está pagada
        if (comandaSnap.hasData) {
          var docsActivos = comandaSnap.data!.docs
              .where((d) => (d.data() as Map)['estado'] != 'PAGADO')
              .toList();
          if (docsActivos.isNotEmpty) {
            var docActiva = docsActivos.first;
            totalPrevio = (docActiva['total'] ?? 0).toDouble();
            historialItems = docActiva['items'] ?? [];
          }
        }

        double totalNuevo = _carrito.fold<double>(
          0.0,
          (sum, item) => sum + (item['precio'] * item['cantidad']),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < Responsive.tabletBreakpoint;
            final menu = Expanded(
              flex: compacto ? 5 : 7,
              child: Container(
                color: const Color(0xFFF8F9FA),
                child: _categoriaSeleccionada.isEmpty
                    ? _buildGridCategorias()
                    : _buildGridProductos(),
              ),
            );
            final cuenta = Expanded(
              flex: compacto ? 6 : 4,
              child: Container(
                color: Colors.white,
                child: _buildCuenta(totalPrevio, historialItems, totalNuevo),
              ),
            );
            return compacto
                ? Column(children: [menu, const Divider(height: 1), cuenta])
                : Row(
                    children: [
                      menu,
                      Container(width: 1, color: Colors.grey.shade300),
                      cuenta,
                    ],
                  );
          },
        );
      },
    );
  }

  Widget _buildCuenta(
    double totalPrevio,
    List<dynamic> historialItems,
    double totalNuevo,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Text(
            'Cuenta Mesa $_mesaSeleccionada',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const Divider(height: 1),

        if (historialItems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            width: double.infinity,
            child: const Text(
              'PEDIDOS ENVIADOS',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: historialItems.length,
              itemBuilder: (context, idx) {
                var item = historialItems[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.grey.shade300,
                        child: Text(
                          '${item['cantidad']}x',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nombre']?.toString().toUpperCase() ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black45,
                              ),
                            ),
                            if (item['nota'] != null && item['nota'] != '')
                              Text(
                                'Nota: ${item['nota']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.redAccent,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${item['precio']} c/u',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFEEF2F6),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL PREVIO:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  '\$${totalPrevio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            height: 2,
            color: Brand.coral,
          ),
        ],

        if (_carrito.isEmpty && historialItems.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'La cuenta está en blanco.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else if (_carrito.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            width: double.infinity,
            child: const Text(
              'NUEVA ORDEN',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _carrito.length,
              itemBuilder: (context, index) {
                var item = _carrito[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Brand.navy,
                        child: Text(
                          '${item['cantidad']}x',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nombre']?.toString().toUpperCase() ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '\$${item['precio']} c/u',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            if (item['nota'] != null && item['nota'] != '')
                              Text(
                                'Nota: ${item['nota']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.redAccent,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: Brand.teal,
                          size: 28,
                        ),
                        onPressed: () => _editarComentario(index),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                          size: 26,
                        ),
                        onPressed: () => _quitarDelCarrito(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${totalNuevo.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _carrito.isEmpty ? null : _enviarOrden,
                  icon: Icon(
                    Icons.send,
                    color: _carrito.isEmpty ? Colors.grey : Colors.white,
                  ),
                  label: Text(
                    'ENVIAR A COCINA / BARRA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _carrito.isEmpty ? Colors.grey : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _carrito.isEmpty
                        ? Colors.grey.shade300
                        : Brand.coral,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.background,
      appBar: AppBar(
        title: Text(
          _vistaActual == 0 ? 'Mesas' : 'Mesa $_mesaSeleccionada · Nueva orden',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Brand.navy,
        leading: _vistaActual == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _vistaActual = 0;
                    _carrito.clear();
                  });
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _vistaActual == 0 ? _buildMapaMesas() : _buildTomaPedidos(),
      ),
    );
  }
}
