// // ignore_for_file: avoid_print
import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';

class UserReportViewModel extends ChangeNotifier {
  late Success _userreportresponse;
  Success get userreportresponse => _userreportresponse;
  late Success _userblockresponse;
  Success get userblockresponse => _userblockresponse;
  late Success _unmatchusersresponse;
  Success get unmatchusersresponse => _unmatchusersresponse;
  late Success _blockedusersresponse;
  Success get blockedusersresponse => _blockedusersresponse;
  late Success _allblockedusersresponse;
  Success get allblockedusersresponse => _allblockedusersresponse;
  late Success _userremoveresponse;
  Success get userremoveresponse => _userremoveresponse;

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

  setUserReportModel(Success userreportresponse) async {
    _userreportresponse = userreportresponse;
    notifyListeners();
  }

  setUserBlockModel(Success userblockresponse) async {
    _userblockresponse = userblockresponse;
    notifyListeners();
  }

  setUnmatchUserModel(Success unmatchusersresponse) async {
    _unmatchusersresponse = unmatchusersresponse;
    notifyListeners();
  }

  setUserRemoveModel(Success userremoveresponse) async {
    _userremoveresponse = userremoveresponse;
    notifyListeners();
  }

  setBlockedUsersModel(Success blockedusersresponse) async {
    _blockedusersresponse = blockedusersresponse;
    notifyListeners();
  }

  setAllBlockedUsersModel(Success allblockedusersresponse) async {
    _allblockedusersresponse = allblockedusersresponse;
    notifyListeners();
  }

  userReportAPI(String fromId, String toId, String reason) async {
    setLoading(true);
    var response = await APIService.userReport(fromId, toId, reason);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUserReportModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUserReportModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  userBlockAPI(String fromId, String toId, String isBlock) async {
    setLoading(true);
    var response = await APIService.userBlock(fromId, toId, isBlock);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUserBlockModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUserBlockModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  unmatchUsersAPI(String fromId, String toId) async {
    setLoading(true);
    var response = await APIService.unmatchUser(fromId, toId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUnmatchUserModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUnmatchUserModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  userRemoveAPI(String fromId, String toId) async {
    setLoading(true);
    var response = await APIService.userRemove(fromId, toId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUserRemoveModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUserRemoveModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  getBlockedUsersAPI(String fromId) async {
    setLoading(true);
    var response = await APIService.getBlockedUser(fromId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setBlockedUsersModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setBlockedUsersModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  getAllBlockedUsersAPI(String fromId) async {
    setLoading(true);
    var response = await APIService.getAllBlockedUser(fromId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setAllBlockedUsersModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setAllBlockedUsersModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }
}
