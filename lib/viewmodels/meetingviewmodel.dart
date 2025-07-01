// // ignore_for_file: avoid_print
import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';

class MeetingViewModel extends ChangeNotifier {
  late Success _sendmeetingtrequestresponse;
  Success get sendmeetingtrequestresponse => _sendmeetingtrequestresponse;
  late Success _meetingtrequestresponse;
  Success get meetingtrequestresponse => _meetingtrequestresponse;
  late Success _acceptmeetingtrequestresponse;
  Success get acceptmeetingtrequestresponse => _acceptmeetingtrequestresponse;
  late Success _rejectmeetingtrequestresponse;
  Success get rejectmeetingtrequestresponse => _rejectmeetingtrequestresponse;
  late Success _meetingcallidresponse;
  Success get meetingcallidresponse => _meetingcallidresponse;
  late Success _updatemeetingtrequestcountresponse;
  Success get updatemeetingtrequestcountresponse =>
      _updatemeetingtrequestcountresponse;

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

  setSendRequestMeetingModel(Success sendmeetingtrequestresponse) async {
    _sendmeetingtrequestresponse = sendmeetingtrequestresponse;
    notifyListeners();
  }

  setUpdateRequestMeetingCountModel(
      Success updatemeetingtrequestcountresponse) async {
    _updatemeetingtrequestcountresponse = updatemeetingtrequestcountresponse;
    notifyListeners();
  }

  setRequestMeetingModel(Success meetingtrequestresponse) async {
    _meetingtrequestresponse = meetingtrequestresponse;
    notifyListeners();
  }

  setMeetingCallIdModel(Success meetingcallidresponse) async {
    _meetingcallidresponse = meetingcallidresponse;
    notifyListeners();
  }

  setAcceptMeetingRequestModel(Success acceptmeetingtrequestresponse) async {
    _acceptmeetingtrequestresponse = acceptmeetingtrequestresponse;
    notifyListeners();
  }

  setRejectMeetingRequestModel(Success rejectmeetingtrequestresponse) async {
    _rejectmeetingtrequestresponse = rejectmeetingtrequestresponse;
    notifyListeners();
  }

  sendMeetingRequest(String userId, String frdId) async {
    setLoading(true);
    var response = await APIService.sendMeetingRequest(userId, frdId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setSendRequestMeetingModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setSendRequestMeetingModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  updateMeetingRequestCount(String reqId, String count) async {
    setLoading(true);
    var response = await APIService.updateMeetingRequestCount(reqId, count);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUpdateRequestMeetingCountModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUpdateRequestMeetingCountModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  getMeetingRequest(String userId) async {
    setLoading(true);
    var response = await APIService.getMeetingRequest(userId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setRequestMeetingModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setRequestMeetingModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  getMeetingCallId(String meetingId) async {
    setLoading(true);
    var response = await APIService.getMeetingCallId(meetingId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setMeetingCallIdModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setMeetingCallIdModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  acceptMeetingRequest(String idFrom, String idTo, String reqId, String callId,
      String scheduleDateTime) async {
    setLoading(true);
    var response = await APIService.acceptMeetingRequest(
        idFrom, idTo, reqId, callId, scheduleDateTime);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setAcceptMeetingRequestModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setAcceptMeetingRequestModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  rejectMeetingRequest(String reqId) async {
    setLoading(true);
    var response = await APIService.rejectMeetingRequest(reqId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setRejectMeetingRequestModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setRejectMeetingRequestModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }
}
