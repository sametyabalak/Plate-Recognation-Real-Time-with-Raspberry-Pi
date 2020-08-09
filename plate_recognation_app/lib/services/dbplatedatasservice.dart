import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';

class DbPlateDatasService {
  DatabaseReference dbRef = FirebaseDatabase.instance.reference();

  // createData(
  //   userId,
  //   phoneNumber,
  //   plateNumber,
  // ) {
  //   dbRef.child(userId).set({
  //     'PhoneNumber': phoneNumber,
  //     'PlateNo': plateNumber,
  //   });
  // }

  createData(registedPlateID, phoneNumber, registedPlateNumber) {
    dbRef
        .child("plateDatas")
        .child("registeredPlates")
        .child(registedPlateID)
        .set({
      'PlateNumber': registedPlateNumber,
      'PhoneNumber': phoneNumber,
      'IsGateOpen': "false",
      'calling': "",
    });
  }

  updateGateStateTrue(userPlatesId, phoneNumber) {
    dbRef
        .child("plateDatas")
        .child("registeredPlates")
        .child(userPlatesId)
        .update({
      'IsGateOpen': "true",
      'calling': phoneNumber,
    });
  }

  updateGateStateFalse(userPlatesId) {
    dbRef
        .child("plateDatas")
        .child("registeredPlates")
        .child(userPlatesId)
        .update({
      'IsGateOpen': "false",
      'calling': "",
    });
  }

  // readData(phoneNumber) {
  //   dbRef
  //       .child("plateDatas")
  //       .child("registeredPlates")
  //       .once()
  //       .then((DataSnapshot dataSnapshot) {
  //     var data = dataSnapshot.value;
  //     var keys = dataSnapshot.value.keys;
  //     // print(keys);
  //     for (var i in keys) {
  //       print(data[i]["PlateNumber"]);
  //       print(data[i]["PhoneNumber"]);
  //       print(i);
  //     }
  //   });
  // }
}
