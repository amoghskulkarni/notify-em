import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:notify_em/signin.dart';
import 'package:notify_em/home.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
User user;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  _auth.authStateChanges().listen((User _user) {
    if (_user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
    user = _user;
  });
  runApp(App());
}

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotifyEm',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FirebaseLoader(),
    );
  }
}

class FirebaseLoader extends StatelessWidget {
  // Create the initialization Future outside of `build`:
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return LandingPage();
        }

        return Container(
          color: Colors.blue,
          child: Center(
            child: CircularProgressIndicator(
              value: null,
            ),
          ),
        );
      },
    );
  }
}

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (user != null) {
      return HomePage(
        user: user,
      );
    }
    return SignInPage();
  }
}
