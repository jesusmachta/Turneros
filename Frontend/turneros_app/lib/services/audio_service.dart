import 'package:audioplayers/audioplayers.dart';

/// Servicio para manejar la reproducción de sonidos en la aplicación
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Reproduce el sonido de timbre para atender
  Future<void> playAttendSound() async {
    try {
      await _audioPlayer.play(AssetSource('Logos/timbre para atender.mp3'));
    } catch (e) {
      // Manejo silencioso del error para evitar interrumpir la experiencia del usuario
      print('Error al reproducir sonido: $e');
    }
  }

  /// Libera los recursos del reproductor de audio
  void dispose() {
    _audioPlayer.dispose();
  }
}
