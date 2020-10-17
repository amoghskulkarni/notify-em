import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:notify_em/notification_wall.dart';
import 'package:notify_em/signin.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore firestore = FirebaseFirestore.instance;

class HomePage extends StatefulWidget {
  /// The page title.
  final String title = 'Notify \'Em';

  // The user object that gets passed to this widget
  final User user;
  HomePage({Key key, @required this.user}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getContent(
    int index,
    User u,
  ) {
    switch (index) {
      case 0:
        return NotificationWallPage(user: u);
      case 1:
        return Text('Analytics (Coming soon)');
      case 2:
        return Text('Profile page');
      default:
        return Text('Error!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Builder(builder: (BuildContext context) {
            return FlatButton(
              child: const Text('Sign out'),
              textColor: Theme.of(context).buttonColor,
              onPressed: () {
                _signOut();

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return SignInPage();
                    },
                  ),
                );
              },
            );
          })
        ],
      ),
      body: Builder(builder: (BuildContext context) {
        return Center(
          child: _getContent(_selectedIndex, widget.user),
        );
      }),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  // Example code for sign out.
  void _signOut() async {
    await _auth.signOut();
  }
}
