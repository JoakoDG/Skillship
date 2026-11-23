import 'package:flutter/material.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/models/usuario.dart';
import 'package:skillship/ui/widgets/button.dart';

/// Diálogo de perfil de la ENTIDAD EDUCATIVA: muestra los datos del registro
/// (nombre, CUIT, teléfono) y los documentos que subió, tal como quedaron
/// guardados en la base de datos.
///
/// Se usa desde el sidebar del panel principal y de las pantallas de detalle.
void mostrarPerfilUniversidad(BuildContext context, Usuario usuario) {
  final servicio = SupabaseService.instance;
  final futuro = Future.wait<Object>([
    servicio.obtenerPerfilUniversidad(usuarioId: usuario.id),
    servicio.obtenerDocumentos(usuarioId: usuario.id),
  ]);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<List<Object>>(
            future: futuro,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF6A7389)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      SupabaseService.mensajeError(snapshot.error!),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    _botonCerrar(context),
                  ],
                );
              }

              final datos = snapshot.data ?? const [];
              final perfil = datos.isNotEmpty
                  ? (datos[0] as Map<String, String>)
                  : <String, String>{};
              final documentos = datos.length > 1
                  ? (datos[1] as List<Map<String, String>>)
                  : <Map<String, String>>[];

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      perfil['nombre'] ?? 'Institución',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.email,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    _dato('CUIT', perfil['cuit'] ?? '—'),
                    _dato('Teléfono', perfil['telefono'] ?? '—'),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 8),
                    const Text(
                      'Documentos subidos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (documentos.isEmpty)
                      const Text(
                        'Todavía no se cargaron documentos.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      )
                    else
                      ...documentos.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF6A7389),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  d['tipo'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: _botonCerrar(context)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

Widget _dato(String etiqueta, String valor) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$etiqueta: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text: valor,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

Widget _botonCerrar(BuildContext contexto) {
  return Button(
    text: 'Cerrar',
    backgroundColor: const Color(0xFF2D2D2D),
    textColor: Colors.white,
    borderRadius: 8.0,
    onPressed: () => Navigator.pop(contexto),
  );
}
