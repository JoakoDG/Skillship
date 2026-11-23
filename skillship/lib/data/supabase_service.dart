import 'package:file_picker/file_picker.dart';
import 'package:skillship/models/perfil_empresa.dart';
import 'package:skillship/models/usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Capa de datos del proyecto: todo lo que habla con Supabase para el
/// **registro con subida de archivos**, el **login** y el **perfil**.
///
/// (Las pasantías, postulaciones, horas y reclamos viven en
/// `repositorio_pasantias.dart`, que elige entre Supabase o datos de prueba.)
///
/// Requiere haber ejecutado `supabase/schema.sql` en el SQL Editor de Supabase.
class SupabaseService {
  SupabaseService._();

  /// Instancia única. También se puede usar `SupabaseService()`.
  static final SupabaseService instance = SupabaseService._();

  factory SupabaseService() => instance;

  /// Bucket donde se guardan los documentos del registro (lo crea el script SQL).
  static const String bucketDocumentos = 'documentos';

  /// Carpeta temporal: los archivos se suben ANTES de tocar la base de datos,
  /// así si falla la subida no queda ningún registro a medias.
  static const String _carpetaTemporal = 'pendientes';

  SupabaseClient get _client => Supabase.instance.client;

  // ===========================================================================
  // REGISTRO DEL ESTUDIANTE
  // ===========================================================================

  /// Da de alta el usuario, su perfil y sube los 4 documentos que pide la
  /// facultad. El alta real vive en [_altaConDocumentos].
  ///
  /// [documentos] va ordenado: etiqueta del campo -> archivo elegido.
  Future<void> registrarEstudianteCompleto({
    required String email,
    required String password,
    required String rol,
    required String nombre,
    required String institucion,
    required String carrera,
    required Map<String, PlatformFile> documentos,
  }) {
    return _altaConDocumentos(
      email: email,
      password: password,
      rol: rol,
      documentos: documentos,
      crearDatos: (usuarioId) async {
        // Datos del alumno
        await _client.from('perfiles_estudiantes').insert({
          'usuario_id': usuarioId,
          'nombre': nombre.trim(),
          'institucion': institucion.trim(),
          'carrera': carrera.trim(),
        });
      },
    );
  }

  /// Da de alta la cuenta de una entidad educativa con su perfil y sus
  /// 4 documentos (mismo mecanismo que el estudiante).
  Future<void> registrarUniversidadCompleto({
    required String email,
    required String password,
    required String nombre,
    required String cuit,
    required String telefono,
    required Map<String, PlatformFile> documentos,
  }) {
    return _altaConDocumentos(
      email: email,
      password: password,
      rol: 'Universidad',
      documentos: documentos,
      crearDatos: (usuarioId) async {
        await _client.from('perfiles_universidades').insert({
          'usuario_id': usuarioId,
          'nombre': nombre.trim(),
          'cuit': cuit.trim(),
          'telefono': telefono.trim(),
        });
      },
    );
  }

  /// Da de alta la cuenta de una empresa con su perfil y sus 3 documentos
  /// (mismo mecanismo que el estudiante y la universidad).
  Future<void> registrarEmpresaCompleto({
    required String email,
    required String password,
    required String nombre,
    required String cuit,
    required String telefono,
    required Map<String, PlatformFile> documentos,
  }) {
    return _altaConDocumentos(
      email: email,
      password: password,
      rol: 'Empresa',
      documentos: documentos,
      crearDatos: (usuarioId) async {
        await _client.from('perfiles_empresas').insert({
          'usuario_id': usuarioId,
          'nombre': nombre.trim(),
          'cuit': cuit.trim(),
          'telefono': telefono.trim(),
        });
      },
    );
  }

