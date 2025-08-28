import 'package:audioplayers/audioplayers.dart';

/// Servicio para manejar la reproducción de sonidos en la aplicación
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;

  /// Inicializa el reproductor de audio
  Future<void> _initializePlayer() async {
    if (!_isInitialized) {
      try {
        _audioPlayer = AudioPlayer();
        _isInitialized = true;
        print('🔊 AudioPlayer inicializado correctamente');
      } catch (e) {
        print('❌ Error al inicializar AudioPlayer: $e');
      }
    }
  }

  /// Reproduce el sonido de timbre para atender
  Future<void> playAttendSound() async {
    try {
      await _initializePlayer();

      if (_audioPlayer == null) {
        print('❌ AudioPlayer no disponible');
        return;
      }

      // Detener cualquier reproducción en curso
      await _audioPlayer!.stop();

      // Reproducir el sonido
      await _audioPlayer!.play(AssetSource('Logos/timbre para atender.mp3'));
      print('🔔 Sonido de timbre reproducido');
    } catch (e) {
      // Manejo detallado del error para debugging
      print('❌ Error al reproducir sonido: $e');
      print('❌ Tipo de error: ${e.runtimeType}');

      // Reintentar inicialización si es necesario
      if (e.toString().contains('Bad state')) {
        print('🔄 Reintentando inicialización del reproductor...');
        _isInitialized = false;
        _audioPlayer?.dispose();
        _audioPlayer = null;

        // Reintentar una vez
        try {
          await _initializePlayer();
          if (_audioPlayer != null) {
            await _audioPlayer!.play(
              AssetSource('Logos/timbre para atender.mp3'),
            );
            print('🔔 Sonido reproducido después del reintento');
          }
        } catch (retryError) {
          print('❌ Error en reintento: $retryError');
        }
      }
    }
  }

  /// Libera los recursos del reproductor de audio
  void dispose() {
    try {
      _audioPlayer?.dispose();
      _audioPlayer = null;
      _isInitialized = false;
      print('🧹 AudioService recursos liberados');
    } catch (e) {
      print('❌ Error al liberar AudioService: $e');
    }
  }
}
