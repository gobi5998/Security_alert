import 'package:flutter/material.dart';
import 'package:security_alert/screens/register.dart';

import '../reuse/customTextfield.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/image/login.png', // Make sure this image exists in assets folder
                height: 180,
              ),
              const SizedBox(height: 16),
              const Text(
                "Good to see you!",
                style: TextStyle(

                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF064FAD),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Let’s continue the journey.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              // TextField(
              //   decoration: InputDecoration(
              //     labelText: 'Username',
              //     border: OutlineInputBorder(),
              //   ),
              // ),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),


              CustomTextField(hintText: 'username',),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.grey, // light grey placeholder
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0), // rounded corners
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    // borderSide: BorderSide(
                    //   color: Color(0xFF064FAD), // optional: custom focus border color
                    // ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text("or", style: TextStyle(fontFamily: 'Nunito',color: Colors.grey)),
              const SizedBox(height: 12),
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
              const SizedBox(height: 32),
                ElevatedButton(

                  onPressed: () {Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF064FAD),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6), // Customize corner radius

                    ),
                  ),
                  child: const Text("Log In",style: TextStyle(fontFamily: 'Nunito',color: Colors.white),),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Don’t have an account? ",
                  style: TextStyle(fontFamily: 'Nunito',),),
                  Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Color(0xFF064FAD),
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
