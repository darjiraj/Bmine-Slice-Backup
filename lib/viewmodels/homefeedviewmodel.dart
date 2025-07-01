// // ignore_for_file: avoid_print
import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';

class HomeFeedViewModel extends ChangeNotifier {
  late Success _homefeedresponse;
  Success get homefeedresponse => _homefeedresponse;

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

  setHomeFeedResponseModel(Success homefeedresponse) async {
    _homefeedresponse = homefeedresponse;
    notifyListeners();
  }

  getHomeFeedAPI(
    String userId,
    String latitude,
    String longitude,
    String gender,
    String age,
    String distance,
    String isVerify,
    String height,
    String looking_for,
    String language,
    bool isShowHeight,
    bool isShowLookingfor,
    String measurementtype,
  ) async {
    setLoading(true);
    var response = await APIService.getHomeFeedData(
      userId,
      latitude,
      longitude,
      gender,
      age,
      distance,
      isVerify,
      height,
      looking_for,
      language,
      isShowHeight,
      isShowLookingfor,
      measurementtype,
    );
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setHomeFeedResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setHomeFeedResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }
}
