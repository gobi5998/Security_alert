import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordUpdateScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onUpdate;
  const ResetPasswordUpdateScreen({Key? key, required this.token, this.onUpdate}) : super(key: key);

  @override
  State<ResetPasswordUpdateScreen> createState() => _ResetPasswordUpdateScreenState();
}

class _ResetPasswordUpdateScreenState extends State<ResetPasswordUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _passwordStrength = '';
  Color _strengthColor = Colors.red;
  final ApiService _apiService = ApiService();
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    if (password.length >= 8 &&
        RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(password) &&
        !RegExp(r'password|1234|qwerty', caseSensitive: false).hasMatch(password)) {
      setState(() {
        _passwordStrength = 'Strong';
        _strengthColor = Colors.green;
      });
    } else {
      setState(() {
        _passwordStrength = 'Weak';
        _strengthColor = Colors.red;
      });
    }
  }

  bool _isPasswordValid(String password) {
    return password.length >= 8 &&
        RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16),
              // Illustration
              Image.asset(
                'assets/image/security2.png',
                height: 180,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 24),
              Text(
                'RESET PASSWORD',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Color(0xFF185ABC),
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password', style: TextStyle(fontSize: 15)),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: _checkPasswordStrength,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (!_isPasswordValid(value)) {
                          return 'Password must be at least 8 characters and contain a number or symbol';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Text('Re-Type Password', style: TextStyle(fontSize: 15)),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please re-type password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Password Strength: ', style: TextStyle(fontSize: 13)),
                  Text(_passwordStrength, style: TextStyle(fontSize: 13, color: _strengthColor)),
                ],
              ),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PasswordRequirement(
                    met: _passwordController.text.length >= 8,
                    text: 'At least 8 characters',
                  ),
                  _PasswordRequirement(
                    met: RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text),
                    text: 'Contain numbers or symbols',
                  ),
                  _PasswordRequirement(
                    met: !_passwordController.text.contains('name') && !_passwordController.text.contains('email'),
                    text: 'Cannot contain your name or email address',
                  ),
                ],
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF185ABC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = '';
                            });
                            
                            try {
                              final newPassword = _passwordController.text;
                              // final response = await _apiService.resetPassword(widget.token, newPassword);
                              
                              setState(() => _isLoading = false);
                              
                              // if (mounted) {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     SnackBar(
                              //       content: Text(response['message'] ?? 'Password reset successfully!'),
                              //       backgroundColor: Colors.green,
                              //     ),
                              //   );
                              //
                              //   if (widget.onUpdate != null) {
                              //     widget.onUpdate!();
                              //   }
                              // }
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                                _errorMessage = e.toString();
                              });
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_errorMessage),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Update', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  final bool met;
  final String text;
  const _PasswordRequirement({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check, size: 16, color: met ? Colors.green : Colors.grey),
        SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: met ? Colors.green : Colors.grey)),
      ],
    );
  }
} 