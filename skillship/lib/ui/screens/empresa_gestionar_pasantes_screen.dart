import 'package:flutter/material.dart';
import 'package:skillship/data/repositorio_empresa.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/models/pasantia.dart';
import 'package:skillship/models/solicitud.dart';
import 'package:skillship/models/usuario.dart';
import 'empresa_detalle_pasante_screen.dart';

class EmpresaGestionarPasantesScreen extends StatefulWidget {
  final Usuario usuario;

  const EmpresaGestionarPasantesScreen({super.key, required this.usuario});

  @override
  State<EmpresaGestionarPasantesScreen> createState() =>
      _EmpresaGestionarPasantesScreenState();
}

class _EmpresaGestionarPasantesScreenState
    extends State<EmpresaGestionarPasantesScreen> {
  /// Postulaciones a las propuestas de la empresa (las que están "en proceso"
  /// son sus pasantes activos).
  List<Solicitud> _postulaciones = [];

  /// Propuestas propias (para administrarlas y cerrarlas).
  List<Pasantia> _pasantias = [];

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
          await RepositorioEmpresa.instance.obtenerPostulacionesPropias(
        empresaId: widget.usuario.id,
      );
      final pasantias =
          await RepositorioEmpresa.instance.obtenerPasantiasPropias(
        empresaId: widget.usuario.id,
      );

      if (!mounted) return;
      setState(() {
        _postulaciones = postulaciones;
        _pasantias = pasantias;
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
  // MIS PROPUESTAS: lista las propuestas propias y permite cerrarlas.
  // ---------------------------------------------------------------------------
  Future<void> _mostrarPropuestas() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Mis propuestas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 340,
          child: _pasantias.isEmpty
              ? const Center(
                  child: Text(
                    'Todavía no publicaste trabajos.\nUsá la pestaña "Publicar Trabajo".',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                )
              : ListView.separated(
                  itemCount: _pasantias.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final pasantia = _pasantias[index];
                    final cerrada = pasantia.estado == 'cerrada';
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pasantia.titulo,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${pasantia.empresa} · ${pasantia.ubicacion}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cerrada ? 'Cerrada' : 'Disponible',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cerrada ? Colors.redAccent : const Color(0xFF2D2D2D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!cerrada)
                          TextButton(
                            onPressed: () => _cerrarPasantia(pasantia),
                            child: const Text(
                              'Cerrar',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarPasantia(Pasantia pasantia) async {
    final confirmo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Cerrar propuesta',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Querés cerrar "${pasantia.titulo}"? Dejará de aparecer para los '
          'estudiantes.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar propuesta',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmo != true) return;

    try {
      await RepositorioEmpresa.instance.cerrarPasantia(pasantiaId: pasantia.id);
      if (!mounted) return;
      Navigator.pop(context); // cierra el diálogo de "Mis propuestas"
      _mostrarAviso('Propuesta cerrada', color: const Color(0xFF2D2D2D));
      await _cargar();
    } catch (e) {
      _mostrarAviso(SupabaseService.mensajeError(e), color: Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Acción principal, con el mismo estilo que las otras pantallas.
          GestureDetector(
            onTap: _mostrarPropuestas,
            child: const Text(
              'Mis propuestas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Expanded(child: _contenido()),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _cargar,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_postulaciones.isEmpty) {
      return const Center(
        child: Text(
          'Todavía no hay postulaciones a tus propuestas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      itemCount: _postulaciones.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final solicitud = _postulaciones[index];
        return InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmpresaDetallePasanteScreen(
                  solicitud: solicitud,
                  usuario: widget.usuario,
                ),
              ),
            );
            // Si volvió de cargar horas, refrescamos la lista.
            _cargar();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFAFA2A2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitud.nombreAlumno.isNotEmpty
                      ? solicitud.nombreAlumno
                      : 'Postulante',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  solicitud.carreraAlumno,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 6),
                Text(
                  '${solicitud.tituloPasantia} · ${solicitud.estadoLegible}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
