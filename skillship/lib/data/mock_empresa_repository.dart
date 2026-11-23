import 'package:skillship/data/datos_de_prueba.dart';
import 'package:skillship/data/empresa_repository.dart';
import 'package:skillship/models/perfil_empresa.dart';
import 'package:skillship/models/pasantia.dart';
import 'package:skillship/models/postulacion.dart';
import 'package:skillship/models/reclamo.dart';
import 'package:skillship/models/solicitud.dart';

/// Repositorio en memoria con **datos de prueba (mocks)** del panel de la
/// empresa. No toca la red ni la base de datos: guarda todo en listas.
///
/// Es una sola "sesión" de demostración: ignora el `empresaId` porque sólo
/// modela a la empresa de prueba (todas sus propuestas y sus pasantes).
class MockEmpresaRepository implements EmpresaRepository {
  MockEmpresaRepository()
      : _pasantias = List.of(DatosDePrueba.pasantias),
        _postulaciones = List.of(DatosDePrueba.postulacionesEmpresa),
        _horas = List.of(DatosDePrueba.horas),
        _reclamos = List.of(DatosDePrueba.reclamos);

  final List<Pasantia> _pasantias;
  final List<Solicitud> _postulaciones;
  final List<RegistroHora> _horas;
  final List<Reclamo> _reclamos;

  int _siguienteId = 100;

  @override
  Future<PerfilEmpresa?> obtenerPerfilEmpresa({required int usuarioId}) async {
    return DatosDePrueba.perfilEmpresa;
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
    if (titulo.trim().isEmpty) {
      throw Exception('Ingresá el título del trabajo.');
    }
    if (horasSemanales <= 0) {
      throw Exception('Las horas por semana tienen que ser mayores a cero.');
    }
    if (duracionSemanas <= 0) {
      throw Exception('La duración tiene que ser mayor a cero.');
    }

    _pasantias.insert(
      0,
      Pasantia(
        id: _siguienteId++,
        titulo: titulo.trim(),
        empresa: empresa.trim(),
        ubicacion: ubicacion.trim(),
        modalidad: modalidad,
        carreraRequerida: carreraRequerida.trim(),
        descripcion: descripcion.trim(),
        requisitos: requisitos.trim(),
        horasSemanales: horasSemanales,
        duracionSemanas: duracionSemanas,
        estado: 'disponible',
        empresaId: DatosDePrueba.idEmpresaDemo,
      ),
    );
  }

  @override
  Future<List<Pasantia>> obtenerPasantiasPropias({required int empresaId}) async {
    final ordenadas = List.of(_pasantias)
      ..sort((a, b) => b.id.compareTo(a.id));
    return ordenadas;
  }

  @override
  Future<void> cerrarPasantia({required int pasantiaId}) async {
    final i = _pasantias.indexWhere((p) => p.id == pasantiaId);
    if (i == -1) {
      throw Exception('La propuesta ya no existe.');
    }
    _pasantias[i] = _pasantias[i].copyWith(estado: 'cerrada');
  }

  @override
  Future<List<Solicitud>> obtenerPostulacionesPropias({
    required int empresaId,
  }) async {
    final ordenadas = List.of(_postulaciones)
      ..sort((a, b) => b.id.compareTo(a.id));
    return ordenadas;
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

    _horas.add(
      RegistroHora(
        id: _siguienteId++,
        postulacionId: postulacionId,
        fecha: fecha,
        horas: horas,
        descripcion: descripcion.trim(),
      ),
    );
  }

  @override
  Future<List<RegistroHora>> obtenerHoras({required int postulacionId}) async {
    final filtradas = _horas.where((h) => h.postulacionId == postulacionId)
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return filtradas;
  }

  @override
  Future<List<Reclamo>> obtenerReclamos({required int postulacionId}) async {
    final filtrados = _reclamos.where((r) => r.postulacionId == postulacionId)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return filtrados;
  }
}
