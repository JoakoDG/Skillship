import 'package:skillship/data/empresa_repository.dart';
import 'package:skillship/data/mock_empresa_repository.dart';
import 'package:skillship/data/supabase_empresa_repository.dart';
import 'package:skillship/models/perfil_empresa.dart';
import 'package:skillship/models/pasantia.dart';
import 'package:skillship/models/postulacion.dart';
import 'package:skillship/models/reclamo.dart';
import 'package:skillship/models/solicitud.dart';

/// Punto único de acceso a los datos del panel de la empresa (Fachada).
///
/// Intenta primero con Supabase. Si la base de datos todavía no está
/// disponible, queda en **modo demo** y responde con
/// [MockEmpresaRepository].
///
/// La UI sólo habla con esta clase, así que no sabe ni tiene que saber de
/// dónde salen los datos.
class RepositorioEmpresa implements EmpresaRepository {
  RepositorioEmpresa._();

  static final RepositorioEmpresa instance = RepositorioEmpresa._();

  final SupabaseEmpresaRepository _supabase = SupabaseEmpresaRepository();
  final EmpresaRepository _mock = MockEmpresaRepository();

  bool _fuenteVerificada = false;
  bool _usarMock = false;

  /// `true` cuando la app está respondiendo con datos de prueba.
  bool get enModoDemo => _usarMock;

  /// Elige la fuente una sola vez y la deja fija para toda la sesión.
  Future<EmpresaRepository> _fuente() async {
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
  Future<PerfilEmpresa?> obtenerPerfilEmpresa({required int usuarioId}) async {
    final fuente = await _fuente();
    return fuente.obtenerPerfilEmpresa(usuarioId: usuarioId);
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
    final fuente = await _fuente();
    return fuente.publicarPasantia(
      empresaId: empresaId,
      titulo: titulo,
      empresa: empresa,
      ubicacion: ubicacion,
      modalidad: modalidad,
      carreraRequerida: carreraRequerida,
      descripcion: descripcion,
      requisitos: requisitos,
      horasSemanales: horasSemanales,
      duracionSemanas: duracionSemanas,
    );
  }

  @override
  Future<List<Pasantia>> obtenerPasantiasPropias({required int empresaId}) async {
    final fuente = await _fuente();
    return fuente.obtenerPasantiasPropias(empresaId: empresaId);
  }

  @override
  Future<void> cerrarPasantia({required int pasantiaId}) async {
    final fuente = await _fuente();
    return fuente.cerrarPasantia(pasantiaId: pasantiaId);
  }

  @override
  Future<List<Solicitud>> obtenerPostulacionesPropias({
    required int empresaId,
  }) async {
    final fuente = await _fuente();
    return fuente.obtenerPostulacionesPropias(empresaId: empresaId);
  }

  @override
  Future<void> cargarHoras({
    required int postulacionId,
    required String fecha,
    required double horas,
    required String descripcion,
  }) async {
    final fuente = await _fuente();
    return fuente.cargarHoras(
      postulacionId: postulacionId,
      fecha: fecha,
      horas: horas,
      descripcion: descripcion,
    );
  }

  @override
  Future<List<RegistroHora>> obtenerHoras({required int postulacionId}) async {
    final fuente = await _fuente();
    return fuente.obtenerHoras(postulacionId: postulacionId);
  }

  @override
  Future<List<Reclamo>> obtenerReclamos({required int postulacionId}) async {
    final fuente = await _fuente();
    return fuente.obtenerReclamos(postulacionId: postulacionId);
  }
}
