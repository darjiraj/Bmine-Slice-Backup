// To parse this JSON data, do
//
//     final profileResponseModel = profileResponseModelFromJson(jsonString);

import 'dart:convert';

PurchaseDetailsResponseModel purchaseDetailsResponseModelFromJson(String str) =>
    PurchaseDetailsResponseModel.fromJson(json.decode(str));

String purchaseDetailsResponseModelToJson(PurchaseDetailsResponseModel data) =>
    json.encode(data.toJson());

class PurchaseDetailsResponseModel {
  bool? success;
  UserGift? userGift;
  UserMembership? userMembership;
  UserSwipe? userSwipe;
  UserVirtualMeetingReq? userVirtualMeetingReq;
  UserLiveEventTickets? userLiveEventTickets;

  PurchaseDetailsResponseModel({
    this.success,
    this.userGift,
    this.userMembership,
    this.userSwipe,
    this.userVirtualMeetingReq,
    this.userLiveEventTickets,
  });

  factory PurchaseDetailsResponseModel.fromJson(Map<String, dynamic> json) =>
      PurchaseDetailsResponseModel(
        success: json["success"],
        userGift: json["user_gift"] == null
            ? UserGift()
            : UserGift.fromJson(json["user_gift"]),
        userMembership: json["user_membership"] == null
            ? UserMembership()
            : UserMembership.fromJson(json["user_membership"]),
        userSwipe: json["user_swipe"] == null
            ? UserSwipe()
            : UserSwipe.fromJson(json["user_swipe"]),
        userVirtualMeetingReq: json["user_virtual_meeting_req"] == null
            ? UserVirtualMeetingReq()
            : UserVirtualMeetingReq.fromJson(json["user_virtual_meeting_req"]),
        userLiveEventTickets: json["user_live_event_ticket"] == null
            ? UserLiveEventTickets()
            : UserLiveEventTickets.fromJson(json["user_live_event_ticket"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "user_gift": userGift!.toJson(),
        "user_membership": userMembership!.toJson(),
        "user_swipe": userSwipe!.toJson(),
        "user_virtual_meeting_req": userVirtualMeetingReq!.toJson(),
        "user_live_event_ticket": userLiveEventTickets!.toJson(),
      };
}

class UserGift {
  List<Gift>? gifts;
  int? totalCount;

  UserGift({
    this.gifts,
    this.totalCount,
  });

  factory UserGift.fromJson(Map<String, dynamic> json) => UserGift(
        gifts: json["gifts"] == null
            ? []
            : List<Gift>.from(json["gifts"].map((x) => Gift.fromJson(x))),
        totalCount: json["total_count"],
      );

  Map<String, dynamic> toJson() => {
        "gifts": List<dynamic>.from(gifts!.map((x) => x.toJson())),
        "total_count": totalCount,
      };
}

class Gift {
  int? id;
  int? userId;
  String? count;
  String? total;
  String? paymentId;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;

  Gift({
    this.id,
    this.userId,
    this.count,
    this.total,
    this.paymentId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Gift.fromJson(Map<String, dynamic> json) => Gift(
        id: json["id"],
        userId: json["user_id"],
        count: json["count"],
        total: json["total"],
        paymentId: json["payment_id"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "count": count,
        "total": total,
        "payment_id": paymentId,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
        "deleted_at": deletedAt,
      };
}

class UserMembership {
  int? id;
  int? userId;
  String? productId;
  String? purchaseId;
  String? planName;
  DateTime? transactionDate;
  DateTime? expireDate;
  String? verificationToken;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;

  UserMembership({
    this.id,
    this.userId,
    this.productId,
    this.purchaseId,
    this.planName,
    this.transactionDate,
    this.expireDate,
    this.verificationToken,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory UserMembership.fromJson(Map<String, dynamic> json) => UserMembership(
        id: json["id"],
        userId: json["user_id"],
        productId: json["product_id"],
        purchaseId: json["purchase_id"],
        planName: json["plan_name"],
        transactionDate: json["transaction_date"] == null
            ? null
            : DateTime.parse(json["transaction_date"]),
        expireDate: json["expire_date"] == null
            ? null
            : DateTime.parse(json["expire_date"]),
        verificationToken: json["verification_token"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "product_id": productId,
        "purchase_id": purchaseId,
        "plan_name": planName,
        "transaction_date": transactionDate!.toIso8601String(),
        "expire_date": expireDate!.toIso8601String(),
        "verification_token": verificationToken,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
        "deleted_at": deletedAt,
      };
}

class UserSwipe {
  List<Gift>? swipes;
  int? totalCount;

  UserSwipe({
    this.swipes,
    this.totalCount,
  });

  factory UserSwipe.fromJson(Map<String, dynamic> json) => UserSwipe(
        swipes: json["swipes"] == null
            ? []
            : List<Gift>.from(json["swipes"].map((x) => Gift.fromJson(x))),
        totalCount: json["total_count"],
      );

  Map<String, dynamic> toJson() => {
        "swipes": List<dynamic>.from(swipes!.map((x) => x.toJson())),
        "total_count": totalCount,
      };
}

class UserLiveEventTickets {
  int? remainTicket;

  UserLiveEventTickets({
    this.remainTicket,
  });

  factory UserLiveEventTickets.fromJson(Map<String, dynamic> json) =>
      UserLiveEventTickets(
        remainTicket: json["remain_ticket"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "remain_ticket": remainTicket,
      };
}

class UserVirtualMeetingReq {
  List<VirtualMeeting>? virtualMeetings;
  int? totalCount;

  UserVirtualMeetingReq({
    this.virtualMeetings,
    this.totalCount,
  });

  factory UserVirtualMeetingReq.fromJson(Map<String, dynamic> json) =>
      UserVirtualMeetingReq(
        virtualMeetings: List<VirtualMeeting>.from(
            json["virtualMeetings"].map((x) => VirtualMeeting.fromJson(x))),
        totalCount: json["total_count"],
      );

  Map<String, dynamic> toJson() => {
        "virtualMeetings":
            List<dynamic>.from(virtualMeetings!.map((x) => x.toJson())),
        "total_count": totalCount,
      };
}

class VirtualMeeting {
  int remainingMetting;

  VirtualMeeting({
    required this.remainingMetting,
  });

  factory VirtualMeeting.fromJson(Map<String, dynamic> json) => VirtualMeeting(
        remainingMetting: json["remaining_metting"],
      );

  Map<String, dynamic> toJson() => {
        "remaining_metting": remainingMetting,
      };
}
