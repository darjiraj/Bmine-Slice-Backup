// To parse this JSON data, do
//
//     final forgotPasswordResponseModel = forgotPasswordResponseModelFromJson(jsonString);

import 'dart:convert';

ForgotPasswordResponseModel forgotPasswordResponseModelFromJson(String str) =>
    ForgotPasswordResponseModel.fromJson(json.decode(str));

String forgotPasswordResponseModelToJson(ForgotPasswordResponseModel data) =>
    json.encode(data.toJson());

class ForgotPasswordResponseModel {
  bool? success;
  String? message;

  ForgotPasswordResponseModel({
    this.success,
    this.message,
  });

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordResponseModel(
        success: json["success"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
      };
}
