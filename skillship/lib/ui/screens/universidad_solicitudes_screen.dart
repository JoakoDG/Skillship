import 'package:flutter/material.dart';
import 'package:skillship/data/repositorio_pasantias.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/models/pasantia.dart';
import 'package:skillship/models/usuario.dart';
import 'universidad_detalle_solicitudes_screen.dart'; // Importa la nueva pantalla

class UniversidadSolicitudesScreen extends StatefulWidget {
  final Usuario usuario;

  const UniversidadSolicitudesScreen({super.key, required this.usuario});

  @override
  State<UniversidadSolicitudesScreen> createState() =>
      _UniversidadSolicitudesScreenState();
}

class _UniversidadSolicitudesScreenState
    extends State<UniversidadSolicitudesScreen> {
  List<Pasantia> _trabajos = [];
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
      final trabajos = await RepositorioPasantias.instance.obtenerPasantias(
        usuarioId: widget.usuario.id,
      );
      if (!mounted) return;
      setState(() {
        _trabajos = trabajos;
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

  void _abrirSolicitudes({int? pasantiaId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversidadDetalleSolicitudesScreen(
          usuario: widget.usuario,
          pasantiaId: pasantiaId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Texto "Ver Solicitudes" convertido en un botón interactivo
          GestureDetector(
            onTap: () => _abrirSolicitudes(),
            child: const Text(
              'Ver Solicitudes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration:
                    TextDecoration.underline, // Opcional: para indicar que es clickeable
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Trabajos Disponibles',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

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

    if (_trabajos.isEmpty) {
      return const Center(
        child: Text(
          'No hay trabajos disponibles por el momento.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      itemCount: _trabajos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trabajo = _trabajos[index];
        // Tocar un trabajo abre las solicitudes hechas a esa propuesta.
        return InkWell(
          onTap: () => _abrirSolicitudes(pasantiaId: trabajo.id),
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
                  trabajo.titulo,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trabajo.empresa} · ${trabajo.modalidad}',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
