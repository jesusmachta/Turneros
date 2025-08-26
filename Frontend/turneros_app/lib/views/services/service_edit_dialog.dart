import 'package:flutter/material.dart';
import '../../models/service_model.dart';

class ServiceEditDialog extends StatefulWidget {
  final ServiceModel service;
  final Function(
    String? newName,
    String? newType,
    bool? newActive,
    bool? newSms,
    bool? newScreen,
  )
  onSave;

  const ServiceEditDialog({
    super.key,
    required this.service,
    required this.onSave,
  });

  @override
  State<ServiceEditDialog> createState() => _ServiceEditDialogState();
}

class _ServiceEditDialogState extends State<ServiceEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late bool _isActive;
  late bool _hasSms;
  late bool _hasScreen;
  bool _isLoading = false;

  // Colores del sistema (azul oscuro principal)
  static const Color primaryDarkBlue = Color(0xFF002858);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121);
  static const Color textGray = Color(0xFF757575);
  static const Color activeGreen = Color(0xFF4CAF50);
  static const Color inactiveRed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _typeController = TextEditingController(text: widget.service.type);
    _isActive = widget.service.active;
    _hasSms = widget.service.sms;
    _hasScreen = widget.service.screen;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    return _nameController.text.trim() != widget.service.name ||
        _typeController.text.trim() != widget.service.type ||
        _isActive != widget.service.active ||
        _hasSms != widget.service.sms ||
        _hasScreen != widget.service.screen;
  }

  void _handleSave() async {
    if (!_hasChanges()) {
      Navigator.of(context).pop();
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorSnackbar('El nombre del servicio es requerido');
      return;
    }

    final type = _typeController.text.trim();
    if (type.isEmpty) {
      _showErrorSnackbar('El tipo del servicio es requerido');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSave(
        name != widget.service.name ? name : null,
        type != widget.service.type ? type : null,
        _isActive != widget.service.active ? _isActive : null,
        _hasSms != widget.service.sms ? _hasSms : null,
        _hasScreen != widget.service.screen ? _hasScreen : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Error al guardar los cambios');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: inactiveRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryDarkBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: primaryDarkBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar Servicio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      Text(
                        'Modificar información del servicio',
                        style: TextStyle(fontSize: 14, color: textGray),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: textGray),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Formulario
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo de nombre
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nombre del servicio',
                      icon: Icons.label_outline,
                      helperText: 'Nombre identificativo del servicio',
                    ),

                    const SizedBox(height: 20),

                    // Campo de tipo
                    _buildTextField(
                      controller: _typeController,
                      label: 'Tipo de servicio',
                      icon: Icons.category_outlined,
                      helperText: 'Categoría o tipo de servicio',
                    ),

                    const SizedBox(height: 24),

                    // Estado activo/inactivo
                    _buildSwitchCard(
                      title: 'Estado del servicio',
                      subtitle:
                          _isActive ? 'Servicio activo' : 'Servicio inactivo',
                      value: _isActive,
                      icon: _isActive ? Icons.check_circle : Icons.pause_circle,
                      color: _isActive ? activeGreen : inactiveRed,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Notificaciones SMS
                    _buildSwitchCard(
                      title: 'Notificaciones SMS',
                      subtitle:
                          _hasSms
                              ? 'Envía notificaciones por SMS'
                              : 'Sin notificaciones SMS',
                      value: _hasSms,
                      icon: Icons.sms,
                      color: const Color(0xFF2196F3),
                      onChanged: (value) {
                        setState(() {
                          _hasSms = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Mostrar en pantalla
                    _buildSwitchCard(
                      title: 'Mostrar en pantalla',
                      subtitle:
                          _hasScreen
                              ? 'Visible en pantallas de turnos'
                              : 'No visible en pantallas',
                      value: _hasScreen,
                      icon: Icons.tv,
                      color: const Color(0xFF9C27B0),
                      onChanged: (value) {
                        setState(() {
                          _hasScreen = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryDarkBlue,
                      foregroundColor: cardWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  cardWhite,
                                ),
                              ),
                            )
                            : const Text(
                              'Guardar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryDarkBlue),
            hintText: 'Ingrese el $label',
            helperText: helperText,
            helperStyle: TextStyle(color: textGray, fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: textGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryDarkBlue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: textGray.withValues(alpha: 0.5)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                Text(subtitle, style: TextStyle(fontSize: 12, color: textGray)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
