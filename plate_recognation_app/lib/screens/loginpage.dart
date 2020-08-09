import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plate_recognation/models/registeredplates.dart';
import 'package:plate_recognation/services/authservice.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:plate_recognation/services/dbplatedatasservice.dart';
// import 'package:plate_recognation/services/dbplatedatasservice.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = new GlobalKey<FormState>();
  final globalKey = GlobalKey<ScaffoldState>();

  String phoneNo, verificationId, smsCode, regPlateId, regPlateNumber;

  List<RegisteredPlates> rpData = [];

  bool retrivedPhoneNumber = false;
  bool codeSent = false;

  @override
  void initState() {
    super.initState();
    DatabaseReference dbRef = FirebaseDatabase.instance.reference();
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
      setState(() {
        // print("length: ${rpData.length}");
      });
    });
  }

  verifyPlate() {
    for (var i = 0; i <= rpData.length - 1; i++) {
      // print(rpData[i].rndId);
      // print(rpData[i].phoneNumber);
      // print(rpData[i].plateNumber);

      if (rpData[i].phoneNumber == phoneNo) {
        setState(() {
          this.regPlateNumber = rpData[i].plateNumber;
          this.regPlateId = rpData[i].rndId;
          this.retrivedPhoneNumber = true;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: globalKey,
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange[900],
                  Colors.orange[900],
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 80,
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Welcome",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Plate Recognation System",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(
                        height: 50,
                      ),
                    ],
                  ),
                ),
                Container(
                  // height: height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      bottomLeft: Radius.circular(60),
                      topRight: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 30,
                        ),
                        Container(
                          // margin: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                  color: Color.fromRGBO(225, 50, 50, .7),
                                  blurRadius: 20,
                                  offset: Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: codeSent
                                      ? Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[200],
                                          ),
                                        )
                                      : null,
                                ),
                                child: TextFormField(
                                  initialValue: "+90",
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Enter Phone Number",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please enter your phone number';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) {
                                    setState(() {
                                      this.phoneNo = val;
                                    });
                                  },
                                ),
                              ),
                              codeSent
                                  ? Container(
                                      padding: EdgeInsets.all(10),
                                      child: TextFormField(
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Enter Verify Code",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            this.smsCode = val;
                                          });
                                        },
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 60,
                        ),
                        InkWell(
                          onTap: () {
                            if (formKey.currentState.validate()) {
                              verifyPlate();

                              if (retrivedPhoneNumber == false) {
                                _displaySnackBar(context);
                              } else {
                                if (codeSent == true) {
                                  DbPlateDatasService().createData(
                                      regPlateId, phoneNo, regPlateNumber);
                                  AuthService()
                                      .signInWithOTP(smsCode, verificationId);
                                } else {
                                  verifyPhone(phoneNo);
                                }
                              }
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 60),
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.orange[900],
                            ),
                            child: Center(
                              child: codeSent
                                  ? Text(
                                      "Login",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500),
                                    )
                                  : Text(
                                      "Verify Code",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 80,
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> verifyPhone(phoneNo) async {
    final PhoneVerificationCompleted verified = (AuthCredential authResult) {
      // AuthService().signIn(authResult); //otomatik girişi sağlıyor elle girmekten se
    };

    final PhoneVerificationFailed verificationfailed =
        (AuthException authException) {
      print('${authException.message}');
    };

    final PhoneCodeSent smsSent = (String verId, [int forceResend]) {
      this.verificationId = verId;
      setState(() {
        this.codeSent = true;
      });
    };

    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this.verificationId = verId;
    };

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNo,
      timeout: Duration(seconds: 5),
      verificationCompleted: verified,
      verificationFailed: verificationfailed,
      codeSent: smsSent,
      codeAutoRetrievalTimeout: autoTimeout,
    );
  }

  _displaySnackBar(BuildContext context) {
    final snackBar = SnackBar(
        content: Text(
            'This phone number was not found in the system. Talk to your manager and register your phone number in the system.'));
    globalKey.currentState.showSnackBar(snackBar);
  }
}
