import 'package:flutter/material.dart';
// import 'package:plate_recognation/screens/dashboardpage.dart';
// import 'package:plate_recognation/screens/loginpage.dart';
import 'package:plate_recognation/services/authservice.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthService().handleAuth(),
      // home: DashboardPage(),
      theme: ThemeData(
        primaryColor: Colors.orange[900],
      ),
    );
  }
}
