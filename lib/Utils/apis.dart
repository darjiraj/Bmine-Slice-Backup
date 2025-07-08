class API {
  // static String baseUrl = "http/://192.168.1.61:5000";
  // static String baseUrl = "http/://192.168.1.51:5000";
  // static String baseUrl = "http://192.168.1.37:5000";

  // static String baseUrl = "http://34.238.246.50:6001";
  static String baseUrl = "https://bminedating.com";
  // static String baseUrl = "http://35.173.211.225:6001";

  static String dosignup = "$baseUrl/api/signup";
  static String dologin = "$baseUrl/api/login";
  static String forgotpassword = "$baseUrl/api/forgot-password";
  static String checkAccountExist = "$baseUrl/api/social-account-exist";
  static String getProfile = "$baseUrl/api/get-profile/";
  static String updateProfile = "$baseUrl/api/update-profile/";
  static String updateFirebaseData = "$baseUrl/api/update-firebase-data/";
  static String getHomeFeedData = "$baseUrl/api/get-home-feed-data/";
  static String userLikeFeedData = "$baseUrl/api/user-like-feed-data/";
  static String userLiveEventFeedData =
      "$baseUrl/api/user-live-event-feed-data/";
  static String getEvents = "$baseUrl/api/get-events";
  static String getEventDetails = "$baseUrl/api/get-event-details/";
  static String userLike = "$baseUrl/api/user-like/";
  static String addLocation = "$baseUrl/api/add-location/";
  static String updateProfilePosts = "$baseUrl/api/update-profile-posts/";
  static String updatePostsSeq = "$baseUrl/api/update-posts-seq/";
  static String deleteUserPostsImage = "$baseUrl/api/delete-user-posts-image/";
  static String sendMeetingRequest = "$baseUrl/api/send-meeting-request";
  static String getMeetingRequest = "$baseUrl/api/get-meeting-request/";
  static String acceptMeetingRequest = "$baseUrl/api/accept-meeting-request";
  static String deleteMeetingRequest = "$baseUrl/api/delete-meeting-request";
  static String getMeetingCallId = "$baseUrl/api/get-meeting-call-id/";
  static String joinEvent = "$baseUrl/api/join-event";
  static String withdrawEvent = "$baseUrl/api/withdraw-event";
  static String pendingCall = "$baseUrl/api/get-pending-call-events/";
  static String joinEventCall = "$baseUrl/api/join-call-event";
  static String alreadyjoinEventCall =
      "$baseUrl/api/already-event-call-available";
  static String updatejoinEventCallId = "$baseUrl/api/update-join-call-id";
  static String updateEventCallStatus = "$baseUrl/api/update-join-call-data";
  static String getNotifications = "$baseUrl/api/get-notification/";
  static String buyMembership = "$baseUrl/api/buy-membership";
  static String buySwipes = "$baseUrl/api/buy-swipe";
  static String buyGifts = "$baseUrl/api/buy-gift";
  static String buyLiveEventTickets = "$baseUrl/api/buy-live-event-ticket";
  static String buyVirtualMeetingRequests =
      "$baseUrl/api/buy-virtual-meeting-request";
  static String reportUser = "$baseUrl/api/report-user";
  static String uploadverifyvideos = "$baseUrl/api/upload-verify-videos";
  static String updateVirtualMeetingCount =
      "$baseUrl/api/update-virtual-meeting-count";
  static String updateswipesCount = "$baseUrl/api/update-swipe-count";
  static String purchaseDetails = "$baseUrl/api/get-purchase-details/";
  static String sendGifts = "$baseUrl/api/send-gift";
  static String deleteUser = "$baseUrl/api/delete-user/";
  static String termsandconditionurl = "$baseUrl/admin/terms-condition/";
  static String getswipecount = "$baseUrl/api/get-swipe-count/";
  static String deletenotification = "$baseUrl/api/delete-notification/";
  static String sendnotification = "$baseUrl/api/send-push";
  static String contactUs = "$baseUrl/api/contact/";
  static String blockUser = "$baseUrl/api/user-block";
  static String removeUser = "$baseUrl/api/user-like-remove";
  static String getblockUser = "$baseUrl/api/get-blocked-users/";
  static String getallblockUser = "$baseUrl/api/get-blocked-users-all/";
  static String removeAllLikeUser = "$baseUrl/api/user-like-remove-all";
  static String userUnmatch = "$baseUrl/api/user-unmatch";
  static String clearnotification = "$baseUrl/api/clear-notification/";

  static int messageunreadcount = 0;
}
