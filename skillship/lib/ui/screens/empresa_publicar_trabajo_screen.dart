import 'package:flutter/material.dart';
import 'package:skillship/data/repositorio_empresa.dart';
import 'package:skillship/data/supabase_service.dart';
import 'package:skillship/models/usuario.dart';

class EmpresaPublicarTrabajoScreen extends StatefulWidget {
  final Usuario usuario;

  const EmpresaPublicarTrabajoScreen({super.key, required this.usuario});

  @override
  State<EmpresaPublicarTrabajoScreen> createState() =>
      _EmpresaPublicarTrabajoScreenState();
}

class _EmpresaPublicarTrabajoScreenState
    extends State<EmpresaPublicarTrabajoScreen> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _horasController = TextEditingController();
  final TextEditingController _duracionController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _requisitosController = TextEditingController();

  String _modalidad = 'Presencial';
  bool _cargando = false;

  static const List<String> _modalidades = [
    'Presencial',
    'Híbrido',
    'Virtual',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _ubicacionController.dispose();
    _carreraController.dispose();
    _horasController.dispose();
    _duracionController.dispose();
    _descripcionController.dispose();
    _requisitosController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    final titulo = _tituloController.text.trim();
    final horas = int.tryParse(_horasController.text.trim());
    final duracion = int.tryParse(_duracionController.text.trim());

    if (titulo.isEmpty) {
      _mostrarAviso('Ingresá el título del trabajo.', color: Colors.redAccent);
      return;
    }
    if (horas == null || horas <= 0) {
      _mostrarAviso(
        'Ingresá las horas por semana (número mayor a cero).',
        color: Colors.redAccent,
      );
      return;
    }
    if (duracion == null || duracion <= 0) {
      _mostrarAviso(
        'Ingresá la duración en semanas (número mayor a cero).',
        color: Colors.redAccent,
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      // El nombre que ven los estudiantes es el de la empresa dueña.
      final perfil = await RepositorioEmpresa.instance.obtenerPerfilEmpresa(
        usuarioId: widget.usuario.id,
      );

      await RepositorioEmpresa.instance.publicarPasantia(
        empresaId: widget.usuario.id,
        titulo: titulo,
        empresa: perfil?.nombre.isNotEmpty == true
            ? perfil!.nombre
            : widget.usuario.email,
        ubicacion: _ubicacionController.text,
        modalidad: _modalidad,
        carreraRequerida: _carreraController.text,
        descripcion: _descripcionController.text,
        requisitos: _requisitosController.text,
        horasSemanales: horas,
        duracionSemanas: duracion,
      );

      _limpiar();
      _mostrarAviso(
        'Trabajo publicado. Ya aparece en "Buscar Trabajos".',
        color: const Color(0xFF2D2D2D),
      );
    } catch (e) {
      _mostrarAviso(SupabaseService.mensajeError(e), color: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _limpiar() {
    _tituloController.clear();
    _ubicacionController.clear();
    _carreraController.clear();
    _horasController.clear();
    _duracionController.clear();
    _descripcionController.clear();
    _requisitosController.clear();
    setState(() => _modalidad = 'Presencial');
  }

  void _mostrarAviso(String mensaje, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Detalles del trabajo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Campos del formulario
            _buildTextField(label: 'Título', controller: _tituloController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Ubicación', controller: _ubicacionController),
            const SizedBox(height: 16),
            _buildModalidad(),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Carrera requerida',
              controller: _carreraController,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Horas por semana',
                    controller: _horasController,
                    teclado: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Duración (semanas)',
                    controller: _duracionController,
                    teclado: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Descripción',
              controller: _descripcionController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Requisitos',
              controller: _requisitosController,
            ),
            const SizedBox(height: 24),

            // Botón de Enviar solicitud
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: _cargando ? null : _publicar,
                child: Text(
                  _cargando ? 'Publicando…' : 'Publicar\ntrabajo',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para mantener el estilo de los inputs de texto
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType teclado = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            keyboardType: teclado,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildModalidad() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modalidad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _modalidad,
              isExpanded: true,
              style: const TextStyle(color: Colors.black, fontSize: 15),
              items: _modalidades
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (valor) {
                if (valor == null) return;
                setState(() => _modalidad = valor);
              },
            ),
          ),
        ),
      ],
    );
  }
}
