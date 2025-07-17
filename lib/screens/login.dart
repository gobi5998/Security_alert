import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_alert/screens/register.dart';
import '../custom/customButton.dart';
import '../custom/customTextfield.dart';
import '../provider/auth_provider.dart';
import 'dashboard_page.dart';
import 'reset_password_request.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Image.asset('assets/image/login.png', height: 180),
                    const SizedBox(height: 16),
                    const Text(
                      "Good to see you!",
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Color(0xFF064FAD)),
                    ),
                    const SizedBox(height: 8),
                    const Text("Let's continue the journey.", style: TextStyle(fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 32),

                    if (authProvider.errorMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red.shade600, size: 20),
                              onPressed: () => authProvider.clearError(),
                            ),
                          ],
                        ),
                      ),

                    CustomTextField(hintText: 'username', controller: _usernameController, label: 'Username', ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Password', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(fontFamily: 'Nunito', color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResetPasswordRequestScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF064FAD),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text("or", style: TextStyle(fontFamily: 'Nunito', color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(backgroundColor: Colors.white, radius: 20, child: Image.asset('assets/image/google.png', height: 50)),
                        const SizedBox(width: 16),
                        CircleAvatar(backgroundColor: Colors.white, radius: 20, child: Image.asset('assets/image/facebook.jpg', height: 50)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Login',
                      onPressed: authProvider.isLoading ? null : () async {
                        final username = _usernameController.text.trim();
                        final password = _passwordController.text.trim();

                        if (username.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill in all fields")),
                          );
                          return;
                        }

                        final success = await authProvider.login(username, password);
                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const DashboardPage()),
                          );
                        } else {
                          // Error message is handled by authProvider and shown in the UI
                        }
                      },
                      isLoading: authProvider.isLoading,
                      borderCircular: 6,
                      width: 350,
                      height: 55,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),


                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?", style: TextStyle(fontFamily: 'Nunito')),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                          child: const Text("SignUp", style: TextStyle(color: Color(0xFF064FAD), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}


