import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../utils/functions/function_helper.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  // final _nameController = TextEditingController();
  // final _identificationNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _hidePassword = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_isLogin) {
          EasyLoading.show(status: 'Signing in, please wait...');
          await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          EasyLoading.dismiss();
          EasyLoading.showToast('Sign in successful');
        } else {
          try {
            EasyLoading.show(status: 'Creating account, please wait...');
            await _auth.createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
            EasyLoading.dismiss();
            if (kDebugMode) {
              print("Account created successfully");
            }
            EasyLoading.showToast(
              'Account created successfully',
              toastPosition: EasyLoadingToastPosition.bottom,
            );

            // String? userId = FirebaseAuth.instance.currentUser?.uid;
            //
            // if (userId != null) {
            //   try {
            //     await FirebaseFirestore.instance
            //         .collection('users')
            //         .doc(userId)
            //         .set({
            //           'displayName': _nameController.text.trim(),
            //           'identificationNumber':
            //               _identificationNumberController.text.trim(),
            //           'email': _emailController.text.trim(),
            //           'createdAt': FieldValue.serverTimestamp(),
            //         });
            //     if (kDebugMode) {
            //       print("User data saved to Firestore");
            //     }
            //
            //     try {
            //       await FirebaseAuth.instance.currentUser
            //           ?.sendEmailVerification();
            //       if (kDebugMode) {
            //         print("Verification email sent");
            //       }
            //     } catch (emailError) {
            //       if (kDebugMode) {
            //         print("Could not send verification email: $emailError");
            //       }
            //       // Continue even if email verification fails
            //     }
            //   } catch (firestoreError) {
            //     if (kDebugMode) {
            //       print("Firestore error: $firestoreError");
            //     }
            //     EasyLoading.showToast(
            //       'Account created but profile setup failed. Please update your profile later.',
            //       toastPosition: EasyLoadingToastPosition.bottom,
            //     );
            //   }
            // } else {
            //   if (kDebugMode) {
            //     print("User ID is null after account creation");
            //   }
            //   EasyLoading.showToast(
            //     'Account created but user ID could not be retrieved.',
            //     toastPosition: EasyLoadingToastPosition.bottom,
            //   );
            // }
          } catch (authError) {
            if (kDebugMode) {
              print("Auth error: $authError");
            }
            EasyLoading.showToast(
              'Account creation failed: $authError',
              toastPosition: EasyLoadingToastPosition.bottom,
            );
          }
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("General error: $e");
        }
        if (kDebugMode) {
          print("General error: $s");
        }
        EasyLoading.showToast(
          'Error: $e',
          toastPosition: EasyLoadingToastPosition.bottom,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // if (!_isLogin) ...[
              //   TextFormField(
              //     controller: _nameController,
              //     decoration: const InputDecoration(labelText: 'Name'),
              //     // validator: (value) {
              //     //   if (value == null || value.isEmpty) {
              //     //     return 'Please enter your name';
              //     //   }
              //     //   return null;
              //     // },
              //   ),
              //   TextFormField(
              //     controller: _identificationNumberController,
              //     decoration: const InputDecoration(
              //       labelText: 'Identification Number',
              //     ),
              //     // validator: (value) {
              //     //   if (value == null || value.isEmpty) {
              //     //     return 'Please enter your identification number';
              //     //   }
              //     //   return null;
              //     // },
              //   ),
              // ],
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!isValidEmail(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: _hidePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password should be at least 3 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.remove_red_eye
                          : CupertinoIcons.eye_slash_fill,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Create an account'
                      : 'Already have an account? Sign In',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
