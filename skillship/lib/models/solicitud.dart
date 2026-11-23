/// Solicitud que un alumno de la universidad hizo a una pasantía
/// (es una fila de `postulaciones` + datos de la pasantía y del alumno).
///
/// La universidad la revisa y la acepta (pasa a `en_proceso` con tutor) o la
/// rechaza (`rechazada`).
class Solicitud {
  final int id;
  final int pasantiaId;
  final int usuarioId;

  /// pendiente | en_proceso | finalizada | rechazada
  final String estado;

  final String? tutor;
  final String? fechaInicio;

  final String tituloPasantia;
  final String empresaPasantia;
  final String descripcionPasantia;
  final String nombreAlumno;
  final String carreraAlumno;

  const Solicitud({
    required this.id,
    required this.pasantiaId,
    required this.usuarioId,
    required this.estado,
    this.tutor,
    this.fechaInicio,
    required this.tituloPasantia,
    required this.empresaPasantia,
    required this.descripcionPasantia,
    required this.nombreAlumno,
    required this.carreraAlumno,
  });

  bool get pendiente => estado == 'pendiente';

  String get estadoLegible {
    switch (estado) {
      case 'en_proceso':
        return 'En proceso';
      case 'finalizada':
        return 'Finalizada';
      case 'rechazada':
        return 'Rechazada';
      case 'pendiente':
      default:
        return 'Pendiente';
    }
  }

  /// Fecha para mostrar en pantalla: `07/09/2026` o `—`.
  String get fechaInicioLegible {
    final fecha = fechaInicio ?? '';
    final partes = fecha.split('-');
    if (partes.length != 3) return '—';
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  /// Arma una solicitud desde una fila de `postulaciones` con el join
  /// `pasantias(...)` ya resuelto, más los datos del alumno (que se pasan
  /// aparte porque no hay join directo entre esas tablas en la base).
  factory Solicitud.fromMap(
    Map<String, dynamic> map, {
    String nombreAlumno = '',
    String carreraAlumno = '',
  }) {
    final pasantia = map['pasantias'];
    return Solicitud(
      id: (map['id'] as num).toInt(),
      pasantiaId: (map['pasantia_id'] as num).toInt(),
      usuarioId: (map['usuario_id'] as num).toInt(),
      estado: map['estado']?.toString() ?? 'pendiente',
      tutor: map['tutor']?.toString(),
      fechaInicio: map['fecha_inicio']?.toString(),
      tituloPasantia: pasantia is Map ? pasantia['titulo']?.toString() ?? '' : '',
      empresaPasantia: pasantia is Map ? pasantia['empresa']?.toString() ?? '' : '',
      descripcionPasantia:
          pasantia is Map ? pasantia['descripcion']?.toString() ?? '' : '',
      nombreAlumno: nombreAlumno,
      carreraAlumno: carreraAlumno,
    );
  }

  /// Copia con cambios puntuales (la usa el repositorio en modo demo para
  /// actualizar el estado tras aceptar o rechazar).
  Solicitud copyWith({
    String? estado,
    String? tutor,
    String? fechaInicio,
  }) {
    return Solicitud(
      id: id,
      pasantiaId: pasantiaId,
      usuarioId: usuarioId,
      estado: estado ?? this.estado,
      tutor: tutor ?? this.tutor,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      tituloPasantia: tituloPasantia,
      empresaPasantia: empresaPasantia,
      descripcionPasantia: descripcionPasantia,
      nombreAlumno: nombreAlumno,
      carreraAlumno: carreraAlumno,
    );
  }
}