  /// Camino común del registro:
  ///   1. Sube los archivos ANTES de tocar la base (si falla, no se crea nada).
  ///   2. Crea la cuenta, ejecuta [crearDatos] (perfil) y registra los archivos.
  ///   3. Si falla la base, borra los archivos para no dejar huérfanos.
  Future<void> _altaConDocumentos({
    required String email,
    required String password,
    required String rol,
    required Map<String, PlatformFile> documentos,
    required Future<void> Function(int usuarioId) crearDatos,
  }) async {
    if (documentos.isEmpty) {
      throw Exception('Seleccioná los documentos pedidos antes de registrarte.');
    }

    // 1) Subir primero: si falla (p. ej. falta el bucket) no se crea nada en la BD.
    final subidos = <String, String>{}; // etiqueta -> path
    try {
      for (final entrada in documentos.entries) {
        final path = await _subirArchivo(entrada.value, carpeta: _carpetaTemporal);
        subidos[entrada.key] = path;
      }
    } catch (e) {
      await _borrarArchivos(subidos.values.toList());
      rethrow;
    }

    try {
      // 2) Usuario principal
      final usuario = await _client
          .from('usuarios')
          .insert({
            'email': email.trim(),
            'password': password,
            'rol': rol,
          })
          .select('id')
          .single();
      final int usuarioId = (usuario['id'] as num).toInt();

      // 3) Datos específicos del rol (perfil del estudiante / de la universidad)
      await crearDatos(usuarioId);

      // 4) Pasar cada archivo a la carpeta del usuario y registrar su ruta
      for (final entrada in subidos.entries) {
        var path = entrada.value;
        try {
          final nombreArchivo = path.split('/').last;
          final destino = '$usuarioId/$nombreArchivo';
          await _client.storage.from(bucketDocumentos).move(path, destino);
          path = destino;
        } catch (_) {
          // Si el move falla el archivo sigue existiendo en "pendientes/".
        }

        await _client.from('documentos_registro').insert({
          'usuario_id': usuarioId,
          'tipo_documento': entrada.key,
          'archivo_path': path,
        });
      }
    } catch (e) {
      // Si falla la base de datos, no dejamos archivos huérfanos.
      await _borrarArchivos(subidos.values.toList());
      rethrow;
    }
  }

