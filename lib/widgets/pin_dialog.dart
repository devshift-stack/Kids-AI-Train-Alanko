import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

/// PIN entry dialog for parental controls
class PinDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool isSetup;
  final bool requireConfirmation;
  final Future<bool> Function(String pin)? onVerify;
  final Future<bool> Function(String pin)? onSetup;

  const PinDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.isSetup = false,
    this.requireConfirmation = false,
    this.onVerify,
    this.onSetup,
  });

  /// Show PIN verification dialog
  static Future<bool> showVerify(
    BuildContext context, {
    required Future<bool> Function(String pin) onVerify,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinDialog(
        title: 'Eltern-PIN eingeben',
        subtitle: 'Bitte gib deinen 4-stelligen PIN ein',
        onVerify: onVerify,
      ),
    );
    return result ?? false;
  }

  /// Show PIN setup dialog
  static Future<bool> showSetup(
    BuildContext context, {
    required Future<bool> Function(String pin) onSetup,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinDialog(
        title: 'PIN einrichten',
        subtitle: 'Wähle einen 4-stelligen PIN',
        isSetup: true,
        requireConfirmation: true,
        onSetup: onSetup,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      // Move to next field
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered
        _onPinComplete();
      }
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getCurrentPin() {
    return _controllers.map((c) => c.text).join();
  }

  void _clearPin() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _onPinComplete() async {
    final currentPin = _getCurrentPin();
    if (currentPin.length != 4) return;

    setState(() => _error = null);

    if (widget.isSetup) {
      if (widget.requireConfirmation && !_isConfirming) {
        // First entry - save and ask for confirmation
        _pin = currentPin;
        setState(() => _isConfirming = true);
        _clearPin();
        return;
      }

      if (_isConfirming) {
        // Confirmation entry
        _confirmPin = currentPin;
        if (_pin != _confirmPin) {
          setState(() {
            _error = 'PINs stimmen nicht überein';
            _isConfirming = false;
          });
          _clearPin();
          return;
        }
      }

      // Setup PIN
      if (widget.onSetup != null) {
        setState(() => _isLoading = true);
        final success = await widget.onSetup!(currentPin);
        setState(() => _isLoading = false);

        if (success && mounted) {
          Navigator.of(context).pop(true);
        } else {
          setState(() => _error = 'PIN konnte nicht gespeichert werden');
          _clearPin();
        }
      }
    } else {
      // Verify PIN
      if (widget.onVerify != null) {
        setState(() => _isLoading = true);
        final success = await widget.onVerify!(currentPin);
        setState(() => _isLoading = false);

        if (success && mounted) {
          Navigator.of(context).pop(true);
        } else {
          setState(() => _error = 'Falscher PIN');
          _clearPin();
          HapticFeedback.heavyImpact();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      title: Column(
        children: [
          Icon(
            widget.isSetup ? Icons.lock_outline : Icons.lock,
            size: 48,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.subtitle != null || _isConfirming)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                _isConfirming ? 'PIN bestätigen' : widget.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),

          // PIN entry fields
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 50,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) => _onKeyEvent(index, event),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    obscureText: true,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _onDigitChanged(index, value),
                  ),
                ),
              );
            }),
          ),

          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 14,
                ),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}

/// Quick PIN numpad widget (alternative UI)
class PinNumpad extends StatelessWidget {
  final Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onSubmit;

  const PinNumpad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        _buildRow(['', '0', 'del']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 80, height: 80);
        }

        if (key == 'del') {
          return _NumpadButton(
            onTap: onDelete,
            child: const Icon(Icons.backspace_outlined),
          );
        }

        return _NumpadButton(
          onTap: () => onDigit(key),
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _NumpadButton({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(40),
          child: SizedBox(
            width: 70,
            height: 70,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
