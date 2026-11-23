import 'package:flutter/material.dart';
import 'package:skillship/data/repositorio_empresa.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/models/postulacion.dart';
import 'package:skillship/models/reclamo.dart';
import 'package:skillship/models/solicitud.dart';
import 'package:skillship/models/usuario.dart';
import 'package:skillship/ui/widgets/perfil_empresa.dart';

class EmpresaDetallePasanteScreen extends StatefulWidget {
  final Solicitud solicitud;
  final Usuario usuario;

  const EmpresaDetallePasanteScreen({
    super.key,
    required this.solicitud,
    required this.usuario,
  });

  @override
  State<EmpresaDetallePasanteScreen> createState() =>
      _EmpresaDetallePasanteScreenState();
}

class _EmpresaDetallePasanteScreenState
    extends State<EmpresaDetallePasanteScreen> {
  List<RegistroHora> _horas = [];
  List<Reclamo> _reclamos = [];

  bool _cargando = true;
  String? _error;

  double get _horasTotal =>
      _horas.fold<double>(0, (total, h) => total + h.horas);

  bool get _esPasante => widget.solicitud.estado == 'en_proceso';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final horas = await RepositorioEmpresa.instance.obtenerHoras(
        postulacionId: widget.solicitud.id,
      );
      final reclamos = await RepositorioEmpresa.instance.obtenerReclamos(
        postulacionId: widget.solicitud.id,
      );

      if (!mounted) return;
      setState(() {
        _horas = horas;
        _reclamos = reclamos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = SupabaseService.mensajeError(e);
        _cargando = false;
      });
    }
  }

  void _mostrarAviso(String mensaje, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  // ---------------------------------------------------------------------------
  // CARGAR HORAS DEL PASANTE
  // ---------------------------------------------------------------------------
  Future<void> _cargarHoras() async {
    final fechaController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final horasController = TextEditingController();
    final descripcionController = TextEditingController();

    final guardado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Cargar horas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fechaController,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Fecha (AAAA-MM-DD)',
                  labelStyle: TextStyle(fontSize: 13),
                  hintText: '2026-09-21',
                  hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                  filled: true,
                  fillColor: Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: horasController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Horas',
                  labelStyle: TextStyle(fontSize: 13),
                  hintText: '8',
                  hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                  filled: true,
                  fillColor: Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: TextStyle(fontSize: 13),
                  hintText: 'Qué se hizo en esa jornada',
                  hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                  filled: true,
                  fillColor: Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cargar',
              style: TextStyle(
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (guardado != true) return;

    final horas = double.tryParse(horasController.text.trim().replaceAll(',', '.'));
    if (horas == null || horas <= 0) {
      _mostrarAviso('Ingresá las horas cargadas.', color: Colors.redAccent);
      return;
    }

    try {
      await RepositorioEmpresa.instance.cargarHoras(
        postulacionId: widget.solicitud.id,
        fecha: fechaController.text.trim(),
        horas: horas,
        descripcion: descripcionController.text,
      );
      _mostrarAviso('Horas cargadas', color: const Color(0xFF2D2D2D));
      await _cargar();
    } catch (e) {
      _mostrarAviso(SupabaseService.mensajeError(e), color: Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101D),
      body: SafeArea(
        child: Row(
          children: [
            // ================= PANEL LATERAL (SIDEBAR FIJO) =================
            Container(
              width: 100,
              color: const Color(0xFF6A7389),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => mostrarPerfilEmpresa(context, widget.usuario),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(
                        child: Text(
                          'Perfil',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cerrar Sesión',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        SizedBox(height: 8),
                        Icon(Icons.logout, color: Colors.black, size: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= CONTENIDO PRINCIPAL =================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Botón de retroceso
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAFA2A2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _contenido(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D2D2D)),
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cargar,
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Color(0xFF2D2D2D)),
            ),
          ),
        ],
      );
    }

    final solicitud = widget.solicitud;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            solicitud.nombreAlumno.isNotEmpty
                ? solicitud.nombreAlumno
                : 'Postulante',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            solicitud.carreraAlumno,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pasantía',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${solicitud.tituloPasantia}\n'
            '${solicitud.empresaPasantia}\n'
            '${solicitud.estadoLegible}'
            '${solicitud.tutor != null ? '\nTutor: ${solicitud.tutor}' : ''}'
            '${solicitud.fechaInicio != null ? '\nInicio: ${solicitud.fechaInicioLegible}' : ''}',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          const Text(
            'Horas trabajadas\n(Semanales)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total acumulado: ${_horasTotal.toStringAsFixed(0)} h',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (_horas.isEmpty)
            const Text(
              'Todavía no se cargaron horas.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            )
          else
            ..._horas.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${h.fecha} · ${h.horas.toStringAsFixed(0)} h'
                  '${h.descripcion.isNotEmpty ? ' · ${h.descripcion}' : ''}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Reclamos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (_reclamos.isEmpty)
            const Text(
              'Sin reclamos.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            )
          else
            ..._reclamos.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${r.mensaje} (${r.estado})',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (_esPasante)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _cargarHoras,
                child: const Text(
                  'Cargar horas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