  Future<String> _subirArchivo(PlatformFile archivo, {required String carpeta}) async {
    final bytes = await archivo.readAsBytes();
    final extension = archivo.extension ?? 'bin';
    final nombreLimpio = archivo.name.replaceAll(RegExp(r'\s+'), '_');
    final path = '$carpeta/${DateTime.now().millisecondsSinceEpoch}_$nombreLimpio';

    await _client.storage.from(bucketDocumentos).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentType(extension),
            upsert: true,
          ),
        );
    return path;
  }

  Future<void> _borrarArchivos(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(bucketDocumentos).remove(paths);
    } catch (_) {
      // Mejor esfuerzo: no queremos tapar el error original.
    }
  }

  static String _contentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Documentos que el estudiante subió en el registro (los muestra el perfil).
  Future<List<Map<String, String>>> obtenerDocumentos({required int usuarioId}) async {
    final filas = await _client
        .from('documentos_registro')
        .select('tipo_documento, archivo_path')
        .eq('usuario_id', usuarioId)
        .order('id');

    return filas
        .map((f) => {
              'tipo': f['tipo_documento']?.toString() ?? '',
              'path': f['archivo_path']?.toString() ?? '',
            })
        .toList();
  }

  /// Datos del perfil del estudiante (nombre, institución y carrera).
  Future<Map<String, String>> obtenerPerfilEstudiante({required int usuarioId}) async {
    final filas = await _client
        .from('perfiles_estudiantes')
        .select('nombre, institucion, carrera')
        .eq('usuario_id', usuarioId)
        .limit(1);

    if (filas.isEmpty) return <String, String>{};

    final fila = filas.first;
    return {
      'nombre': fila['nombre']?.toString() ?? '',
      'institucion': fila['institucion']?.toString() ?? '',
      'carrera': fila['carrera']?.toString() ?? '',
    };
  }

  /// Datos del perfil de la entidad educativa (nombre, CUIT y teléfono).
  Future<Map<String, String>> obtenerPerfilUniversidad({required int usuarioId}) async {
    final filas = await _client
        .from('perfiles_universidades')
        .select('nombre, cuit, telefono')
        .eq('usuario_id', usuarioId)
        .limit(1);

    if (filas.isEmpty) return <String, String>{};

    final fila = filas.first;
    return {
      'nombre': fila['nombre']?.toString() ?? '',
      'cuit': fila['cuit']?.toString() ?? '',
      'telefono': fila['telefono']?.toString() ?? '',
    };
  }

  /// Datos del perfil de la empresa (razón social, CUIT y teléfono).
  /// Devuelve `null` si la cuenta todavía no cargó su registro.
  Future<PerfilEmpresa?> obtenerPerfilEmpresa({required int usuarioId}) async {
    final filas = await _client
        .from('perfiles_empresas')
        .select('id, usuario_id, nombre, cuit, telefono')
        .eq('usuario_id', usuarioId)
        .limit(1);

    if (filas.isEmpty) return null;
    return PerfilEmpresa.fromMap(filas.first);
  }

  // ===========================================================================
  // INICIO DE SESIÓN
  // ===========================================================================

  /// Da de alta una cuenta de acceso (empresa / universidad).
  ///
  /// El resto de los datos de esos roles todavía es maqueta, pero así pueden
  /// iniciar sesión con el mismo mecanismo que un estudiante.
  Future<void> crearCuenta({
    required String email,
    required String password,
    required String rol,
  }) async {
    await _client.from('usuarios').insert({
      'email': email.trim(),
      'password': password,
      'rol': rol,
    });
  }

  /// Valida correo + contraseña contra la tabla `usuarios` y trae el nombre del perfil.
  Future<Usuario> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final filas = await _client
        .from('usuarios')
        .select('id, email, rol, password')
        .eq('email', email.trim())
        .eq('password', password)
        .limit(1);

    if (filas.isEmpty) {
      throw Exception('Correo o contraseña incorrectos.');
    }

    final datos = filas.first;
    var usuario = Usuario.fromMap(datos);

    // El nombre vive en perfiles_estudiantes (solo existe para estudiantes).
    try {
      final perfil = await _client
          .from('perfiles_estudiantes')
          .select('nombre')
          .eq('usuario_id', usuario.id)
          .limit(1);
      if (perfil.isNotEmpty) {
        usuario = Usuario.fromMap(datos, nombre: perfil.first['nombre']?.toString());
      }
    } catch (_) {
      // Si falta la tabla o el perfil, el login igualmente es válido.
    }

    return usuario;
  }

  // ===========================================================================
  // ERRORES
  // ===========================================================================

  /// Traduce las excepciones de Supabase a mensajes que se le puedan mostrar
  /// a un usuario (y le recuerdan al equipo qué falta configurar).
  static String mensajeError(Object e) {
    if (e is PostgrestException) {
      switch (e.code) {
        case 'PGRST205':
          return 'Faltan tablas en la base de datos: ejecutá supabase/schema.sql en el SQL Editor de Supabase.';
        case '23505':
          return 'Ya existe una cuenta con ese correo electrónico.';
        case '23503':
          return 'El registro hace referencia a datos que no existen en la base de datos.';
        case '42501':
        case 'PGRST301':
          return 'Sin permisos sobre la base de datos: revisá las políticas RLS del script SQL.';
        default:
          return 'Error de base de datos: ${e.message}';
      }
    }

    if (e is StorageException) {
      if (e.statusCode == '404' || (e.message.contains('Bucket not found'))) {
        return 'No existe el bucket "documentos": ejecutá supabase/schema.sql en el SQL Editor de Supabase.';
      }
      return 'No se pudo subir el archivo: ${e.message}';
    }

    return e.toString().replaceFirst('Exception: ', '');
  }
}
