import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/turn_display_controller.dart';
import '../home/home_view.dart';

class TurnDisplayView extends StatefulWidget {
  const TurnDisplayView({super.key});

  @override
  State<TurnDisplayView> createState() => _TurnDisplayViewState();
}

class _TurnDisplayViewState extends State<TurnDisplayView> {
  late TurnDisplayController _turnDisplayController;

  // Colores según el diseño
  static const Color primaryBlue = Color(0xFF002858); // Azul para "En Atención"
  static const Color lightGrey = Color(0xFFF3F4F6); // Gris claro para fondo
  static const Color darkGrey = Color(0xFF374151); // Gris oscuro para texto
  static const Color orangeWaiting = Color(
    0xFFEA580C,
  ); // Naranja para "Esperando"

  @override
  void initState() {
    super.initState();
    _turnDisplayController = TurnDisplayController();
    _startRealTimeListening();
  }

  @override
  void dispose() {
    _turnDisplayController.dispose();
    super.dispose();
  }

  void _startRealTimeListening() {
    // Usar addPostFrameCallback para asegurar que el context esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      if (authController.isAuthenticated &&
          authController.currentUser?.storeId != null) {
        print(
          '🚀 Iniciando escucha en tiempo real para Store ID: ${authController.currentUser!.storeId}',
        );
        _turnDisplayController.startListening(
          authController.currentUser!.storeId!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Ajustes responsivos para diferentes tamaños
    final isSmallScreen = screenWidth < 700;
    final isMediumScreen = screenWidth >= 700 && screenWidth < 1100;
    final isLargeScreen = screenWidth >= 1100 && screenWidth < 1500;

    final logoHeight =
        isSmallScreen
            ? 30.0
            : isMediumScreen
            ? 40.0
            : isLargeScreen
            ? 50.0
            : 60.0;
    final headerPadding =
        isSmallScreen
            ? 12.0
            : isMediumScreen
            ? 16.0
            : isLargeScreen
            ? 18.0
            : 20.0;
    final contentPadding =
        isSmallScreen
            ? 12.0
            : isMediumScreen
            ? 20.0
            : isLargeScreen
            ? 28.0
            : 36.0;
    final columnSpacing =
        isSmallScreen
            ? 12.0
            : isMediumScreen
            ? 20.0
            : isLargeScreen
            ? 32.0
            : 40.0;

    return ChangeNotifierProvider<TurnDisplayController>.value(
      value: _turnDisplayController,
      child: Consumer<AuthController>(
        builder: (context, authController, child) {
          if (!authController.isAuthenticated) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: lightGrey,
            body: Column(
              children: [
                // Header con logo
                Container(
                  width: double.infinity,
                  color: primaryBlue,
                  padding: EdgeInsets.symmetric(
                    vertical: headerPadding / 2, // Más corto
                    horizontal: contentPadding,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeView(),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/Logos/logo_farmatodo.png',
                        height: logoHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // Contenido principal
                Expanded(
                  child: Consumer<TurnDisplayController>(
                    builder: (context, controller, child) {
                      return Padding(
                        padding: EdgeInsets.all(contentPadding),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Columna de Farmacia
                            Expanded(
                              child: _buildTurnColumn(
                                title: 'Farmacia',
                                currentTurn: controller.currentPharmacyTurn,
                                nextTurns: controller.nextPharmacyTurns,
                                isLoading: controller.isLoadingPharmacy,
                                error: controller.pharmacyError,
                                screenWidth: screenWidth,
                              ),
                            ),

                            SizedBox(width: columnSpacing),

                            // Columna de Servicios Farmacéuticos
                            Expanded(
                              child: _buildTurnColumn(
                                title: 'Servicios Farmacéuticos',
                                currentTurn: controller.currentServicesTurn,
                                nextTurns: controller.nextServicesTurns,
                                isLoading: controller.isLoadingServices,
                                error: controller.servicesError,
                                screenWidth: screenWidth,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTurnColumn({
    required String title,
    required String currentTurn,
    required List<String> nextTurns,
    required bool isLoading,
    required String? error,
    required double screenWidth,
  }) {
    // Tamaños responsivos basados en el ancho de pantalla
    final isSmallScreen = screenWidth < 700;
    final isMediumScreen = screenWidth >= 700 && screenWidth < 1100;
    final isLargeScreen = screenWidth >= 1100 && screenWidth < 1500;

    // Tamaños de fuente más responsivos
    final titleFontSize =
        isSmallScreen
            ? 22.0
            : isMediumScreen
            ? 28.0
            : isLargeScreen
            ? 34.0
            : 42.0;
    final attentionFontSize =
        isSmallScreen
            ? 15.0
            : isMediumScreen
            ? 18.0
            : isLargeScreen
            ? 22.0
            : 26.0;
    final currentTurnFontSize =
        isSmallScreen
            ? 52.0
            : isMediumScreen
            ? 70.0
            : isLargeScreen
            ? 88.0
            : 110.0;
    final sectionTitleFontSize =
        isSmallScreen
            ? 18.0
            : isMediumScreen
            ? 24.0
            : isLargeScreen
            ? 30.0
            : 36.0;
    final containerPadding =
        isSmallScreen
            ? 14.0
            : isMediumScreen
            ? 18.0
            : isLargeScreen
            ? 22.0
            : 28.0;
    final verticalPadding =
        isSmallScreen
            ? 22.0
            : isMediumScreen
            ? 28.0
            : isLargeScreen
            ? 36.0
            : 44.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sección superior - En Atención
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: containerPadding,
            ),
            decoration: const BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título de la sección
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(
                  height:
                      isSmallScreen
                          ? 16
                          : isMediumScreen
                          ? 20
                          : isLargeScreen
                          ? 28
                          : 32,
                ),
                Text(
                  'En Atención',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: attentionFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height:
                      isSmallScreen
                          ? 12
                          : isMediumScreen
                          ? 16
                          : isLargeScreen
                          ? 20
                          : 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading && currentTurn == '--')
                      Container(
                        width:
                            isSmallScreen
                                ? 40
                                : isMediumScreen
                                ? 50
                                : isLargeScreen
                                ? 60
                                : 70,
                        height:
                            isSmallScreen
                                ? 40
                                : isMediumScreen
                                ? 50
                                : isLargeScreen
                                ? 60
                                : 70,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: currentTurnFontSize,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            currentTurn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Sección inferior - Próximos turnos (con Flex)
          Expanded(
            flex: 4, // Menos espacio para la lista de próximos turnos
            child: Padding(
              padding: EdgeInsets.all(containerPadding),
              child: Column(
                children: [
                  // Título centrado en contenedor más corto y responsivo
                  Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            isSmallScreen
                                ? 280
                                : isMediumScreen
                                ? 300
                                : isLargeScreen
                                ? 350
                                : 400,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical:
                            isSmallScreen
                                ? 8
                                : isMediumScreen
                                ? 10
                                : isLargeScreen
                                ? 12
                                : 14,
                        horizontal:
                            isSmallScreen
                                ? 20
                                : isMediumScreen
                                ? 28
                                : isLargeScreen
                                ? 36
                                : 44,
                      ),
                      decoration: BoxDecoration(
                        color: lightGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: Text(
                        'Próximos turnos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: sectionTitleFontSize,
                          fontWeight: FontWeight.w700,
                          color: darkGrey,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height:
                        isSmallScreen
                            ? 16
                            : isMediumScreen
                            ? 20
                            : isLargeScreen
                            ? 28
                            : 32,
                  ),

                  // Lista de próximos turnos
                  Expanded(
                    child: _buildNextTurnsList(
                      nextTurns: nextTurns,
                      isLoading: isLoading,
                      error: error,
                      screenWidth: screenWidth,
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

  Widget _buildNextTurnsList({
    required List<String> nextTurns,
    required bool isLoading,
    required String? error,
    required double screenWidth,
  }) {
    // Tamaños responsivos
    final isSmallScreen = screenWidth < 700;
    final isMediumScreen = screenWidth >= 700 && screenWidth < 1100;
    final isLargeScreen = screenWidth >= 1100 && screenWidth < 1500;

    // Tamaños de íconos y fuentes responsivos
    final iconSize =
        isSmallScreen
            ? 34.0
            : isMediumScreen
            ? 42.0
            : isLargeScreen
            ? 52.0
            : 64.0;
    final errorFontSize =
        isSmallScreen
            ? 16.0
            : isMediumScreen
            ? 18.0
            : isLargeScreen
            ? 22.0
            : 26.0;
    final emptyFontSize =
        isSmallScreen
            ? 16.0
            : isMediumScreen
            ? 18.0
            : isLargeScreen
            ? 22.0
            : 26.0;
    final turnoFontSize =
        isSmallScreen
            ? 18.0
            : isMediumScreen
            ? 22.0
            : isLargeScreen
            ? 26.0
            : 30.0;
    final numberFontSize =
        isSmallScreen
            ? 20.0
            : isMediumScreen
            ? 24.0
            : isLargeScreen
            ? 28.0
            : 32.0;
    final esperandoFontSize =
        isSmallScreen
            ? 14.0
            : isMediumScreen
            ? 16.0
            : isLargeScreen
            ? 18.0
            : 20.0;
    final itemPadding =
        isSmallScreen
            ? 12.0
            : isMediumScreen
            ? 14.0
            : isLargeScreen
            ? 18.0
            : 22.0;
    final itemMargin =
        isSmallScreen
            ? 8.0
            : isMediumScreen
            ? 10.0
            : isLargeScreen
            ? 14.0
            : 18.0;

    return Stack(
      children: [
        // Contenido principal
        if (error != null)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[300],
                  size: iconSize,
                ),
                SizedBox(
                  height:
                      isSmallScreen
                          ? 15
                          : isMediumScreen
                          ? 18
                          : isLargeScreen
                          ? 22
                          : 25,
                ),
                Text(
                  'Error al cargar',
                  style: TextStyle(
                    color: Colors.red[300],
                    fontSize: errorFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else if (nextTurns.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  color: Colors.grey[400],
                  size: iconSize,
                ),
                SizedBox(
                  height:
                      isSmallScreen
                          ? 15
                          : isMediumScreen
                          ? 18
                          : isLargeScreen
                          ? 22
                          : 25,
                ),
                Text(
                  'No hay turnos\nen espera',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: emptyFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: nextTurns.length,
            itemBuilder: (context, index) {
              final turnParts = nextTurns[index].split(' ');
              final turnText = turnParts.length > 1 ? turnParts[0] : 'Turno: ';
              final turnNumber =
                  turnParts.length > 1 ? turnParts[1] : turnParts[0];

              return Center(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth:
                        isSmallScreen
                            ? 280
                            : isMediumScreen
                            ? 320
                            : isLargeScreen
                            ? 380
                            : 420,
                  ),
                  margin: EdgeInsets.only(bottom: itemMargin),
                  padding: EdgeInsets.symmetric(
                    vertical: itemPadding,
                    horizontal:
                        isSmallScreen
                            ? 16
                            : isMediumScreen
                            ? 20
                            : isLargeScreen
                            ? 28
                            : 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width:
                          isSmallScreen
                              ? 1.5
                              : isMediumScreen
                              ? 2
                              : isLargeScreen
                              ? 2
                              : 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: '$turnText ',
                              style: TextStyle(
                                fontSize: turnoFontSize,
                                color: darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: turnNumber,
                              style: TextStyle(
                                fontSize: numberFontSize,
                                color: darkGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              isSmallScreen
                                  ? 12
                                  : isMediumScreen
                                  ? 14
                                  : isLargeScreen
                                  ? 18
                                  : 20,
                          vertical:
                              isSmallScreen
                                  ? 6
                                  : isMediumScreen
                                  ? 8
                                  : isLargeScreen
                                  ? 10
                                  : 12,
                        ),
                        decoration: BoxDecoration(
                          color: orangeWaiting.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Esperando',
                          style: TextStyle(
                            color: orangeWaiting,
                            fontWeight: FontWeight.bold,
                            fontSize: esperandoFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // Loader transparente superpuesto (apenas visible)
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SizedBox(
                  width:
                      isSmallScreen
                          ? 20
                          : isMediumScreen
                          ? 25
                          : isLargeScreen
                          ? 35
                          : 40,
                  height:
                      isSmallScreen
                          ? 20
                          : isMediumScreen
                          ? 25
                          : isLargeScreen
                          ? 35
                          : 40,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(
                        40,
                        0,
                        40,
                        88,
                      ), // primaryBlue muy transparente
                    ),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
