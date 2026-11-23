import 'package:flutter/material.dart';
import 'package:skillship/models/usuario.dart';
import 'package:skillship/ui/widgets/perfil_universidad.dart';
import 'universidad_gestionar_alumnos_screen.dart';
import 'universidad_solicitudes_screen.dart';

class UniversidadMainScreen extends StatefulWidget {
  final Usuario usuario;

  const UniversidadMainScreen({super.key, required this.usuario});

  @override
  State<UniversidadMainScreen> createState() => _UniversidadMainScreenState();
}

class _UniversidadMainScreenState extends State<UniversidadMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    UniversidadGestionarAlumnosScreen(usuario: widget.usuario),
    UniversidadSolicitudesScreen(usuario: widget.usuario),
  ];

  @override
  Widget build(BuildContext context) {
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
                    onTap: () => mostrarPerfilUniversidad(context, widget.usuario),
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

            // ================= CONTENIDO CAMBIANTE =================
            Expanded(
              child: _screens[_currentIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF161F33),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Alumnos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Solicitudes',
          ),
        ],
      ),
    );
  }
}
