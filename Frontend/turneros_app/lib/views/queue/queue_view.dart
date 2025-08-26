import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/queue_controller.dart';
import '../../models/queue_client_model.dart';
import '../../models/service_model.dart';
import '../../controllers/auth_controller.dart';
import '../../services/audio_service.dart';

class QueueView extends StatefulWidget {
  const QueueView({super.key});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  late QueueController _queueController;
  final AudioService _audioService = AudioService();

  // Colores del sistema (azul oscuro principal)
  static const Color primaryDarkBlue = Color(0xFF002858);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color attendingGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color waitingOrange = Color(0xFFFF9800);
  static const Color textDark = Color(0xFF212121);
  static const Color textGray = Color(0xFF757575);
  // Colores específicos para Picking RX
  static const Color pickingPreparedTeal = Color(
    0xFF00a19a,
  ); // Verde azulado para Preparado
  static const Color pickingPendingYellow = Color(
    0xFFa1ac00,
  ); // Amarillo verdoso para Pendiente
  static const Color lightTeal = Color(
    0xFFE0F2F1,
  ); // Verde azulado claro para fondo
  static const Color lightYellow = Color(
    0xFFF9FBE7,
  ); // Amarillo verdoso claro para fondo

  @override
  void initState() {
    super.initState();
    _queueController = QueueController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      if (authController.isAuthenticated &&
          authController.currentUser?.storeId != null) {
        _queueController.initialize(authController.currentUser!.storeId!);
      }
    });
  }

  @override
  void dispose() {
    _queueController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        backgroundColor: primaryDarkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _queueController.refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: ChangeNotifierProvider.value(
          value: _queueController,
          child: Consumer<QueueController>(
            builder: (context, controller, child) {
              if (controller.isLoading && controller.pharmacyWaiting.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryDarkBlue),
                  ),
                );
              }

              if (controller.error != null) {
                return Center(
                  child: Text(
                    'Error: ${controller.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.refresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Si la pantalla es pequeña (< 768px), usar layout vertical scrollable
                    if (constraints.maxWidth < 768) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Farmacia Section
                            SizedBox(
                              height:
                                  400, // Altura fija para las secciones en móvil
                              child: _buildSectionCard(
                                'Farmacia',
                                controller.pharmacyAttending,
                                controller.pharmacyWaiting,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Servicios Farmacéuticos Section
                            SizedBox(
                              height: 400,
                              child: _buildSectionCard(
                                'Servicios Farmacéuticos',
                                controller.pharmaceuticalServicesAttending,
                                controller.pharmaceuticalServicesWaiting,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Picking Rx Section
                            SizedBox(
                              height: 400,
                              child: _buildSectionCard(
                                'Picking Rx',
                                controller.pickingRxPrepared,
                                controller.pickingRxPending,
                                isPickingRx: true,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Para pantallas grandes (>= 768px), usar layout horizontal
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Farmacia Section
                          Expanded(
                            child: SizedBox(
                              height:
                                  constraints.maxHeight -
                                  32, // Altura disponible menos padding
                              child: _buildSectionCard(
                                'Farmacia',
                                controller.pharmacyAttending,
                                controller.pharmacyWaiting,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Servicios Farmacéuticos Section
                          Expanded(
                            child: SizedBox(
                              height: constraints.maxHeight - 32,
                              child: _buildSectionCard(
                                'Servicios Farmacéuticos',
                                controller.pharmaceuticalServicesAttending,
                                controller.pharmaceuticalServicesWaiting,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Picking Rx Section
                          Expanded(
                            child: SizedBox(
                              height: constraints.maxHeight - 32,
                              child: _buildSectionCard(
                                'Picking Rx',
                                controller.pickingRxPrepared,
                                controller.pickingRxPending,
                                isPickingRx: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    List<QueueClientModel> attending,
    List<QueueClientModel> waiting, {
    bool isPickingRx = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 200;
                return Row(
                  children: [
                    Icon(
                      title == 'Farmacia'
                          ? Icons.local_pharmacy_outlined
                          : title == 'Picking Rx'
                          ? Icons.receipt_long_outlined
                          : Icons.medical_services_outlined,
                      color: textDark,
                      size: isSmall ? 18 : 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmall ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                        maxLines: isSmall ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Content: Dos columnas lado a lado con altura fija
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda (Preparado/Atendiendo)
                  Expanded(
                    child: _buildQueueList(
                      isPickingRx ? 'Preparado' : 'Atendiendo',
                      attending,
                      isAttending: !isPickingRx,
                      isPrepared: isPickingRx,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna derecha (Pendiente/En Espera)
                  Expanded(
                    child: _buildQueueList(
                      isPickingRx ? 'Pendiente' : 'En Espera',
                      waiting,
                      isAttending: false,
                      isPending: isPickingRx,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(
    String title,
    List<QueueClientModel> clients, {
    required bool isAttending,
    bool isPrepared = false,
    bool isPending = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isPrepared
                  ? Icons.check_circle_outline
                  : isPending
                  ? Icons.schedule
                  : isAttending
                  ? Icons.support_agent
                  : Icons.hourglass_empty,
              color:
                  isPrepared
                      ? pickingPreparedTeal
                      : isPending
                      ? pickingPendingYellow
                      : isAttending
                      ? attendingGreen
                      : waitingOrange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textGray,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${clients.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              clients.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        isPrepared
                            ? 'No hay órdenes preparadas'
                            : isPending
                            ? 'No hay órdenes pendientes'
                            : 'Sin clientes',
                        style: const TextStyle(color: textGray),
                      ),
                    ),
                  )
                  : ListView.separated(
                    itemCount: clients.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildClientCard(
                        clients[index],
                        isAttending,
                        isPrepared: isPrepared,
                        isPending: isPending,
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildClientCard(
    QueueClientModel client,
    bool isAttending, {
    bool isPrepared = false,
    bool isPending = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isPrepared
                ? lightTeal
                : isPending
                ? lightYellow
                : isAttending
                ? lightGreen
                : cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isPrepared
                  ? pickingPreparedTeal
                  : isPending
                  ? pickingPendingYellow
                  : isAttending
                  ? attendingGreen
                  : Colors.grey[300]!,
          width: (isPrepared || isPending || isAttending) ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                client.formattedTurn,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            client.clientName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          if (isAttending && client.attendedBy != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Por: ${client.attendedBy}',
                style: const TextStyle(color: textGray, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          // Solo mostrar botones de acción para farmacia y servicios, no para Picking RX
          if (!isPrepared && !isPending)
            _buildActionButtons(client, isAttending),
        ],
      ),
    );
  }

  Widget _buildActionButtons(QueueClientModel client, bool isAttending) {
    final isPharmacy = client.comesFrom == 'Atención en Mostrador';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Para pantallas muy pequeñas (< 300px), usar botones más compactos pero en la misma fila
        if (constraints.maxWidth < 300) {
          final extraSmallButtonHeight = 36.0;
          final extraSmallFontSize = 12.0;

          return Row(
            children: [
              if (isAttending)
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _handleFinishAction(client, isPharmacy),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: attendingGreen,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, extraSmallButtonHeight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: Text(
                      'Finalizar',
                      style: TextStyle(fontSize: extraSmallFontSize),
                    ),
                  ),
                )
              else
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _handleAttendAction(client, isPharmacy),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryDarkBlue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, extraSmallButtonHeight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: Text(
                      'Atender',
                      style: TextStyle(fontSize: extraSmallFontSize),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              // Botón Transferir (solo para farmacia atendiendo)
              if (isAttending && isPharmacy)
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () => _handleTransferAction(client),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryDarkBlue,
                      side: BorderSide(color: primaryDarkBlue),
                      minimumSize: Size(0, extraSmallButtonHeight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                    ),
                    child: Text(
                      'Transfer',
                      style: TextStyle(fontSize: extraSmallFontSize),
                    ),
                  ),
                ),
              if (isAttending && isPharmacy) const SizedBox(width: 4),
              // Botón cancelar
              Flexible(
                child: IconButton(
                  onPressed: () => _handleCancelAction(client, isPharmacy),
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  iconSize: extraSmallButtonHeight,
                  padding: const EdgeInsets.all(6),
                ),
              ),
            ],
          );
        }

        // Para pantallas normales, usar layout horizontal responsivo
        final isSmall = constraints.maxWidth < 400;
        final buttonTextStyle = TextStyle(fontSize: isSmall ? 14 : 16);
        final buttonHeight = isSmall ? 40.0 : 44.0;

        return Row(
          children: [
            if (isAttending)
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleFinishAction(client, isPharmacy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: attendingGreen,
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, buttonHeight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: Text('Finalizar', style: buttonTextStyle),
                ),
              )
            else
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAttendAction(client, isPharmacy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDarkBlue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, buttonHeight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: Text('Atender', style: buttonTextStyle),
                ),
              ),
            const SizedBox(width: 8),
            // El botón Transferir solo aparece cuando el cliente está siendo atendido EN FARMACIA
            if (isAttending && isPharmacy)
              OutlinedButton(
                onPressed: () => _handleTransferAction(client),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryDarkBlue,
                  side: BorderSide(color: primaryDarkBlue),
                  minimumSize: Size(0, buttonHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: Text(
                  'Transferir',
                  style: TextStyle(fontSize: isSmall ? 12 : 14),
                ),
              ),
            if (isAttending && isPharmacy) const SizedBox(width: 8),
            IconButton(
              onPressed: () => _handleCancelAction(client, isPharmacy),
              icon: Icon(
                Icons.close,
                color: Colors.red,
                size: isSmall ? 20 : 24,
              ),
              iconSize: isSmall ? 40 : 44,
              padding: const EdgeInsets.all(8),
            ),
          ],
        );
      },
    );
  }

  // ===========================================
  // MÉTODOS MANEJADORES DE ACCIONES
  // ===========================================

  /// Maneja la acción de atender un cliente
  void _handleAttendAction(QueueClientModel client, bool isPharmacy) async {
    try {
      // Reproducir sonido de timbre para atender
      _audioService.playAttendSound();

      if (isPharmacy) {
        await _queueController.startAttendingPharmacy(client);
        _showAttendToast(true);
      } else {
        await _queueController.startAttendingService(client);
        _showAttendToast(false);
      }
    } catch (e) {
      _showErrorToast('Error al atender cliente');
    }
  }

  /// Maneja la acción de finalizar atención
  void _handleFinishAction(QueueClientModel client, bool isPharmacy) async {
    try {
      // Reproducir sonido de timbre
      _audioService.playAttendSound();

      if (isPharmacy) {
        await _queueController.finishAttendingPharmacy(client);
        _showFinishToast(true);
      } else {
        await _queueController.finishAttendingService(client);
        _showFinishToast(false);
      }
    } catch (e) {
      _showErrorToast('Error al finalizar atención');
    }
  }

  /// Maneja la acción de cancelar un turno
  void _handleCancelAction(QueueClientModel client, bool isPharmacy) async {
    try {
      if (isPharmacy) {
        await _queueController.cancelTurnPharmacy(client);
        _showCancelToast(true);
      } else {
        await _queueController.cancelTurnService(client);
        _showCancelToast(false);
      }
    } catch (e) {
      _showErrorToast('Error al cancelar turno');
    }
  }

  /// Maneja la acción de transferir
  void _handleTransferAction(QueueClientModel client) async {
    final selectedService = await _showTransferDialog(client);
    if (selectedService != null) {
      try {
        await _queueController.transferToService(client, selectedService);
        _showTransferToast();
      } catch (e) {
        _showErrorToast('Error al transferir cliente');
      }
    }
  }

  // ===========================================
  // MÉTODOS DE UTILIDAD PARA TOAST NOTIFICATIONS
  // ===========================================

  /// Muestra un toast de error discreto y no invasivo
  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(
          0xFFE53E3E,
        ), // Rojo que combina con el tema
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.25,
          right: MediaQuery.of(context).size.width * 0.25,
        ),
        elevation: 4,
      ),
    );
  }

  /// Toast específico para cuando se atiende un cliente
  void _showAttendToast(bool isPharmacy) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_pin, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isPharmacy
                    ? 'Cliente atendido en farmacia'
                    : 'Cliente atendido en servicios',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: primaryDarkBlue, // Azul principal de la app
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.2,
          right: MediaQuery.of(context).size.width * 0.2,
        ),
        elevation: 4,
      ),
    );
  }

  /// Toast específico para cuando se finaliza la atención
  void _showFinishToast(bool isPharmacy) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isPharmacy ? 'Atención finalizada' : 'Servicio completado',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: attendingGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.2,
          right: MediaQuery.of(context).size.width * 0.2,
        ),
        elevation: 4,
      ),
    );
  }

  /// Toast específico para cuando se cancela un turno
  void _showCancelToast(bool isPharmacy) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isPharmacy ? 'Turno cancelado' : 'Servicio cancelado',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: waitingOrange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.2,
          right: MediaQuery.of(context).size.width * 0.2,
        ),
        elevation: 4,
      ),
    );
  }

  /// Toast específico para cuando se transfiere un cliente
  void _showTransferToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Cliente transferido',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(
          0xFF7B68EE,
        ), // Violeta que combina con el tema
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.2,
          right: MediaQuery.of(context).size.width * 0.2,
        ),
        elevation: 4,
      ),
    );
  }

  /// Muestra el diálogo para seleccionar el servicio de transferencia
  Future<ServiceModel?> _showTransferDialog(QueueClientModel client) async {
    return showDialog<ServiceModel>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.swap_horiz, color: primaryDarkBlue, size: 24),
              const SizedBox(width: 8),
              const Text('Transferir Cliente'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cliente: ${client.clientName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Turno: ${client.formattedTurn}',
                style: const TextStyle(fontSize: 14, color: textGray),
              ),
              const SizedBox(height: 16),
              const Text(
                'Seleccionar servicio de destino:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<ServiceModel>>(
                future: _queueController.getActiveServices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error al cargar servicios',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    );
                  }

                  final services = snapshot.data ?? [];
                  if (services.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No hay servicios disponibles',
                        style: TextStyle(color: textGray),
                      ),
                    );
                  }

                  return _TransferServiceSelector(
                    services: services,
                    onServiceSelected: (service) {
                      Navigator.of(context).pop(service);
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}

/// Widget para seleccionar el servicio en el diálogo de transferencia
class _TransferServiceSelector extends StatefulWidget {
  final List<ServiceModel> services;
  final Function(ServiceModel) onServiceSelected;

  const _TransferServiceSelector({
    required this.services,
    required this.onServiceSelected,
  });

  @override
  State<_TransferServiceSelector> createState() =>
      _TransferServiceSelectorState();
}

class _TransferServiceSelectorState extends State<_TransferServiceSelector> {
  ServiceModel? _selectedService;
  static const Color primaryDarkBlue = Color(0xFF002858);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ServiceModel>(
              hint: const Text('Seleccionar servicio'),
              value: _selectedService,
              isExpanded: true,
              items:
                  widget.services.map((ServiceModel service) {
                    return DropdownMenuItem<ServiceModel>(
                      value: service,
                      child: Text(
                        service.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
              onChanged: (ServiceModel? newValue) {
                setState(() {
                  _selectedService = newValue;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _selectedService != null
                    ? () => widget.onServiceSelected(_selectedService!)
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryDarkBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Transferir'),
          ),
        ),
      ],
    );
  }
}
