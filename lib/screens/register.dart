import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_alert/screens/login.dart';

import '../provider/auth_provider.dart';
import '../reuse/customTextfield.dart';

void main() {
  runApp(const MaterialApp(home: RegisterPage()));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String username = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  bool get hasMinLength => password.length >= 8;
  bool get hasNumberOrSymbol => RegExp(r'[0-9!@#\$&*~]').hasMatch(password);
  bool get notContainName => !password.toLowerCase().contains(username.toLowerCase());
  bool get notContainEmail => !password.toLowerCase().contains(email.toLowerCase());
  bool get isStrong => hasMinLength && hasNumberOrSymbol && notContainName && notContainEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_back),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "Welcome!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF064FAD),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    "Sign up to get started.",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 32),

                // Username
                const Text("Username"),
                const SizedBox(height: 8),


                CustomTextField(hintText: 'Username',),
                const SizedBox(height: 16),

                // Email
                const Text("Email"),
                const SizedBox(height: 8),
                CustomTextField(hintText: 'Example@gmail.com'),
                const SizedBox(height: 16),

                // Password
                const Text("Password"),
                const SizedBox(height: 8),
                TextField(
                  obscureText: _obscurePassword,
                  onChanged: (val) => setState(() => password = val),
                  decoration: InputDecoration(
                    hintText: '********',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black)
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Password rules
                Text(
                  "✔ Password Strength: ${isStrong ? "Strong" : "Weak"}",
                  style: TextStyle(color: isStrong ? Colors.green : Color(0xFF064FAD)),
                ),
                Text(
                  "✔ cannot contain your name or email address",
                  style: TextStyle(
                    fontSize: 12,
                    color: (notContainName && notContainEmail) ? Colors.black : Color(0xFF064FAD),
                  ),
                ),
                Text(
                  "✔ at least 8 characters",
                  style: TextStyle(
                    fontSize: 12,
                    color: hasMinLength ? Colors.black : Color(0xFF064FAD),
                  ),
                ),
                Text(
                  "✔ contain numbers or symbols",
                  style: TextStyle(
                    fontSize: 12,
                    color: hasNumberOrSymbol ? Colors.black : Color(0xFF064FAD),
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm Password
                const Text("Confirm Password"),
                const SizedBox(height: 8),
                TextField(
                  obscureText: _obscureConfirm,
                  onChanged: (val) => setState(() => confirmPassword = val),
                  decoration: InputDecoration(
                    hintText: '********',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color when focused
                        width: 2.0,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                const Center(child: Text("or")),
                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: Image.asset('assets/image/google.png', height: 50),
                    ),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: Image.asset('assets/image/facebook.jpg', height: 50),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () {
                    if (!isStrong) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password is not strong")),
                      );
                    } else if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords do not match")),
                      );
                    } else {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      auth.register(username, email, password);

                      if (auth.isRegistered) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Registered Successfully")),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      }
                    }
                  },


                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064FAD),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Sign Up", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  [
                    Text("Already have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      }, child: Text("Login",
                      style: TextStyle(
                        color: Color(0xFF064FAD),
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,),
                    ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}





