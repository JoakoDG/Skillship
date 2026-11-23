import 'package:skillship/data/empresa_repository.dart';
import 'package:skillship/models/perfil_empresa.dart';
import 'package:skillship/models/pasantia.dart';
import 'package:skillship/models/postulacion.dart';
import 'package:skillship/models/reclamo.dart';
import 'package:skillship/models/solicitud.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación real de [EmpresaRepository]: habla con Supabase.
///
/// Sólo necesita que se haya ejecutado `supabase/schema.sql`.
class SupabaseEmpresaRepository implements EmpresaRepository {
  SupabaseEmpresaRepository();

  SupabaseClient get _client => Supabase.instance.client;

  /// Comprueba que las tablas del flujo empresa existan y sean accesibles.
  /// Si falla, el repositorio con fallback pasa a datos de prueba.
  Future<void> probarDisponibilidad() async {
    await _client.from('perfiles_empresas').select('id').limit(1);
  }

  @override
  Future<PerfilEmpresa?> obtenerPerfilEmpresa({required int usuarioId}) async {
    final filas = await _client
        .from('perfiles_empresas')
        .select('id, usuario_id, nombre, cuit, telefono')
        .eq('usuario_id', usuarioId)
        .limit(1);

    if (filas.isEmpty) return null;
    return PerfilEmpresa.fromMap(filas.first);
  }

  @override
  Future<void> publicarPasantia({
    required int empresaId,
    required String titulo,
    required String empresa,
    required String ubicacion,
    required String modalidad,
    required String carreraRequerida,
    required String descripcion,
    required String requisitos,
    required int horasSemanales,
    required int duracionSemanas,
  }) async {
    final tituloLimpio = titulo.trim();
    if (tituloLimpio.isEmpty) {
      throw Exception('Ingresá el título del trabajo.');
    }
    if (horasSemanales <= 0) {
      throw Exception('Las horas por semana tienen que ser mayores a cero.');
    }
    if (duracionSemanas <= 0) {
      throw Exception('La duración tiene que ser mayor a cero.');
    }

    await _client.from('pasantias').insert({
      'titulo': tituloLimpio,
      'empresa': empresa.trim(),
      'ubicacion': ubicacion.trim(),
      'modalidad': modalidad,
      'carrera_requerida': carreraRequerida.trim(),
      'descripcion': descripcion.trim(),
      'requisitos': requisitos.trim(),
      'horas_semanales': horasSemanales,
      'duracion_semanas': duracionSemanas,
      'empresa_id': empresaId,
    });
  }

  @override
  Future<List<Pasantia>> obtenerPasantiasPropias({required int empresaId}) async {
    final filas = await _client
        .from('pasantias')
        .select()
        .eq('empresa_id', empresaId)
        .order('id', ascending: false);

    return filas.map(Pasantia.fromMap).toList();
  }

  @override
  Future<void> cerrarPasantia({required int pasantiaId}) async {
    await _client
        .from('pasantias')
        .update({'estado': 'cerrada'})
        .eq('id', pasantiaId);
  }

  @override
  Future<List<Solicitud>> obtenerPostulacionesPropias({
    required int empresaId,
  }) async {
    // 1) Las propuestas de la empresa (si no tiene, no tiene postulaciones).
    final propias = await _client
        .from('pasantias')
        .select('id')
        .eq('empresa_id', empresaId);

    if (propias.isEmpty) return [];

    final idsPasantias = propias
        .map((p) => (p['id'] as num).toInt())
        .toList();

    // 2) Las postulaciones a esas propuestas, con el detalle de la pasantía.
    final filas = await _client
        .from('postulaciones')
        .select(
          'id, pasantia_id, usuario_id, estado, tutor, fecha_inicio, '
          'created_at, pasantias(titulo, empresa, descripcion)',
        )
        .inFilter('pasantia_id', idsPasantias)
        .order('created_at', ascending: false);

    if (filas.isEmpty) return [];

    // 3) El nombre/carrera del alumno no viene en el join (no hay FK directa),
    //    así que lo cruzamos en memoria con una consulta a los perfiles.
    final usuariosIds = filas
        .map((f) => (f['usuario_id'] as num).toInt())
        .toSet()
        .toList();

    final perfiles = await _client
        .from('perfiles_estudiantes')
        .select('usuario_id, nombre, carrera')
        .inFilter('usuario_id', usuariosIds);

    final porUsuario = <int, Map<String, dynamic>>{
      for (final p in perfiles) (p['usuario_id'] as num).toInt(): p,
    };

    return filas.map((f) {
      final perfil = porUsuario[(f['usuario_id'] as num).toInt()];
      return Solicitud.fromMap(
        f,
        nombreAlumno: perfil?['nombre']?.toString() ?? '',
        carreraAlumno: perfil?['carrera']?.toString() ?? '',
      );
    }).toList();
  }

  @override
  Future<void> cargarHoras({
    required int postulacionId,
    required String fecha,
    required double horas,
    required String descripcion,
  }) async {
    if (horas <= 0) {
      throw Exception('Ingresá las horas cargadas.');
    }

    await _client.from('horas_pasantia').insert({
      'postulacion_id': postulacionId,
      'fecha': fecha,
      'horas': horas,
      'descripcion': descripcion.trim(),
    });
  }

  @override
  Future<List<RegistroHora>> obtenerHoras({required int postulacionId}) async {
    final filas = await _client
        .from('horas_pasantia')
        .select()
        .eq('postulacion_id', postulacionId)
        .order('fecha');

    return filas.map(RegistroHora.fromMap).toList();
  }

  @override
  Future<List<Reclamo>> obtenerReclamos({required int postulacionId}) async {
    final filas = await _client
        .from('reclamos')
        .select()
        .eq('postulacion_id', postulacionId)
        .order('created_at', ascending: false);

    return filas.map(Reclamo.fromMap).toList();
  }
}
