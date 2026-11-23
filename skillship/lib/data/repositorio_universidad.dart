import 'package:skillship/data/mock_universidad_repository.dart';
import 'package:skillship/data/supabase_universidad_repository.dart';
import 'package:skillship/data/universidad_repository.dart';
import 'package:skillship/models/alumno.dart';
import 'package:skillship/models/solicitud.dart';

/// Punto único de acceso a los datos del panel de la universidad (Fachada).
///
/// Intenta primero con Supabase. Si la base de datos todavía no está
/// disponible, queda en **modo demo** y responde con
/// [MockUniversidadRepository].
///
/// La UI sólo habla con esta clase, así que no sabe ni tiene que saber de
/// dónde salen los datos.
class RepositorioUniversidad implements UniversidadRepository {
  RepositorioUniversidad._();

  static final RepositorioUniversidad instance = RepositorioUniversidad._();

  final SupabaseUniversidadRepository _supabase = SupabaseUniversidadRepository();
  final UniversidadRepository _mock = MockUniversidadRepository();

  bool _fuenteVerificada = false;
  bool _usarMock = false;

  /// `true` cuando la app está respondiendo con datos de prueba.
  bool get enModoDemo => _usarMock;

  /// Elige la fuente una sola vez y la deja fija para toda la sesión.
  Future<UniversidadRepository> _fuente() async {
    if (_fuenteVerificada) return _usarMock ? _mock : _supabase;

    try {
      await _supabase.probarDisponibilidad();
      _usarMock = false;
    } catch (_) {
      _usarMock = true;
    }

    _fuenteVerificada = true;
    return _usarMock ? _mock : _supabase;
  }

  @override
  Future<List<Alumno>> obtenerAlumnos({required int universidadId}) async {
    final fuente = await _fuente();
    return fuente.obtenerAlumnos(universidadId: universidadId);
  }

  @override
  Future<void> agregarAlumno({
    required int universidadId,
    required String email,
  }) async {
    final fuente = await _fuente();
    return fuente.agregarAlumno(universidadId: universidadId, email: email);
  }

  @override
  Future<void> desvincularAlumno({required int alumnoId}) async {
    final fuente = await _fuente();
    return fuente.desvincularAlumno(alumnoId: alumnoId);
  }

  @override
  Future<List<Solicitud>> obtenerSolicitudes({
    required int universidadId,
    int? pasantiaId,
  }) async {
    final fuente = await _fuente();
    return fuente.obtenerSolicitudes(
      universidadId: universidadId,
      pasantiaId: pasantiaId,
    );
  }

  @override
  Future<void> aceptarSolicitud({
    required int solicitudId,
    required String tutor,
  }) async {
    final fuente = await _fuente();
    return fuente.aceptarSolicitud(solicitudId: solicitudId, tutor: tutor);
  }

  @override
  Future<void> rechazarSolicitud({required int solicitudId}) async {
    final fuente = await _fuente();
    return fuente.rechazarSolicitud(solicitudId: solicitudId);
  }
}
