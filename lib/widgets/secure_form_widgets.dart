// lib/widgets/secure_form_widgets.dart - FIXED form validation components
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// FIXED: Secure text field with comprehensive validation
class SecureTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final bool isPassword;
  final bool isEmail;
  final bool isRequired;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? customValidator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final String? semanticLabel;

  const SecureTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.isPassword = false,
    this.isEmail = false,
    this.isRequired = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.customValidator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.semanticLabel,
  }) : super(key: key);

  @override
  State<SecureTextField> createState() => _SecureTextFieldState();
}

class _SecureTextFieldState extends State<SecureTextField> {
  bool _obscurePassword = true;
  String? _errorText;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_errorText != null && widget.controller.text.isNotEmpty) {
      // Clear error when user starts typing
      setState(() {
        _errorText = null;
      });
    }
  }

  String? _validateInput(String? value) {
    if (widget.customValidator != null) {
      return widget.customValidator!(value);
    }

    if (widget.isRequired && (value == null || value.trim().isEmpty)) {
      return '${widget.label} est requis';
    }

    if (value != null && value.isNotEmpty) {
      // Length validation
      if (widget.maxLength != null && value.length > widget.maxLength!) {
        return '${widget.label} trop long (max ${widget.maxLength} caractères)';
      }

      // Email validation
      if (widget.isEmail) {
        return _validateEmail(value);
      }

      // Password validation
      if (widget.isPassword) {
        return _validatePassword(value);
      }

      // General security validation
      return _validateSecurity(value);
    }

    return null;
  }

  String? _validateEmail(String email) {
    final sanitizedEmail = email.trim().toLowerCase();
    
    if (sanitizedEmail.length > 254) {
      return 'Email trop long';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
    );
    
    if (!emailRegex.hasMatch(sanitizedEmail)) {
      return 'Format d\'email invalide';
    }

    // Check for common typos
    final domain = sanitizedEmail.split('@').last;
    if (domain.contains('gmial') || domain.contains('yahooo') || domain.contains('hotmial')) {
      return 'Vérifiez l\'orthographe de votre email';
    }
    
    return null;
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Minimum 8 caractères requis';
    }
    if (password.length > 128) {
      return 'Mot de passe trop long';
    }
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Au moins une lettre requise';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Au moins un chiffre requis';
    }
    
    // Check for common weak passwords
    final weakPasswords = [
      '12345678', 'password', 'motdepasse', 'azerty123', 'qwerty123'
    ];
    if (weakPasswords.contains(password.toLowerCase())) {
      return 'Mot de passe trop faible';
    }
    
    return null;
  }

  String? _validateSecurity(String input) {
    // Check for potentially harmful characters
    if (RegExp(r'[<>"\'/\\]').hasMatch(input)) {
      return 'Caractères non autorisés détectés';
    }

    // Check for potential injection patterns
    if (input.toLowerCase().contains('script') || 
        input.toLowerCase().contains('javascript') ||
        input.toLowerCase().contains('vbscript')) {
      return 'Contenu non autorisé';
    }

    return null;
  }

  Future<void> _validateAsync() async {
    if (_isValidating) return;

    setState(() {
      _isValidating = true;
    });

    // Simulate async validation (could be server-side email check, etc.)
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      final error = _validateInput(widget.controller.text);
      setState(() {
        _errorText = error;
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 20,
                color: const Color(0xFF2C5F66),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C5F66),
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Text field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscurePassword,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            enabled: widget.enabled,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              counterText: '', // Hide counter
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7DD3D8), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: _buildSuffixIcon(),
              errorText: _errorText,
              // FIXED: Add semantic label for accessibility
              semanticCounterText: widget.semanticLabel ?? widget.label,
            ),
            onChanged: (value) {
              widget.onChanged?.call(value);
              // Validate on change for better UX
              if (value.isNotEmpty) {
                _validateAsync();
              }
            },
            onFieldSubmitted: widget.onSubmitted,
            // FIXED: Add auto-validation
            validator: _validateInput,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey[400],
        ),
        onPressed: widget.enabled ? () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        } : null,
      );
    }
    
    if (_isValidating) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (_errorText == null && widget.controller.text.isNotEmpty && widget.isRequired) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 20,
      );
    }
    
    return null;
  }
}

// FIXED: Secure date picker field
class SecureDateField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isRequired;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime?)? onDateSelected;

  const SecureDateField({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isRequired = true,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
  }) : super(key: key);

  @override
  State<SecureDateField> createState() => _SecureDateFieldState();
}

class _SecureDateFieldState extends State<SecureDateField> {
  String? _validateDate(String? value) {
    if (widget.isRequired && (value == null || value.trim().isEmpty)) {
      return '${widget.label} est requis';
    }

    if (value != null && value.isNotEmpty) {
      // Validate DD/MM/YYYY format
      final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
      if (!dateRegex.hasMatch(value)) {
        return 'Format invalide (JJ/MM/AAAA)';
      }

      try {
        final parts = value.split('/');
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        if (day < 1 || day > 31) return 'Jour invalide';
        if (month < 1 || month > 12) return 'Mois invalide';

        final date = DateTime(year, month, day);
        
        // Check date bounds
        if (widget.firstDate != null && date.isBefore(widget.firstDate!)) {
          return 'Date trop ancienne';
        }
        if (widget.lastDate != null && date.isAfter(widget.lastDate!)) {
          return 'Date trop récente';
        }

        return null;
      } catch (e) {
        return 'Date invalide';
      }
    }

    return null;
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = widget.firstDate ?? DateTime(1900);
    final DateTime lastDate = widget.lastDate ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.isBefore(lastDate) ? now : lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2C5F66),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C5F66),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      widget.controller.text = formattedDate;
      widget.onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecureTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      icon: Icons.calendar_today,
      isRequired: widget.isRequired,
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
        LengthLimitingTextInputFormatter(10),
        _DateInputFormatter(),
      ],
      customValidator: _validateDate,
      onSubmitted: (_) => _selectDate(),
    );
  }
}

// FIXED: Date input formatter for better UX
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Auto-add slashes
    if (text.length == 2 && oldValue.text.length == 1) {
      return TextEditingValue(
        text: '$text/',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }
    if (text.length == 5 && oldValue.text.length == 4) {
      return TextEditingValue(
        text: '$text/',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }
    
    return newValue;
  }
}

// FIXED: Secure form validator utility
class FormValidatorUtils {
  static Map<String, String> validateForm(Map<String, String?> fields, Map<String, bool> required) {
    final errors = <String, String>{};
    
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final value = entry.value;
      final isRequired = required[fieldName] ?? false;
      
      if (isRequired && (value == null || value.trim().isEmpty)) {
        errors[fieldName] = 'Ce champ est requis';
      }
    }
    
    return errors;
  }
  
  static bool isFormValid(Map<String, String> errors) {
    return errors.isEmpty;
  }
  
  static void showFormErrors(BuildContext context, Map<String, String> errors) {
    if (errors.isNotEmpty) {
      final errorMessage = errors.values.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// FIXED: Loading button with security features
class SecureButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsets? padding;
  final double? width;

  const SecureButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF2C5F66);
    final effectiveForegroundColor = foregroundColor ?? Colors.white;
    
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        icon: isLoading 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
                ),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(
          isLoading ? 'Chargement...' : text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: effectiveForegroundColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveForegroundColor,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isEnabled ? 4 : 0,
        ),
      ),
    );
  }
}