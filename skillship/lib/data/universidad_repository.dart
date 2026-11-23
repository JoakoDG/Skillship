import 'package:skillship/models/alumno.dart';
import 'package:skillship/models/solicitud.dart';

/// Contrato que define de dónde salen los datos del panel de la universidad.
///
/// Las pantallas solo conocen esta interfaz: así se puede cambiar de fuente
/// (Supabase o datos de prueba) sin tocar ningún widget.
abstract class UniversidadRepository {
  /// Alumnos vinculados a la universidad, ordenados por nombre.
  Future<List<Alumno>> obtenerAlumnos({required int universidadId});

  /// Vincula a un alumno existente (buscado por correo) con la universidad.
  /// Lanza un error con mensaje claro si el correo no existe o si el alumno
  /// ya está en otra institución.
  Future<void> agregarAlumno({
    required int universidadId,
    required String email,
  });

  /// Quita el vínculo de un alumno con la universidad.
  Future<void> desvincularAlumno({required int alumnoId});

  /// Solicitudes (postulaciones) de los alumnos de la universidad.
  /// Si se pasa [pasantiaId], solo las de esa propuesta.
  Future<List<Solicitud>> obtenerSolicitudes({
    required int universidadId,
    int? pasantiaId,
  });

  /// Acepta una solicitud: pasa a `en_proceso` con tutor y fecha de inicio.
  Future<void> aceptarSolicitud({
    required int solicitudId,
    required String tutor,
  });

  /// Rechaza una solicitud: pasa a estado `rechazada`.
  Future<void> rechazarSolicitud({required int solicitudId});
}
