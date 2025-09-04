import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../controllers/auth_controller.dart';
import '../../models/service_model.dart';
import '../../services/turn_api_service.dart';
import '../../services/printer_service.dart';

class DocumentInputView extends StatefulWidget {
  final ServiceModel service;

  const DocumentInputView({super.key, required this.service});

  @override
  State<DocumentInputView> createState() => _DocumentInputViewState();
}

class _DocumentInputViewState extends State<DocumentInputView> {
  String _documentNumber = '';
  String? _selectedDocumentType;
  List<String> _documentTypes = [];
  bool _isLoading = false;
  final TurnApiService _turnApiService = TurnApiService();

  // Colores según el diseño de la app
  static const Color primaryBlue = Color(0xFF002858);
  static const Color lightGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _initializeDocumentTypes();
  }

  void _initializeDocumentTypes() {
    final authController = context.read<AuthController>();
    final storeId = authController.currentUser?.storeId ?? 0;

    if (storeId >= 1000 && storeId <= 1999) {
      _documentTypes = [
        'Cédula de ciudadanía',
        'Registro civil',
        'Tarjeta de identidad',
        'Tarjeta de extranjería',
        'Cédula de extranjería',
        'Número de identificación tributaria',
        'Pasaporte',
        'Permiso especial de permanencia',
        'Documento de identificación extranjero',
        'NUIP',
      ];
      _selectedDocumentType = 'Cédula de ciudadanía';
    } else if (storeId >= 2000 && storeId <= 2999) {
      _documentTypes = [
        'Natural',
        'Pasaporte',
        'Jurídico',
        'Extranjero',
        'Gubernamental',
      ];
      _selectedDocumentType = 'Natural';
    } else {
      // Fallback para otros rangos
      _documentTypes = [
        'Natural',
        'Pasaporte',
        'Jurídico',
        'Extranjero',
        'Gubernamental',
      ];
      _selectedDocumentType = 'Natural';
    }
  }

  void _onNumberPressed(String number) {
    if (_documentNumber.length < 15) {
      // Límite máximo de 15 dígitos
      setState(() {
        _documentNumber += number;
      });
    }
  }

  void _onDeletePressed() {
    if (_documentNumber.isNotEmpty) {
      setState(() {
        _documentNumber = _documentNumber.substring(
          0,
          _documentNumber.length - 1,
        );
      });
    }
  }

  Future<void> _onRequestTurn() async {
    // Validaciones
    if (_documentNumber.isEmpty) {
      _showErrorMessage('Por favor ingresa tu número de documento');
      return;
    }

    if (_documentNumber.length < 6) {
      _showErrorMessage('El número de documento debe tener al menos 6 dígitos');
      return;
    }

    if (_documentNumber.length > 15) {
      _showErrorMessage(
        'El número de documento no puede tener más de 15 dígitos',
      );
      return;
    }

    if (_selectedDocumentType == null) {
      _showErrorMessage('Por favor selecciona el tipo de documento');
      return;
    }

    // Verificar que solo contenga números
    if (!RegExp(r'^\d+$').hasMatch(_documentNumber)) {
      _showErrorMessage('El número de documento solo debe contener números');
      return;
    }

    // Obtener datos del usuario autenticado
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
      // Preparar datos para la API
      final int cedula = int.parse(_documentNumber);
      final String documento = _selectedDocumentType!;

      // Llamar a la API
      final result = await _turnApiService.createTurn(
        storeId: user.storeId!,
        name: widget.service.name,
        type: widget.service.type,
        cedula: cedula,
        documento: documento,
        country: user.country!,
      );

      if (result['success']) {
        // Imprimir ticket automáticamente
        final turnNumber = result['data']['turnNumber'] ?? 0;
        print('🖨️ Imprimiendo ticket #$turnNumber para usuario con documento');

        try {
          final printResult = await PrinterService.printTurnTicket(
            turnNumber: turnNumber,
            cedula: cedula,
            serviceType: widget.service.type,
            storeId: user.storeId!,
          );
          print('✅ Resultado de impresión: $printResult');
        } catch (e) {
          print('⚠️ Error al imprimir: $e');
          // Continuar mostrando el diálogo aunque falle la impresión
        }

        _showSuccessDialog(result['data']);
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

  void _showSuccessDialog(Map<String, dynamic> turnData) {
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
                    'Servicio: ${widget.service.name}',
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
        Navigator.of(context).pop(); // Volver a la vista anterior
      }
    });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Contenido principal
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05), // 5% del ancho
                child: Column(
                  children: [
                    // Sección de datos
                    _buildDataSection(),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.025), // 2.5% de la altura

                    // Teclado numérico
                    Expanded(child: _buildNumericKeypad()),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% de la altura

                    // Botón de solicitar turno
                    _buildRequestButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calcular tamaños responsive para pantalla 15.6" (1080x1920)
    final verticalPadding = screenHeight * 0.02; // 2% de la altura (~38px)
    final horizontalPadding = screenWidth * 0.05; // 5% del ancho (~54px)
    final fontSize = screenWidth * 0.04; // 4% del ancho (~43px) - Aumentado
    
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
          Text(
            'Pide un Turno',
            style: TextStyle(
              fontSize: fontSize.clamp(28.0, 48.0), // Aumentar rango
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calcular tamaños responsive para pantalla 15.6" (1080x1920)
    final titleFontSize = screenWidth * 0.035; // 3.5% del ancho (~38px) - Aumentado
    final subtitleFontSize = screenWidth * 0.026; // 2.6% del ancho (~28px) - Aumentado
    final inputHeight = screenHeight * 0.07; // 7% de la altura (~134px)
    final inputFontSize = screenWidth * 0.025; // 2.5% del ancho (~27px)
    final borderRadius = screenWidth * 0.015; // 1.5% del ancho (~16px)
    final horizontalPadding = screenWidth * 0.025; // 2.5% del ancho (~27px)
    final spacing = screenWidth * 0.02; // 2% del ancho (~22px)
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Centrar contenido
      children: [
        Text(
          'Datos',
          textAlign: TextAlign.center, // Centrar texto
          style: TextStyle(
            fontSize: titleFontSize.clamp(24.0, 42.0), // Aumentar rango
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        SizedBox(height: spacing * 0.4),
        Text(
          'Ingresa tu documento para solicitar un turno',
          textAlign: TextAlign.center, // Centrar texto
          style: TextStyle(
            fontSize: subtitleFontSize.clamp(18.0, 32.0), // Aumentar rango
            color: Colors.grey,
          ),
        ),
        SizedBox(height: spacing * 1.2),

        // Dropdown y campo de documento en una fila
        Row(
          children: [
            // Dropdown
            Expanded(
              flex: 2,
              child: Container(
                height: inputHeight,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(borderRadius),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDocumentType,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: inputFontSize.clamp(16.0, 30.0),
                      color: Colors.black87,
                    ),
                    items: _documentTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type, 
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: inputFontSize.clamp(16.0, 30.0),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDocumentType = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),

            SizedBox(width: spacing),

            // Campo de número de documento
            Expanded(
              flex: 3,
              child: Container(
                height: inputHeight,
                padding: EdgeInsets.all(horizontalPadding),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(borderRadius),
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    _documentNumber.isEmpty ? 'N° de Documento' : _documentNumber,
                    style: TextStyle(
                      fontSize: inputFontSize.clamp(16.0, 30.0),
                      color: _documentNumber.isEmpty
                          ? Colors.grey.shade500
                          : Colors.black87,
                      fontWeight: _documentNumber.isEmpty 
                          ? FontWeight.normal 
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumericKeypad() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calcular tamaños responsive basados en el tamaño de pantalla
    final horizontalPadding = screenWidth * 0.08; // 8% del ancho de pantalla
    final verticalPadding = screenHeight * 0.02; // 2% de la altura de pantalla
    final buttonSpacing = screenWidth * 0.05; // 5% del ancho de pantalla
    final rowSpacing = screenHeight * 0.02; // 2% de la altura de pantalla

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        children: [
          // Fila 1: 1, 2, 3
          Expanded(
            child: Row(
              children: [
                _buildKeypadButton('1'),
                SizedBox(width: buttonSpacing),
                _buildKeypadButton('2'),
                SizedBox(width: buttonSpacing),
                _buildKeypadButton('3'),
              ],
            ),
          ),

          SizedBox(height: rowSpacing),

          // Fila 2: 4, 5, 6
          Expanded(
            child: Row(
              children: [
                _buildKeypadButton('4'),
                SizedBox(width: buttonSpacing),
                _buildKeypadButton('5'),
                SizedBox(width: buttonSpacing),
                _buildKeypadButton('6'),
              ],
            ),
          ),

          SizedBox(height: rowSpacing),

          // Fila 3: 7, 8, 9
          Expanded(
            child: Row(
              children: [
                _buildKeypadButton('7'),
                SizedBox(width: buttonSpacing),
                _buildKeypadButton('8'),
                SizedBox(width: buttonSpacing),
                _buildKeypadButton('9'),
              ],
            ),
          ),

          SizedBox(height: rowSpacing),

          // Fila 4: X, 0
          Expanded(
            child: Row(
              children: [
                _buildKeypadButton('X', isDelete: true),
                SizedBox(width: buttonSpacing),
                _buildKeypadButton('0'),
                SizedBox(width: buttonSpacing),
                // Espacio vacío para mantener simetría
                Expanded(child: Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String text, {bool isDelete = false}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calcular tamaños responsive
    final buttonPadding = screenWidth * 0.015; // 1.5% del ancho de pantalla
    final fontSize = screenHeight * 0.035; // 3.5% de la altura de pantalla
    final iconSize = screenHeight * 0.03; // 3% de la altura de pantalla
    final borderWidth = screenWidth * 0.002; // 0.2% del ancho de pantalla
    final blurRadius = screenWidth * 0.02; // 2% del ancho de pantalla

    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(buttonPadding),
        child: AspectRatio(
          aspectRatio: 1.0, // Mantiene proporción circular
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isDelete) {
                  _onDeletePressed();
                } else {
                  _onNumberPressed(text);
                }
              },
              borderRadius: BorderRadius.circular(100),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.2),
                    width: borderWidth.clamp(1.0, 3.0), // Mínimo 1, máximo 3
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.15),
                      blurRadius: blurRadius.clamp(
                        4.0,
                        16.0,
                      ), // Mínimo 4, máximo 16
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isDelete
                      ? Icon(
                          Icons.backspace_outlined,
                          size: iconSize.clamp(
                            20.0,
                            40.0,
                          ), // Mínimo 20, máximo 40
                          color: primaryBlue,
                        )
                      : Text(
                          text,
                          style: TextStyle(
                            fontSize: fontSize.clamp(
                              24.0,
                              56.0,
                            ), // Mínimo 24, máximo 56
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestButton() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calcular tamaños responsive para pantalla 15.6" (1080x1920)
    final buttonHeight = screenHeight * 0.08; // 8% de la altura (~154px)
    final fontSize = screenWidth * 0.028; // 2.8% del ancho (~30px)
    final borderRadius = screenWidth * 0.02; // 2% del ancho (~22px)
    final loadingSize = buttonHeight * 0.35; // 35% de la altura del botón
    
    final bool isEnabled = _documentNumber.length >= 6 &&
        _documentNumber.length <= 15 &&
        _selectedDocumentType != null &&
        RegExp(r'^\d+$').hasMatch(_documentNumber) &&
        !_isLoading;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isEnabled ? _onRequestTurn : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: isEnabled ? 6 : 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: loadingSize,
                height: loadingSize,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Pedir Turno',
                style: TextStyle(
                  fontSize: fontSize.clamp(18.0, 35.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
