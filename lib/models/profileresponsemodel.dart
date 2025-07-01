// To parse this JSON data, do
//
//     final profileResponseModel = profileResponseModelFromJson(jsonString);

import 'dart:convert';

ProfileResponseModel profileResponseModelFromJson(String str) =>
    ProfileResponseModel.fromJson(json.decode(str));

String profileResponseModelToJson(ProfileResponseModel data) =>
    json.encode(data.toJson());

class ProfileResponseModel {
  bool? success;
  UserProfile? userProfile;
  // UserGift? userGift;
  // UserMembership? userMembership;
  // UserSwipe? userSwipe;
  // UserVirtualMeetingReq? userVirtualMeetingReq;
  List<PostDatum>? postData;
  List<AboutMe>? aboutMe;
  List<String>? lookingFor;
  List<String>? intrested;

  ProfileResponseModel({
    this.success,
    this.userProfile,
    // this.userGift,
    // this.userMembership,
    // this.userSwipe,
    // this.userVirtualMeetingReq,
    this.postData,
    this.aboutMe,
    this.lookingFor,
    this.intrested,
  });

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) =>
      ProfileResponseModel(
        success: json["success"],
        userProfile: json["user_profile"] == null
            ? UserProfile()
            : UserProfile.fromJson(json["user_profile"]),
        // userGift: json["user_gift"] == null
        //     ? UserGift()
        //     : UserGift.fromJson(json["user_gift"]),
        // userMembership: json["user_membership"] == null
        //     ? UserMembership()
        //     : UserMembership.fromJson(json["user_membership"]),
        // userSwipe: json["user_swipe"] == null
        //     ? UserSwipe()
        //     : UserSwipe.fromJson(json["user_swipe"]),
        // userVirtualMeetingReq: json["user_virtual_meeting_req"] == null
        //     ? UserVirtualMeetingReq()
        //     : UserVirtualMeetingReq.fromJson(json["user_virtual_meeting_req"]),
        postData: json["post_data"] == null
            ? []
            : List<PostDatum>.from(
                json["post_data"].map((x) => PostDatum.fromJson(x))),
        aboutMe: json["about_me"] == null
            ? []
            : List<AboutMe>.from(
                json["about_me"].map((x) => AboutMe.fromJson(x))),
        lookingFor: json["looking_for"] == null
            ? []
            : List<String>.from(json["looking_for"].map((x) => x)),
        intrested: json["intrested"] == null
            ? []
            : List<String>.from(json["intrested"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "user_profile": userProfile!.toJson(),
        // "user_gift": userGift!.toJson(),
        // "user_membership": userMembership!.toJson(),
        // "user_swipe": userSwipe!.toJson(),
        // "user_virtual_meeting_req": userVirtualMeetingReq!.toJson(),
        "post_data": List<dynamic>.from(postData!.map((x) => x.toJson())),
        "about_me": List<dynamic>.from(aboutMe!.map((x) => x.toJson())),
        "looking_for": List<dynamic>.from(lookingFor!.map((x) => x)),
        "intrested": List<dynamic>.from(intrested!.map((x) => x)),
      };
}

class AboutMe {
  String? type;
  String? value;

  AboutMe({
    this.type,
    this.value,
  });

  factory AboutMe.fromJson(Map<String, dynamic> json) => AboutMe(
        type: json["type"],
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "value": value,
      };
}

class PostDatum {
  int? id;
  int? userId;
  int? seq;
  String? images;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;

  PostDatum({
    this.id,
    this.userId,
    this.seq,
    this.images,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory PostDatum.fromJson(Map<String, dynamic> json) => PostDatum(
        id: json["id"],
        userId: json["user_id"],
        images: json["images"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
        seq: json["seq"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "images": images,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
        "deleted_at": deletedAt,
        "seq": seq,
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

class UserProfile {
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  String? username;
  String? phoneNumber;
  DateTime? dob;
  String? bio;
  String? language;
  String? profileImage;
  String? location;
  String? latitude;
  String? longitude;
  String? hometown;
  String? status;
  String? verifyVideo;
  int? isVerify;
  String? socialId;
  String? socialType;
  String? userType;
  String? firebaseId;
  String? fcmToken;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;
  double? distance;

  UserProfile({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.username,
    this.phoneNumber,
    this.dob,
    this.bio,
    this.language,
    this.profileImage,
    this.location,
    this.latitude,
    this.longitude,
    this.hometown,
    this.status,
    this.verifyVideo,
    this.isVerify,
    this.socialId,
    this.socialType,
    this.userType,
    this.firebaseId,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.distance,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json["id"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        email: json["email"],
        password: json["password"],
        username: json["username"],
        phoneNumber: json["phone_number"],
        dob: json["dob"] == null ? null : DateTime.parse(json["dob"]),
        bio: json["bio"],
        language: json["language"],
        profileImage: json["profile_image"],
        location: json["location"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        hometown: json["hometown"],
        status: json["status"],
        verifyVideo: json["verify_video"],
        isVerify: json["is_verify"],
        socialId: json["social_id"],
        socialType: json["social_type"],
        userType: json["user_type"],
        firebaseId: json["firebase_id"],
        fcmToken: json["fcm_token"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
        distance: json["distance"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "username": username,
        "phone_number": phoneNumber,
        "dob": dob!.toIso8601String(),
        "bio": bio,
        "language": language,
        "profile_image": profileImage,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "hometown": hometown,
        "status": status,
        "verify_video": verifyVideo,
        "is_verify": isVerify,
        "social_id": socialId,
        "social_type": socialType,
        "user_type": userType,
        "firebase_id": firebaseId,
        "fcm_token": fcmToken,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "deleted_at": deletedAt,
        "distance": distance,
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
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
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

class ImageData {
  String path;
  int id;
  ImageData({required this.path, required this.id});
}

class MediaData {
  String path;
  int id;
  bool isVideo;

  MediaData({required this.path, required this.id, required this.isVideo});
}
