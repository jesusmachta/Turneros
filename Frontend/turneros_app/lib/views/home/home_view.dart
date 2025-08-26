import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../controllers/auth_controller.dart';
import '../../services/dashboard_service.dart';
import '../auth/login_view.dart';
import '../services/request_turn_view.dart';
import '../services/services_management_view.dart';
import '../queue/queue_view.dart';
import '../turn_display/turn_display_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final DashboardService _dashboardService = DashboardService();
  DashboardStats? _stats;
  bool _isLoading = true;

  // Colores según el diseño
  static const Color primaryBlue = Color(0xFF002858); // Azul oscuro header
  static const Color attendedGreen = Color(0xFF4CAF50); // Verde para atendidos
  static const Color attentionBlue = Color(0xFF1976D2); // Azul para en atención
  static const Color waitingOrange = Color(
    0xFFFF9800,
  ); // Naranja para en espera
  static const Color cancelledRed = Color(0xFFE53935); // Rojo para cancelados
  static const Color timeBlue = Color(0xFF2196F3); // Azul para tiempo de espera

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final authController = context.read<AuthController>();
      if (authController.isAuthenticated &&
          authController.currentUser?.storeId != null) {
        final stats = await _dashboardService.getDashboardStats(
          authController.currentUser!.storeId!,
        );
        if (mounted) {
          setState(() {
            _stats = stats;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        // Si no está autenticado, redirigir al login
        if (!authController.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginView()),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authController.currentUser!;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Column(
              children: [
                // Header con logo y saludo
                _buildHeader(user),

                // Contenido principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        // Pregunta principal centrada
                        Center(
                          child: Text(
                            '¿Qué deseas hacer?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 1. ESTADÍSTICAS (primero - después del título)
                        _buildStatsRow(),

                        const SizedBox(height: 32),

                        // 2. BOTONES DE ACCIÓN (segundo)
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye el header con logo y saludo
  Widget _buildHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Menú de opciones (esquina superior derecha)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.exit_to_app, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Cerrar Sesión'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Icono de la tienda centrado
          const Center(
            child: Icon(Icons.local_pharmacy, size: 48, color: Colors.white),
          ),

          const SizedBox(height: 12),

          // Saludo principal centrado
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                children: [
                  const TextSpan(text: '¡Hola '),
                  TextSpan(
                    text: user.storeName ?? 'Tienda',
                    style: const TextStyle(
                      color: Color.fromARGB(
                        255,
                        255,
                        255,
                        255,
                      ), // Verde para destacar
                    ),
                  ),
                  const TextSpan(text: '!'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Construye la fila de estadísticas según el diseño
  Widget _buildStatsRow() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
          ),
        ),
      );
    }

    final stats = _stats ?? DashboardStats.empty();

    return Row(
      children: [
        // Atendidos
        Expanded(
          child: _buildStatCard(
            title: 'Atendidos',
            value: stats.clientesAtendidos.toString(),
            color: attendedGreen,
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: 6),

        // En atención
        Expanded(
          child: _buildStatCard(
            title: 'En atención',
            value: stats.clientesEnAtencion.toString(),
            color: attentionBlue,
            icon: Icons.person,
          ),
        ),
        const SizedBox(width: 6),

        // En espera
        Expanded(
          child: _buildStatCard(
            title: 'En espera',
            value: stats.clientesEnEspera.toString(),
            color: waitingOrange,
            icon: Icons.hourglass_empty,
          ),
        ),
        const SizedBox(width: 6),

        // Cancelados
        Expanded(
          child: _buildStatCard(
            title: 'Cancelados',
            value: stats.clientesCancelados.toString(),
            color: cancelledRed,
            icon: Icons.close,
          ),
        ),
        const SizedBox(width: 6),

        // Tiempo de espera
        Expanded(
          child: _buildStatCard(
            title: 'Tiempo de\nEspera',
            value: '${stats.tiempoPromedioEspera.toStringAsFixed(1)}min',
            color: timeBlue,
            icon: Icons.access_time,
          ),
        ),
      ],
    );
  }

  /// Construye una tarjeta de estadística individual
  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Icono en la esquina superior izquierda
          Positioned(
            top: 12,
            left: 12,
            child: Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
          ),

          // Contenido centrado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Número
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 2),

                // Título
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.8),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye los botones de acción según el diseño
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primera fila
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Clientes en espera',
                subtitle: 'Gestiona los clientes que están esperando',
                icon: Icons.people_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QueueView()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                title: 'Pantalla de turnos',
                subtitle: 'Visualiza el estado actual de los turnos',
                icon: Icons.tv,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TurnDisplayView(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Segunda fila
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Gestión de servicios',
                subtitle: 'Configura los servicios disponibles',
                icon: Icons.miscellaneous_services,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServicesManagementView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                title: 'Pedir turnos',
                subtitle: 'Registra nuevos clientes en la fila',
                icon: Icons.add_circle_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestTurnView(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construye un botón de acción individual
  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryBlue, // #002858
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: primaryBlue, size: 32),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Está seguro que desea cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final authController = context.read<AuthController>();
      await authController.signOut();
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: 'Sesión cerrada correctamente',
          backgroundColor: Colors.green,
          textColor: Colors.white,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }
}
