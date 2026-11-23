/// Perfil de la empresa (tabla `perfiles_empresas`).
///
/// La cuenta de acceso vive en `usuarios` (rol `Empresa`); acá quedan sus
/// datos de registro: razón social, CUIT y teléfono.
class PerfilEmpresa {
  final int id;

  /// Cuenta de la empresa en `usuarios`.
  final int usuarioId;

  /// Razón social.
  final String nombre;
  final String cuit;
  final String telefono;

  const PerfilEmpresa({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.cuit = '',
    this.telefono = '',
  });

  factory PerfilEmpresa.fromMap(Map<String, dynamic> map) {
    return PerfilEmpresa(
      id: (map['id'] as num).toInt(),
      usuarioId: (map['usuario_id'] as num).toInt(),
      nombre: map['nombre']?.toString() ?? '',
      cuit: map['cuit']?.toString() ?? '',
      telefono: map['telefono']?.toString() ?? '',
    );
  }
}
