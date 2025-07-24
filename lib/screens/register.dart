import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_alert/custom/customButton.dart';
import 'package:security_alert/screens/login.dart';

import '../custom/customTextfield.dart';
import '../provider/auth_provider.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String get username => _usernameController.text;
  String get firstname => _firstnameController.text;
  String get lastname => _lastnameController.text;
  String get password => _passwordController.text;
  String get confirmPassword => _confirmPasswordController.text;

  bool get hasMinLength => password.length >= 8;
  bool get hasNumberOrSymbol => RegExp(r'[0-9!@#\$&*~]').hasMatch(password);
  bool get notContainName => !password.toLowerCase().contains(username.toLowerCase());
  bool get notContainEmail => !password.toLowerCase().contains(username.toLowerCase());
  bool get isStrong => hasMinLength && hasNumberOrSymbol && notContainName && notContainEmail;

  @override
  void dispose() {
    
    _firstnameController.dispose();
    _lastnameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 7),
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
                      child: Text("Sign up to get started.", style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 25),

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

                    CustomTextField(
                      hintText: 'firstname',
                      controller: _firstnameController,
                      label: 'firstname'
                    ),
                    SizedBox(height: 10,),
                    CustomTextField(
                      hintText: 'lastname',
                      controller: _lastnameController,
                      label: 'lastname'
                    ),
                    CustomTextField(
                      hintText: 'Username',
                      controller: _usernameController,
                      label: 'Username'
                    ),
                    const SizedBox(height: 16),
                    // CustomTextField(
                    //   hintText: 'Example@gmail.com',
                    //   controller: _emailController,
                    //   label: 'Email',
                    //   validator: (val) =>
                    //   val == null || val.isEmpty ? 'Required' : null,
                    // ),
                    const SizedBox(height: 16),

                    const Text("Password"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      // onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '********',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Text(
                    //   "✔ Password Strength: ${isStrong ? "Strong" : "Weak"}",
                    //   style: TextStyle(color: isStrong ? Colors.green : Color(0xFF064FAD)),
                    // ),
                    // Text(
                    //   "✔ cannot contain your name or email address",
                    //   style: TextStyle(fontSize: 12, color: (notContainName && notContainEmail) ? Colors.black : Color(0xFF064FAD)),
                    // ),
                    // Text(
                    //   "✔ at least 8 characters",
                    //   style: TextStyle(fontSize: 12, color: hasMinLength ? Colors.black : Color(0xFF064FAD)),
                    // ),
                    // Text(
                    //   "✔ contain numbers or symbols",
                    //   style: TextStyle(fontSize: 12, color: hasNumberOrSymbol ? Colors.black : Color(0xFF064FAD)),
                    // ),

                    // const SizedBox(height: 16),
                    // const Text("Confirm Password"),
                    // const SizedBox(height: 8),
                    // TextField(
                    //   controller: _confirmPasswordController,
                    //   obscureText: _obscureConfirm,
                    //   onChanged: (val) => setState(() {}),
                    //   decoration: InputDecoration(
                    //     hintText: '********',
                    //     hintStyle: const TextStyle(color: Colors.grey),
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //       borderSide: const BorderSide(color: Colors.black),
                    //     ),
                    //     suffixIcon: IconButton(
                    //       icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    //       onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    //     ),
                    //   ),
                    // ),
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
                    CustomButton(text: 'Sign Up',  onPressed: 
                    authProvider.isLoading ? null : () async {
                      if ( firstname.isEmpty || lastname.isEmpty ||username.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please fill in all fields")),
                        );
                        return;
                      }
                      {
                        final success = await authProvider.register(firstname, lastname, username, password,);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Registered Successfully")),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        }
                      }
                    },isLoading: authProvider.isLoading,
                    width: 370,
                    height: 55,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    borderCircular: 6,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Color(0xFF064FAD),
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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





