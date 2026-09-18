import 'package:flutter/material.dart';

import 'grafo_screen.dart' as grafo;
import 'asignacion_screen.dart' as asignacion;
import 'johnson_screen.dart';

class MenuPrincipalScreen extends StatelessWidget {
  const MenuPrincipalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Centro de Módulos Algorítmicos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona un Algoritmo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Elige un módulo interactivo para simular y resolver problemas de optimización.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: constraints.maxWidth > 900 ? 3 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.72,
                    children: [
                      _TarjetaModulo(
                        titulo: 'Redes y Grafos',
                        descripcion: 'Modela redes viales complejas para encontrar la ruta más corta entre puntos de control, optimizando tiempos de respuesta en despachos.',
                        icono: Icons.alt_route_rounded,
                        colorAcento: const Color(0xFFEC4899),
                        badgeText: 'Disponible',
                        ilustracionWidget: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFEC4899)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.hub_outlined,
                              color: Color(0xFFEC4899),
                              size: 42,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const grafo.GrafoScreen(),
                            ),
                          );
                        },
                      ),
                      _TarjetaModulo(
                        titulo: 'Método de Asignación',
                        descripcion: 'Resuelve problemas de distribución óptima vinculando recursos disponibles con tareas específicas al mínimo costo o tiempo operativo.',
                        icono: Icons.assignment_turned_in_rounded,
                        colorAcento: const Color(0xFF6366F1),
                        badgeText: 'Disponible',
                        ilustracionWidget: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.table_chart_rounded,
                              color: Color(0xFF6366F1),
                              size: 42,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const asignacion.AsignacionScreen(),
                            ),
                          );
                        },
                      ),
                      _TarjetaModulo(
                        titulo: 'Algoritmo de Johnson',
                        descripcion: 'Optimiza la programación de tareas a través de múltiples máquinas o estaciones de trabajo en serie, minimizando el tiempo total (makespan).',
                        icono: Icons.schedule_rounded,
                        colorAcento: const Color(0xFFF59E0B),
                        badgeText: 'Disponible',
                        ilustracionWidget: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.linear_scale_rounded,
                              color: Color(0xFFF59E0B),
                              size: 42,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JohnsonScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaModulo extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color colorAcento;
  final String badgeText;
  final Widget ilustracionWidget;
  final VoidCallback onTap;

  const _TarjetaModulo({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.colorAcento,
    required this.badgeText,
    required this.ilustracionWidget,
    required this.onTap,
  });

  @override
  State<_TarjetaModulo> createState() => _TarjetaModuloState();
}

class _TarjetaModuloState extends State<_TarjetaModulo> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isHovered
                ? const Color(0xFF18181B)
                : const Color(0xFF121214),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHovered
                  ? widget.colorAcento.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isHovered)
                BoxShadow(
                  color: widget.colorAcento.withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.colorAcento.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.colorAcento.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          widget.icono,
                          color: widget.colorAcento,
                          size: 22,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          widget.badgeText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  widget.ilustracionWidget,
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.descripcion,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
