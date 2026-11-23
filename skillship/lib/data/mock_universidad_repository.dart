import 'package:skillship/data/datos_de_prueba.dart';
import 'package:skillship/data/universidad_repository.dart';
import 'package:skillship/models/alumno.dart';
import 'package:skillship/models/solicitud.dart';

/// Repositorio en memoria con **datos de prueba (mocks)** del panel de la
/// universidad. No toca la red ni la base de datos: guarda todo en listas.
///
/// Es una sola "sesión" de demostración: ignora el `universidadId` porque
/// sólo modela a la universidad de prueba.
class MockUniversidadRepository implements UniversidadRepository {
  MockUniversidadRepository()
      : _alumnos = List.of(DatosDePrueba.alumnos),
        _solicitudes = List.of(DatosDePrueba.solicitudesUniversidad);

  final List<Alumno> _alumnos;
  final List<Solicitud> _solicitudes;

  int _siguienteIdAlumno = 100;

  @override
  Future<List<Alumno>> obtenerAlumnos({required int universidadId}) async {
    final ordenados = List.of(_alumnos)
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return ordenados;
  }

  @override
  Future<void> agregarAlumno({
    required int universidadId,
    required String email,
  }) async {
    final correo = email.trim().toLowerCase();
    if (correo.isEmpty) {
      throw Exception('Ingresá el correo del alumno.');
    }

    if (DatosDePrueba.correosVinculados.contains(correo)) {
      throw Exception('Ese alumno ya está vinculado a esta institución.');
    }

    final candidato = DatosDePrueba.candidatos[correo];
    if (candidato == null) {
      throw Exception('No existe ninguna cuenta de estudiante con ese correo.');
    }

    _alumnos.add(Alumno(
      id: _siguienteIdAlumno++,
      usuarioId: candidato.usuarioId,
      nombre: candidato.nombre,
      institucion: candidato.institucion,
      carrera: candidato.carrera,
    ));
  }

  @override
  Future<void> desvincularAlumno({required int alumnoId}) async {
    _alumnos.removeWhere((a) => a.id == alumnoId);
  }

  @override
  Future<List<Solicitud>> obtenerSolicitudes({
    required int universidadId,
    int? pasantiaId,
  }) async {
    final filtradas = _solicitudes.where((s) {
      final alumnoOk = _alumnos.any((a) => a.usuarioId == s.usuarioId);
      final pasantiaOk = pasantiaId == null || s.pasantiaId == pasantiaId;
      return alumnoOk && pasantiaOk;
    }).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return filtradas;
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

    _actualizar(solicitudId, (s) => s.copyWith(
          estado: 'en_proceso',
          tutor: nombreTutor,
          fechaInicio: DateTime.now().toIso8601String().substring(0, 10),
        ));
  }

  @override
  Future<void> rechazarSolicitud({required int solicitudId}) async {
    _actualizar(solicitudId, (s) => s.copyWith(estado: 'rechazada'));
  }

  void _actualizar(int id, Solicitud Function(Solicitud) cambiar) {
    final i = _solicitudes.indexWhere((s) => s.id == id);
    if (i == -1) {
      throw Exception('La solicitud ya no existe.');
    }
    _solicitudes[i] = cambiar(_solicitudes[i]);
  }
}
