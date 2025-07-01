import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';

class LikeFeedViewModel extends ChangeNotifier {
  late Success _likefeedresponse;
  Success get likefeedresponse => _likefeedresponse;
  late Success _userlikeresponse;
  Success get userlikeresponse => _userlikeresponse;
  late Success _removealluserlikeresponse;
  Success get removealluserlikeresponse => _removealluserlikeresponse;

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

  setLikeFeedResponseModel(Success likefeedresponse) async {
    _likefeedresponse = likefeedresponse;
    notifyListeners();
  }

  setUserLikeResponseModel(Success userlikeresponse) async {
    _userlikeresponse = userlikeresponse;
    notifyListeners();
  }

  setRemoveAllLikeUserResponseModel(Success removealluserlikeresponse) async {
    _removealluserlikeresponse = removealluserlikeresponse;
    notifyListeners();
  }

  getLikeFeedDataAPI(
    String userId,
    String tabType,
    String latitude,
    String longitude,
    String measurementtype,
  ) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.getLikeFeedData(
        userId, tabType, latitude, longitude, measurementtype);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setLikeFeedResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setLikeFeedResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  userLikeAPI(
    String id_from,
    String id_to,
    String is_like,
  ) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.userLike(id_from, id_to, is_like);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUserLikeResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUserLikeResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  removeAllLikeUser(
    String id_from,
    String is_like,
    String is_me,
  ) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.removeAllLikeUser(id_from, is_like, is_me);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setRemoveAllLikeUserResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setRemoveAllLikeUserResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }
}
