import 'package:flutter/material.dart';
import 'package:skillship/data/repositorio_universidad.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/models/solicitud.dart';
import 'package:skillship/models/usuario.dart';
import 'package:skillship/ui/widgets/perfil_universidad.dart';

class UniversidadAceptarSolicitudScreen extends StatefulWidget {
  final Solicitud solicitud;
  final Usuario usuario;

  const UniversidadAceptarSolicitudScreen({
    super.key,
    required this.solicitud,
    required this.usuario,
  });

  @override
  State<UniversidadAceptarSolicitudScreen> createState() =>
      _UniversidadAceptarSolicitudScreenState();
}

class _UniversidadAceptarSolicitudScreenState
    extends State<UniversidadAceptarSolicitudScreen> {
  bool _enviando = false;

  void _mostrarAviso(String mensaje, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  // ---------------------------------------------------------------------------
  // ACEPTAR: pide el tutor y guarda el cambio en la base de datos.
  // ---------------------------------------------------------------------------
  Future<void> _aceptar() async {
    if (_enviando) return;

    final controlador = TextEditingController();
    final tutor = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Aceptar solicitud',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asigná un tutor a ${widget.solicitud.nombreAlumno} para iniciar la pasantía.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controlador,
              autofocus: true,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Nombre del tutor',
                hintStyle: TextStyle(color: Colors.black45, fontSize: 14),
                filled: true,
                fillColor: Color(0xFFF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controlador.text),
            child: const Text(
              'Aceptar',
              style: TextStyle(
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (tutor == null || tutor.trim().isEmpty) {
      if (tutor != null) {
        _mostrarAviso('Asigná un tutor antes de aceptar la solicitud');
      }
      return;
    }

    setState(() => _enviando = true);
    try {
      await RepositorioUniversidad.instance.aceptarSolicitud(
        solicitudId: widget.solicitud.id,
        tutor: tutor,
      );
      _mostrarAviso('Solicitud aceptada', color: const Color(0xFF2D2D2D));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarAviso(SupabaseService.mensajeError(e), color: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // RECHAZAR: confirma y guarda el cambio en la base de datos.
  // ---------------------------------------------------------------------------
  Future<void> _rechazar() async {
    if (_enviando) return;

    final confirmo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Rechazar solicitud',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Rechazar la solicitud de ${widget.solicitud.nombreAlumno} a "${widget.solicitud.tituloPasantia}"?',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Rechazar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmo != true) return;

    setState(() => _enviando = true);
    try {
      await RepositorioUniversidad.instance.rechazarSolicitud(
        solicitudId: widget.solicitud.id,
      );
      _mostrarAviso('Solicitud rechazada', color: Colors.redAccent);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarAviso(SupabaseService.mensajeError(e), color: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitud = widget.solicitud;

    return Scaffold(
      backgroundColor: const Color(0xFF0A101D),
      body: SafeArea(
        child: Row(
          children: [
            // ================= PANEL LATERAL (SIDEBAR FIJO) =================
            Container(
              width: 100,
              color: const Color(0xFF6A7389),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () =>
                        mostrarPerfilUniversidad(context, widget.usuario),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(
                        child: Text(
                          'Perfil',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cerrar Sesión',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        SizedBox(height: 8),
                        Icon(Icons.logout, color: Colors.black, size: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= CONTENIDO PRINCIPAL DE DETALLE =================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Botón de retroceso
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAFA2A2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                solicitud.tituloPasantia,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _dato('Alumno',
                                  '${solicitud.nombreAlumno} (${solicitud.carreraAlumno})'),
                              _dato('Empresa', solicitud.empresaPasantia),
                              _dato('Estado', solicitud.estadoLegible),
                              _dato('Inicio', solicitud.fechaInicioLegible),
                              if (solicitud.tutor != null)
                                _dato('Tutor', solicitud.tutor!),
                              const SizedBox(height: 20),
                              const Text(
                                'Descripción',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                solicitud.descripcionPasantia.isEmpty
                                    ? 'Sin descripción cargada.'
                                    : solicitud.descripcionPasantia,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Botones dispuestos verticalmente para evitar el
                              // desbordamiento de pantalla
                              if (solicitud.pendiente)
                                Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        onPressed:
                                            _enviando ? null : _aceptar,
                                        child: _enviando
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.black54,
                                                ),
                                              )
                                            : const Text(
                                                'Aceptar solicitud',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        onPressed:
                                            _enviando ? null : _rechazar,
                                        child: const Text(
                                          'Rechazar solicitud',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  'Esta solicitud ya fue respondida: ${solicitud.estadoLegible.toLowerCase()}.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: valor,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
