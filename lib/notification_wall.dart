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
  bool dateSelectedManually = false;
  List<Timestamp> dateDropdownValues = [];
  Timestamp selectedDate;

  List<String> folioDropdownValues = [null];
  String selectedFolio;

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
              final String scheme = n['scheme'];

              // Push the date if the array doesn't contain it
              if (!dateDropdownValues.contains(t)) {
                dateDropdownValues.add(t);
              }

              if (!folioDropdownValues.contains(scheme)) {
                folioDropdownValues.add(scheme);
              }
            }

            if (dateDropdownValues.isNotEmpty && !dateSelectedManually) {
              selectedDate = dateDropdownValues.last;
            }

            // Filter notifications according to what is selected
            // in the date dropdown
            filteredNotifications = notifications.where((el) {
              final Timestamp t = el['date'];
              if (selectedDate.compareTo(t) == 0) {
                return true;
              }
              return false;
            }).toList();

            filteredNotifications = filteredNotifications.where((el) {
              if (selectedFolio == null) {
                return true;
              }
              final String _scheme = el['scheme'];
              if ((selectedFolio != null) &&
                  (selectedFolio.compareTo(_scheme) == 0)) {
                return true;
              }
              return false;
            }).toList();

            return new Column(children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('As of: '),
                            _getDateDropdown(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Folio: '),
                            _getFolioDropdown(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      icon: Icon(
        Icons.arrow_downward,
        color: Colors.blue,
      ),
      iconSize: 16,
      elevation: 8,
      style: TextStyle(color: Colors.blue),
      underline: Container(
        height: 2,
        color: Colors.blue[50],
      ),
      onChanged: (Timestamp newValue) {
        setState(() {
          selectedDate = newValue;
          dateSelectedManually = true;
        });
      },
      items: dateDropdownValues.map<DropdownMenuItem<Timestamp>>((Timestamp t) {
        String description = "";
        if (t == null) {
          description += "All";
        } else {
          final DateTime d =
              DateTime.fromMillisecondsSinceEpoch(t.millisecondsSinceEpoch);

          description += (d.month.toString() + ' / ' + d.year.toString() + ' ');
        }
        return DropdownMenuItem<Timestamp>(
          value: t,
          child: Text(description),
        );
      }).toList(),
    );
  }

  Widget _getFolioDropdown() {
    return DropdownButton<String>(
      value: selectedFolio,
      icon: Icon(
        Icons.arrow_downward,
        color: Colors.blue,
      ),
      iconSize: 16,
      elevation: 8,
      style: TextStyle(color: Colors.blue),
      underline: Container(
        height: 2,
        color: Colors.blue[50],
      ),
      onChanged: (String newValue) {
        setState(() {
          selectedFolio = newValue;
        });
      },
      items: folioDropdownValues.map<DropdownMenuItem<String>>((String s) {
        String description = "";
        if (s == null) {
          description += "All";
        } else {
          description += s;
        }
        return DropdownMenuItem<String>(
          value: s,
          child: SizedBox(
            child: Text(
              description,
              overflow: TextOverflow.ellipsis,
            ),
            width: 100.0,
          ),
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
