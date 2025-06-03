import 'dart:developer'; // For log() function
import 'dart:io'; // Keep this import for the InternetAddress.lookup if you want it for mobile, but it's okay if unused on web.

import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:flutter/material.dart'; // Material Design widgets
import 'package:google_sign_in/google_sign_in.dart'; // Google Sign-In package
import 'package:flutter/foundation.dart'; // Import kIsWeb for platform detection

import '../../api/apis.dart'; // Your API services file
import '../../helper/dialogs.dart'; // Your dialogs helper file
import '../../main.dart'; // Main app file for global 'mq' (media query) access
import '../home_screen.dart'; // Your home screen widget

// Login screen -- implements google sign in or sign up feature for app
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;

  @override
  void initState() {
    super.initState();

    // for auto triggering animation
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _isAnimate = true);
    });
  }

  // Handles Google login button click
  _handleGoogleBtnClick() {
    // for showing progress bar
    Dialogs.showLoading(context);

    _signInWithGoogle().then((userCredential) async {
      // for hiding progress bar
      if (mounted) { // Check mounted before pop
        Navigator.pop(context);
      }

      if (userCredential != null) {
        // User is successfully authenticated with Firebase
        log('\nUser: ${userCredential.user?.displayName}');
        log('\nUser Email: ${userCredential.user?.email}');
        log('\nUserAdditionalInfo: ${userCredential.additionalUserInfo}');

        // Check if user exists in your custom 'APIs' system
        if (await APIs.userExists() && mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          // Create user if they don't exist in your custom 'APIs' system
          await APIs.createUser().then((value) {
            if (mounted) { // Check mounted again before navigation
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            }
          });
        }
      } else {
        // userCredential is null, meaning sign-in failed or was cancelled
        log('Google Sign-In failed or was cancelled.');
        if (mounted) {
          // Show a snackbar if sign-in was cancelled
          Dialogs.showSnackbar(context, 'Google Sign-In cancelled.');
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      // The InternetAddress.lookup is specific to dart:io and not supported on web.
      // We will only run it if not on the web.
      if (!kIsWeb) {
        await InternetAddress.lookup('google.com'); // This check is for mobile only
      }

      // Trigger the authentication flow for Google Sign-In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user cancelled the sign-in process (e.g., closed the popup)
        return null;
      }

      // Obtain the authentication details from the Google user
      final GoogleSignInAuthentication? googleAuth =
          await googleUser.authentication;

      // Create a new Firebase credential using Google's access and ID tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await APIs.auth.signInWithCredential(credential);

    } on FirebaseAuthException catch (e) {
      // Catch specific errors from Firebase Authentication
      log('\nFirebase Auth Error during Google sign-in: ${e.code} - ${e.message}');
      if (mounted) {
        // Display a more informative error message to the user
        Dialogs.showSnackbar(context, 'Login Failed: ${e.message}');
      }
      return null;
    } catch (e) {
      // Catch any other general errors that might occur
      log('\nGeneral Error during _signInWithGoogle: $e');

      if (mounted) {
        // Display a general error message to the user
        Dialogs.showSnackbar(context, 'Something went wrong. Please try again.');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initializing media query (for getting device screen size)
    // This assumes 'mq' is defined globally in main.dart and available.
    mq = MediaQuery.sizeOf(context);

    return Scaffold(
      // App bar
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button on login screen
        title: const Text('Welcome to We Chat'),
      ),

      // Body of the screen
      body: Stack(children: [
        // App logo animation
        AnimatedPositioned(
            top: mq.height * .15,
            right: _isAnimate ? mq.width * .25 : -mq.width * .5,
            width: mq.width * .5,
            duration: const Duration(seconds: 1),
            // Make sure 'assets/images/icon.png' exists and is declared in pubspec.yaml
            child: Image.asset('assets/images/icon.png')),

        // Google login button
        Positioned(
            bottom: mq.height * .15,
            left: mq.width * .05,
            width: mq.width * .9,
            height: mq.height * .06,
            child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 223, 255, 187),
                    shape: const StadiumBorder(),
                    elevation: 1),

                // On tap, trigger the Google login handler
                onPressed: _handleGoogleBtnClick,

                // Google icon
                // Make sure 'assets/images/google.png' exists and is declared in pubspec.yaml
                icon: Image.asset('assets/images/google.png',
                    height: mq.height * .03),

                // Login with Google label
                label: RichText(
                  text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      children: [
                        TextSpan(text: 'Login with '),
                        TextSpan(
                            text: 'Google',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ]),
                ))),
      ]),
    );
  }
}