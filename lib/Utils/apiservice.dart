// ignore_for_file: non_constant_identifier_names, avoid_print, unnecessary_brace_in_string_interps, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/locationservice.dart';
import 'package:bmine_slice/models/allblockeduserresponsemodel.dart';
import 'package:bmine_slice/models/alreadyjoincallresponsemodel.dart';
import 'package:bmine_slice/models/checkuserexistmodel.dart';
import 'package:bmine_slice/models/clearnotificationresponsemodel.dart';
import 'package:bmine_slice/models/commonresponsemodel.dart';
import 'package:bmine_slice/models/eventdetailsresponsemodel.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/homefeedresponsemodel.dart';
import 'package:bmine_slice/models/joineventcallresponsemodel.dart';
import 'package:bmine_slice/models/likefeedresponsemodel.dart';
import 'package:bmine_slice/models/liveeventresponsemodel.dart';
import 'package:bmine_slice/models/loginresponsemodel.dart';
import 'package:bmine_slice/models/meetingcallidresponsemodel.dart';
import 'package:bmine_slice/models/meetingrequestresponsemodel.dart';
import 'package:bmine_slice/models/notificationresponsemodel.dart';
import 'package:bmine_slice/models/pandingcallresponsemodel.dart';
import 'package:bmine_slice/models/profileresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/models/signupresponsemodel.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:bmine_slice/models/swipecountresponsemodel.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';

import '../models/blockedusersresponsemodel.dart';

class APIService {
  static Timer? _timer;
  static int _apiCallCount = 0;

