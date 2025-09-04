import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:turneros_app/views/home/home_view.dart';
import '../../controllers/auth_controller.dart';
import '../../models/service_model.dart';
import '../../services/services_api_service.dart';
import '../../services/turn_api_service.dart';
import '../../services/printer_service.dart';
import 'document_input_view.dart';

class RequestTurnView extends StatefulWidget {
  const RequestTurnView({super.key});

  @override
  State<RequestTurnView> createState() => _RequestTurnViewState();
}

class _RequestTurnViewState extends State<RequestTurnView> {
  final ServicesApiService _servicesApiService = ServicesApiService();
  final TurnApiService _turnApiService = TurnApiService();
  List<ServiceModel> _services = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<ServiceModel>>? _servicesSubscription;

  // Colores según el diseño de la app
  static const Color primaryBlue = Color(0xFF002858);
  static const Color lightGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _startListeningToServices();
  }

  @override
  void dispose() {
    _servicesSubscription?.cancel();
    _servicesApiService.dispose();
    super.dispose();
  }

  void _startListeningToServices() {
    // Usar addPostFrameCallback para asegurar que el context esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      if (!authController.isAuthenticated ||
          authController.currentUser?.storeId == null) {
        setState(() {
          _error = 'Usuario no autenticado o sin tienda asignada';
          _isLoading = false;
        });
        return;
      }

      final storeId = authController.currentUser!.storeId!.toString();

      print('🚀 Iniciando listener de servicios para Store ID: $storeId');

      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Configurar el listener del stream
      _servicesSubscription =
          _servicesApiService.getServicesStream(storeId: storeId).listen(
        (services) {
          if (mounted) {
            setState(() {
              _services =
                  services; // Ya filtrados por active = true en el servicio
              _isLoading = false;
              _error = null;
            });
            print(
              '✅ Servicios actualizados: ${services.length} servicios activos',
            );
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = error.toString();
              _isLoading = false;
            });
            print('❌ Error en listener de servicios: $error');
          }
        },
      );
    });
  }

  /// Método legacy para recargar servicios manualmente
  Future<void> _loadServices() async {
    print('⚠️ Método _loadServices() legacy llamado - reiniciando listeners');

    // Reiniciar el listener
    _servicesSubscription?.cancel();
    _startListeningToServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 200, // Aumentar aún más el espacio para el logo más grande
        leading: GestureDetector(
          onTap: _showBackofficeDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 6.0, // Reducir aún más el padding vertical
              horizontal: 8.0, // Reducir aún más el padding horizontal
            ),
            child: Image.asset(
              'assets/Logos/logo_farmatodo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header con logo de Farmatodo (similar al diseño)
            _buildHeader(),

            // Contenido principal
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calcular tamaños responsive para pantalla 15.6" (1080x1920)
    final verticalPadding = screenHeight * 0.025; // 2.5% de la altura (~48px)
    final horizontalPadding = screenWidth * 0.05; // 5% del ancho (~54px)
    final fontSize = screenWidth * 0.055; // 5.5% del ancho (~59px) - Aumentado
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Título principal
          Text(
            '¡Solicita tu Turno!',
            style: TextStyle(
              fontSize: fontSize.clamp(35.0, 65.0), // Aumentar rango mínimo y máximo
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando servicios...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar servicios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadServices,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_services.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay servicios disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Separar servicios por tipo
    final farmaciaServices =
        _services.where((service) => service.type == 'Farmacia').toList();
    final serviciosServices =
        _services.where((service) => service.type == 'Servicio').toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05; // 5% del ancho (~54px)
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Servicios de Farmacia
          if (farmaciaServices.isNotEmpty) ...[
            _buildServicesList(farmaciaServices),
            SizedBox(height: padding * 0.6),
          ],

          // Servicios generales
          if (serviciosServices.isNotEmpty) ...[
            _buildServicesList(serviciosServices),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesList(List<ServiceModel> services) {
    return Column(
      children:
          services.map((service) => _buildServiceButton(service)).toList(),
    );
  }

  Widget _buildServiceButton(ServiceModel service) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calcular tamaños responsive para pantalla 15.6" (1080x1920)
    final buttonHeight = screenHeight * 0.12; // 12% de la altura de pantalla (~230px)
    final iconSize = screenWidth * 0.1; // 10% del ancho (~108px)
    final fontSize = screenWidth * 0.04; // 4% del ancho (~43px)
    final padding = screenWidth * 0.03; // 3% del ancho (~32px)
    final margin = screenHeight * 0.015; // 1.5% de la altura (~29px)
    
    return Container(
      margin: EdgeInsets.only(bottom: margin),
      height: buttonHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleServiceTap(service),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue, width: 3),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centrar todo el contenido horizontalmente
              crossAxisAlignment: CrossAxisAlignment.center, // Centrar verticalmente
              children: [
                // Icono del servicio
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Quitar fondo gris
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: service.iconUrl.isNotEmpty
                        ? _buildServiceImage(service.iconUrl, iconSize)
                        : Icon(
                            Icons.local_pharmacy,
                            color: primaryBlue,
                            size: iconSize * 0.6,
                          ),
                  ),
                ),

                SizedBox(width: padding), // Espacio horizontal entre icono y texto

                // Texto del servicio - flexible para adaptarse al contenido
                Flexible(
                  child: Text(
                    service.name,
                    textAlign: TextAlign.center, // Centrar el texto
                    style: TextStyle(
                      fontSize: (fontSize * 1.1).clamp(30.0, 55.0), // Texto más grande
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleServiceTap(ServiceModel service) {
    final authController = context.read<AuthController>();
    final storeId = authController.currentUser?.storeId ?? 0;

    // Si el storeId está entre 3000 y 3999, crear turno directamente
    if (storeId >= 3000 && storeId <= 3999) {
      _createDirectTurn(service);
    } else {
      // Navegar a la vista de entrada de documento
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentInputView(service: service),
        ),
      );
    }
  }

  /// Crea un turno directamente sin solicitar datos de documento
  Future<void> _createDirectTurn(ServiceModel service) async {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;

    if (user == null || user.storeId == null || user.country == null) {
      _showErrorMessage('Error: Usuario no autenticado correctamente');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear turno con datos por defecto para tiendas 3000-3999
      final result = await _turnApiService.createTurn(
        storeId: user.storeId!,
        name: service.name,
        type: service.type,
        cedula: 0, // Sin cédula para este tipo de tiendas
        documento: 'Sin documento', // Sin documento para este tipo de tiendas
        country: user.country!,
      );

      if (result['success']) {
        // Imprimir ticket automáticamente para tiendas 3000-3999
        final turnNumber = result['data']['turnNumber'] ?? 0;
        print('🖨️ Imprimiendo ticket para turno directo #$turnNumber');

        try {
          final printResult = await PrinterService.printTurnTicket(
            turnNumber: turnNumber,
            cedula: 0, // Sin cédula para turnos directos
            serviceType: service.type,
            storeId: user.storeId!,
          );
          print('✅ Resultado de impresión: $printResult');
        } catch (e) {
          print('⚠️ Error al imprimir: $e');
          // Continuar mostrando el diálogo aunque falle la impresión
        }

        _showSuccessDialog(result['data'], service);
      } else {
        _showErrorMessage(result['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      _showErrorMessage('Error al procesar la solicitud: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  void _showSuccessDialog(Map<String, dynamic> turnData, ServiceModel service) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de éxito con círculo verde
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),

            const SizedBox(height: 24),

            // Título centrado
            const Text(
              '¡Turno Creado!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 8),

            // Mensaje centrado
            const Text(
              'Tu turno ha sido creado exitosamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Contenedor con información del servicio
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Servicio: ${service.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Número de turno en grande
                  if (turnData['turnNumber'] != null) ...[
                    const Text(
                      'Tu número es:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${turnData['turnNumber']}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Regresando automáticamente...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );

    // Cerrar automáticamente después de 6 segundos
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo
      }
    });
  }

  /// Construye el widget de imagen para los servicios
  Widget _buildServiceImage(String imageUrl, [double? size]) {
    final imageSize = size ?? 60;
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: imageSize,
      height: imageSize,
      headers: const {'User-Agent': 'Flutter-App', 'Accept': 'image/*'},
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: imageSize * 0.5,
            height: imageSize * 0.5,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: primaryBlue,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Log del error para debug
        print('Error cargando imagen: $error');
        print('URL: $imageUrl');
        return Icon(Icons.medical_services, color: primaryBlue, size: imageSize * 0.6);
      },
    );
  }

  /// Muestra el diálogo para acceder al backoffice
  void _showBackofficeDialog() {
    final TextEditingController codeController = TextEditingController();
    final authController = context.read<AuthController>();
    final expectedCode = authController.currentUser?.storeId?.toString() ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.all(screenWidth * 0.08), // 8% del ancho
          title: Text(
            'Acceso Backoffice',
            style: TextStyle(
              color: primaryBlue, 
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045, // 4.5% del ancho (~49px)
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: screenWidth * 0.8, // 80% del ancho de pantalla
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingresa el código de acceso:',
                  style: TextStyle(fontSize: screenWidth * 0.035), // 3.5% del ancho (~38px)
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.03), // 3% de la altura
                SizedBox(
                  height: screenHeight * 0.08, // 8% de la altura (~154px)
                  child: TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    style: TextStyle(fontSize: screenWidth * 0.04), // 4% del ancho
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Código',
                      hintText: 'Ingresa tu código',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.03),
                      hintStyle: TextStyle(fontSize: screenWidth * 0.03),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              height: screenHeight * 0.06, // 6% de la altura (~115px)
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancelar',
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
              ),
            ),
            SizedBox(
              height: screenHeight * 0.06, // 6% de la altura (~115px)
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenHeight * 0.015,
                  ),
                ),
                              onPressed: () {
                  if (codeController.text.trim() == expectedCode) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeView()),
                    );
                  } else {
                    Fluttertoast.showToast(
                      msg: 'Código incorrecto',
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      gravity: ToastGravity.BOTTOM,
                    );
                  }
                },
                child: Text(
                  'Acceder',
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
