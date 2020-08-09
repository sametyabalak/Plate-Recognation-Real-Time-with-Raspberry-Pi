import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plate_recognation/screens/dashboardpage.dart';
import 'package:plate_recognation/screens/loginpage.dart';

class AuthService {
  // handles auth
  handleAuth() {
    return StreamBuilder(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return DashboardPage();
        } else {
          return LoginPage();
        }
      },
    );
  }

  //sign out
  signOut() {
    FirebaseAuth.instance.signOut();
  }

  //sign in
  signIn(AuthCredential authCreds) {
    FirebaseAuth.instance.signInWithCredential(authCreds);
  }

  signInWithOTP(smsCode, verId) {
    AuthCredential authCredential = PhoneAuthProvider.getCredential(
      verificationId: verId,
      smsCode: smsCode,
    );
    signIn(authCredential);
  }

  Future<String> getCurrentUser() async {
    final FirebaseUser user = await FirebaseAuth.instance.currentUser();
    // final uid = user.uid;
    return user.phoneNumber;
    // Similarly we can get email as well
    //final uemail = user.email;
    //print(uemail);
  }
}
