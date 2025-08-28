import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sunmi_printer_plus/core/styles/sunmi_text_style.dart';
import 'package:sunmi_printer_plus/core/styles/sunmi_qrcode_style.dart';
import 'package:sunmi_printer_plus/core/enums/enums.dart';
import 'package:sunmi_printer_plus/core/sunmi/sunmi_printer.dart';

/// Servicio para manejar la impresión de tickets en dispositivos Sunmi
class PrinterService {
  /// Inicializa la impresora Sunmi al inicio de la aplicación
  /// Se recomienda llamar esta función en el startup de la app
  static Future<void> initializeSunmiPrinter() async {
    try {
      // Solo inicializar en dispositivos Android físicos
      if (kIsWeb || !Platform.isAndroid) {
        print('📱 Inicialización de impresora omitida - no es Android físico');
        return;
      }

      print('🖨️ Inicializando impresora Sunmi...');

      await SunmiPrinter.bindingPrinter();
      await SunmiPrinter.initPrinter();
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);

      print('✅ Impresora Sunmi inicializada correctamente');
    } catch (e) {
      print('❌ Error inicializando impresora: $e');
      // La app puede continuar funcionando aunque falle la inicialización
      // solo que no podrá imprimir tickets
    }
  }

  /// Imprime un ticket de turno con los datos proporcionados
  ///
  /// [turnNumber] - Número del turno a imprimir
  /// [cedula] - Número de cédula del cliente
  /// [serviceType] - Tipo de servicio solicitado
  ///
  /// Retorna un mensaje indicando el resultado de la impresión
  static Future<String> printTurnTicket({
    required int turnNumber,
    required int cedula,
    required String serviceType,
  }) async {
    try {
      // Solo imprimir en dispositivos Android físicos
      if (kIsWeb || !Platform.isAndroid) {
        print('📱 Impresión no disponible en web o iOS. Solo Android físico.');
        return "Impresión no disponible en esta plataforma";
      }

      print('🖨️ Iniciando impresión de ticket...');
      print('📄 Turno: $turnNumber, Servicio: $serviceType, Cédula: $cedula');

      // Verificar conexión de impresora (ya inicializada en main.dart)
      try {
        await SunmiPrinter.initPrinter();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        // Si falla, intentar reconectar
        print('⚠️ Reconectando impresora...');
        await SunmiPrinter.bindingPrinter();
        await Future.delayed(const Duration(milliseconds: 500));
        await SunmiPrinter.initPrinter();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // --- Contenido del Ticket ---

      await SunmiPrinter.lineWrap(1);
      await Future.delayed(const Duration(milliseconds: 100));

      // Título principal
      await SunmiPrinter.printText(
        'Farmatodo',
        style: SunmiTextStyle(
          align: SunmiPrintAlign.CENTER,
          fontSize: 48,
          bold: true,
        ),
      );
      await SunmiPrinter.lineWrap(1);
      await Future.delayed(const Duration(milliseconds: 100));

      // Tipo de servicio
      await SunmiPrinter.printText(
        'Turno de: $serviceType',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER, fontSize: 30),
      );
      await SunmiPrinter.lineWrap(1);
      await Future.delayed(const Duration(milliseconds: 100));

      // Mensaje "Su turno es"
      await SunmiPrinter.printText(
        'Su turno es:',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER, fontSize: 24),
      );
      await SunmiPrinter.lineWrap(3);
      await Future.delayed(const Duration(milliseconds: 100));

      // Número de turno (Grande y en negrita)
      await SunmiPrinter.printText(
        '$turnNumber',
        style: SunmiTextStyle(
          align: SunmiPrintAlign.CENTER,
          fontSize: 72,
          bold: true,
        ),
      );
      await SunmiPrinter.lineWrap(2);
      await Future.delayed(const Duration(milliseconds: 100));

      // Imprimir código QR solo si hay cédula válida
      if (cedula != 0) {
        // Imprimir el código QR con la cédula y el carácter "Enter"
        // Se agrega '\n' al final del string para simular la tecla Enter.
        await SunmiPrinter.printQRCode(
          '${cedula.toString()}\n\n', // Convertir la cédula a String y añadir salto de línea
          style: SunmiQrcodeStyle(
            align: SunmiPrintAlign.CENTER,
            qrcodeSize: 4, // Tamaño del QR (1-16, donde 4 es un tamaño medio)
          ),
        );
        await Future.delayed(const Duration(milliseconds: 200));

        await SunmiPrinter.lineWrap(2);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Mensaje final
      await SunmiPrinter.printText(
        'Por favor, conserve este ticket.',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER, fontSize: 22),
      );

      await SunmiPrinter.lineWrap(3);
      await Future.delayed(const Duration(milliseconds: 100));

      // Cortar papel y finalizar
      await SunmiPrinter.cutPaper();
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ Ticket impreso correctamente');
      return "Ticket impreso correctamente con código QR";
    } catch (e) {
      final errorMsg = "Error al imprimir: ${e.toString()}";
      print('❌ $errorMsg');
      return errorMsg;
    }
  }
}
