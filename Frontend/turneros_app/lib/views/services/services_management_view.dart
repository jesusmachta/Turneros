import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/services_management_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/service_model.dart';
import 'service_edit_dialog.dart';

class ServicesManagementView extends StatefulWidget {
  const ServicesManagementView({super.key});

  @override
  State<ServicesManagementView> createState() => _ServicesManagementViewState();
}

class _ServicesManagementViewState extends State<ServicesManagementView> {
  late ServicesManagementController _servicesController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, active, inactive
  String _searchQuery = '';

  // Colores del sistema (azul oscuro principal)
  static const Color primaryDarkBlue = Color(0xFF002858);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color activeGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color inactiveRed = Color(0xFFF44336);
  static const Color lightRed = Color(0xFFFFEBEE);
  static const Color textDark = Color(0xFF212121);
  static const Color textGray = Color(0xFF757575);
  static const Color smsBlue = Color(0xFF2196F3);
  static const Color screenPurple = Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    _servicesController = ServicesManagementController();
    _loadServices();
  }

  @override
  void dispose() {
    _servicesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadServices() {
    final authController = context.read<AuthController>();
    if (authController.isAuthenticated &&
        authController.currentUser != null &&
        authController.currentUser!.storeId != null) {
      final storeId = authController.currentUser!.storeId.toString();
      _servicesController.loadServices(storeId);
    }
  }

  List<ServiceModel> _getFilteredServices() {
    List<ServiceModel> services;

    // Aplicar filtro de estado
    switch (_selectedFilter) {
      case 'active':
        services = _servicesController.activeServices;
        break;
      case 'inactive':
        services = _servicesController.inactiveServices;
        break;
      default:
        services = _servicesController.services;
    }

    // Aplicar búsqueda
    if (_searchQuery.isNotEmpty) {
      services =
          services
              .where(
                (service) =>
                    service.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    service.type.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    return services;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _servicesController,
      child: Consumer<ServicesManagementController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: backgroundGray,
            appBar: AppBar(
              title: Row(
                children: [
                  Icon(
                    Icons.miscellaneous_services,
                    color: cardWhite,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Gestión de Servicios',
                    style: TextStyle(
                      color: cardWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryDarkBlue,
              elevation: 4,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: cardWhite),
                  onPressed: _loadServices,
                  tooltip: 'Actualizar servicios',
                ),
              ],
            ),
            body: Column(
              children: [
                // Encabezado con búsqueda y filtros
                Container(
                  padding: const EdgeInsets.all(16),
                  color: cardWhite,
                  child: Column(
                    children: [
                      // Barra de búsqueda
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar servicios...',
                          prefixIcon: const Icon(Icons.search, color: textGray),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: textGray,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: textGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: primaryDarkBlue,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Filtros
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterChip(
                              'all',
                              'Todos',
                              Icons.list_alt,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip(
                              'active',
                              'Activos',
                              Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip(
                              'inactive',
                              'Inactivos',
                              Icons.pause_circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Estadísticas
                if (controller.hasServices) _buildStatsCard(),

                // Lista de servicios
                Expanded(child: _buildServicesContent(controller)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? cardWhite : primaryDarkBlue),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? cardWhite : primaryDarkBlue,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selectedColor: primaryDarkBlue,
      backgroundColor: cardWhite,
      checkmarkColor: cardWhite,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
    );
  }

  Widget _buildStatsCard() {
    final stats = _servicesController.getServicesStats();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  stats['total'].toString(),
                  Icons.inventory,
                  primaryDarkBlue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Activos',
                  stats['active'].toString(),
                  Icons.check_circle,
                  activeGreen,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'SMS',
                  stats['withSMS'].toString(),
                  Icons.sms,
                  smsBlue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Pantalla',
                  stats['withScreen'].toString(),
                  Icons.tv,
                  screenPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: textGray)),
      ],
    );
  }

  Widget _buildServicesContent(ServicesManagementController controller) {
    if (controller.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryDarkBlue),
            SizedBox(height: 16),
            Text('Cargando servicios...', style: TextStyle(color: textGray)),
          ],
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: inactiveRed),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: textDark),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadServices,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDarkBlue,
                foregroundColor: cardWhite,
              ),
            ),
          ],
        ),
      );
    }

    final filteredServices = _getFilteredServices();

    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: textGray),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron servicios con "$_searchQuery"'
                  : 'No hay servicios disponibles',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: textGray),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        return _buildServiceCard(service);
      },
    );
  }

  void _showEditDialog(ServiceModel service) {
    showDialog(
      context: context,
      builder:
          (context) => ServiceEditDialog(
            service: service,
            onSave: (newName, newType, newActive, newSms, newScreen) async {
              final authController = context.read<AuthController>();
              if (authController.isAuthenticated &&
                  authController.currentUser != null &&
                  authController.currentUser!.storeId != null) {
                final storeId = authController.currentUser!.storeId.toString();

                final success = await _servicesController.updateService(
                  storeId: storeId,
                  currentName: service.name,
                  newName: newName,
                  newType: newType,
                  newActive: newActive,
                  newSms: newSms,
                  newScreen: newScreen,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Servicio "${service.name}" actualizado correctamente',
                      ),
                      backgroundColor: activeGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _servicesController.errorMessage ??
                            'Error al actualizar el servicio',
                      ),
                      backgroundColor: inactiveRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícono del servicio
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: service.active ? lightGreen : lightRed,
                borderRadius: BorderRadius.circular(30),
              ),
              child:
                  service.iconUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          service.iconUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.miscellaneous_services,
                              size: 30,
                              color: service.active ? activeGreen : inactiveRed,
                            );
                          },
                        ),
                      )
                      : Icon(
                        Icons.miscellaneous_services,
                        size: 30,
                        color: service.active ? activeGreen : inactiveRed,
                      ),
            ),
            const SizedBox(width: 16),

            // Información del servicio
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.type,
                    style: const TextStyle(fontSize: 14, color: textGray),
                  ),
                  const SizedBox(height: 8),

                  // Características del servicio
                  Row(
                    children: [
                      _buildServiceFeature(
                        service.active ? 'Activo' : 'Inactivo',
                        service.active ? activeGreen : inactiveRed,
                        service.active
                            ? Icons.check_circle
                            : Icons.pause_circle,
                      ),
                      const SizedBox(width: 12),
                      if (service.sms)
                        _buildServiceFeature('SMS', smsBlue, Icons.sms),
                      if (service.sms && service.screen)
                        const SizedBox(width: 12),
                      if (service.screen)
                        _buildServiceFeature(
                          'Pantalla',
                          screenPurple,
                          Icons.tv,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Botón de editar
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _showEditDialog(service),
                  icon: const Icon(Icons.edit_outlined),
                  color: primaryDarkBlue,
                  tooltip: 'Editar servicio',
                  style: IconButton.styleFrom(
                    backgroundColor: primaryDarkBlue.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceFeature(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
