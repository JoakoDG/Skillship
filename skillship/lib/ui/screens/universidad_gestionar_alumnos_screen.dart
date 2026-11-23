import 'package:flutter/material.dart';
import 'package:skillship/data/repositorio_universidad.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/models/alumno.dart';
import 'package:skillship/models/usuario.dart';
import 'universidad_detalle_alumno_screen.dart'; // Importa la nueva pantalla

class UniversidadGestionarAlumnosScreen extends StatefulWidget {
  final Usuario usuario;

  const UniversidadGestionarAlumnosScreen({super.key, required this.usuario});

  @override
  State<UniversidadGestionarAlumnosScreen> createState() =>
      _UniversidadGestionarAlumnosScreenState();
}

class _UniversidadGestionarAlumnosScreenState
    extends State<UniversidadGestionarAlumnosScreen> {
  List<Alumno> _alumnos = [];
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
      final alumnos = await RepositorioUniversidad.instance.obtenerAlumnos(
        universidadId: widget.usuario.id,
      );
      if (!mounted) return;
      setState(() {
        _alumnos = alumnos;
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
  // AGREGAR ALUMNO: la universidad vincula a un estudiante por su correo.
  // ---------------------------------------------------------------------------
  Future<void> _agregarAlumno() async {
    final controlador = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Agregar alumno',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Correo del estudiante',
            hintStyle: TextStyle(color: Colors.black45, fontSize: 14),
            filled: true,
            fillColor: Color(0xFFF2F4F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controlador.text),
            child: const Text(
              'Vincular',
              style: TextStyle(
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (email == null || email.trim().isEmpty) return;

    try {
      await RepositorioUniversidad.instance.agregarAlumno(
        universidadId: widget.usuario.id,
        email: email,
      );
      _mostrarAviso('Alumno vinculado', color: const Color(0xFF2D2D2D));
      await _cargar();
    } catch (e) {
      _mostrarAviso(SupabaseService.mensajeError(e), color: Colors.redAccent);
    }
  }

  // ---------------------------------------------------------------------------
  // DESVINCULAR ALUMNO
  // ---------------------------------------------------------------------------
  Future<void> _desvincular(Alumno alumno) async {
    final confirmo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Desvincular alumno',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Querés quitar a ${alumno.nombre} de esta institución?',
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
              'Desvincular',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmo != true) return;

    try {
      await RepositorioUniversidad.instance.desvincularAlumno(
        alumnoId: alumno.id,
      );
      _mostrarAviso('Alumno desvinculado', color: const Color(0xFF2D2D2D));
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

          // Acción principal, con el mismo estilo que "Ver Solicitudes".
          GestureDetector(
            onTap: _agregarAlumno,
            child: const Text(
              'Agregar alumno',
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

    if (_alumnos.isEmpty) {
      return const Center(
        child: Text(
          'Todavía no hay alumnos vinculados.\nUsá "Agregar alumno" para empezar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      itemCount: _alumnos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final alumno = _alumnos[index];
        return InkWell(
          onTap: () async {
            // Navega a la pantalla de detalles del alumno seleccionado
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UniversidadDetalleAlumnoScreen(
                  alumno: alumno,
                  usuario: widget.usuario,
                ),
              ),
            );
            // Si volvió de desvincular desde el detalle, refrescamos.
            _cargar();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFAFA2A2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alumno.nombre,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alumno.carrera,
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Desvincular',
                  icon: const Icon(Icons.person_remove, color: Colors.black54),
                  onPressed: () => _desvincular(alumno),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
