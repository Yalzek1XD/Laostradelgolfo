import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'pantalla_compras.dart';
import 'pantalla_contabilidad.dart';
import 'pantalla_cajero.dart';
import '../responsive.dart';

class UpperTextFormatterGerente extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) return oldValue;
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) newText += '/';
      newText += text[i];
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class BaseDatos {
  static List<Map<String, String>> personal = [];
}

class PantallaGerente extends StatefulWidget {
  const PantallaGerente({super.key});
  @override
  State<PantallaGerente> createState() => _PantallaGerenteState();
}

class _PantallaGerenteState extends State<PantallaGerente> {
  bool _editandoPersonal = false;
  bool _editandoReceta = false;
  bool _editandoInsumo = false;
  bool _editandoProveedor = false;

  final TextEditingController _c1 = TextEditingController();
  final TextEditingController _c2 = TextEditingController();
  final TextEditingController _c3 = TextEditingController();
  String? _rolSeleccionado;

  final TextEditingController _pId = TextEditingController();
  final TextEditingController _pRfc = TextEditingController();
  final TextEditingController _pNom = TextEditingController();
  final TextEditingController _pCor = TextEditingController();
  final TextEditingController _pTel = TextEditingController();
  final TextEditingController _pDir = TextEditingController();
  String? _pInsumoSeleccionado;
  List<String> _productosProveedorDraft = [];

  final TextEditingController _iId = TextEditingController();
  final TextEditingController _iNom = TextEditingController();
  final TextEditingController _iStockAct = TextEditingController();
  final TextEditingController _iStockMin = TextEditingController();
  String? _iUniMed;

  final TextEditingController _rId = TextEditingController();
  final TextEditingController _rNom = TextEditingController();
  final TextEditingController _rTiempo = TextEditingController();
  final TextEditingController _rCantIng = TextEditingController();
  String? _rInsumoSeleccionado;
  String? _rNombreInsumoSeleccionado;
  String? _rUniMed;
  List<Map<String, dynamic>> _ingredientesDraft = [];

  void _limpiarGenerico() {
    _c1.clear();
    _c2.clear();
    _c3.clear();
    setState(() {
      _rolSeleccionado = null;
      _editandoPersonal = false;
    });
  }

  void _limpiarProveedor() {
    _pId.clear();
    _pRfc.clear();
    _pNom.clear();
    _pCor.clear();
    _pTel.clear();
    _pDir.clear();
    setState(() {
      _pInsumoSeleccionado = null;
      _productosProveedorDraft.clear();
      _editandoProveedor = false;
    });
  }

  void _limpiarInsumo() {
    _iId.clear();
    _iNom.clear();
    _iStockAct.clear();
    _iStockMin.clear();
    setState(() {
      _iUniMed = null;
      _editandoInsumo = false;
    });
  }

