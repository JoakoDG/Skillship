/// Alumno vinculado a una universidad (fila de `perfiles_estudiantes` con
/// `universidad_id` apuntando a la cuenta de la entidad educativa).
class Alumno {
  final int id;

  /// Cuenta del estudiante en `usuarios` (con ella se ven sus postulaciones).
  final int usuarioId;

  final String nombre;
  final String institucion;
  final String carrera;

  const Alumno({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.institucion,
    required this.carrera,
  });

  factory Alumno.fromMap(Map<String, dynamic> map) {
    return Alumno(
      id: (map['id'] as num).toInt(),
      usuarioId: (map['usuario_id'] as num).toInt(),
      nombre: map['nombre']?.toString() ?? '',
      institucion: map['institucion']?.toString() ?? '',
      carrera: map['carrera']?.toString() ?? '',
    );
  }
}
