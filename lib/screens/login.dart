import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_alert/screens/register.dart';

import '../provider/auth_provider.dart';
import '../reuse/customTextfield.dart';

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
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
                const Text("Let’s continue the journey.", style: TextStyle(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Username', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                CustomTextField(hintText: 'username', controller: _usernameController),
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
                const SizedBox(height: 24),
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
                ElevatedButton(
                  onPressed: () {
                    final username = _usernameController.text.trim();
                    final password = _passwordController.text.trim();
                    authProvider.login(username, password);
                    // Navigate to home if login succeeds
                    if (authProvider.isLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Login Successful")),
                      );
                      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064FAD),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text("Log In", style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an account?", style: TextStyle(fontFamily: 'Nunito')),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                      child: const Text("SignUp", style: TextStyle(color: Color(0xFF064FAD), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