  void _limpiarRecetas() {
    _rId.clear();
    _rNom.clear();
    _rTiempo.clear();
    _rCantIng.clear();
    setState(() {
      _rInsumoSeleccionado = null;
      _rNombreInsumoSeleccionado = null;
      _rUniMed = null;
      _ingredientesDraft.clear();
      _editandoReceta = false;
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool> _confirmarEdicion() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Deseas modificar?'),
            content: const Text('Se guardarán los cambios en el sistema.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí, modificar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _verIngredientes(List ingredientes, String nombrePlatillo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ingredientes: $nombrePlatillo',
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 300,
          child: ingredientes.isEmpty
              ? const Text('No tiene ingredientes registrados.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: ingredientes.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: const Icon(Icons.kitchen, color: Colors.grey),
                    title: Text(
                      ingredientes[i]['nomInsumo'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${ingredientes[i]['cant']} ${ingredientes[i]['uniMed'] ?? ''}',
                    ),
                  ),
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

  Future<void> _abrirFormularioPersonal() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_editandoPersonal ? 'Editar personal' : 'Nuevo personal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input('ID Empleado', _c1),
              _input('Nombre', _c2),
              _input('Teléfono / Turno', _c3, isUpper: false),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _rolSeleccionado,
                items: ['Cocinero', 'Mesero', 'Cajero']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _rolSeleccionado = value),
                decoration: const InputDecoration(labelText: 'Rol'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (_c1.text.isEmpty ||
                  _c2.text.isEmpty ||
                  _rolSeleccionado == null) {
                _mostrarError('ID, Nombre y Rol son obligatorios');
                return;
              }
              if (_editandoPersonal) {
                BaseDatos.personal.removeWhere((p) => p['id'] == _c1.text);
              } else if (BaseDatos.personal.any((p) => p['id'] == _c1.text)) {
                _mostrarError('El ID ya existe');
                return;
              }
              setState(
                () => BaseDatos.personal.add({
                  'id': _c1.text,
                  'nom': _c2.text,
                  'ext': _c3.text,
                  'rol': _rolSeleccionado!,
                }),
              );
              _limpiarGenerico();
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFormularioInsumo() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_editandoInsumo ? 'Editar insumo' : 'Nuevo insumo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input('ID Insumo', _iId),
              _input('Nombre', _iNom),
              _input('Stock Actual', _iStockAct, isNum: true),
              _input('Stock Mínimo', _iStockMin, isNum: true),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _iUniMed,
                items:
                    [
                          'Kilos',
                          'Gramos',
                          'Litros',
                          'Mililitros',
                          'Piezas',
                          'Porciones',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (value) => setState(() => _iUniMed = value),
                decoration: const InputDecoration(labelText: 'Unidad'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (_iId.text.isEmpty || _iNom.text.isEmpty || _iUniMed == null) {
                _mostrarError('ID, Nombre y Unidad son obligatorios');
                return;
              }
              await FirebaseFirestore.instance
                  .collection('insumos')
                  .doc(_iId.text.trim())
                  .set({
                    'id': _iId.text.trim(),
                    'nom': _iNom.text.trim(),
                    'stockAct': _iStockAct.text.trim(),
                    'stockMin': _iStockMin.text.trim(),
                    'uniMed': _iUniMed,
                  });
              _limpiarInsumo();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFormularioProveedor() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _editandoProveedor ? 'Editar proveedor' : 'Nuevo proveedor',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input('ID Proveedor', _pId),
              _input('RFC', _pRfc),
              _input('Nombre Empresa', _pNom),
              _input('Correo', _pCor, isUpper: false),
              _input('Teléfono', _pTel, isUpper: false),
              _input('Dirección', _pDir),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('insumos')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final items = snapshot.data!.docs
                      .map((doc) => doc['nom'].toString())
                      .toSet()
                      .toList();
                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _pInsumoSeleccionado,
                    items: items
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _pInsumoSeleccionado = value),
                    decoration: const InputDecoration(
                      labelText: 'Producto que vende',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (_pId.text.isEmpty || _pNom.text.isEmpty) {
                _mostrarError('ID y Nombre son obligatorios');
                return;
              }
              await FirebaseFirestore.instance
                  .collection('proveedores')
                  .doc(_pId.text.trim())
                  .set({
                    'id': _pId.text.trim(),
                    'rfc': _pRfc.text.trim(),
                    'nom': _pNom.text.trim(),
                    'producto': _productosProveedorDraft.isEmpty
                        ? (_pInsumoSeleccionado ?? '')
                        : _productosProveedorDraft.join(', '),
                    'cor': _pCor.text.trim(),
                    'tel': _pTel.text.trim(),
                    'dir': _pDir.text.trim(),
                  });
              _limpiarProveedor();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFormularioReceta() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_editandoReceta ? 'Editar receta' : 'Nueva receta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input('ID Platillo', _rId),
              _input('Nombre de Platillo', _rNom),
              _input('Tiempo de Preparación', _rTiempo, isUpper: false),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('insumos')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final items = snapshot.data!.docs
                      .map(
                        (doc) => DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(
                            doc['nom'].toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList();
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _rInsumoSeleccionado,
                        items: items,
                        onChanged: (value) => setState(() {
                          _rInsumoSeleccionado = value;
                          _rNombreInsumoSeleccionado = snapshot.data!.docs
                              .firstWhere((doc) => doc.id == value)['nom'];
                        }),
                        decoration: const InputDecoration(labelText: 'Insumo'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _input('Cantidad', _rCantIng, isNum: true),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _rUniMed,
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
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) =>
                                  setState(() => _rUniMed = value),
                              decoration: const InputDecoration(
                                labelText: 'Unidad',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.indigo,
                            ),
                            onPressed: () {
                              if (_rInsumoSeleccionado == null ||
                                  _rCantIng.text.isEmpty ||
                                  _rUniMed == null)
                                return;
                              setState(() {
                                _ingredientesDraft.add({
                                  'idInsumo': _rInsumoSeleccionado,
                                  'nomInsumo': _rNombreInsumoSeleccionado,
                                  'cant': double.tryParse(_rCantIng.text) ?? 1,
                                  'uniMed': _rUniMed,
                                });
                                _rCantIng.clear();
                                _rInsumoSeleccionado = null;
                                _rUniMed = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              if (_ingredientesDraft.isNotEmpty)
                ..._ingredientesDraft.map(
                  (item) => ListTile(
                    dense: true,
                    title: Text(item['nomInsumo'].toString()),
                    subtitle: Text('${item['cant']} ${item['uniMed']}'),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (_rId.text.isEmpty ||
                  _rNom.text.isEmpty ||
                  _ingredientesDraft.isEmpty) {
                _mostrarError('Agrega los datos y al menos un ingrediente');
                return;
              }
              await FirebaseFirestore.instance
                  .collection('recetas')
                  .doc(_rId.text.trim())
                  .set({
                    'id': _rId.text.trim(),
                    'nom': _rNom.text.trim(),
                    'nom_busqueda': _rNom.text.trim().toUpperCase(),
                    'tiempo': _rTiempo.text.trim(),
                    'ingredientes': _ingredientesDraft,
                  });
              _limpiarRecetas();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Panel de Administración Mr. Pulpo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0A192F),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.tealAccent,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'PERSONAL'),
              Tab(icon: Icon(Icons.point_of_sale), text: 'CAJA'),
              Tab(icon: Icon(Icons.account_balance), text: 'CONTABILIDAD'),
              Tab(icon: Icon(Icons.restaurant), text: 'RECETAS'),
              Tab(icon: Icon(Icons.kitchen), text: 'INSUMOS'),
              Tab(icon: Icon(Icons.local_shipping), text: 'PROVEEDOR'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'COMPRAS'),
            ],
          ),
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
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ClipRect(child: _vistaPersonal()),
              const PantallaCajero(),
              const ClipRect(child: PantallaContabilidad()),
              ClipRect(child: _vistaRecetas()),
              ClipRect(child: _vistaInsumos()),
              ClipRect(child: _vistaProveedor()),
              const ClipRect(child: PantallaCompras()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vistaRecetas() {
    final vertical =
        MediaQuery.sizeOf(context).width < Responsive.tabletBreakpoint;
    return Flex(
      direction: vertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!vertical)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _editandoReceta ? 'Editar Receta' : 'Nueva Receta',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _input('ID Platillo', _rId),
                    _input('Nombre de Platillo', _rNom),
                    _input('Tiempo de Preparación', _rTiempo, isUpper: false),
                    const Divider(height: 30, thickness: 1.5),
                    const Text(
                      'Agregar Ingredientes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('insumos')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData)
                                return const LinearProgressIndicator();
                              List<DropdownMenuItem<String>> items = snapshot
                                  .data!
                                  .docs
                                  .map(
                                    (doc) => DropdownMenuItem<String>(
                                      value: doc.id,
                                      child: Text(
                                        doc['nom'].toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList();
                              return DropdownButtonFormField<String>(
                                isExpanded: true,
                                value:
                                    items.any(
                                      (i) => i.value == _rInsumoSeleccionado,
                                    )
                                    ? _rInsumoSeleccionado
                                    : null,
                                items: items,
                                onChanged: (val) {
                                  setState(() {
                                    _rInsumoSeleccionado = val;
                                    _rNombreInsumoSeleccionado = snapshot
                                        .data!
                                        .docs
                                        .firstWhere((d) => d.id == val)['nom'];
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Insumo',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 15,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _rCantIng,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Cant.',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _rUniMed,
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
                            onChanged: (val) => setState(() => _rUniMed = val),
                            decoration: const InputDecoration(
                              labelText: 'Unidad',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.indigo,
                            size: 35,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (_rInsumoSeleccionado == null ||
                                _rCantIng.text.isEmpty ||
                                _rUniMed == null) {
                              _mostrarError('Llena insumo, cantidad y unidad');
                              return;
                            }
                            setState(() {
                              _ingredientesDraft.add({
                                'idInsumo': _rInsumoSeleccionado,
                                'nomInsumo': _rNombreInsumoSeleccionado,
                                'cant': double.tryParse(_rCantIng.text) ?? 1.0,
                                'uniMed': _rUniMed,
                              });
                              _rCantIng.clear();
                              _rInsumoSeleccionado = null;
                              _rUniMed = null;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_ingredientesDraft.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.builder(
                          itemCount: _ingredientesDraft.length,
                          itemBuilder: (context, idx) => ListTile(
                            dense: true,
                            title: Text(_ingredientesDraft[idx]['nomInsumo']),
                            subtitle: Text(
                              'Cantidad: ${_ingredientesDraft[idx]['cant']} ${_ingredientesDraft[idx]['uniMed']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () => setState(
                                () => _ingredientesDraft.removeAt(idx),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_rId.text.isEmpty ||
                                  _rNom.text.isEmpty ||
                                  _ingredientesDraft.isEmpty) {
                                _mostrarError(
                                  'Llena los campos y agrega ingredientes',
                                );
                                return;
                              }
                              if (_editandoReceta) {
                                bool confirma = await _confirmarEdicion();
                                if (!confirma) return;
                              }
                              try {
                                var doc = await FirebaseFirestore.instance
                                    .collection('recetas')
                                    .doc(_rId.text.trim())
                                    .get();
                                if (doc.exists && !_editandoReceta) {
                                  _mostrarError(
                                    'El ID ya existe. Usa lápiz para editar.',
                                  );
                                  return;
                                }
                                await FirebaseFirestore.instance
                                    .collection('recetas')
                                    .doc(_rId.text.trim())
                                    .set({
                                      'id': _rId.text.trim(),
                                      'nom': _rNom.text.trim(),
                                      'nom_busqueda': _rNom.text
                                          .trim()
                                          .toUpperCase(),
                                      'tiempo': _rTiempo.text.trim(),
                                      'ingredientes': _ingredientesDraft,
                                    });
                                _limpiarRecetas();
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Receta guardada/actualizada',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                              } catch (e) {
                                _mostrarError('Error al guardar: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: const Icon(Icons.save),
                            label: Text(
                              _editandoReceta ? 'MODIFICAR' : 'GUARDAR',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _limpiarRecetas,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _editandoReceta
                                  ? Colors.red
                                  : Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: Icon(
                              _editandoReceta
                                  ? Icons.cancel
                                  : Icons.cleaning_services,
                            ),
                            label: Text(
                              _editandoReceta ? 'CANCELAR' : 'LIMPIAR',
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
        if (vertical)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilledButton.icon(
              onPressed: _abrirFormularioReceta,
              icon: const Icon(Icons.add),
              label: const Text('NUEVA RECETA'),
            ),
          ),
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recetas')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey[200],
                      ),
                      columns: const [
                        DataColumn(label: Text('ID Platillo')),
                        DataColumn(label: Text('Nombre Platillo')),
                        DataColumn(label: Text('Tiempo Prep.')),
                        DataColumn(label: Text('Ingredientes')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: snapshot.data!.docs.map((doc) {
                        var e = doc.data() as Map<String, dynamic>;
                        List ings = e['ingredientes'] ?? [];
                        return DataRow(
                          cells: [
                            DataCell(Text(e['id'] ?? '')),
                            DataCell(
                              Text(
                                e['nom'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(e['tiempo'] ?? '')),
                            DataCell(
                              IconButton(
                                icon: const Icon(
                                  Icons.folder,
                                  color: Colors.amber,
                                  size: 30,
                                ),
                                tooltip: 'Ver Ingredientes',
                                onPressed: () =>
                                    _verIngredientes(ings, e['nom']),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Editar Receta',
                                    onPressed: () {
                                      setState(() {
                                        _rId.text = e['id'] ?? '';
                                        _rNom.text = e['nom'] ?? '';
                                        _rTiempo.text = e['tiempo'] ?? '';
                                        _ingredientesDraft =
                                            List<Map<String, dynamic>>.from(
                                              e['ingredientes'] ?? [],
                                            );
                                        _editandoReceta = true;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Borrar',
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('recetas')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _vistaPersonal() {
    final vertical =
        MediaQuery.sizeOf(context).width < Responsive.tabletBreakpoint;
    return Flex(
      direction: vertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!vertical)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _editandoPersonal ? 'Editar Personal' : 'Nuevo Personal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _input('ID Empleado', _c1),
                    _input('Nombre', _c2),
                    _input('Teléfono / Turno', _c3, isUpper: false),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _rolSeleccionado,
                        items: ['Cocinero', 'Mesero', 'Cajero']
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _rolSeleccionado = val),
                        decoration: const InputDecoration(
                          labelText: 'Rol de Empleado',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_c1.text.isEmpty ||
                                  _c2.text.isEmpty ||
                                  _rolSeleccionado == null) {
                                _mostrarError(
                                  'ID, Nombre y Rol son obligatorios',
                                );
                                return;
                              }
                              if (_editandoPersonal) {
                                bool confirma = await _confirmarEdicion();
                                if (!confirma) return;
                                BaseDatos.personal.removeWhere(
                                  (p) => p['id'] == _c1.text,
                                );
                              } else if (BaseDatos.personal.any(
                                (p) => p['id'] == _c1.text,
                              )) {
                                _mostrarError(
                                  'El ID ya existe. Usa el lápiz para editar.',
                                );
                                return;
                              }
                              setState(
                                () => BaseDatos.personal.add({
                                  'id': _c1.text,
                                  'nom': _c2.text,
                                  'ext': _c3.text,
                                  'rol': _rolSeleccionado!,
                                }),
                              );
                              _limpiarGenerico();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: const Icon(Icons.save),
                            label: Text(
                              _editandoPersonal ? 'MODIFICAR' : 'GUARDAR',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _limpiarGenerico,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _editandoPersonal
                                  ? Colors.red
                                  : Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: Icon(
                              _editandoPersonal
                                  ? Icons.cancel
                                  : Icons.cleaning_services,
                            ),
                            label: Text(
                              _editandoPersonal ? 'CANCELAR' : 'LIMPIAR',
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
        if (vertical)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilledButton.icon(
              onPressed: _abrirFormularioPersonal,
              icon: const Icon(Icons.person_add),
              label: const Text('NUEVO PERSONAL'),
            ),
          ),
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Rol')),
                    DataColumn(label: Text('Teléfono/Turno')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: BaseDatos.personal
                      .map(
                        (e) => DataRow(
                          cells: [
                            DataCell(Text(e['id'] ?? '')),
                            DataCell(Text(e['nom'] ?? '')),
                            DataCell(
                              Text(
                                e['rol'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            DataCell(Text(e['ext'] ?? '')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      setState(() {
                                        _c1.text = e['id']!;
                                        _c2.text = e['nom']!;
                                        _c3.text = e['ext']!;
                                        _rolSeleccionado = e['rol'];
                                        _editandoPersonal = true;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Borrar',
                                    onPressed: () => setState(
                                      () => BaseDatos.personal.remove(e),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vistaInsumos() {
    final vertical =
        MediaQuery.sizeOf(context).width < Responsive.tabletBreakpoint;
    return Flex(
      direction: vertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!vertical)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _editandoInsumo ? 'Editar Insumo' : 'Nuevo Insumo',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _input('ID Insumo', _iId),
                    _input('Nombre de Insumo', _iNom),
                    _input('Stock Actual', _iStockAct, isNum: true),
                    _input('Stock Mínimo', _iStockMin, isNum: true),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _iUniMed,
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
                        onChanged: (val) => setState(() => _iUniMed = val),
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Cantidad',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_iId.text.isEmpty ||
                                  _iNom.text.isEmpty ||
                                  _iUniMed == null) {
                                _mostrarError(
                                  'ID, Nombre y Tipo son obligatorios',
                                );
                                return;
                              }
                              if (_editandoInsumo) {
                                bool confirma = await _confirmarEdicion();
                                if (!confirma) return;
                              }
                              try {
                                var doc = await FirebaseFirestore.instance
                                    .collection('insumos')
                                    .doc(_iId.text.trim())
                                    .get();
                                if (doc.exists && !_editandoInsumo) {
                                  _mostrarError(
                                    'El ID ya existe. Usa lápiz para editar.',
                                  );
                                  return;
                                }
                                await FirebaseFirestore.instance
                                    .collection('insumos')
                                    .doc(_iId.text.trim())
                                    .set({
                                      'id': _iId.text.trim(),
                                      'nom': _iNom.text.trim(),
                                      'stockAct': _iStockAct.text.trim(),
                                      'stockMin': _iStockMin.text.trim(),
                                      'uniMed': _iUniMed,
                                    });
                                _limpiarInsumo();
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Insumo guardado/actualizado',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                              } catch (e) {
                                _mostrarError('Error: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: const Icon(Icons.save),
                            label: Text(
                              _editandoInsumo ? 'MODIFICAR' : 'GUARDAR',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _limpiarInsumo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _editandoInsumo
                                  ? Colors.red
                                  : Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: Icon(
                              _editandoInsumo
                                  ? Icons.cancel
                                  : Icons.cleaning_services,
                            ),
                            label: Text(
                              _editandoInsumo ? 'CANCELAR' : 'LIMPIAR',
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
        if (vertical)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilledButton.icon(
              onPressed: _abrirFormularioInsumo,
              icon: const Icon(Icons.add_box),
              label: const Text('NUEVO INSUMO'),
            ),
          ),
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('insumos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey[200],
                      ),
                      columns: const [
                        DataColumn(label: Text('ID Insumo')),
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Stock Actual')),
                        DataColumn(label: Text('Stock Mínimo')),
                        DataColumn(label: Text('Tipo Cantidad')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: snapshot.data!.docs.map((doc) {
                        var e = doc.data() as Map<String, dynamic>;
                        double stockAct =
                            double.tryParse(e['stockAct']?.toString() ?? '0') ??
                            0;
                        double stockMin =
                            double.tryParse(e['stockMin']?.toString() ?? '0') ??
                            0;
                        bool alertaStock = stockAct <= stockMin;
                        String stockTexto = stockAct % 1 == 0
                            ? stockAct.toInt().toString()
                            : stockAct.toString();
                        return DataRow(
                          cells: [
                            DataCell(Text(e['id'] ?? '')),
                            DataCell(Text(e['nom'] ?? '')),
                            DataCell(
                              Row(
                                children: [
                                  Text(
                                    stockTexto,
                                    style: TextStyle(
                                      color: alertaStock
                                          ? Colors.red
                                          : Colors.black,
                                      fontWeight: alertaStock
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: alertaStock ? 16 : 14,
                                    ),
                                  ),
                                  if (alertaStock) const SizedBox(width: 5),
                                  if (alertaStock)
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text(e['stockMin'] ?? '')),
                            DataCell(Text(e['uniMed'] ?? '')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Editar Insumo',
                                    onPressed: () {
                                      setState(() {
                                        _iId.text = e['id'] ?? '';
                                        _iNom.text = e['nom'] ?? '';
                                        _iStockAct.text =
                                            e['stockAct']?.toString() ?? '';
                                        _iStockMin.text =
                                            e['stockMin']?.toString() ?? '';
                                        _iUniMed = e['uniMed'];
                                        _editandoInsumo = true;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Eliminar Insumo',
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('insumos')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _vistaProveedor() {
    final vertical =
        MediaQuery.sizeOf(context).width < Responsive.tabletBreakpoint;
    return Flex(
      direction: vertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!vertical)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _editandoProveedor
                          ? 'Editar Proveedor'
                          : 'Nuevo Proveedor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _input('ID Proveedor', _pId),
                    _input('RFC', _pRfc),
                    _input('Nombre Empresa', _pNom),
                    _input('Correo', _pCor, isUpper: false),
                    _input('Teléfono', _pTel, isUpper: false),
                    _input('Dirección', _pDir),
                    const Divider(height: 30, thickness: 1.5),
                    const Text(
                      'Agregar Productos que Vende',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('insumos')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData)
                                return const LinearProgressIndicator();
                              List<DropdownMenuItem<String>> items = snapshot
                                  .data!
                                  .docs
                                  .map(
                                    (doc) => DropdownMenuItem<String>(
                                      value: doc['nom'].toString(),
                                      child: Text(
                                        doc['nom'].toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList();
                              return DropdownButtonFormField<String>(
                                isExpanded: true,
                                value:
                                    items.any(
                                      (i) => i.value == _pInsumoSeleccionado,
                                    )
                                    ? _pInsumoSeleccionado
                                    : null,
                                items: items,
                                onChanged: (val) {
                                  setState(() {
                                    _pInsumoSeleccionado = val;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Selecciona Producto',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 15,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.indigo,
                            size: 35,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (_pInsumoSeleccionado != null &&
                                !_productosProveedorDraft.contains(
                                  _pInsumoSeleccionado,
                                )) {
                              setState(() {
                                _productosProveedorDraft.add(
                                  _pInsumoSeleccionado!,
                                );
                                _pInsumoSeleccionado = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (_productosProveedorDraft.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.builder(
                          itemCount: _productosProveedorDraft.length,
                          itemBuilder: (context, idx) => ListTile(
                            dense: true,
                            title: Text(_productosProveedorDraft[idx]),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () => setState(
                                () => _productosProveedorDraft.removeAt(idx),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_pId.text.isEmpty || _pNom.text.isEmpty) {
                                _mostrarError('ID y Nombre son obligatorios');
                                return;
                              }
                              if (_editandoProveedor) {
                                bool confirma = await _confirmarEdicion();
                                if (!confirma) return;
                              }
                              try {
                                var doc = await FirebaseFirestore.instance
                                    .collection('proveedores')
                                    .doc(_pId.text.trim())
                                    .get();
                                if (doc.exists && !_editandoProveedor) {
                                  _mostrarError(
                                    'El ID ya existe. Usa el lápiz para editar.',
                                  );
                                  return;
                                }
                                String listadoProductos =
                                    _productosProveedorDraft.join(', ');
                                await FirebaseFirestore.instance
                                    .collection('proveedores')
                                    .doc(_pId.text.trim())
                                    .set({
                                      'id': _pId.text.trim(),
                                      'rfc': _pRfc.text.trim(),
                                      'nom': _pNom.text.trim(),
                                      'producto': listadoProductos,
                                      'cor': _pCor.text.trim(),
                                      'tel': _pTel.text.trim(),
                                      'dir': _pDir.text.trim(),
                                    });
                                _limpiarProveedor();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '✅ Proveedor Guardado / Actualizado',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                _mostrarError('Error al guardar: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: const Icon(Icons.save),
                            label: Text(
                              _editandoProveedor ? 'MODIFICAR' : 'GUARDAR',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _limpiarProveedor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _editandoProveedor
                                  ? Colors.red
                                  : Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: Icon(
                              _editandoProveedor
                                  ? Icons.cancel
                                  : Icons.cleaning_services,
                            ),
                            label: Text(
                              _editandoProveedor ? 'CANCELAR' : 'LIMPIAR',
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
        if (vertical)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilledButton.icon(
              onPressed: _abrirFormularioProveedor,
              icon: const Icon(Icons.local_shipping),
              label: const Text('NUEVO PROVEEDOR'),
            ),
          ),
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('proveedores')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(
                    child: Text(
                      "No hay proveedores en la base de datos.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey[200],
                      ),
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('RFC')),
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Productos')),
                        DataColumn(label: Text('Teléfono')),
                        DataColumn(label: Text('Dirección')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: snapshot.data!.docs.map((doc) {
                        var p = doc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(Text(p['id'] ?? '')),
                            DataCell(Text(p['rfc'] ?? '')),
                            DataCell(Text(p['nom'] ?? '')),
                            DataCell(
                              Text(
                                p['producto'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            DataCell(Text(p['tel'] ?? '')),
                            DataCell(Text(p['dir'] ?? '')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      setState(() {
                                        _pId.text = p['id'] ?? '';
                                        _pRfc.text = p['rfc'] ?? '';
                                        _pNom.text = p['nom'] ?? '';
                                        _pCor.text = p['cor'] ?? '';
                                        _pTel.text = p['tel'] ?? '';
                                        _pDir.text = p['dir'] ?? '';
                                        _productosProveedorDraft =
                                            p['producto'] != null &&
                                                p['producto']
                                                    .toString()
                                                    .isNotEmpty
                                            ? p['producto']
                                                  .toString()
                                                  .split(', ')
                                                  .toList()
                                            : [];
                                        _editandoProveedor = true;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Borrar',
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('proveedores')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _input(
    String label,
    TextEditingController ctrl, {
    bool isNum = false,
    bool isDate = false,
    bool isUpper = true,
  }) {
    List<TextInputFormatter> formats = [];
    if (isDate) formats.add(DateInputFormatter());
    if (isNum)
      formats.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')));
    if (isUpper && !isNum && !isDate) formats.add(UpperTextFormatterGerente());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: isDate || isNum
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: formats,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
