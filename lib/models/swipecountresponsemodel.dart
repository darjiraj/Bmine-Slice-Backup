// To parse this JSON data, do
//
//     final swipeCountResponseModel = swipeCountResponseModelFromJson(jsonString);

import 'dart:convert';

SwipeCountResponseModel swipeCountResponseModelFromJson(String str) =>
    SwipeCountResponseModel.fromJson(json.decode(str));

String swipeCountResponseModelToJson(SwipeCountResponseModel data) =>
    json.encode(data.toJson());

class SwipeCountResponseModel {
  bool? success;
  List<UserSwipe>? userSwipe;

  SwipeCountResponseModel({
    this.success,
    this.userSwipe,
  });

  factory SwipeCountResponseModel.fromJson(Map<String, dynamic> json) =>
      SwipeCountResponseModel(
        success: json["success"],
        userSwipe: List<UserSwipe>.from(
            json["user_swipe"].map((x) => UserSwipe.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "user_swipe": List<dynamic>.from(userSwipe!.map((x) => x.toJson())),
      };
}

class UserSwipe {
  int? swipeCount;
  int? freeSwipe;
  int? paidSwipe;

  UserSwipe({
    this.swipeCount,
    this.freeSwipe,
    this.paidSwipe,
  });

  factory UserSwipe.fromJson(Map<String, dynamic> json) => UserSwipe(
        swipeCount: json["swipe_count"] ?? 0,
        freeSwipe: json["free_swipe"] ?? 0,
        paidSwipe: json["paid_swipe"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "swipe_count": swipeCount,
        "free_swipe": freeSwipe,
        "paid_swipe": paidSwipe,
      };
}
