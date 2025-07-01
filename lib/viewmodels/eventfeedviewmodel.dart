import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';

class EventFeedViewModel extends ChangeNotifier {
  late Success _liveEventfeedresponse;
  Success get liveEventfeedresponse => _liveEventfeedresponse;
  late Success _joinEventresponse;
  Success get joinEventresponse => _joinEventresponse;
  late Success _withdrawEventresponse;
  Success get withdrawEventresponse => _withdrawEventresponse;
  late Success _eventDetailsresponse;
  Success get eventDetailsresponse => _eventDetailsresponse;
  late Success _joinEventCallresponse;
  Success get joinEventCallresponse => _joinEventCallresponse;
  late Success _alreadyjoinEventCallresponse;
  Success get alreadyjoinEventCallresponse => _alreadyjoinEventCallresponse;
  late Success _updatejoinEventCallresponse;
  Success get updatejoinEventCallresponse => _updatejoinEventCallresponse;
  late Success _updateCallStatusresponse;
  Success get updateCallStatusresponse => _updateCallStatusresponse;
  late Success _pendingcallsresponse;
  Success get pendingcallsresponse => _pendingcallsresponse;

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

  setLiveEventFeedResponseModel(Success liveEventfeedresponse) async {
    _liveEventfeedresponse = liveEventfeedresponse;
    notifyListeners();
  }

  setJoinEventResponseModel(Success joinEventresponse) async {
    _joinEventresponse = joinEventresponse;
    notifyListeners();
  }

  setWithdrawEventResponseModel(Success withdrawEventresponse) async {
    _withdrawEventresponse = withdrawEventresponse;
    notifyListeners();
  }

  setEventDetailsResponseModel(Success eventDetailsresponse) async {
    _eventDetailsresponse = eventDetailsresponse;
    notifyListeners();
  }

  setJoinEventCallResponseModel(Success joinEventCallresponse) async {
    _joinEventCallresponse = joinEventCallresponse;
    notifyListeners();
  }

  setAlreadyJoinEventCallResponseModel(
      Success alreadyjoinEventCallresponse) async {
    _alreadyjoinEventCallresponse = alreadyjoinEventCallresponse;
    notifyListeners();
  }

  setUpdateJoinEventCallResponseModel(
      Success updatejoinEventCallresponse) async {
    _updatejoinEventCallresponse = updatejoinEventCallresponse;
    notifyListeners();
  }

  setUpdateCallStatusResponseModel(Success updateCallStatusresponse) async {
    _updateCallStatusresponse = updateCallStatusresponse;
    notifyListeners();
  }

  setPendingCallResponseModel(Success pendingcallsresponse) async {
    _pendingcallsresponse = pendingcallsresponse;
    notifyListeners();
  }

  getLiveEventFeedDataAPI(String userId, String latitude, String longitude) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.getLiveEventFeedData(latitude, longitude);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setLiveEventFeedResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setLiveEventFeedResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  joinEventAPI(String eventId, String userId) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.joinEventAPI(eventId, userId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setJoinEventResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setJoinEventResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  withdrawEventAPI(String eventId, String userId) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.withdrawEventAPI(eventId, userId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setWithdrawEventResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setWithdrawEventResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  getEventDetailsAPI(String eventId) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.getEventDetails(eventId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setEventDetailsResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setEventDetailsResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  joinEventCallAPI(List<Map<String, dynamic>> callEvent, String eventId) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.joinEventCallAPI(callEvent, eventId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setJoinEventCallResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setJoinEventCallResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  checkjoinEventCallAPI(String eventId, String userId) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.checkJoinEventCallAPI(eventId, userId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setAlreadyJoinEventCallResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setAlreadyJoinEventCallResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  updatejoinEventCallAPI(String eventId, String userId, String callId) async {
    setSuccess(false);
    setLoading(true);
    var response =
        await APIService.updatejoinEventCallAPI(eventId, userId, callId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUpdateJoinEventCallResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUpdateJoinEventCallResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  updateCallStatusAPI(String id, String status) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.updateCallStatusAPI(id, status);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUpdateCallStatusResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUpdateCallStatusResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  getPendingCallAPI(String eventId, String userId) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.getPendingCallData(eventId, userId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setPendingCallResponseModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setPendingCallResponseModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }
}
