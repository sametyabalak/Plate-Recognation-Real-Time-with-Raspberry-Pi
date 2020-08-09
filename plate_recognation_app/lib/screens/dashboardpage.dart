import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:plate_recognation/models/registeredplates.dart';
import 'package:plate_recognation/services/authservice.dart';
import 'package:plate_recognation/services/dbplatedatasservice.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final scfKey = GlobalKey<ScaffoldState>();
  List<RegisteredPlates> rpData = [];
  String cUserPhoneNumber;
  String cUserPlateNumber;
  String cUserPlateId;
  bool gateState = false;
  bool shown = false;
  DatabaseReference dbRef = FirebaseDatabase.instance.reference();
  Timer _timer;
  Timer _dbTimer;
  int _start = 30;
  double _dbStart = 1.5;

  @override
  void initState() {
    super.initState();

    // AuthService().getCurrentUser().then((value) {
    //   if (mounted) {
    //     setState(() {
    //       cUserPhoneNumber = value;
    //     });
    //     print(cUserPhoneNumber);
    //   }
    // });
    //bu şekilde yapıyordum future fonksiyon haline getirdim.
    getUserPhone(); //bu
//
    getDatasFromDb();
//
  }

  getDatasFromDb() {
    dbRef
        .child('plateDatas')
        .child('registeredPlates')
        .once()
        .then((DataSnapshot dataSnapshot) {
      var keys = dataSnapshot.value.keys;
      var data = dataSnapshot.value;
      rpData.clear();
      for (var key in keys) {
        RegisteredPlates registeredDatas = new RegisteredPlates(
          key,
          data[key]['PhoneNumber'],
          data[key]['PlateNumber'],
          data[key]["IsGateOpen"],
        );
        rpData.add(registeredDatas);
      }
      // setState(() {
      //   // print("length: ${rpData.length}");
      // });
    });
  }

  void startTimer(id) {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          if (_start < 1) {
            DbPlateDatasService().updateGateStateFalse(id);
            _start = 30;
            timer.cancel();
          } else {
            _start = _start - 1;
          }
        },
      ),
    );
  }

  void dbTimer() {
    const oneSec = const Duration(milliseconds: 500);
    _dbTimer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          if (_dbStart == 0) {
            _dbStart = 1.5;
            timer.cancel();
          } else {
            gateStatesCheck();
            _dbStart = _dbStart - (.5);
          }
        },
      ),
    );
  }

  Future<String> getUserPhone() async {
    cUserPhoneNumber = await AuthService().getCurrentUser();
    return cUserPhoneNumber;
  }

  Future<void> waitTwoSeconds(bool deger) {
    return Future.delayed(Duration(seconds: 2), () {
      if (_start == 30) {
        if (gateState == true) {
          if (deger == true) {
            DbPlateDatasService()
                .updateGateStateTrue(cUserPlateId, "05537434305");
            startTimer(cUserPlateId);
          } else {
            DbPlateDatasService()
                .updateGateStateTrue(cUserPlateId, "05397799699");
            startTimer(cUserPlateId);
          }
        } else {
          _displaySnackBar(context);
        }
      }
    });
  }

  void gateStatesCheck() {
    getDatasFromDb();
    int x = 0;
    for (var i = 0; i <= rpData.length - 1; i++) {
      // print(rpData[i].gateState);
      if (rpData[i].phoneNumber != cUserPhoneNumber &&
          rpData[i].gateState == "false") {
        // print(rpData[i].gateState);
        x++;
        if (x == rpData.length - 1) {
          setState(() {
            this.gateState = true;
          });
        }
      } else if (rpData[i].phoneNumber != cUserPhoneNumber &&
          rpData[i].gateState == "true") {
        // print(rpData[i].gateState);
        setState(() {
          this.gateState = false;
        });
      }
    }
    // print(gateState);
  }

  void verifyPlate() {
    for (var i = 0; i <= rpData.length - 1; i++) {
      if (rpData[i].phoneNumber == cUserPhoneNumber) {
        setState(() {
          this.cUserPlateNumber = rpData[i].plateNumber;
          this.cUserPlateId = rpData[i].rndId;
        });
        // break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scfKey,
      appBar: AppBar(
        title: Text("Plate Recognation System"),
        actions: <Widget>[
          InkWell(
            onTap: () {
              DbPlateDatasService().updateGateStateFalse(cUserPlateId);
              AuthService().signOut();
            },
            child: Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 30,
            ),
            getinfo(),
            shown
                ? Container(
                    margin: EdgeInsets.symmetric(horizontal: 30),
                    height: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Your Plate Numbers : $cUserPlateNumber ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Your Phone Numbers : $cUserPhoneNumber ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : Container(
                    height: 40,
                  ),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: InkWell(
                  onDoubleTap: () {
                    verifyPlate();
                    dbTimer();
                    waitTwoSeconds(false);
                  },
                  onTap: () {
                    // _displaySnackBar(context);
                    verifyPlate();
                    dbTimer();
                    waitTwoSeconds(true);
                    // Buradaki fonksiyon wait two seconds ın içine alındı
                  },
                  child: Center(
                    child: Text(
                      "Open",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            _start == 30 ? Text("") : Text("$_start"),
            SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget getinfo() {
    return RaisedButton(
      color: Colors.tealAccent,
      onPressed: () {
        if (shown == false) {
          verifyPlate();
          setState(() {
            shown = true;
          });
        } else {
          setState(() {
            shown = false;
          });
        }
      },
      child: shown ? Text("Close Your Info") : Text("Fetch Your Info"),
    );
  }

  _displaySnackBar(BuildContext context) {
    final snackBar = SnackBar(
        content: Text(
      "Entrance gate is open please wait a bit",
      style: TextStyle(fontWeight: FontWeight.bold),
    ));
    scfKey.currentState.showSnackBar(snackBar);
  }
}
