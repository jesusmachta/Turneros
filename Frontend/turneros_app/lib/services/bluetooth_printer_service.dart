import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

/// Servicio para manejar la impresión de tickets en impresoras Bluetooth térmicas
/// Específicamente para tiendas con ID entre 3000-3999 usando flutter_pos_printer_platform
class BluetoothPrinterService {
  static final PrinterManager _printerManager = PrinterManager.instance;
  static PrinterDevice? _connectedDevice;
  static bool _isConnected = false;

  /// Inicializa la impresora Bluetooth al inicio de la aplicación
  static Future<void> initializeBluetoothPrinter() async {
    try {
      // Solo inicializar en dispositivos Android físicos
      if (kIsWeb || !Platform.isAndroid) {
        print(
            '📱 Inicialización de impresora Bluetooth omitida - no es Android físico');
        return;
      }

      print('🖨️ Inicializando servicio Flutter POS Printer Platform...');

      // Escuchar cambios de estado de Bluetooth
      _printerManager.stateBluetooth.listen((status) {
        print('🔗 Estado de Bluetooth: $status');
        _isConnected = (status == BTStatus.connected);
      });

      print('✅ Servicio Flutter POS Printer Platform inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando Flutter POS Printer Platform: $e');
    }
  }

  /// Inicia el escaneo de dispositivos Bluetooth
  static Future<List<PrinterDevice>> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      if (kIsWeb || !Platform.isAndroid) {
        print('📱 Escaneo Bluetooth no disponible en web o iOS');
        return [];
      }

      print('🔍 Iniciando escaneo de dispositivos Bluetooth...');
      
      List<PrinterDevice> devices = [];
      
      // Configurar el listener para encontrar dispositivos
      _printerManager.discovery(type: PrinterType.bluetooth, isBle: false).listen((device) {
        print('📱 Dispositivo encontrado: ${device.name} (${device.address})');
        devices.add(device);
      });

      // Esperar el tiempo de timeout
      await Future.delayed(timeout);
      
