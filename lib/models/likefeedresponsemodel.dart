// To parse this JSON data, do
//
//     final likeFeedResponseModel = likeFeedResponseModelFromJson(jsonString);

import 'dart:convert';

LikeFeedResponseModel likeFeedResponseModelFromJson(String str) =>
    LikeFeedResponseModel.fromJson(json.decode(str));

String likeFeedResponseModelToJson(LikeFeedResponseModel data) =>
    json.encode(data.toJson());

class LikeFeedResponseModel {
  bool? success;
  List<LikeFeedData>? likeFeedData;
  // User? userGift;
  // UserMembership? userMembership;
  // User? userSwipe;
  // User? userVirtualMeetingReq;

  LikeFeedResponseModel({
    this.success,
    this.likeFeedData,
    // this.userGift,
    // this.userMembership,
    // this.userSwipe,
    // this.userVirtualMeetingReq,
  });

  factory LikeFeedResponseModel.fromJson(Map<String, dynamic> json) =>
      LikeFeedResponseModel(
        success: json["success"],
        likeFeedData: json["home_data"] == null
            ? []
            : List<LikeFeedData>.from(
                json["home_data"].map((x) => LikeFeedData.fromJson(x))),
        // userGift: json["user_gift"] == null
        //     ? User()
        //     : User.fromJson(json["user_gift"]),
        // userMembership: json["user_membership"] == null
        //     ? UserMembership()
        //     : UserMembership.fromJson(json["user_membership"]),
        // userSwipe: json["user_swipe"] == null
        //     ? User()
        //     : User.fromJson(json["user_swipe"]),
        // userVirtualMeetingReq: json["user_virtual_meeting_req"] == null
        //     ? User()
        //     : User.fromJson(json["user_virtual_meeting_req"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "home_data": List<dynamic>.from(likeFeedData!.map((x) => x.toJson())),
        // "user_gift": userGift!.toJson(),
        // "user_membership": userMembership!.toJson(),
        // "user_swipe": userSwipe!.toJson(),
        // "user_virtual_meeting_req": userVirtualMeetingReq!.toJson(),
      };
}

class LikeFeedData {
  int? id;
  String? firstName;
  String? lastName;
  int? userId;
  String? email;
  String? password;
  String? username;
  String? phoneNumber;
  DateTime? dob;
  String? bio;
  String? language;
  String? profileImage;
  String? work;
  String? education;
  String? gender;
  String? location;
  String? latitude;
  String? longitude;
  String? hometown;
  String? height;
  String? exercise;
  String? educationLevel;
  String? smoking;
  String? drinking;
  String? ethnicity;
  String? horoscope;
  String? haveKid;
  String? relationship;
  String? lookingFor;
  String? intrested;
  String? status;
  String? verifyVideo;
  int? isVerify;
  String? socialId;
  String? socialType;
  String? userType;
  String? firebaseId;
  String? fcmToken;
  int? freeSwipe;
  int? paidSwipe;
  int? suspend;
  DateTime? lastGiftSent;
  DateTime? createdAt;
  DateTime? lastUsedAt;
  DateTime? lastSwipe;
  DateTime? lastVirtualMeeting;
  DateTime? updatedAt;
  dynamic deletedAt;
  String? planName;
  double? distance;
  List<Post>? posts;
  LikeFeedData({
    required this.id,
    this.firstName,
    this.lastName,
    this.userId,
    this.email,
    this.password,
    this.username,
    this.phoneNumber,
    this.dob,
    this.bio,
    this.language,
    this.profileImage,
    this.work,
    this.education,
    this.gender,
    this.location,
    this.latitude,
    this.longitude,
    this.hometown,
    this.height,
    this.exercise,
    this.educationLevel,
    this.smoking,
    this.drinking,
    this.ethnicity,
    this.horoscope,
    this.haveKid,
    this.relationship,
    this.lookingFor,
    this.intrested,
    this.status,
    this.verifyVideo,
    this.isVerify,
    this.socialId,
    this.socialType,
    this.userType,
    this.firebaseId,
    this.fcmToken,
    this.freeSwipe,
    this.paidSwipe,
    this.suspend,
    this.lastGiftSent,
    this.createdAt,
    this.lastUsedAt,
    this.lastSwipe,
    this.lastVirtualMeeting,
    this.updatedAt,
    this.deletedAt,
    this.planName,
    this.distance,
    this.posts,
  });

