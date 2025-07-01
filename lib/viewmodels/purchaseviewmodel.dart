// // ignore_for_file: avoid_print
import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';

class PurchaseViewModel extends ChangeNotifier {
  late Success _buymembershipresponse;
  Success get buymembershipresponse => _buymembershipresponse;
  late Success _buyswipesresponse;
  Success get buyswipesresponse => _buyswipesresponse;
  late Success _buygiftsresponse;
  Success get buygiftsresponse => _buygiftsresponse;
  late Success _buyvirtualmeetingrequestresponse;
  Success get buyvirtualmeetingrequestresponse =>
      _buyvirtualmeetingrequestresponse;
  late Success _purchasedetailsresponse;
  Success get purchasedetailsresponse => _purchasedetailsresponse;
  late Success _swipescountresponse;
  Success get swipescountresponse => _swipescountresponse;
  late Success _sendgiftsresponse;
  Success get sendgiftsresponse => _sendgiftsresponse;
  late Success _swipecountresponse;
  Success get swipecountresponse => _swipecountresponse;
  late Success _buyliveeventticketresponse;
  Success get buyliveeventticketresponse => _buyliveeventticketresponse;

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

  setBuyMembershipModel(Success buymembershipresponse) async {
    _buymembershipresponse = buymembershipresponse;
    notifyListeners();
  }

  setBuySwipesModel(Success buyswipesresponse) async {
    _buyswipesresponse = buyswipesresponse;
    notifyListeners();
  }

  setBuyGiftsModel(Success buygiftsresponse) async {
    _buygiftsresponse = buygiftsresponse;
    notifyListeners();
  }

  setSendGiftsModel(Success sendgiftsresponse) async {
    _sendgiftsresponse = sendgiftsresponse;
    notifyListeners();
  }

  setBuyVirtualMeetingRequestModel(
      Success buyvirtualmeetingrequestresponse) async {
    _buyvirtualmeetingrequestresponse = buyvirtualmeetingrequestresponse;
    notifyListeners();
  }

  setBuyLiveEventTicketsModel(Success buyliveeventticketresponse) async {
    _buyliveeventticketresponse = buyliveeventticketresponse;
    notifyListeners();
  }

  setPurchaseDetailsModel(Success purchasedetailsresponse) async {
    _purchasedetailsresponse = purchasedetailsresponse;
    notifyListeners();
  }

  setSwipeCountModel(Success swipecountresponse) async {
    _swipecountresponse = swipecountresponse;
    notifyListeners();
  }

  setSwipesCountModel(Success swipescountresponse) async {
    _swipescountresponse = swipescountresponse;
    notifyListeners();
  }

  buyMembershipApi(String userId, String purchaseId, String planName,
      String price, String verificationToken) async {
    setLoading(true);
    var response = await APIService.buyMembership(
        userId, purchaseId, planName, price, verificationToken);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setBuyMembershipModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setBuyMembershipModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  buySwipesApi(
    String user_id,
    String count,
    String total,
    String verificationToken,
    String payment_id,
  ) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.buySwipes(
        user_id, count, total, verificationToken, payment_id);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setBuySwipesModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setBuySwipesModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  buyGiftsApi(
    String user_id,
    String count,
    String total,
    String verificationToken,
    String payment_id,
  ) async {
    setSuccess(false);

    setLoading(true);
    var response = await APIService.buyGifts(
        user_id, count, total, verificationToken, payment_id);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setBuyGiftsModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setBuyGiftsModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  buyVirtualMeetingRequestApi(
    String user_id,
    String count,
    String total,
    String verificationToken,
    String payment_id,
  ) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.buyVirtualMeetingsRequests(
        user_id, count, total, verificationToken, payment_id);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setBuyVirtualMeetingRequestModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setBuyVirtualMeetingRequestModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  buyLiveEventTicketsApi(
    String user_id,
    String count,
    String total,
    String verificationToken,
    String payment_id,
  ) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.buyLiveEventTickets(
        user_id, count, total, verificationToken, payment_id);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setBuyLiveEventTicketsModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setBuyLiveEventTicketsModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  getPurchaseDetailsAPI(
    String user_id,
  ) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.getPurchaseDetails(user_id);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setPurchaseDetailsModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setPurchaseDetailsModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  getSwipeCountAPI(String user_id, int isValue) async {
    setSuccess(false);
    setLoading(true);
    var response = await APIService.getSwipeCount(user_id, isValue);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setSwipeCountModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setSwipeCountModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  updateSwipesCount(String swipeId, String count) async {
    setLoading(true);
    var response = await APIService.updateSwipesCount(swipeId, count);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setSwipesCountModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setSwipesCountModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  sendGiftsApi(String from_id, String to_id, String quantity,
      String gift_type) async {
    setSuccess(false);

    setLoading(true);
    var response = await APIService.sendGifts(
         from_id, to_id, quantity, gift_type);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setSendGiftsModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setSendGiftsModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }
}
