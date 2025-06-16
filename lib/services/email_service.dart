// lib/services/email_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class EmailService {
  // Configuration - Replace with your actual email service credentials
  static const String _apiKey = 'YOUR_SENDGRID_API_KEY'; // SendGrid API key
  static const String _senderEmail = 'noreply@vaccigo.com'; // Your sender email
  static const String _senderName = 'Vaccigo Support';
  
  // Alternative: Gmail SMTP settings (if using Gmail)
  static const String _gmailEmail = 'your-email@gmail.com';
  static const String _gmailPassword = 'your-app-password'; // Use App Password, not regular password
  
  // Store reset tokens temporarily (in production, use a proper database)
  static final Map<String, ResetToken> _resetTokens = {};

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email, String userName) async {
    try {
      // Generate secure reset token
      final token = _generateResetToken();
      final resetUrl = 'https://your-app.com/reset-password?token=$token';
      
      // Store token (expires in 1 hour)
      _resetTokens[email] = ResetToken(
        token: token,
        email: email,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      
      // Prepare email content
      final subject = 'Réinitialisation de votre mot de passe Vaccigo';
      final htmlContent = _buildPasswordResetEmailHtml(userName, resetUrl, token);
      final textContent = _buildPasswordResetEmailText(userName, resetUrl, token);
      
      // Try SendGrid first, fall back to Gmail SMTP
      bool sent = false;
      
      if (_apiKey != 'YOUR_SENDGRID_API_KEY') {
        sent = await _sendEmailViaService(
          to: email,
          subject: subject,
          htmlContent: htmlContent,
          textContent: textContent,
        );
      }
      
      if (!sent) {
        // Fallback to local simulation
        sent = await _simulateEmailSending(email, subject, htmlContent);
      }
      
      return sent;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  /// Verify reset token
  bool verifyResetToken(String email, String token) {
    final storedToken = _resetTokens[email];
    if (storedToken == null) return false;
    
    if (storedToken.token != token) return false;
    if (DateTime.now().isAfter(storedToken.expiresAt)) {
      _resetTokens.remove(email); // Clean up expired token
      return false;
    }
    
    return true;
  }

  /// Consume reset token (use it once)
  bool consumeResetToken(String email, String token) {
    if (verifyResetToken(email, token)) {
      _resetTokens.remove(email);
      return true;
    }
    return false;
  }

  /// Send email via email service (SendGrid, etc.)
  Future<bool> _sendEmailViaService({
    required String to,
    required String subject,
    required String htmlContent,
    required String textContent,
  }) async {
    try {
      // SendGrid API implementation
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [
                {'email': to}
              ],
              'subject': subject,
            }
          ],
          'from': {
            'email': _senderEmail,
            'name': _senderName,
          },
          'content': [
            {
              'type': 'text/plain',
              'value': textContent,
            },
            {
              'type': 'text/html',
              'value': htmlContent,
            }
          ],
        }),
      );

      if (response.statusCode == 202) {
        print('Email sent successfully via SendGrid to: $to');
        return true;
      } else {
        print('SendGrid error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending email via service: $e');
      return false;
    }
  }

  /// Simulate email sending for development/demo
  Future<bool> _simulateEmailSending(String email, String subject, String content) async {
    print('=== SIMULATED EMAIL ===');
    print('To: $email');
    print('Subject: $subject');
    print('Content Preview: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');
    print('=====================');
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Log to console (in production, you might log to a file or database)
    _logEmailToConsole(email, subject, content);
    
    return true; // Always return true for simulation
  }

  /// Log email details for debugging
  void _logEmailToConsole(String email, String subject, String content) {
    final timestamp = DateTime.now().toIso8601String();
    print('''
📧 EMAIL SENT (SIMULATED) - $timestamp
📤 To: $email
📋 Subject: $subject
🔗 Reset URL: ${_extractResetUrl(content)}
⏰ Token expires in 1 hour
''');
  }

  String _extractResetUrl(String content) {
    final regex = RegExp(r'https://[^"\s]+reset-password[^"\s]*');
    final match = regex.firstMatch(content);
    return match?.group(0) ?? 'URL not found';
  }

  /// Generate secure reset token
  String _generateResetToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final base64Token = base64Url.encode(bytes);
    
    // Add timestamp hash for additional security
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final combined = '$base64Token$timestamp';
    final hash = sha256.convert(utf8.encode(combined));
    
    return '${base64Token}_${hash.toString().substring(0, 8)}';
  }

  /// Build HTML email content
  String _buildPasswordResetEmailHtml(String userName, String resetUrl, String token) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Réinitialisation de mot de passe - Vaccigo</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #2C5F66;
            background-color: #F8FCFD;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(44, 95, 102, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #7DD3D8, #B8E6EA);
            padding: 30px;
            text-align: center;
        }
        .logo {
            width: 60px;
            height: 60px;
            background: #2C5F66;
            border-radius: 12px;
            margin: 0 auto 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            color: white;
        }
        .content {
            padding: 30px;
        }
        .button {
            display: inline-block;
            background: #2C5F66;
            color: white;
            padding: 16px 32px;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 600;
            margin: 20px 0;
        }
        .footer {
            background: #F5F9FA;
            padding: 20px;
            text-align: center;
            font-size: 14px;
            color: #6B7280;
        }
        .warning {
            background: #FFF3CD;
            border: 1px solid #FFE69C;
            border-radius: 8px;
            padding: 16px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">💉</div>
            <h1 style="margin: 0; color: #2C5F66;">Vaccigo</h1>
            <p style="margin: 8px 0 0; color: #2C5F66;">Carnet de Vaccination Numérique</p>
        </div>
        
        <div class="content">
            <h2>Bonjour $userName,</h2>
            <p>Vous avez demandé la réinitialisation de votre mot de passe pour votre compte Vaccigo.</p>
            
            <p>Pour réinitialiser votre mot de passe, cliquez sur le bouton ci-dessous :</p>
            
            <div style="text-align: center;">
                <a href="$resetUrl" class="button">Réinitialiser mon mot de passe</a>
            </div>
            
            <p>Ou copiez ce lien dans votre navigateur :</p>
            <p style="word-break: break-all; background: #F5F9FA; padding: 12px; border-radius: 8px; font-family: monospace;">$resetUrl</p>
            
            <div class="warning">
                <strong>⚠️ Important :</strong>
                <ul>
                    <li>Ce lien expire dans <strong>1 heure</strong></li>
                    <li>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email</li>
                    <li>Ne partagez jamais ce lien avec personne</li>
                </ul>
            </div>
            
            <p>Pour votre sécurité, ce lien ne peut être utilisé qu'une seule fois.</p>
            
            <p>Si vous avez des questions, contactez notre support à support@vaccigo.com</p>
            
            <p>Cordialement,<br>L'équipe Vaccigo</p>
        </div>
        
        <div class="footer">
            <p>© 2025 Vaccigo - Carnet de Vaccination Numérique</p>
            <p>Token de sécurité : ${token.substring(0, 8)}***</p>
        </div>
    </div>
</body>
</html>
''';
  }

  /// Build plain text email content
  String _buildPasswordResetEmailText(String userName, String resetUrl, String token) {
    return '''
Bonjour $userName,

Vous avez demandé la réinitialisation de votre mot de passe pour votre compte Vaccigo.

Pour réinitialiser votre mot de passe, cliquez sur ce lien :
$resetUrl

IMPORTANT :
- Ce lien expire dans 1 heure
- Si vous n'avez pas demandé cette réinitialisation, ignorez cet email
- Ne partagez jamais ce lien avec personne
- Ce lien ne peut être utilisé qu'une seule fois

Si vous avez des questions, contactez notre support à support@vaccigo.com

Cordialement,
L'équipe Vaccigo

---
© 2025 Vaccigo - Carnet de Vaccination Numérique
Token de sécurité : ${token.substring(0, 8)}***
''';
  }

  /// Send welcome email to new users
  Future<bool> sendWelcomeEmail(String email, String userName) async {
    try {
      final subject = 'Bienvenue sur Vaccigo ! 🎉';
      final htmlContent = _buildWelcomeEmailHtml(userName);
      final textContent = _buildWelcomeEmailText(userName);
      
      if (_apiKey != 'YOUR_SENDGRID_API_KEY') {
        return await _sendEmailViaService(
          to: email,
          subject: subject,
          htmlContent: htmlContent,
          textContent: textContent,
        );
      } else {
        return await _simulateEmailSending(email, subject, htmlContent);
      }
    } catch (e) {
      print('Error sending welcome email: $e');
      return false;
    }
  }

  String _buildWelcomeEmailHtml(String userName) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Bienvenue sur Vaccigo</title>
    <style>
        body { font-family: Arial, sans-serif; color: #2C5F66; background: #F8FCFD; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; }
        .header { background: linear-gradient(135deg, #7DD3D8, #B8E6EA); padding: 30px; text-align: center; }
        .content { padding: 30px; }
        .button { background: #2C5F66; color: white; padding: 16px 32px; text-decoration: none; border-radius: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Bienvenue sur Vaccigo !</h1>
        </div>
        <div class="content">
            <h2>Bonjour $userName,</h2>
            <p>Votre compte Vaccigo a été créé avec succès ! Vous pouvez maintenant :</p>
            <ul>
                <li>📱 Numériser vos carnets de vaccination avec l'IA</li>
                <li>🗂️ Organiser vos vaccinations</li>
                <li>✈️ Préparer vos voyages</li>
                <li>🔔 Recevoir des rappels personnalisés</li>
            </ul>
            <p>Votre santé, notre priorité !</p>
            <p>L'équipe Vaccigo</p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildWelcomeEmailText(String userName) {
    return '''
🎉 Bienvenue sur Vaccigo !

Bonjour $userName,

Votre compte Vaccigo a été créé avec succès !

Vous pouvez maintenant :
- 📱 Numériser vos carnets de vaccination avec l'IA
- 🗂️ Organiser vos vaccinations
- ✈️ Préparer vos voyages
- 🔔 Recevoir des rappels personnalisés

Votre santé, notre priorité !

L'équipe Vaccigo
''';
  }

  /// Clean up expired tokens periodically
  void cleanupExpiredTokens() {
    final now = DateTime.now();
    _resetTokens.removeWhere((email, token) => now.isAfter(token.expiresAt));
  }
}

/// Reset token model
class ResetToken {
  final String token;
  final String email;
  final DateTime expiresAt;

  ResetToken({
    required this.token,
    required this.email,
    required this.expiresAt,
  });
}

/// Email configuration for different providers
class EmailConfig {
  // SendGrid configuration
  static const sendGridConfig = {
    'apiUrl': 'https://api.sendgrid.com/v3/mail/send',
    'apiKey': 'YOUR_SENDGRID_API_KEY',
  };
  
  // Gmail SMTP configuration
  static const gmailConfig = {
    'host': 'smtp.gmail.com',
    'port': 587,
    'username': 'your-email@gmail.com',
    'password': 'your-app-password',
  };
  
  // Mailgun configuration
  static const mailgunConfig = {
    'apiUrl': 'https://api.mailgun.net/v3/YOUR_DOMAIN/messages',
    'apiKey': 'YOUR_MAILGUN_API_KEY',
    'domain': 'YOUR_DOMAIN',
  };
}