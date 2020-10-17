import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class NotificationWallPage extends StatefulWidget {
  // The user object that gets passed to this widget
  final User user;
  NotificationWallPage({Key key, @required this.user}) : super(key: key);

  @override
  _NotificationWallPageState createState() => _NotificationWallPageState();
}

class _NotificationWallPageState extends State<NotificationWallPage> {
  @override
  Widget build(BuildContext context) {
    return NotificationCards(user: widget.user);
  }
}

class NotificationCards extends StatelessWidget {
  // The user object that gets passed to this widget
  final User user;
  NotificationCards({Key key, @required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      final String _uid = user.uid;
      DocumentReference userDoc = firestore.collection('data').doc(_uid);

      return StreamBuilder<DocumentSnapshot>(
        stream: userDoc.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }

          final Map<String, dynamic> docdata = snapshot.data.data();
          final notifications = docdata['notifications'];

          return new ListView(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: _generateCards(notifications),
          );
        },
      );
    } else {
      return Container();
    }
  }

  List<Widget> _generateCards(listIn) {
    List<Widget> listOut = [];

    listIn.forEach((element) {
      final num investment = element['investment'];
      final num roi = element['return'];
      final num nav = element['NAV'];
      final String folio = element['folio'];
      final Timestamp timestamp = element['date'];

      final DateTime date =
          DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);

      listOut.add(
        Padding(
          padding: EdgeInsets.all(15.0),
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: Text(
                    element['scheme'],
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('Folio: $folio'),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                  child: Divider(),
                ),
                ListTile(
                  title: Text('Investment'),
                  subtitle: Text(investment.toString()),
                ),
                ListTile(
                  title: Text('Return on Investment (RoI)'),
                  subtitle: Text(
                    roi.toString() + ' %',
                    // style: TextStyle(
                    //   color: (roi < 0.0) ? Colors.red : Colors.green,
                    // ),
                  ),
                ),
                ListTile(
                  title: Text('NAV'),
                  subtitle: Text(nav.toString()),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                  child: Divider(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(date.day.toString() +
                          ' / ' +
                          date.month.toString() +
                          ' / ' +
                          date.year.toString())
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });

    return listOut;
  }
}
