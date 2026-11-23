import 'package:flutter/material.dart';
import 'package:skillship/data/repositorio_pasantias.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/models/alumno.dart';
import 'package:skillship/models/postulacion.dart';
import 'package:skillship/models/usuario.dart';
import 'package:skillship/ui/widgets/perfil_universidad.dart';

class UniversidadDetalleAlumnoScreen extends StatefulWidget {
  final Alumno alumno;
  final Usuario usuario;

  const UniversidadDetalleAlumnoScreen({
    super.key,
    required this.alumno,
    required this.usuario,
  });

  @override
  State<UniversidadDetalleAlumnoScreen> createState() =>
      _UniversidadDetalleAlumnoScreenState();
}

class _UniversidadDetalleAlumnoScreenState
    extends State<UniversidadDetalleAlumnoScreen> {
  List<Postulacion> _postulaciones = [];

  /// horas cargadas por postulación (id de postulación -> horas)
  final Map<int, double> _horasPorPostulacion = {};
  double _horasTotal = 0;

  bool _cargando = true;
  String? _error;

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
      final postulaciones =
          await RepositorioPasantias.instance.obtenerPostulaciones(
        usuarioId: widget.alumno.usuarioId,
      );

      // Las horas de cada postulación (es poquita data: se traen en serie).
      final horasPorPost = <int, double>{};
      var total = 0.0;
      for (final p in postulaciones) {
        final horas =
            await RepositorioPasantias.instance.obtenerHoras(postulacionId: p.id);
        final suma = horas.fold<double>(0, (a, h) => a + h.horas);
        horasPorPost[p.id] = suma;
        total += suma;
      }

      if (!mounted) return;
      setState(() {
        _postulaciones = postulaciones;
        _horasPorPostulacion
          ..clear()
          ..addAll(horasPorPost);
        _horasTotal = total;
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
                    onTap: () =>
                        mostrarPerfilUniversidad(context, widget.usuario),
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

            // ================= CONTENIDO PRINCIPAL DE DETALLE DEL ALUMNO =================
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
                          color: const Color(0xFFAFA2A2), // Color de tarjeta según diseño
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

    final alumno = widget.alumno;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del alumno (viene de la base de datos)
          Text(
            alumno.nombre,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Descripcion',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${alumno.carrera}\n${alumno.institucion}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
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
          const SizedBox(height: 16),
          if (_postulaciones.isEmpty)
            const Text(
              'Todavía no tiene postulaciones.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            )
          else
            ..._postulaciones.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.pasantia?.titulo ?? 'Pasantía',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.estadoLegible} · ${(_horasPorPostulacion[p.id] ?? 0).toStringAsFixed(0)} h cargadas'
                      '${p.tutor != null ? ' · Tutor: ${p.tutor}' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
