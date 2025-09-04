import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

/// Servicio para manejar la impresión de tickets en impresoras USB térmicas
/// Específicamente para tiendas con ID entre 3000-3999 usando flutter_esc_pos_utils
class USBPrinterService {
  static CapabilityProfile? _profile;
  static Generator? _generator;

  /// Inicializa el generador ESC/POS
  static Future<void> initializeUSBPrinter() async {
    try {
      // Solo inicializar en dispositivos Android físicos
      if (kIsWeb || !Platform.isAndroid) {
        print('📱 Inicialización de impresora USB omitida - no es Android físico');
        return;
      }

      print('🖨️ Inicializando generador ESC/POS...');

      // Cargar perfil de capacidades por defecto
      _profile = await CapabilityProfile.load();
      
      // Crear generador para papel de 80mm (estándar para impresoras térmicas)
      _generator = Generator(PaperSize.mm80, _profile!);

      print('✅ Generador ESC/POS inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando generador ESC/POS: $e');
    }
  }

  /// Genera bytes ESC/POS para un ticket simple
  static List<int> _generateTicketBytes({
    required int turnNumber,
    required String serviceName,
  }) {
    if (_generator == null) {
      throw Exception('Generador ESC/POS no inicializado');
    }

    List<int> bytes = [];

    // Línea en blanco inicial
    bytes += _generator!.feed(1);

    // FARMATODO - Título principal en grande y centrado
    bytes += _generator!.text(
      'Farmatodo',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += _generator!.feed(1);

    // Línea separadora
    bytes += _generator!.text(
      '--------------------------------',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += _generator!.feed(1);

    // Tipo de servicio
    bytes += _generator!.text(
      'Turno de: $serviceName',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
        bold: true,
      ),
    );
    bytes += _generator!.feed(2);

    // Texto "Su turno es:"
    bytes += _generator!.text(
      'Su turno es:',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );
    bytes += _generator!.feed(1);

    // Número de turno - MUY GRANDE
    bytes += _generator!.text(
      '$turnNumber',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size3,
        width: PosTextSize.size3,
        bold: true,
      ),
    );
    bytes += _generator!.feed(2);

    // Línea separadora final
    bytes += _generator!.text(
      '--------------------------------',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += _generator!.feed(1);

    // Mensaje final
    bytes += _generator!.text(
      'Por favor, conserve este ticket.',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += _generator!.feed(3);

    // Cortar papel
    bytes += _generator!.cut();

    return bytes;
  }

  /// Imprime un ticket de turno para tiendas 3000-3999 usando USB
  /// Solo contiene: Farmatodo, número de turno y tipo de servicio
  ///
  /// [turnNumber] - Número del turno a imprimir
  /// [serviceName] - Nombre del servicio solicitado
  ///
  /// Retorna un mensaje indicando el resultado de la impresión
  static Future<String> printTurnTicket({
    required int turnNumber,
    required String serviceName,
  }) async {
    try {
      // Solo imprimir en dispositivos Android físicos
      if (kIsWeb || !Platform.isAndroid) {
        print('📱 Impresión USB no disponible en web o iOS.');
        return "Impresión USB no disponible en esta plataforma";
      }

      print('🖨️ Iniciando impresión de ticket USB...');
      print('📄 Turno: $turnNumber, Servicio: $serviceName');

      // Verificar que el generador esté inicializado
      if (_generator == null || _profile == null) {
        print('❌ Generador ESC/POS no inicializado');
        await initializeUSBPrinter();
        
        if (_generator == null) {
          return "Error: No se pudo inicializar el generador ESC/POS";
        }
      }

      // Validar parámetros
      if (turnNumber <= 0) {
        return "Error: Número de turno inválido";
      }

      if (serviceName.trim().isEmpty) {
        return "Error: Nombre de servicio no puede estar vacío";
      }

      // Generar bytes del ticket
      print('📝 Generando bytes del ticket con flutter_esc_pos_utils...');
      final bytes = _generateTicketBytes(
        turnNumber: turnNumber,
        serviceName: serviceName.trim(),
      );
      
      print('📊 Bytes generados: ${bytes.length} bytes');

      // NOTA: flutter_esc_pos_utils solo genera los bytes ESC/POS
      // Para enviar a impresora USB, se necesita una implementación específica
      // de comunicación USB que no está incluida en esta librería.
      
      // Por ahora, simular envío exitoso
      print('🔗 Bytes ESC/POS generados correctamente');
      print('⚠️ NOTA: Se requiere implementación adicional para comunicación USB');

      // TODO: Implementar envío real a impresora USB
      // Los bytes están listos en la variable 'bytes'
      
      print('✅ Ticket USB generado correctamente');
      return "Ticket generado correctamente con flutter_esc_pos_utils (${bytes.length} bytes)";
      
    } catch (e) {
      final errorMsg = "Error al generar ticket USB: ${e.toString()}";
      print('❌ $errorMsg');
      return errorMsg;
    }
  }

  /// Genera un ticket de prueba
  static Future<String> printTestTicket() async {
    try {
      return await printTurnTicket(
        turnNumber: 999,
        serviceName: "PRUEBA USB",
      );
    } catch (e) {
      return "Error al generar ticket de prueba: $e";
    }
  }

  /// Obtiene información del generador actual
  static Map<String, dynamic> getGeneratorInfo() {
    return {
      'initialized': _generator != null && _profile != null,
      'paperSize': _generator != null ? 'mm80' : null,
      'profileLoaded': _profile != null,
    };
  }
}
