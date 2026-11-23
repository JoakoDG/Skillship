import 'package:skillship/data/universidad_repository.dart';
import 'package:skillship/models/alumno.dart';
import 'package:skillship/models/solicitud.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación real de [UniversidadRepository]: habla con Supabase.
///
/// Sólo necesita que se haya ejecutado `supabase/schema.sql`.
class SupabaseUniversidadRepository implements UniversidadRepository {
  SupabaseUniversidadRepository();

  SupabaseClient get _client => Supabase.instance.client;

  /// Comprueba que las tablas del flujo universidad existan y sean
  /// accesibles. Si falla, el repositorio con fallback pasa a datos de prueba.
  Future<void> probarDisponibilidad() async {
    await _client.from('perfiles_universidades').select('id').limit(1);
  }

  @override
  Future<List<Alumno>> obtenerAlumnos({required int universidadId}) async {
    final filas = await _client
        .from('perfiles_estudiantes')
        .select()
        .eq('universidad_id', universidadId)
        .order('nombre');

    return filas.map(Alumno.fromMap).toList();
  }

  @override
  Future<void> agregarAlumno({
    required int universidadId,
    required String email,
  }) async {
    final correo = email.trim();
    if (correo.isEmpty) {
      throw Exception('Ingresá el correo del alumno.');
    }

    // 1) La cuenta tiene que existir y ser de un estudiante.
    final usuarios = await _client
        .from('usuarios')
        .select('id')
        .eq('email', correo)
        .eq('rol', 'Estudiante')
        .limit(1);

    if (usuarios.isEmpty) {
      throw Exception('No existe ninguna cuenta de estudiante con ese correo.');
    }
    final usuarioId = (usuarios.first['id'] as num).toInt();

    // 2) Tiene que tener el registro de estudiante completado.
    final perfiles = await _client
        .from('perfiles_estudiantes')
        .select('id, universidad_id')
        .eq('usuario_id', usuarioId)
        .limit(1);

    if (perfiles.isEmpty) {
      throw Exception('Ese estudiante todavía no completó su registro.');
    }

    final perfil = perfiles.first;
    final perfilId = (perfil['id'] as num).toInt();
    final vinculado = perfil['universidad_id'];

    // 3) Si ya está vinculado a OTRA universidad, no se puede volver a agregar.
    if (vinculado != null && (vinculado as num).toInt() != universidadId) {
      throw Exception('Ese alumno ya está vinculado a otra institución.');
    }

    if (vinculado == null) {
      await _client
          .from('perfiles_estudiantes')
          .update({'universidad_id': universidadId}).eq('id', perfilId);
    }
    // Si ya estaba vinculado a esta misma universidad no hace falta nada.
  }

  @override
  Future<void> desvincularAlumno({required int alumnoId}) async {
    await _client
        .from('perfiles_estudiantes')
        .update({'universidad_id': null}).eq('id', alumnoId);
  }

  @override
  Future<List<Solicitud>> obtenerSolicitudes({
    required int universidadId,
    int? pasantiaId,
  }) async {
    // 1) Los alumnos de esta universidad (sin alumnos no hay solicitudes).
    final alumnos = await obtenerAlumnos(universidadId: universidadId);
    if (alumnos.isEmpty) return [];

    final usuariosAlumnos = alumnos.map((a) => a.usuarioId).toList();

    // 2) Sus postulaciones con el detalle de la pasantía.
    var consulta = _client
        .from('postulaciones')
        .select(
          'id, pasantia_id, usuario_id, estado, tutor, fecha_inicio, '
          'created_at, pasantias(titulo, empresa, descripcion)',
        )
        .inFilter('usuario_id', usuariosAlumnos);

    if (pasantiaId != null) {
      consulta = consulta.eq('pasantia_id', pasantiaId);
    }

    final filas = await consulta.order('created_at', ascending: false);

    // 3) El nombre/carrera del alumno no viene en el join (no hay FK directa),
    //    así que lo cruzamos en memoria con el paso 1.
    final porUsuario = <int, Alumno>{for (final a in alumnos) a.usuarioId: a};

    return filas.map((f) {
      final alumno = porUsuario[(f['usuario_id'] as num).toInt()];
      return Solicitud.fromMap(
        f,
        nombreAlumno: alumno?.nombre ?? '',
        carreraAlumno: alumno?.carrera ?? '',
      );
    }).toList();
  }

  @override
  Future<void> aceptarSolicitud({
    required int solicitudId,
    required String tutor,
  }) async {
    final nombreTutor = tutor.trim();
    if (nombreTutor.isEmpty) {
      throw Exception('Asigná un tutor antes de aceptar la solicitud.');
    }

    final hoy = DateTime.now().toIso8601String().substring(0, 10);

    await _client.from('postulaciones').update({
      'estado': 'en_proceso',
      'tutor': nombreTutor,
      'fecha_inicio': hoy,
    }).eq('id', solicitudId);
  }

  @override
  Future<void> rechazarSolicitud({required int solicitudId}) async {
    await _client
        .from('postulaciones')
        .update({'estado': 'rechazada'}).eq('id', solicitudId);
  }
}