      print('✅ Escaneo completado, encontrados ${devices.length} dispositivos');
      return devices;
    } catch (e) {
      print('❌ Error durante escaneo: $e');
      return [];
    }
  }

  /// Conecta a una impresora Bluetooth
  static Future<bool> connectToPrinter(PrinterDevice device) async {
    try {
      if (kIsWeb || !Platform.isAndroid) {
        print('📱 Conexión Bluetooth no disponible en web o iOS.');
        return false;
      }

      print('🔗 Conectando a impresora: ${device.name} (${device.address})');

      await _printerManager.connect(
        type: PrinterType.bluetooth,
        model: BluetoothPrinterInput(
          name: device.name,
          address: device.address!,
          isBle: false,
          autoConnect: true,
        ),
      );

      _connectedDevice = device;

      // Esperar un momento para que se establezca la conexión
      await Future.delayed(const Duration(seconds: 2));

      if (_isConnected) {
        print('✅ Conectado exitosamente a ${device.name}');
        return true;
      } else {
        print('❌ Falló la conexión a ${device.name}');
        return false;
      }
    } catch (e) {
      print('❌ Error conectando a impresora: $e');
      return false;
    }
  }

  /// Verifica el estado de conexión de la impresora
  static bool isConnected() {
    return _isConnected && _connectedDevice != null;
  }

  /// Obtiene el dispositivo conectado actualmente
  static PrinterDevice? getConnectedDevice() {
    return _connectedDevice;
  }

  /// Desconecta de la impresora
  static Future<bool> disconnect() async {
    try {
      if (kIsWeb || !Platform.isAndroid) {
        return true;
      }

      print('🔌 Desconectando impresora...');
      await _printerManager.disconnect(type: PrinterType.bluetooth);
      
      _isConnected = false;
      _connectedDevice = null;
      
      print('✅ Desconectado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error desconectando: $e');
      return false;
    }
  }

  /// Genera bytes ESC/POS para un ticket simple de 58mm
  static List<int> _generateTicketBytes({
    required int turnNumber,
    required String serviceName,
  }) {
    List<int> bytes = [];

    // Comandos ESC/POS básicos
    const esc = 0x1B;
    const gs = 0x1D;
    
    // Inicializar impresora
    bytes.addAll([esc, 0x40]); // ESC @
    
    // Configurar para papel de 58mm
    bytes.addAll([esc, 0x61, 0x01]); // ESC a - Centrar texto
    
    // Espacio inicial
    bytes.addAll([0x0A]); // Nueva línea
    
    // FARMATODO - Título principal
    bytes.addAll([esc, 0x21, 0x30]); // ESC ! - Texto grande y negrita
    bytes.addAll('FARMATODO'.codeUnits);
    bytes.addAll([0x0A, 0x0A]); // Doble nueva línea
    
    // Separador
    bytes.addAll([esc, 0x21, 0x00]); // ESC ! - Texto normal
    bytes.addAll('--------------------------------'.codeUnits);
    bytes.addAll([0x0A, 0x0A]);
    
    // Tipo de servicio
    bytes.addAll([esc, 0x21, 0x10]); // ESC ! - Texto mediano y negrita
    bytes.addAll('SERVICIO:'.codeUnits);
    bytes.addAll([0x0A]);
    
    bytes.addAll([esc, 0x21, 0x00]); // ESC ! - Texto normal
    bytes.addAll(serviceName.toUpperCase().codeUnits);
    bytes.addAll([0x0A, 0x0A]);
    
    // Texto "SU TURNO ES:"
    bytes.addAll([esc, 0x21, 0x10]); // ESC ! - Texto mediano y negrita
    bytes.addAll('SU TURNO ES:'.codeUnits);
    bytes.addAll([0x0A, 0x0A]);
    
    // Número de turno - MUY GRANDE
    bytes.addAll([esc, 0x21, 0x38]); // ESC ! - Texto muy grande y negrita
    bytes.addAll('$turnNumber'.codeUnits);
    bytes.addAll([0x0A, 0x0A]);
    
    // Separador final
    bytes.addAll([esc, 0x21, 0x00]); // ESC ! - Texto normal
    bytes.addAll('--------------------------------'.codeUnits);
    bytes.addAll([0x0A]);
    
    // Mensaje final
    bytes.addAll('Conserve este ticket'.codeUnits);
    bytes.addAll([0x0A, 0x0A, 0x0A]);
    
    // Cortar papel (si la impresora lo soporta)
    bytes.addAll([gs, 0x56, 0x00]); // GS V - Cortar papel
    
    return bytes;
  }

  /// Imprime un ticket de turno simple para tiendas 3000-3999
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
        print('📱 Impresión Bluetooth no disponible en web o iOS.');
        return "Impresión Bluetooth no disponible en esta plataforma";
      }

      print('🖨️ Iniciando impresión de ticket Bluetooth...');
      print('📄 Turno: $turnNumber, Servicio: $serviceName');

      // Verificar conexión
      if (!isConnected()) {
        print('❌ No hay impresora Bluetooth conectada');
        return "Error: No hay impresora Bluetooth conectada";
      }

      print('📱 Dispositivo conectado: ${_connectedDevice?.name}');

      // Generar bytes del ticket
      print('📝 Generando bytes del ticket...');
      final bytes = _generateTicketBytes(
        turnNumber: turnNumber,
        serviceName: serviceName,
      );
      
      print('📊 Bytes generados: ${bytes.length} bytes');
      print('🔗 Enviando datos a impresora Bluetooth...');

      // Enviar bytes a la impresora
      await _printerManager.send(
        type: PrinterType.bluetooth,
        bytes: bytes,
      );
      
      print('📤 Datos enviados exitosamente');

      print('✅ Ticket Bluetooth impreso correctamente');
      return "Ticket impreso correctamente via Bluetooth";
    } catch (e) {
      final errorMsg = "Error al imprimir via Bluetooth: ${e.toString()}";
      print('❌ $errorMsg');
      return errorMsg;
    }
  }

  /// Imprime un ticket de prueba
  static Future<String> printTestTicket() async {
    try {
      if (!isConnected()) {
        return "Error: No hay impresora Bluetooth conectada";
      }

      final bytes = _generateTicketBytes(
        turnNumber: 999,
        serviceName: "PRUEBA",
      );

      await _printerManager.send(
        type: PrinterType.bluetooth,
        bytes: bytes,
      );
      
      return "Ticket de prueba impreso correctamente";
    } catch (e) {
      return "Error al imprimir ticket de prueba: $e";
    }
  }
}