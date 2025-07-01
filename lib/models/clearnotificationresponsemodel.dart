// To parse this JSON data, do
//
//     final clearNotificationResponseModel = clearNotificationResponseModelFromJson(jsonString);

import 'dart:convert';

ClearNotificationResponseModel clearNotificationResponseModelFromJson(
        String str) =>
    ClearNotificationResponseModel.fromJson(json.decode(str));

String clearNotificationResponseModelToJson(
        ClearNotificationResponseModel data) =>
    json.encode(data.toJson());

class ClearNotificationResponseModel {
  bool? success;
  String? message;
  Data? data;

  ClearNotificationResponseModel({
    this.success,
    this.message,
    this.data,
  });

  factory ClearNotificationResponseModel.fromJson(Map<String, dynamic> json) =>
      ClearNotificationResponseModel(
        success: json["success"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class Data {
  int fieldCount;
  int affectedRows;
  int insertId;
  int serverStatus;
  int warningCount;
  String message;
  bool protocol41;
  int changedRows;

  Data({
    required this.fieldCount,
    required this.affectedRows,
    required this.insertId,
    required this.serverStatus,
    required this.warningCount,
    required this.message,
    required this.protocol41,
    required this.changedRows,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        fieldCount: json["fieldCount"],
        affectedRows: json["affectedRows"],
        insertId: json["insertId"],
        serverStatus: json["serverStatus"],
        warningCount: json["warningCount"],
        message: json["message"],
        protocol41: json["protocol41"],
        changedRows: json["changedRows"],
      );

  Map<String, dynamic> toJson() => {
        "fieldCount": fieldCount,
        "affectedRows": affectedRows,
        "insertId": insertId,
        "serverStatus": serverStatus,
        "warningCount": warningCount,
        "message": message,
        "protocol41": protocol41,
        "changedRows": changedRows,
      };
}