  static void startPeriodicApiCall(Function(String) updateCallback) {
    print("Starting periodic API calls");
    // Call API immediately
    // _callApi(updateCallback);
    LocationService.getCurrentLocation();
    // Then set up timer for subsequent calls every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5),
        (_) => LocationService.getCurrentLocation());
  }

  static void stopPeriodicApiCall() {
    print("Stopping periodic API calls");
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> callApi(Function(String) updateCallback) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _apiCallCount++;
    print("Attempting API call #$_apiCallCount");
    try {
      final response = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
      if (response.statusCode == 200) {
        print("API call Time :: ${DateTime.now()}");
        print("API call #$_apiCallCount successful: ${response.statusCode}");
        prefs.setBool("IsLocationStart", true);
        print("IS LOCATION == ${prefs.getBool("IsLocationStart")}");
        updateCallback("API call #$_apiCallCount successful");
      } else {
        print(
            'API call #$_apiCallCount failed with status: ${response.statusCode}');
        updateCallback(
            "API call #$_apiCallCount failed: ${response.statusCode}");
      }
    } catch (e) {
      print('API call #$_apiCallCount error: $e');
      updateCallback("API call #$_apiCallCount error: $e");
    }
  }

  static Future<Object> doSignup(
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
    Map<String, String> Jsonbody = {
      "first_name": first_name,
      "last_name": last_name,
      "email": email,
      "password": password,
      "mobile_no": mobile_no,
      "dob":
          DateFormat('yyyy-MM-dd').format(DateFormat('dd/MM/yyyy').parse(dob)),
      "gender": gender,
      "social_id": social_id,
      "social_type": social_type,
      'hometown': hometown,
      'latitude': latitude,
      'longitude': longitude,
    };

    //  "social_type": social_type,
    //   "email": email,
    //   "password": password,
    //   "first_name": first_name ?? "",
    //   "last_name": last_name ?? "",
    //   "social_id": social_id ?? "",

    try {
      var url = Uri.parse(
        API.dosignup,
      );

      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("doSignup Json body  $Jsonbody");
      print("doSignup url $url");
      print("doSignup response ${response.body}");
      print("doSignup status code ${response.statusCode}");
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        var message = jsonData['message'];
        if (jsonData['success'] == false) {
          return Success(
            code: 200,
            response: "",
            msg: message,
            success: false,
          );
        } else {
          return Success(
            code: 200,
            response: signUpResponseModelFromJson(response.body),
            msg: message,
            success: true,
          );
        }
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 401,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> doLogin(
      String social_type, String email, String password,
      {first_name, last_name, social_id}) async {
    Map<String, String> Jsonbody = {
      "social_type": social_type,
      "email": email,
      "password": password,
      "first_name": first_name ?? "",
      "last_name": last_name ?? "",
      "social_id": social_id ?? "",
    };

    try {
      var url = Uri.parse(
        API.dologin,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("doLogin Json body  $Jsonbody");
      print("doLogin url $url");
      print("doLogin response ${response.body}");
      print("doLogin status code ${response.statusCode}");
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        var message = jsonData['message'];
        return Success(
          code: 200,
          response: loginResponseModelFromJson(response.body),
          msg: message,
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 403) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 403,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> checkAccountExist(
    String socialId,
  ) async {
    print("checkAccountExist called");
    try {
      var url = Uri.parse(
        "${API.checkAccountExist}/$socialId",
      );
      var response = await http.get(
        url,
      );
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: checkUserExistModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      print("ERRRRRORRRRRR");
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> forgotPassword(
    String email,
  ) async {
    Map<String, String> Jsonbody = {
      "email": email,
    };

    try {
      var url = Uri.parse(
        API.forgotpassword,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );

      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getProfile(
    String userId,
    String latitude,
    String longitude,
    String measurementtype,
  ) async {
    try {
      final url = Uri.parse(
        "${API.getProfile}$userId?latitude=$latitude&longitude=$longitude&measurementtype=$measurementtype",
      );
      final response = await http.get(url);
      final body = response.body;
      final statusCode = response.statusCode;

      print("url $url");
      print("response $body");
      print("statusCode $statusCode");

      if (statusCode == 200) {
        return Success(
          code: 200,
          response: profileResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      } else {
        final msg = jsonDecode(body)['message'] ?? "Something went wrong";

        return Success(
          code: statusCode,
          response: false,
          msg: msg.toString(),
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getHomeFeedData(
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
    try {
      var url = Uri.parse(
        "${API.getHomeFeedData}$userId?latitude=$latitude&longitude=$longitude&gender=$gender&age=$age&distance=$distance&verify=$isVerify&height=$height&looking_for=$looking_for&language=$language&is_show_height=$isShowHeight&is_show_looking_for=$isShowLookingfor&measurementtype=$measurementtype",
      );
      var response = await http.get(
        url,
      );
      print("getHomeFeedData url === $url");
      print("getHomeFeedData statusCode === ${response.statusCode}");
      print("getHomeFeedData body === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: homeFeedResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getLikeFeedData(
    String userId,
    String tabType,
    String latitude,
    String longitude,
    String measurementtype,
  ) async {
    print("getLikeFeedData called in api service");

    try {
      var url = Uri.parse(
        "${API.userLikeFeedData}$userId/$tabType?latitude=$latitude&longitude=$longitude&measurementtype=$measurementtype",
      );
      var response = await http.get(
        url,
      );
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: likeFeedResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getLiveEventFeedData(
      String latitude, String longitude) async {
    print("getLiveEventFeedData called in api service");

    try {
      var url = Uri.parse(
        "${API.getEvents}?latitude=$latitude&longitude=$longitude",
      );
      print("getLiveEventFeedData ${url}");

      var response = await http.get(
        url,
      );
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: liveEventResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> joinEventAPI(String eventId, String userId) async {
    try {
      var url = Uri.parse(
        API.joinEvent,
      );
      var response =
          await http.post(url, body: {'event_id': eventId, 'user_id': userId});
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> withdrawEventAPI(String eventId, String userId) async {
    try {
      var url = Uri.parse(
        API.withdrawEvent,
      );
      var response =
          await http.post(url, body: {'event_id': eventId, 'user_id': userId});
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> joinEventCallAPI(
      List<Map<String, dynamic>> callEvent, String eventId) async {
    try {
      var url = Uri.parse(
        API.joinEventCall,
      );
      var response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'event_id': eventId,
            // 'start_time':
            'call_event': callEvent
          }));
      // print("joinEventCallAPI == $response");
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return Success(
          code: 200,
          response: joinEventCallidResponseModelFromJson(response.body),
          msg: "",
          success: jsonData['success'],
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> checkJoinEventCallAPI(
      String eventId, String userId) async {
    try {
      var url = Uri.parse(
        API.alreadyjoinEventCall,
      );
      var response = await http.post(url, body: {
        'event_id': eventId,
        'user_id': userId,
      });
      // print("checkJoinEventCallAPI response == ${response.body}");
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return Success(
          code: 200,
          response: alreadyJoinEventCallResponseModelFromJson(response.body),
          msg: jsonData['message'],
          success: jsonData['success'],
        );
      }
      if (response.statusCode == 201) {
        var jsonData = jsonDecode(response.body);
        return Success(
          code: 201,
          response: alreadyJoinEventCallResponseModelFromJson(response.body),
          msg: jsonData['message'],
          success: jsonData['success'],
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> updatejoinEventCallAPI(
      String eventId, String userId, String callId) async {
    try {
      var url = Uri.parse(
        API.updatejoinEventCallId,
      );
      var response = await http.post(url, body: {
        'event_id': eventId,
        'call_id': callId,
        'user_id': userId,
      });
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: jsonData['success'],
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> updateCallStatusAPI(String id, String status) async {
    try {
      var url = Uri.parse(
        API.updateEventCallStatus,
      );
      var response = await http.post(url, body: {
        'id': id,
        'status': status,
      });
      // print("url $url");
      // print("response ${response.body}");
      // print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: jsonData['success'],
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> updateProfile(
      String userId, Map<String, dynamic> jsonBody) async {
    try {
      var url = Uri.parse("${API.updateProfile}$userId");
      var response = await http.post(url, body: jsonBody);
      print("jsonBody: ${jsonBody}");
      print("Response Body: ${response.body}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        var msg = jsonData['message'] ?? "An error occurred";

        return Success(
          code: 200,
          response: jsonDecode(response.body),
          msg: msg,
          success: true,
        );
      }

      // Handle different sus codes
      var jsonData = jsonDecode(response.body);
      var detail = jsonData['message'] ?? "An error occurred";

      return Success(
        code: response.statusCode,
        response: false,
        msg: detail,
        success: false,
      );
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "Network error occurred",
        success: false,
      );
    } catch (e) {
      print("Error: $e");
      return Success(
        code: 500,
        response: false,
        msg: "Something went wrong",
        success: false,
      );
    }
  }

  static bool _isVideoFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.3gp') ||
        ext.endsWith('.webm');
  }

  static String? _getMimeType(String path) {
    final ext = path.toLowerCase();
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.gif')) return 'image/gif';
    if (ext.endsWith('.mp4')) return 'video/mp4';
    if (ext.endsWith('.mov')) return 'video/quicktime';
    if (ext.endsWith('.avi')) return 'video/x-msvideo';
    if (ext.endsWith('.mkv')) return 'video/x-matroska';
    if (ext.endsWith('.3gp')) return 'video/3gpp';
    if (ext.endsWith('.webm')) return 'video/webm';
    return null; // Default
  }

  // static Future<Object> uploadPhotos(
  //     String userId, String firebaseId, List<XFile?> images) async {
  //   print("uploadPhotos called in ApiService ---- $images");

  //   try {
  //     var url = Uri.parse("${API.updateProfilePosts}$userId");
  //     var request = http.MultipartRequest('POST', url);
  //     request.fields['firebase_id'] = firebaseId;

  //     for (XFile? image in images) {
  //       print("image == ${image}");
  //       if (image != null) {
  //         request.files.add(await http.MultipartFile.fromPath(
  //           'images', // Field name for images array
  //           image.path, // Get the file path from the XFile object
  //         ));
  //       }
  //     }

  //     print("url: ${url}");
  //     print("Request Fields: ${request.fields}");
  //     print("Request Files: ${request.files.first}");

  //     // Sending the request
  //     var streamedResponse = await request.send();
  //     var response = await http.Response.fromStream(streamedResponse);

  //     print("Response Status: ${response.statusCode}");
  //     print("Response Body: ${response.body}");

  //     if (response.statusCode == 200) {
  //       var jsonData = jsonDecode(response.body);
  //       var msg = jsonData['message'] ?? "An error occurred";

  //       return Success(
  //         code: 200,
  //         response: jsonDecode(response.body),
  //         msg: msg,
  //         success: true,
  //       );
  //     }

  //     // Handle different status codes
  //     var jsonData = jsonDecode(response.body);
  //     var detail = jsonData['message'] ?? "An error occurred";

  //     return Success(
  //       code: response.statusCode,
  //       response: false,
  //       msg: detail,
  //       success: false,
  //     );
  //   } on HttpException {
  //     return Success(
  //       code: 101,
  //       response: false,
  //       msg: "Network error occurred",
  //       success: false,
  //     );
  //   } catch (e) {
  //     print("Error: $e");
  //     return Success(
  //       code: 500,
  //       response: false,
  //       msg: "Something went wrong",
  //       success: false,
  //     );
  //   }
  // }
  static Future<XFile?> compressVideo(XFile originalFile) async {
    final info = await VideoCompress.compressVideo(
      originalFile.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false, // keep original
    );

    return info != null ? XFile(info.path!) : null;
  }

  static Future<Object> uploadPhotos(String userId, String firebaseId,
      List<XFile?> mediaFiles, int seq) async {
    print("uploadMedia called in ApiService ---- $mediaFiles");

    try {
      var url = Uri.parse("${API.updateProfilePosts}$userId/$seq");
      var request = http.MultipartRequest('POST', url);
      request.fields['firebase_id'] = firebaseId;

      for (XFile? file in mediaFiles) {
        if (file != null) {
          final mimeType = _getMimeType(file.path);
          final fieldName = 'images';
          if (_isVideoFile(file.path)) {
            file = await compressVideo(file) ?? file;
          }
          request.files.add(await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          ));
        }
      }

      print("url: $url");
      print("Request Fields: ${request.fields}");
      print("Request Files: ${request.files.first.contentType}");
      print("Request Files: ${request.files.first.field}");
      print("Request Files: ${request.files.first.filename}");
      print("Request Files len: ${request.files.length}");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        var msg = jsonData['message'] ?? "Success";

        return Success(
          code: 200,
          response: jsonData,
          msg: msg,
          success: true,
        );
      }

      var jsonData = jsonDecode(response.body);
      var detail = jsonData['message'] ?? "An error occurred";

      return Success(
        code: response.statusCode,
        response: false,
        msg: detail,
        success: false,
      );
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "Network error occurred",
        success: false,
      );
    } catch (e) {
      print("Error: $e");
      return Success(
        code: 500,
        response: false,
        msg: "Something went wrong",
        success: false,
      );
    }
  }

  static Future<Object> removePhotos(
    String imageId,
  ) async {
    try {
      var url = Uri.parse(
        "${API.deleteUserPostsImage}$imageId",
      );
      var response = await http.post(
        url,
      );
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      var jsonData = jsonDecode(response.body);
      var msg = jsonData['message'] ?? "An error occurred";

      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: jsonDecode(response.body),
          msg: msg,
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> updatePostSeq(
      String imageId1, int seq1, String imageId2, int seq2) async {
    try {
      var url = Uri.parse(
        "${API.updatePostsSeq}$imageId1/$seq1/$imageId2/$seq2",
      );
      var response = await http.post(
        url,
      );
      print("url seq $url");
      print("response seq ${response.body}");
      print("response seq ${response.statusCode}");
      var jsonData = jsonDecode(response.body);
      var msg = jsonData['message'] ?? "An error occurred";

      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: jsonDecode(response.body),
          msg: msg,
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> updateFirebaseId(
    String u_id,
    String firebase_id,
    String fcm_token,
  ) async {
    print("updateFirebaseId called in api service");

    Map<String, String> Jsonbody = {
      "firebase_id": firebase_id,
      "fcm_token": fcm_token,
    };

    try {
      var url = Uri.parse(
        "${API.updateFirebaseData}$u_id",
      );

      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("Json body  $Jsonbody");
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: "",
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['msg'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['detail'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getPendingCallData(
      String eventId, String userId) async {
    try {
      var url = Uri.parse(
        // API.getEvents,
        "${API.pendingCall}$eventId/$userId",
      );
      var response = await http.get(
        url,
      );
      print("url $url");

      // print("active_call ======== $detail");
      // print("getPendingCallData ======== ${response.body}");
      // print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: pendingCallResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> userLike(
    String id_from,
    String id_to,
    String is_like,
  ) async {
    print("userLike called in api service");

    Map<String, String> Jsonbody = {
      "id_from": id_from,
      "id_to": id_to,
      "is_like": is_like,
    };
    print("Json body  $Jsonbody");
    try {
      var url = Uri.parse(
        API.userLike,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("Json body  $Jsonbody");
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> sendMeetingRequest(
    String userId,
    String frdId,
  ) async {
    Map<String, String> Jsonbody = {
      "id_from": userId,
      "id_to": frdId,
    };

    try {
      var url = Uri.parse(
        API.sendMeetingRequest,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("sendMeetingRequest Jsonbody == $Jsonbody");
      print("sendMeetingRequest response == ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> updateMeetingRequestCount(
    String reqId,
    String count,
  ) async {
    Map<String, String> Jsonbody = {
      "virtual_meeting_req_id": reqId,
      "count": count,
    };
    print("sendMeetingRequest Jsonbody == $Jsonbody");
    try {
      var url = Uri.parse(
        API.updateVirtualMeetingCount,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("Json body  $Jsonbody");
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getEventDetails(String eventId) async {
    print("getLiveEventFeedData called in api service");

    try {
      var url = Uri.parse(
        "${API.getEventDetails}$eventId",
      );
      var response = await http.get(
        url,
      );
      // print("url $url");
      // print("response ${response.body}");
      // print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: eventDetailsResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getMeetingRequest(String userId) async {
    print("getLiveEventFeedData called in api service");

    try {
      var url = Uri.parse(
        "${API.getMeetingRequest}$userId",
      );
      var response = await http.get(
        url,
      );
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: meetingRequestResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getMeetingCallId(String meetingId) async {
    print("getMeetingCallId called in api service");

    try {
      var url = Uri.parse(
        "${API.getMeetingCallId}$meetingId",
      );
      var response = await http.get(
        url,
      );
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: meetingCallIdResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        print("JSON DATA STRING +++ $detail");
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> acceptMeetingRequest(
    String idFrom,
    String idTo,
    String reqId,
    String callId,
    String scheduleDateTime,
  ) async {
    Map<String, String> Jsonbody = {
      "id_from": idFrom,
      "id_to": idTo,
      "id": reqId,
      "call_id": callId,
      "schedule_at": scheduleDateTime,
    };
    print("acceptMeetingRequest Jsonbody === $Jsonbody");
    try {
      var url = Uri.parse(
        API.acceptMeetingRequest,
      );
      var response = await http.post(url, body: Jsonbody);
      print("acceptMeetingRequest Response === ${response.body}");

      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> rejectMeetingRequest(
    String reqId,
  ) async {
    try {
      var url = Uri.parse(
        "${API.deleteMeetingRequest}/$reqId",
      );
      var response = await http.get(
        url,
      );
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getNotifications(
    String userId,
  ) async {
    try {
      var url = Uri.parse(
        "${API.getNotifications}$userId",
      );
      var response = await http.get(url);

      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: notificationResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> buyMembership(String userId, String purchaseId,
      String planName, String price, String verificationToken) async {
    Map<String, String> Jsonbody = {
      "user_id": userId,
      "purchase_id": purchaseId,
      "plan_name": planName,
      "price": price,
      "verification_token": verificationToken,
    };

    try {
      var url = Uri.parse(
        API.buyMembership,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("buyMembership url === $url");
      print("buyMembership Jsonbody === $Jsonbody");
      print("buyMembership response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> buySwipes(
    String user_id,
    String count,
    String total,
    String verificationToken,
    String payment_id,
  ) async {
    Map<String, String> Jsonbody = {
      "user_id": user_id,
      "count": count,
      "total": total,
      "verification_token": verificationToken,
      "payment_id": payment_id,
    };

    try {
      var url = Uri.parse(
        API.buySwipes,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("buySwipes url === ${url}");
      print("buySwipes Jsonbody === ${Jsonbody}");
      print("buySwipes statusCode === ${response.statusCode}");
      print("buySwipes response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> buyGifts(
    String user_id,
    String count,
    String total,
    String verificationToken,
    String payment_id,
  ) async {
    Map<String, String> Jsonbody = {
      "user_id": user_id,
      "count": count,
      "total": total,
      "verification_token": verificationToken,
      "payment_id": payment_id,
    };
    try {
      var url = Uri.parse(
        API.buyGifts,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("buyGifts url === ${url}");
      print("buyGifts Jsonbody === ${Jsonbody}");
      print("buyGifts statusCode === ${response.statusCode}");
      print("buyGifts response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> buyLiveEventTickets(
    String user_id,
    String count,
    String total,
    String verificationToken,
    String payment_id,
  ) async {
    Map<String, String> Jsonbody = {
      "user_id": user_id,
      "count": count,
      "total": total,
      "verification_token": verificationToken,
      "payment_id": payment_id,
    };
    try {
      var url = Uri.parse(
        API.buyLiveEventTickets,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("buyLiveEventTickets url === ${url}");
      print("buyLiveEventTickets Jsonbody === ${Jsonbody}");
      print("buyLiveEventTickets statusCode === ${response.statusCode}");
      print("buyLiveEventTickets response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> buyVirtualMeetingsRequests(
    String user_id,
    String count,
    String total,
    String verificationToken,
    String payment_id,
  ) async {
    Map<String, String> Jsonbody = {
      "user_id": user_id,
      "count": count,
      "total": total,
      "verification_token": verificationToken,
      "payment_id": payment_id,
    };
    try {
      var url = Uri.parse(
        API.buyVirtualMeetingRequests,
      );
      var response = await http.post(url, body: Jsonbody);
      print("buyVirtualMeetingsRequests url === ${url}");
      print("buyVirtualMeetingsRequests Jsonbody === ${Jsonbody}");
      print("buyVirtualMeetingsRequests statusCode === ${response.statusCode}");
      print("buyVirtualMeetingsRequests response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> userReport(
      String fromId, String toId, String reason) async {
    Map<String, String> Jsonbody = {
      "from_id": fromId,
      "to_id": toId,
      "reason": reason,
    };

    try {
      var url = Uri.parse(
        API.reportUser,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("userReport url == $url");
      print("userReport response == ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> uploadVerifyVideo(String userId, XFile video) async {
    print("uploadVideo called in ApiService ---- $video");

    try {
      var url = Uri.parse(API.uploadverifyvideos);
      var request = http.MultipartRequest('POST', url);
      request.fields['id'] = userId;
      request.files.add(await http.MultipartFile.fromPath(
        'video',
        video.path,
        contentType: MediaType.parse("video/mp4"),
      ));
      print("url: ${url}");
      print("Request Fields: ${request.fields}");
      print("Request Files: ${request.files.first}");

      // Sending the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        var msg = jsonData['message'] ?? "An error occurred";

        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: msg,
          success: true,
        );
      }

      // Handle different status codes
      var jsonData = jsonDecode(response.body);
      var detail = jsonData['message'] ?? "An error occurred";

      return Success(
        code: response.statusCode,
        response: false,
        msg: detail,
        success: false,
      );
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "Network error occurred",
        success: false,
      );
    } catch (e) {
      print("Error: $e");
      return Success(
        code: 500,
        response: false,
        msg: "Something went wrong",
        success: false,
      );
    }
  }

  static Future<Object> getPurchaseDetails(String userId) async {
    try {
      var url = Uri.parse(
        "${API.purchaseDetails}$userId",
      );
      var response = await http.get(
        url,
        // headers: headers,
      );
      print("getPurchaseDetails url === ${url}");
      print("getPurchaseDetails statusCode === ${response.statusCode}");
      print("getPurchaseDetails response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: purchaseDetailsResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> updateSwipesCount(
    String swipeId,
    String count,
  ) async {
    Map<String, String> Jsonbody = {
      "swipe_id": swipeId,
      "count": count,
    };
    print("updateSwipesCount Jsonbody == $Jsonbody");
    try {
      var url = Uri.parse(
        API.updateswipesCount,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("Json body  $Jsonbody");
      print("url $url");
      print("response ${response.body}");
      print("response ${response.statusCode}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> sendGifts(
      String from_id, String to_id, String quantity, String gift_type) async {
    Map<String, String> Jsonbody = {
      "from_id": from_id,
      "to_id": to_id,
      "quantity": quantity,
      "gift_type": gift_type,
    };
    try {
      var url = Uri.parse(
        API.sendGifts,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("sendGifts url === ${url}");
      print("sendGifts Jsonbody === ${Jsonbody}");
      print("sendGifts statusCode === ${response.statusCode}");
      print("sendGifts response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> deleteAccount(String userId) async {
    try {
      var url = Uri.parse(
        "${API.deleteUser}$userId",
      );
      var response = await http.get(url
          // headers: headers,
          );
      print("deleteAccount url === ${url}");
      print("deleteAccount statusCode === ${response.statusCode}");
      print("deleteAccount response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getSwipeCount(String userId, int isvalue) async {
    try {
      var url = Uri.parse(
        "${API.getswipecount}$userId/$isvalue",
      );
      var response = await http.get(url
          // headers: headers,
          );
      print("getSwipeCount url === ${url}");
      print("getSwipeCount statusCode === ${response.statusCode}");
      print("getSwipeCount response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: swipeCountResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> deleteNotification(String notificationId) async {
    try {
      var url = Uri.parse(
        "${API.deletenotification}$notificationId",
      );
      var response = await http.get(url);

      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: commonResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> sendNotification(
      String from_id, String to_id, String message) async {
    Map<String, String> Jsonbody = {
      "id_from": from_id,
      "id_to": to_id,
      "message": message,
    };
    try {
      var url = Uri.parse(
        API.sendnotification,
      );
      var response = await http.post(
        url,
        body: Jsonbody,
      );
      print("sendNotification url === ${url}");
      print("sendNotification Jsonbody === $Jsonbody");
      print("sendNotification statusCode === ${response.statusCode}");
      print("sendNotification response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: commonResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> contactUs(
      String email, String subject, String message) async {
    Map<String, String> Jsonbody = {
      "email": email,
      "subject": subject,
      "message": message,
    };
    try {
      var url = Uri.parse(
        API.contactUs,
      );
      var response = await http.post(
        url,
        body: Jsonbody,
      );
      print("contactUs url === ${url}");
      print("contactUs Jsonbody === $Jsonbody");
      print("contactUs statusCode === ${response.statusCode}");
      print("contactUs response === ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> userBlock(
      String fromId, String toId, String reason) async {
    Map<String, String> Jsonbody = {
      "id_from": fromId,
      "id_to": toId,
      "is_block": reason,
    };

    try {
      var url = Uri.parse(
        API.blockUser,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("userBlock url == $url");
      print("userBlock response == ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> unmatchUser(String fromId, String toId) async {
    Map<String, String> Jsonbody = {
      "id_from": fromId,
      "id_to": toId,
    };

    try {
      var url = Uri.parse(
        API.userUnmatch,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("unmatchUser url == $url");
      print("unmatchUser response == ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> userRemove(String fromId, String toId) async {
    Map<String, String> Jsonbody = {
      "id_from": fromId,
      "id_to": toId,
    };

    try {
      var url = Uri.parse(
        API.removeUser,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("userRemove url == $url");
      print("userRemove Jsonbody == $Jsonbody");
      print("userRemove response == ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getBlockedUser(String userId) async {
    try {
      var url = Uri.parse(
        "${API.getblockUser}$userId",
      );
      var response = await http.get(url);
      print("getBlockedUser url == $url");
      print("getBlockedUser response == ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: blockedUsersResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> getAllBlockedUser(String userId) async {
    try {
      var url = Uri.parse(
        "${API.getallblockUser}$userId",
      );
      var response = await http.get(url);
      print("getAllBlockedUser url == $url");
      print("getAllBlockedUser response == ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: allBlockedUserResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> removeAllLikeUser(
      String fromId, String isLike, String is_me) async {
    Map<String, String> Jsonbody = {
      "id_from": fromId,
      "is_like": isLike,
      "is_me": is_me,
    };

    try {
      var url = Uri.parse(
        API.removeAllLikeUser,
      );
      var response = await http.post(url, body: Jsonbody
          // headers: headers,
          );
      print("removeAllLikeUser url == $url");
      print("removeAllLikeUser Jsonbody == $Jsonbody");
      print("removeAllLikeUser response == ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: forgotPasswordResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }

  static Future<Object> clearNotification(String userId) async {
    try {
      var url = Uri.parse(
        "${API.clearnotification}$userId",
      );
      var response = await http.get(
        url,
        // headers: headers,
      );
      print("clearNotification url == $url");
      print("clearNotification response == ${response.body}");
      if (response.statusCode == 200) {
        return Success(
          code: 200,
          response: clearNotificationResponseModelFromJson(response.body),
          msg: "",
          success: true,
        );
      }

      if (response.statusCode == 400) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 400,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 422) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 422,
          response: false,
          msg: detail.toString(),
          success: false,
        );
      }
      if (response.statusCode == 500) {
        return Success(
          code: 500,
          response: false,
          msg: "Somthing went wrong",
          success: false,
        );
      }
      if (response.statusCode == 401) {
        var jsonData = jsonDecode(response.body);
        var detail = jsonData['message'];
        return Success(
          code: 100,
          response: false,
          msg: detail,
          success: false,
        );
      } else {
        return Success(
          code: 100,
          response: false,
          msg: "",
          success: false,
        );
      }
    } on HttpException {
      return Success(
        code: 101,
        response: false,
        msg: "",
        success: false,
      );
    }
  }
}
