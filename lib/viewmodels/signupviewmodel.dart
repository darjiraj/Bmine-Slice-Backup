// // ignore_for_file: avoid_print

// ignore_for_file: non_constant_identifier_names

import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';

class SignUpViewModel extends ChangeNotifier {
  late Success _signupresponse;
  Success get signupresponse => _signupresponse;
  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  late Success _updatedevicetokenresponse;
  Success get updatedevicetokenresponse => _updatedevicetokenresponse;
  setLoading(bool loading) async {
    _isLoading = loading;
    notifyListeners();
  }

  setSuccess(bool isSuccess) async {
    _isSuccess = isSuccess;
    notifyListeners();
  }

  setSignupModel(Success signupresponse) async {
    _signupresponse = signupresponse;
    notifyListeners();
  }

  setUpdateDeviceTokenModel(Success updatedevicetokenresponse) async {
    _updatedevicetokenresponse = updatedevicetokenresponse;
    notifyListeners();
  }

  doSignup(
    String first_name,
    String last_name,
    String email,
    String password,
    String mobile_no,
    String dob,
    String gender,
    String social_id,
    String social_type,
    String hometown,
    String latitude,
    String longitude,
  ) async {
    setLoading(true);
    var response = await APIService.doSignup(first_name, last_name, email,
        password, mobile_no, dob, gender, social_id, social_type,hometown,latitude,longitude);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setSignupModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setSignupModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  updateFirebaseId(
    String u_id,
    String firebase_id,
    String fcm_token,
  ) async {
    setLoading(true);
    var response =
        await APIService.updateFirebaseId(u_id, firebase_id, fcm_token);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUpdateDeviceTokenModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUpdateDeviceTokenModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }
}
