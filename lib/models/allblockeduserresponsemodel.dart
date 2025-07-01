// To parse this JSON data, do
//
//     final allBlockedUserResponseModel = allBlockedUserResponseModelFromJson(jsonString);

import 'dart:convert';

AllBlockedUserResponseModel allBlockedUserResponseModelFromJson(String str) =>
    AllBlockedUserResponseModel.fromJson(json.decode(str));

String allBlockedUserResponseModelToJson(AllBlockedUserResponseModel data) =>
    json.encode(data.toJson());

class AllBlockedUserResponseModel {
  bool? success;
  List<AllBlockedUsersDatum>? data;

  AllBlockedUserResponseModel({
    this.success,
    this.data,
  });

  factory AllBlockedUserResponseModel.fromJson(Map<String, dynamic> json) =>
      AllBlockedUserResponseModel(
        success: json["success"],
        data: json["data"] == null
            ? []
            : List<AllBlockedUsersDatum>.from(
                json["data"].map((x) => AllBlockedUsersDatum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class AllBlockedUsersDatum {
  int? id;
  String? firebaseId;

  AllBlockedUsersDatum({
    this.id,
    this.firebaseId,
  });

  factory AllBlockedUsersDatum.fromJson(Map<String, dynamic> json) =>
      AllBlockedUsersDatum(
        id: json["id"],
        firebaseId: json["firebase_id"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "firebase_id": firebaseId,
      };
}
