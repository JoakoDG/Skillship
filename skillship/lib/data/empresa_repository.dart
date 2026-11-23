import 'package:skillship/models/perfil_empresa.dart';
import 'package:skillship/models/pasantia.dart';
import 'package:skillship/models/postulacion.dart';
import 'package:skillship/models/reclamo.dart';
import 'package:skillship/models/solicitud.dart';

/// Contrato que define de dónde salen los datos del panel de la empresa.
///
/// Las pantallas solo conocen esta interfaz: así se puede cambiar de fuente
/// (Supabase o datos de prueba) sin tocar ningún widget.
abstract class EmpresaRepository {
  /// Perfil de la empresa (datos que cargó en el registro). Puede ser `null`
  /// si la cuenta todavía no completó el registro.
  Future<PerfilEmpresa?> obtenerPerfilEmpresa({required int usuarioId});

  /// Publica una nueva propuesta a nombre de [empresaId]. Aparece en el
  /// buscador de los estudiantes y en el panel de la universidad.
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
  });

  /// Propuestas de la empresa (disponibles y cerradas), para administrarlas.
  Future<List<Pasantia>> obtenerPasantiasPropias({required int empresaId});

  /// Cierra una propuesta para que deje de aparecer en "Buscar Trabajos".
  Future<void> cerrarPasantia({required int pasantiaId});

  /// Postulaciones a las propuestas de la empresa, con los datos del alumno.
  /// Las que están `en_proceso` son los pasantes.
  Future<List<Solicitud>> obtenerPostulacionesPropias({required int empresaId});

  /// Carga horas trabajadas de un pasante (postulación en proceso).
  Future<void> cargarHoras({
    required int postulacionId,
    required String fecha,
    required double horas,
    required String descripcion,
  });

  /// Horas cargadas de un pasante.
  Future<List<RegistroHora>> obtenerHoras({required int postulacionId});

  /// Reclamos que el pasante dejó en esa postulación.
  Future<List<Reclamo>> obtenerReclamos({required int postulacionId});
}