  factory LikeFeedData.fromJson(Map<String, dynamic> json) => LikeFeedData(
        id: json["id"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        email: json["email"],
        password: json["password"],
        username: json["username"],
        userId: json["user_id"],
        phoneNumber: json["phone_number"],
        dob: json["dob"] == null ? null : DateTime.parse(json["dob"]),
        bio: json["bio"],
        language: json["language"],
        profileImage: json["profile_image"],
        work: json["work"],
        education: json["education"],
        gender: json["gender"],
        location: json["location"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        hometown: json["hometown"],
        height: json["height"],
        exercise: json["exercise"],
        educationLevel: json["education_level"],
        smoking: json["smoking"],
        drinking: json["drinking"],
        ethnicity: json["ethnicity"],
        horoscope: json["horoscope"],
        haveKid: json["have_kid"],
        relationship: json["relationship"],
        lookingFor: json["looking_for"],
        intrested: json["intrested"],
        status: json["status"],
        verifyVideo: json["verify_video"],
        isVerify: json["is_verify"],
        socialId: json["social_id"],
        socialType: json["social_type"],
        userType: json["user_type"],
        firebaseId: json["firebase_id"],
        fcmToken: json["fcm_token"],
        freeSwipe: json["free_swipe"],
        paidSwipe: json["paid_swipe"],
        suspend: json["suspend"],
        lastGiftSent: json["last_gift_sent"] == null
            ? null
            : DateTime.parse(json["last_gift_sent"]),
        createdAt: DateTime.parse(json["created_at"]),
        lastUsedAt: DateTime.parse(json["last_used_at"]),
        lastSwipe: DateTime.parse(json["last_swipe"]),
        lastVirtualMeeting: DateTime.parse(json["last_virtual_meeting"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
        planName: json["plan_name"],
        distance: json["distance"] == null ? 0 : json["distance"].toDouble(),
        posts: json["posts"] == null
            ? []
            : List<Post>.from(json["posts"].map((x) => Post.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "first_name": firstName,
        "last_name": lastName,
        "user_id": userId,
        "email": email,
        "password": password,
        "username": username,
        "phone_number": phoneNumber,
        "dob": dob?.toIso8601String(),
        "bio": bio,
        "language": language,
        "profile_image": profileImage,
        "work": work,
        "education": education,
        "gender": gender,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "hometown": hometown,
        "height": height,
        "exercise": exercise,
        "education_level": educationLevel,
        "smoking": smoking,
        "drinking": drinking,
        "ethnicity": ethnicity,
        "horoscope": horoscope,
        "have_kid": haveKid,
        "relationship": relationship,
        "looking_for": lookingFor,
        "intrested": intrested,
        "status": status,
        "verify_video": verifyVideo,
        "is_verify": isVerify,
        "social_id": socialId,
        "social_type": socialType,
        "user_type": userType,
        "firebase_id": firebaseId,
        "fcm_token": fcmToken,
        "free_swipe": freeSwipe,
        "paid_swipe": paidSwipe,
        "suspend": suspend,
        "last_gift_sent": lastGiftSent?.toIso8601String(),
        "created_at": createdAt?.toIso8601String(),
        "last_used_at": lastUsedAt?.toIso8601String(),
        "last_swipe": lastSwipe?.toIso8601String(),
        "last_virtual_meeting": lastVirtualMeeting?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "deleted_at": deletedAt,
        "plan_name": planName,
        "distance": distance,
        "posts": List<dynamic>.from(posts!.map((x) => x.toJson())),
      };
}

class Post {
  int? id;
  int? userId;
  String? images;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;

  Post({
    this.id,
    this.userId,
    this.images,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json["id"],
        userId: json["user_id"],
        images: json["images"],
        createdAt:
            json["dob"] != null ? DateTime.parse(json["created_at"]) : null,
        updatedAt:
            json["dob"] != null ? DateTime.parse(json["updated_at"]) : null,
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "images": images,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "deleted_at": deletedAt,
      };
}

class User {
  int? id;
  int? userId;
  String? count;
  String? total;
  String? paymentId;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;

  User({
    this.id,
    this.userId,
    this.count,
    this.total,
    this.paymentId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        userId: json["user_id"],
        count: json["count"],
        total: json["total"],
        paymentId: json["payment_id"],
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
        "count": count,
        "total": total,
        "payment_id": paymentId,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "deleted_at": deletedAt,
      };
}

class UserMembership {
  int? id;
  int? userId;
  String? planId;
  String? planName;
  String? price;
  dynamic startDate;
  dynamic endDate;
  dynamic duration;
  dynamic createdAt;
  dynamic updatedAt;
  dynamic deletedAt;

  UserMembership({
    this.id,
    this.userId,
    this.planId,
    this.planName,
    this.price,
    this.startDate,
    this.endDate,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory UserMembership.fromJson(Map<String, dynamic> json) => UserMembership(
        id: json["id"],
        userId: json["user_id"],
        planId: json["plan_id"],
        planName: json["plan_name"],
        price: json["price"],
        startDate: json["start_date"],
        endDate: json["end_date"],
        duration: json["duration"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "plan_id": planId,
        "plan_name": planName,
        "price": price,
        "start_date": startDate,
        "end_date": endDate,
        "duration": duration,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "deleted_at": deletedAt,
      };
}
