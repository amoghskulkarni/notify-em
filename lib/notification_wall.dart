import 'package:flutter/foundation.dart';
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
  List<Timestamp> dateDropdownValues = [null];
  Timestamp selectedDate;

  @override
  Widget build(BuildContext context) {
    // return NotificationCards(user: widget.user);
    if (widget.user != null) {
      final String _uid = widget.user.uid;
      DocumentReference userDoc = firestore.collection('data').doc(_uid);

      return StreamBuilder<DocumentSnapshot>(
        stream: userDoc.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong!');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(
              value: null,
            );
          }

          if (snapshot.hasData) {
            final Map<String, dynamic> docdata = snapshot.data.data();
            final List<dynamic> notifications = docdata['notifications'];
            List<dynamic> filteredNotifications;

            for (var n in notifications) {
              final Timestamp t = n['date'];

              // Push the date if the array doesn't contain it
              if (!dateDropdownValues.contains(t)) {
                dateDropdownValues.add(t);
              }
            }

            // Filter notifications according to what is selected
            // in the dropdowns
            filteredNotifications = notifications.where((el) {
              if (selectedDate == null) {
                return true;
              }
              final Timestamp t = el['date'];
              if ((selectedDate != null) && (selectedDate.compareTo(t) == 0)) {
                return true;
              }
              return false;
            }).toList();

            return new Column(children: [
              _getDateDropdown(),
              SizedBox(
                height: 10.0,
              ),
              Expanded(
                child: NotificationCards(notifications: filteredNotifications),
              ),
            ]);
          }

          // Show the spinner by default
          return CircularProgressIndicator(
            value: null,
          );
        },
      );
    } else {
      return Container(
        child: CircularProgressIndicator(
          value: null,
        ),
      );
    }
  }

  Widget _getDateDropdown() {
    return DropdownButton<Timestamp>(
      value: selectedDate,
      icon: Icon(Icons.arrow_downward),
      iconSize: 16,
      elevation: 8,
      style: TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.blue[200],
      ),
      onChanged: (Timestamp newValue) {
        setState(() {
          selectedDate = newValue;
        });
      },
      items: dateDropdownValues.map<DropdownMenuItem<Timestamp>>((Timestamp t) {
        String description = "";
        if (t == null) {
          description += "All";
        } else {
          final DateTime d =
              DateTime.fromMillisecondsSinceEpoch(t.millisecondsSinceEpoch);

          description += d.month.toString();
          description += '/';
          description += d.year.toString();
        }
        return DropdownMenuItem<Timestamp>(
          value: t,
          child: Text(description),
        );
      }).toList(),
    );
  }
}

class NotificationCards extends StatelessWidget {
  // The user object that gets passed to this widget
  final List<dynamic> notifications;
  NotificationCards({Key key, @required this.notifications}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      children: _generateCards(notifications),
    );
  }

  Color _getCardColorByInvestment(num gain) {
    if (gain < 0.0) {
      return Colors.red;
    }
    return Colors.green;
  }

  String _getRupeesString(num rs) {
    String rsString = rs.toString();
    Characters retString = new Characters('');

    Characters rsChars = rsString.characters;
    bool commaAt3 = false;
    var j = 1;
    for (var i = rsChars.length - 1; i >= 0; i--) {
      retString += rsChars.characterAt(i);
      if (!commaAt3) {
        if (j == 3) {
          retString += new Characters(',');
          commaAt3 = true;
        }
      } else {
        if ((j - 3).isEven && (i > 0)) {
          retString += new Characters(',');
        }
      }

      j += 1;
    }

    return retString.toString().split('').reversed.join();
  }

  List<Widget> _generateCards(listIn) {
    List<Widget> listOut = [];

    listIn.forEach((element) {
      final num investment = element['investment'];
      final num roi = element['return'];
      final num nav = element['NAV'];
      final String folio = element['folio'];
      final String option = element['option'];
      final Timestamp timestamp = element['date'];

      final DateTime date =
          DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);

      listOut.add(
        Padding(
          padding: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 5.0,
                ),
                SizedBox(
                  height: 10.0,
                  child: Container(
                    color: _getCardColorByInvestment(roi),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Text(
                        element['scheme'],
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 10.0,
                        ),
                        Text('Folio: '),
                        Text(
                          folio,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 10.0,
                        ),
                        Text('Option: '),
                        Text(
                          option,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 10.0,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                  child: Card(
                    elevation: 0.0,
                    color: Colors.lightBlue[50].withAlpha(80),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Investment'),
                                SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  String.fromCharCode(8377) +
                                      ' ' +
                                      _getRupeesString(investment),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 30,
                          child: VerticalDivider(
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Returns'),
                                SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  roi.toString() + ' %',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 30,
                          child: VerticalDivider(
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('NAV'),
                                SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  String.fromCharCode(8377) +
                                      ' ' +
                                      _getRupeesString(nav),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('As of: '),
                      Text(
                        date.day.toString() +
                            ' / ' +
                            date.month.toString() +
                            ' / ' +
                            date.year.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
