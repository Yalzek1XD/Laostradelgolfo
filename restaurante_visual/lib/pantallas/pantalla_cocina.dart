import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../responsive.dart';
import '../ui/brand.dart';

class PantallaCocina extends StatelessWidget {
  const PantallaCocina({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.background,
      appBar: AppBar(
        title: const Text(
          'Comandas Pendientes - COCINA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Brand.navy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('comandas')
              .where('estado', isEqualTo: 'PENDIENTE')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'No se pudieron cargar las comandas.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Todo listo por ahora\nNo hay comandas pendientes',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.gridColumns(
                    constraints.maxWidth,
                    phone: 1,
                    tablet: 2,
                    wide: 4,
                    minItemWidth: 310,
                  ),
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.8,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return _construirTarjetaComandaCocina(context, doc);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _construirTarjetaComandaCocina(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) {
    var data = doc.data() as Map<String, dynamic>;
    var items = data['items'] as List<dynamic>? ?? [];
    var timestamp = data['fecha'] as Timestamp;
    String horaFormateada = DateFormat('hh:mm a').format(timestamp.toDate());
    String nombreMesero = data['mesero_nombre'] ?? 'Sin Nombre';

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Brand.navy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NUEVA COMANDA',
                      style: TextStyle(
                        color: Brand.aqua,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'MESA ${data['mesa']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mesero: $nombreMesero',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Recibida: $horaFormateada',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                var item = items[i];
                int cantidad = item['cantidad'] ?? 0;
                String platillo = item['nombre'] ?? 'Sin Nombre';
                String comentario = item['comentario'] ?? '';

                return Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Brand.coral.withOpacity(.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$cantidad',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Brand.coral,
                          ),
                        ),
                      ),
                      title: Text(
                        platillo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: comentario.isNotEmpty
                          ? Text(
                              '📝 Nota: $comentario',
                              style: const TextStyle(
                                color: Brand.coral,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton.icon(
              onPressed: () => _marcarComandaComoLista(context, doc.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Brand.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'MARCAR COMO LISTA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _marcarComandaComoLista(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('comandas').doc(docId).update(
        {'estado': 'LISTO'},
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Comanda despachada!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
