import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/ui/widgets/button.dart';
import 'package:skillship/ui/widgets/upload_field.dart';

import 'package:skillship/ui/screens/pagina_ingreso.dart';

class RegistroUniversidadScreen extends StatefulWidget {
  final String email;
  final String password;

  const RegistroUniversidadScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<RegistroUniversidadScreen> createState() =>
      _RegistroUniversidadScreenState();
}

class _RegistroUniversidadScreenState extends State<RegistroUniversidadScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cuitController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  /// Documentos que pide la entidad educativa, en el orden que se muestran.
  static const List<String> _tiposDocumento = [
    'Convenio de Marco de Pasantias',
    'Copia de DNI',
    'Estatuto social',
    'Constancia de CUIT',
  ];

  /// etiqueta del campo -> archivo elegido por el usuario
  final Map<String, PlatformFile> _documentos = {};

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _cuitController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  // Abre el selector de archivos nativo y guarda el elegido.
  Future<void> _seleccionarArchivo(String tipo) async {
    try {
      final archivos = await FilePicker.pickFiles(type: FileType.any);
      if (archivos.isEmpty) return; // el usuario canceló
      setState(() => _documentos[tipo] = archivos.first);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el selector de archivos: $e')),
        );
      }
    }
  }

  Future<void> _registrarse() async {
    if (_nombreController.text.trim().isEmpty ||
        _cuitController.text.trim().isEmpty ||
        _telefonoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos de texto')),
      );
      return;
    }

    final faltantes = _tiposDocumento.where((t) => !_documentos.containsKey(t));
    if (faltantes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Faltan archivos por cargar: ${faltantes.join(', ')}')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService.instance.registrarUniversidadCompleto(
        email: widget.email,
        password: widget.password,
        nombre: _nombreController.text,
        cuit: _cuitController.text,
        telefono: _telefonoController.text,
        documentos: _documentos,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro completado. Ya podés iniciar sesión.'),
          backgroundColor: Color(0xFF2D2D2D),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PantallaIngreso()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SupabaseService.mensajeError(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _campoDocumento(String tipo) {
    return UploadField(
      label: tipo,
      isUpload: true,
      fileName: _documentos[tipo]?.name,
      onTap: () => _seleccionarArchivo(tipo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF9E9E9E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la institución',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _cuitController,
                            decoration: const InputDecoration(
                              labelText: 'CUIT',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _telefonoController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Campos con ícono de carga
                          _campoDocumento('Convenio de Marco de Pasantias'),
                          _campoDocumento('Copia de DNI'),
                          _campoDocumento('Estatuto social'),
                          _campoDocumento('Constancia de CUIT'),
                          SizedBox(
                            width: double.infinity,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : Button(
                                    text: 'Registrarse',
                                    backgroundColor: Colors.white,
                                    textColor: Colors.black,
                                    borderRadius: 8.0,
                                    onPressed: _registrarse,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
