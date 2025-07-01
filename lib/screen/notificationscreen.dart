import 'dart:ui';

import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/utils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/clearnotificationresponsemodel.dart';
import 'package:bmine_slice/models/commonresponsemodel.dart';
import 'package:bmine_slice/models/notificationresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/bottemnavbar.dart';
import 'package:bmine_slice/screen/chatscreen.dart';
import 'package:bmine_slice/screen/giftscreen.dart';
import 'package:bmine_slice/screen/myprofilescreen.dart';
import 'package:bmine_slice/screen/subscriptionscreen.dart';
import 'package:bmine_slice/viewmodels/notificationsviewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String userid = "";
  bool isLoading = false;

  bool isDeleteLoading = false;
  List<NotificationDatum> notificationsData = [];

  @override
  void initState() {
    super.initState();
    getNotificationsData();
  }

  @override
  Widget build(BuildContext context) {
    var kSize = MediaQuery.of(context).size;

    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppColors.whiteclr,
        appBar: AppBar(
          backgroundColor: AppColors.whiteclr,
          surfaceTintColor: AppColors.whiteclr,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2.0),
            child: Container(
              color: AppColors.textfieldclr,
              height: 1.0,
            ),
          ),
          title: Row(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      AppAssets.backarraowicon,
                      height: 24,
                      width: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    Languages.of(context)!.notificationtxt,
                    style: Appstyle.marcellusSC20w500
                        .copyWith(color: AppColors.blackclr),
                  )
                ],
              ),
              Spacer(),
              InkWell(
                onTap: () async {
                  if (notificationsData.isEmpty) {
                    showToast(Languages.of(context)!.dataalreadyclearedtxt);
                  } else {
                    _showClearListAlertDialog();
                  }
                },
                child: Text(Languages.of(context)!.clearlisttxt,
                    style:
                        Appstyle.quicksand16w600.copyWith(color: Colors.red)),
              ),
            ],
          ),
        ),
        body: isLoading
            ? SizedBox(
                height: kSize.height,
                width: kSize.width,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.bminetxtclr,
                  ),
                ),
              )
            : notificationsData.isEmpty
                ? SizedBox(
                    height: kSize.height,
                    width: kSize.width,
                    child: Center(
                      child: Text(
                        Languages.of(context)!.nodatafoundtxt,
                        style: Appstyle.quicksand16w500
                            .copyWith(color: AppColors.blackclr),
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      RefreshIndicator(
                        color: AppColors.bminetxtclr,
                        onRefresh: () async => await getNotificationsData(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: notificationsData.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final notification = notificationsData[index];
                            return Dismissible(
                              key: Key(notification.id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerRight,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                bool shouldDelete =
                                    await _showDeleteConfirmation(
                                        notification.id.toString(), index);
                                if (shouldDelete) {
                                  setState(() {
                                    notificationsData.removeAt(index);
                                  });
                                  return true;
                                }
                                return false;
                              },
                              child: InkWell(
                                onTap: () async {
                                  if (notification.type == "miss_you_swipe") {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              BottomNavBar(index: 0)),
                                      (Route<dynamic> route) => false,
                                    );
                                  } else if (notification.type ==
                                      "meeting_request") {
                                    isMessageTab = 1;
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              BottomNavBar(index: 3)),
                                      (Route<dynamic> route) => false,
                                    );
                                  } else if (notification.type ==
                                      "no_more_likes") {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              SubscriptionScreen()),
                                    );
                                  } else if (notification.type ==
                                      "low_on_gift") {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) => GiftScreen(
                                                frd_id: "",
                                                isSettingScreen: true,
                                              )),
                                    );
                                  } else if (notification.type ==
                                      "low_on_profile") {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              BottomNavBar(index: 4)),
                                      (Route<dynamic> route) => false,
                                    );
                                  } else if (notification.type == "match") {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                              oppId: notification.firebase_id
                                                  .toString(),
                                              frdId: notification.userId
                                                  .toString())),
                                    );
                                  } else {
                                    if (notification.userId.toString() ==
                                        userid) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                BottomNavBar(index: 4)),
                                        (Route<dynamic> route) => false,
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MyProfileScreen(
                                            isScreen: "Friend-Profile",
                                            frdId:
                                                notification.userId.toString(),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  margin: index == 0
                                      ? EdgeInsets.zero
                                      : const EdgeInsets.only(top: 3),
                                  color: notification.isRead == 1
                                      ? AppColors.whiteclr
                                      : AppColors.lightgreycolor2,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 25),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        maxRadius: 25,
                                        backgroundImage: notification.profileImg !=
                                                    null &&
                                                notification
                                                    .profileImg!.isNotEmpty
                                            ? NetworkImage(
                                                "${API.baseUrl}/upload/${notification.profileImg}")
                                            : AssetImage(AppAssets.femaleUser)
                                                as ImageProvider,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        "${notification.firstname ?? ""} ",
                                                    style: Appstyle
                                                        .quicksand16w600
                                                        .copyWith(
                                                            color: AppColors
                                                                .blackclr),
                                                  ),
                                                  if (notification.lastname !=
                                                          null &&
                                                      notification
                                                          .lastname!.isNotEmpty)
                                                    TextSpan(
                                                      text:
                                                          "${notification.lastname![0]} ",
                                                      style: Appstyle
                                                          .quicksand16w600
                                                          .copyWith(
                                                              color: AppColors
                                                                  .blackclr),
                                                    ),
                                                  TextSpan(
                                                    text:
                                                        notification.message ??
                                                            "",
                                                    style: Appstyle
                                                        .quicksand16w500
                                                        .copyWith(
                                                            color: AppColors
                                                                .blackclr),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (notification.createdAt != null)
                                              Text(
                                                // notification.createdAt
                                                //     .toString(),
                                                DateFormat(
                                                        'EEE, d MMM \'at\' hh:mm a')
                                                    .format(notification
                                                        .createdAt!
                                                        .toLocal()),
                                                style: Appstyle.quicksand13w400
                                                    .copyWith(
                                                        color: AppColors
                                                            .timetxtgrey),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (isDeleteLoading)
                        Container(
                          height: kSize.height,
                          width: kSize.width,
                          color: Colors.black.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.bminetxtclr,
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  void _showClearListAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: StatefulBuilder(builder: (context, setAState) {
            return AlertDialog(
              actionsAlignment: MainAxisAlignment.start,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              backgroundColor: AppColors.whiteclr,
              alignment: Alignment.center,
              contentPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.only(left: 10, right: 10),
              actions: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 25,
                      ),
                      Center(
                        child: Text(
                          Languages.of(context)!.clearlistalerttxt,
                          textAlign: TextAlign.center,
                          style: Appstyle.quicksand14w600
                              .copyWith(color: AppColors.blackclr),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await clearNotificationAPI();
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: 40,
                                // width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      AppColors.signinclr1,
                                      AppColors.signinclr2
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    Languages.of(context)!.clearlisttxt,
                                    style: Appstyle.quicksand14w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: 40,
                                // width: 100,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: AppColors.cancelbtnclr),
                                child: Center(
                                  child: Text(
                                    Languages.of(context)!.canceltxt,
                                    style: Appstyle.quicksand14w500
                                        .copyWith(color: AppColors.blackclr),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            );
          }),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(String notificationId, int index) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.whiteclr,
              surfaceTintColor: AppColors.whiteclr,
              title: Text(
                Languages.of(context)!.deletenotificationtxt,
                style: Appstyle.quicksand20w600
                    .copyWith(color: AppColors.blackclr),
              ),
              content: Text(
                Languages.of(context)!.deletenotificationalrtmsgtxt,
                style: Appstyle.quicksand18w500
                    .copyWith(color: AppColors.blackclr),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    Languages.of(context)!.canceltxt,
                    style: Appstyle.quicksand19w500
                        .copyWith(color: AppColors.blackclr),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await deleteNotificationAPI(notificationId, index);
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    Languages.of(context)!.deletetxt,
                    style: Appstyle.quicksand19w500.copyWith(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
  }

  getNotificationsData() async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<NotificationsViewModel>(context, listen: false)
            .getNotifications(
          userid,
        );
        if (Provider.of<NotificationsViewModel>(context, listen: false)
                .isLoading ==
            false) {
          if (Provider.of<NotificationsViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              NotificationResponseModel notificationResponseModel =
                  Provider.of<NotificationsViewModel>(context, listen: false)
                      .notificationsresponse
                      .response as NotificationResponseModel;
              notificationsData = notificationResponseModel.data ?? [];
            });
          }
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  deleteNotificationAPI(String notificationId, int index) async {
    print("deleteNotificationAPI function call");
    setState(() {
      isDeleteLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<NotificationsViewModel>(context, listen: false)
            .deleteNotification(notificationId);
        if (Provider.of<NotificationsViewModel>(context, listen: false)
                .isLoading ==
            false) {
          if (Provider.of<NotificationsViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            CommonResponseModel commonResponseModel = CommonResponseModel();
            setState(() {
              isDeleteLoading = false;
              print("Success");
              commonResponseModel =
                  Provider.of<NotificationsViewModel>(context, listen: false)
                      .deletednotificationsresponse
                      .response as CommonResponseModel;
            });
            showToast(commonResponseModel.message ?? "");
          } else {
            setState(() {
              isDeleteLoading = false;
            });
            showToast(
                Provider.of<NotificationsViewModel>(context, listen: false)
                    .deletednotificationsresponse
                    .msg
                    .toString());
          }
        }
      } else {
        setState(() {
          isDeleteLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  clearNotificationAPI() async {
    print("clearNotificationAPI function call");
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<NotificationsViewModel>(context, listen: false)
            .clearNotification(userid);
        if (Provider.of<NotificationsViewModel>(context, listen: false)
                .isLoading ==
            false) {
          if (Provider.of<NotificationsViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            ClearNotificationResponseModel clearNotificationResponseModel =
                ClearNotificationResponseModel();
            setState(() {
              print("Success");
              clearNotificationResponseModel =
                  Provider.of<NotificationsViewModel>(context, listen: false)
                      .clearnotificationsresponse
                      .response as ClearNotificationResponseModel;
              isLoading = false;
            });
            showToast(clearNotificationResponseModel.message ?? "");

            await getNotificationsData();
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(
                Provider.of<NotificationsViewModel>(context, listen: false)
                    .clearnotificationsresponse
                    .msg
                    .toString());
          }
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }
}
