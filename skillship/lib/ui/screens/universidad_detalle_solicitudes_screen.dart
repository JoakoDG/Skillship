import 'package:flutter/material.dart';
import 'package:skillship/data/repositorio_universidad.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/models/solicitud.dart';
import 'package:skillship/models/usuario.dart';
import 'package:skillship/ui/widgets/perfil_universidad.dart';
import 'universidad_aceptar_solicitud_screen.dart'; // Importa la pantalla de detalles

class UniversidadDetalleSolicitudesScreen extends StatefulWidget {
  final Usuario usuario;

  /// Si viene, se muestran sólo las solicitudes de esa propuesta.
  final int? pasantiaId;

  const UniversidadDetalleSolicitudesScreen({
    super.key,
    required this.usuario,
    this.pasantiaId,
  });

  @override
  State<UniversidadDetalleSolicitudesScreen> createState() =>
      _UniversidadDetalleSolicitudesScreenState();
}

class _UniversidadDetalleSolicitudesScreenState
    extends State<UniversidadDetalleSolicitudesScreen> {
  List<Solicitud> _solicitudes = [];
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
      final solicitudes =
          await RepositorioUniversidad.instance.obtenerSolicitudes(
        universidadId: widget.usuario.id,
        pasantiaId: widget.pasantiaId,
      );
      if (!mounted) return;
      setState(() {
        _solicitudes = solicitudes;
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

            // ================= LISTA DE SOLICITUDES =================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 20),
                    Expanded(child: _contenido()),
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

    if (_solicitudes.isEmpty) {
      return const Center(
        child: Text(
          'No hay solicitudes para revisar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      itemCount: _solicitudes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final solicitud = _solicitudes[index];
        return InkWell(
          onTap: () async {
            // Navega a la pantalla de detalles al tocar la solicitud
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UniversidadAceptarSolicitudScreen(
                  solicitud: solicitud,
                  usuario: widget.usuario,
                ),
              ),
            );
            // Volvió de aceptar/rechazar: refrescamos el estado.
            _cargar();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFAFA2A2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitud.tituloPasantia,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${solicitud.nombreAlumno} · ${solicitud.empresaPasantia}',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 6),
                Text(
                  solicitud.estadoLegible,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: solicitud.pendiente
                        ? const Color(0xFF2D2D2D)
                        : solicitud.estado == 'rechazada'
                            ? Colors.redAccent
                            : const Color(0xFF2D6A4F),
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
