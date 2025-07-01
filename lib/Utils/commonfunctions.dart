import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

showToast(String message, {Color? toastColor}) async {
  return Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      // gravity: Platform.isIOS ? ToastGravity.BOTTOM : ToastGravity.CENTER,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: toastColor ?? Colors.black,
      textColor: Colors.white,
      fontSize: 16.0);
}

// internet check validation :
Future<bool> isInternetAvailable() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    return false;
  } else {
    return true;
  }
}

bool validateEmail(String value) {
  Pattern pattern = r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$';
  RegExp regex = RegExp(pattern.toString());
  if (!regex.hasMatch(value)) {
    return false;
  } else {
    return true;
  }
}

int calculateAge(DateTime dob) {
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}
