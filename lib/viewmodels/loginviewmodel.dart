// // ignore_for_file: avoid_print

// ignore_for_file: non_constant_identifier_names

import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  late Success _loginresponse;
  Success get loginresponse => _loginresponse;
  late Success _accountexistsponse;
  Success get accountexistsponse => _accountexistsponse;
  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  setLoading(bool loading) async {
    _isLoading = loading;
    notifyListeners();
  }

  setSuccess(bool isSuccess) async {
    _isSuccess = isSuccess;
    notifyListeners();
  }

  setLoginModel(Success loginresponse) async {
    _loginresponse = loginresponse;
    notifyListeners();
  }

  setAlreadyExistAccountModel(Success accountexistsponse) async {
    _accountexistsponse = accountexistsponse;
    notifyListeners();
  }

  doLogin(
    String social_type,
    String email,
    String password, {
    first_name,
    last_name,
    social_id,
  }) async {
    setLoading(true);
    var response = await APIService.doLogin(
      social_type,
      email,
      password,
      first_name: first_name,
      last_name: last_name,
      social_id: social_id,
    );
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setLoginModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setLoginModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  checkAccountExist(String socialId) async {
    setLoading(true);
    var response = await APIService.checkAccountExist(socialId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setAlreadyExistAccountModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setAlreadyExistAccountModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }
}
