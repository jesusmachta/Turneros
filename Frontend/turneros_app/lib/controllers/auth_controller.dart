import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Inicia sesión con Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 Iniciando proceso de autenticación con Google...');

      final user = await _authService.signInWithGoogle();
      _currentUser = user;

      print('✅ Autenticación exitosa para: ${user.email}');
      print('🏪 Tienda: ${user.storeName}');

      notifyListeners();
      return true;
    } on StoreNotFoundException catch (e) {
      _setError('Tienda no autorizada: ${e.message}');
      print('❌ Tienda no encontrada: $e');
      return false;
    } catch (e) {
      String errorMsg = 'Error al iniciar sesión';

      if (e.toString().contains('cancelled') ||
          e.toString().contains('popup_closed_by_user')) {
        errorMsg = 'Inicio de sesión cancelado';
      } else if (e.toString().contains('network') ||
          e.toString().contains('network_error')) {
        errorMsg = 'Error de conexión. Verifique su internet';
      } else if (e.toString().contains('timeout')) {
        errorMsg = 'Tiempo de espera agotado. Intente nuevamente';
      } else if (e.toString().contains('CLIENT_ID') ||
          e.toString().contains('appClientId')) {
        errorMsg = 'Error de configuración. Reintente en unos momentos';
      } else if (e.toString().contains('PlatformException')) {
        errorMsg = 'Error de plataforma. Reintente en unos momentos';
      } else {
        errorMsg = 'Error al validar la tienda. Contacte al administrador';
      }

      _setError(errorMsg);
      print('❌ Error en autenticación: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _clearError();

      print('👋 Sesión cerrada correctamente');
      notifyListeners();
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      _setError('Error al cerrar sesión');
    }
  }

  /// Verifica si hay un usuario autenticado al iniciar la app
  Future<void> checkAuthState() async {
    try {
      final user = await _authService.getCurrentUserModel();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error al verificar estado de autenticación: $e');
    }
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Limpia el mensaje de error
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
