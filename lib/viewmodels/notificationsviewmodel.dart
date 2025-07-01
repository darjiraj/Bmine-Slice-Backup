// // ignore_for_file: avoid_print
import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';

class NotificationsViewModel extends ChangeNotifier {
  late Success _notificationsresponse;
  Success get notificationsresponse => _notificationsresponse;
  late Success _deletednotificationsresponse;
  Success get deletednotificationsresponse => _deletednotificationsresponse;
  late Success _clearnotificationsresponse;
  Success get clearnotificationsresponse => _clearnotificationsresponse;
  late Success _sendnotificationsresponse;
  Success get sendnotificationsresponse => _sendnotificationsresponse;

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

  setNotificationsModel(Success notificationsresponse) async {
    _notificationsresponse = notificationsresponse;
    notifyListeners();
  }

  setDeletedNotificationsModel(Success deletednotificationsresponse) async {
    _deletednotificationsresponse = deletednotificationsresponse;
    notifyListeners();
  }

  setClearNotificationsModel(Success clearnotificationsresponse) async {
    _clearnotificationsresponse = clearnotificationsresponse;
    notifyListeners();
  }

  setSendNotificationsModel(Success sendnotificationsresponse) async {
    _sendnotificationsresponse = sendnotificationsresponse;
    notifyListeners();
  }

  getNotifications(String userId) async {
    setLoading(true);
    var response = await APIService.getNotifications(userId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setNotificationsModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setNotificationsModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  sendNotification(
    String from_id,
    String to_id,
    String message,
  ) async {
    setLoading(true);
    var response = await APIService.sendNotification(from_id, to_id, message);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setSendNotificationsModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setSendNotificationsModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  deleteNotification(String notificationId) async {
    setLoading(true);
    var response = await APIService.deleteNotification(notificationId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setDeletedNotificationsModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setDeletedNotificationsModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  clearNotification(String userId) async {
    setLoading(true);
    var response = await APIService.clearNotification(userId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setClearNotificationsModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setClearNotificationsModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }
}
