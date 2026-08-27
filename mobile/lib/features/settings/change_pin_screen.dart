import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_typography.dart';

class ChangePinFlow extends ConsumerStatefulWidget {
  const ChangePinFlow({super.key});

  @override
  ConsumerState<ChangePinFlow> createState() => _ChangePinFlowState();
}

class _ChangePinFlowState extends ConsumerState<ChangePinFlow> {
  int _currentStep = 0;
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSuccess = false;

  static const int _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _loadCurrentPin();
  }

  Future<void> _loadCurrentPin() async {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_isSuccess) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _errorMessage = null;
      
      switch (_currentStep) {
        case 0:
          if (_currentPin.length < _pinLength) {
            _currentPin += digit;
            if (_currentPin.length == _pinLength) {
              _validateCurrentPin();
            }
          }
          break;
        case 1:
          if (_newPin.length < _pinLength) {
            _newPin += digit;
          }
          break;
        case 2:
          if (_confirmPin.length < _pinLength) {
            _confirmPin += digit;
            if (_confirmPin.length == _pinLength) {
              _validateConfirmPin();
            }
          }
          break;
      }
    });
  }

  void _onBackspacePressed() {
    if (_isSuccess) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _errorMessage = null;
      
      switch (_currentStep) {
        case 0:
          if (_currentPin.isNotEmpty) {
            _currentPin = _currentPin.substring(0, _currentPin.length - 1);
          }
          break;
        case 1:
          if (_newPin.isNotEmpty) {
            _newPin = _newPin.substring(0, _newPin.length - 1);
          }
          break;
        case 2:
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          }
          break;
      }
    });
  }

  Future<void> _validateCurrentPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('security_pin') ?? '1234';
    
    if (_currentPin == savedPin) {
      setState(() {
        _currentStep = 1;
        _currentPin = '';
      });
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
      _shakeAndClear();
    }
  }

  void _validateConfirmPin() {
    if (_confirmPin == _newPin) {
      _saveNewPin();
    } else {
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
      });
      _shakeAndClear();
    }
  }

  Future<void> _saveNewPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_pin', _newPin);
    
    setState(() {
      _isSuccess = true;
    });
    
    // Auto-dismiss after success
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.pop();
      }
    });
  }

  void _shakeAndClear() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _confirmPin = '';
        });
      }
    });
  }

  String get _currentPinDisplay {
    switch (_currentStep) {
      case 0:
        return _currentPin;
      case 1:
        return _newPin;
      case 2:
        return _confirmPin;
      default:
        return '';
    }
  }

  bool get _isStepComplete {
    switch (_currentStep) {
      case 0:
        return _currentPin.length == _pinLength;
      case 1:
        return _newPin.length == _pinLength;
      case 2:
        return _confirmPin.length == _pinLength;
      default:
        return false;
    }
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return 'Enter Current PIN';
      case 1:
        return 'Enter New PIN';
      case 2:
        return 'Confirm New PIN';
      default:
        return '';
    }
  }

  String get _stepDescription {
    switch (_currentStep) {
      case 0:
        return 'Please enter your current 4-digit PIN to continue';
      case 1:
        return 'Choose a new 4-digit PIN for your app protection.';
      case 2:
        return 'Please re-enter your new PIN to confirm';
      default:
        return '';
    }
  }

  String get _stepButtonText {
    switch (_currentStep) {
      case 0:
        return 'Continue';
      case 1:
        return 'Save New PIN';
      case 2:
        return 'Confirm New PIN';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: const Text('Change PIN'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            _currentStep == 0 ? Icons.close : Icons.arrow_back,
            color: colors.onSurfaceVariant,
          ),
          onPressed: () {
            if (_currentStep == 0) {
              context.pop();
            } else {
              setState(() {
                _currentStep--;
                _errorMessage = null;
                if (_currentStep == 1) {
                  _newPin = '';
                } else if (_currentStep == 0) {
                  _currentPin = '';
                }
              });
            }
          },
        ),
        title: Text(
          'Change PIN',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.stackLg),
                    _buildHeader(colors, textTheme),
                    const SizedBox(height: AppSpacing.stackLg),
                    _buildPinIndicators(colors),
                    const SizedBox(height: AppSpacing.stackMd),
                    _buildErrorMessage(colors, textTheme),
                    const SizedBox(height: AppSpacing.stackLg),
                  ],
                ),
              ),
            ),
            _buildKeypad(colors),
            _buildActionButton(colors, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          _stepTitle,
          style: textTheme.headlineSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          _stepDescription,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPinIndicators(ColorScheme colors) {
    final currentPin = _currentPinDisplay;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final isFilled = index < currentPin.length;
        final isError = _errorMessage != null && _isSuccess == false;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter / 2),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (isError ? colors.error : colors.primary)
                : colors.surfaceContainerHighest,
            border: Border.all(
              color: isFilled
                  ? (isError ? colors.error : colors.primary)
                  : colors.outlineVariant,
              width: 1.5,
            ),
          ),
          child: isFilled
              ? AnimatedScale(
                  scale: isFilled ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: colors.onPrimary,
                  ),
                )
              : null,
        );
      }),
    );
  }

  Widget _buildErrorMessage(ColorScheme colors, TextTheme textTheme) {
    if (_errorMessage == null) {
      return const SizedBox(height: 24);
    }
    
    return AnimatedOpacity(
      opacity: _errorMessage != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        height: 24,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 18,
              color: colors.error,
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Text(
              _errorMessage!,
              style: textTheme.labelLarge?.copyWith(
                color: colors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
      ),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3'], colors),
          const SizedBox(height: AppSpacing.stackMd),
          _buildKeypadRow(['4', '5', '6'], colors),
          const SizedBox(height: AppSpacing.stackMd),
          _buildKeypadRow(['7', '8', '9'], colors),
          const SizedBox(height: AppSpacing.stackMd),
          _buildKeypadRow(['', '0', '⌫'], colors),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 64);
        }
        
        if (key == '⌫') {
          return _buildSpecialKey(
            icon: Icons.backspace_outlined,
            onTap: _onBackspacePressed,
            colors: colors,
          );
        }
        
        return _buildNumberKey(key, colors);
      }).toList(),
    );
  }

  Widget _buildNumberKey(String digit, ColorScheme colors) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: colors.surfaceContainerHigh,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          onTap: () => _onDigitPressed(digit),
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              digit,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              color: colors.onSurfaceVariant,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(ColorScheme colors, TextTheme textTheme) {
    final isEnabled = _isStepComplete && !_isSuccess;
    
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: AppSpacing.stackMd,
        bottom: AppSpacing.stackMd + MediaQuery.of(context).padding.bottom,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled ? _onActionButtonPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled
                ? (_isSuccess ? colors.secondaryContainer : colors.primary)
                : colors.surfaceContainerHighest,
            foregroundColor: isEnabled
                ? (_isSuccess ? colors.onSecondaryContainer : colors.onPrimary)
                : colors.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            elevation: isEnabled ? 2 : 0,
          ),
          child: _isSuccess
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colors.onSecondaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Text(
                      'PIN Confirmed',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Text(
                  _stepButtonText,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  void _onActionButtonPressed() {
    switch (_currentStep) {
      case 0:
        _validateCurrentPin();
        break;
      case 1:
        setState(() {
          _currentStep = 2;
        });
        break;
      case 2:
        _validateConfirmPin();
        break;
    }
  }
}
