// ignore: depend_on_referenced_packages
import 'package:bmine_slice/Utils/DeepLinkHandler.dart';
import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/utils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/main.dart';
import 'package:bmine_slice/models/meetingrequestresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/likescreen.dart';
import 'package:bmine_slice/screen/home.dart';
import 'package:bmine_slice/screen/liveeventscreen.dart';
import 'package:bmine_slice/screen/myprofilescreen.dart';
import 'package:bmine_slice/viewmodels/meetingviewmodel.dart';
import 'package:bmine_slice/viewmodels/signupviewmodel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'messagesscreen.dart';

class BottomNavBar extends StatefulWidget {
  int? index;
  BottomNavBar({super.key, this.index});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with WidgetsBindingObserver {
  
  int pageIndex = 0;
  int matchcount = 0;
  int meetingcount = 0;

  List<Widget> pageList = <Widget>[
    const HomeScreen(),
    const LikeScreen(),
    const LiveEventsList(),
    const MessageScreen(),
    MyProfileScreen(
      isScreen: "My-Profile",
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      pageIndex = index;
    });
    if (pageIndex == 3) {
      isMessageTab = 0;
    }
    getCallAPI();
  }

  getCallAPI() async {
    await getchannellist();
    await getMeetingRequestAPI();
  }

 

  @override
  void initState() {
    super.initState();
  
    gefcmToken();
    getCallAPI();
    WidgetsBinding.instance.addObserver(this);
    if (widget.index != null) {
      pageIndex = widget.index!;
      getCallAPI();
    }
  }

  gefcmToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String fcmToken = await FirebaseMessaging.instance.getToken() ?? "";
    String firebaseId = pref.getString("firebaseId") ?? "";

    await updateFirebaseId(firebaseId, fcmToken);
  }

  updateFirebaseId(
    String firebase_id,
    String fcm_token,
  ) async {
    print("firebase_id = $firebase_id && fcm_token = $fcm_token");
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<SignUpViewModel>(context, listen: false)
            .updateFirebaseId(userid, firebase_id, fcm_token);
        if (Provider.of<SignUpViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<SignUpViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              // kToast(model.message!);
            });
          }
        } else {
          setState(() {});
          showToast(Languages.of(context)!.nointernettxt);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Set<String> unreadUsersSet = {};
  String firebaseId = "";
  List<Map<dynamic, dynamic>> usersList = [];
  List<Map<dynamic, dynamic>> tmpsearchusersList = [];
  List<Map<dynamic, dynamic>> userunreadCountlist = [];

  getchannellist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firebaseId = prefs.getString('firebaseId') ?? "";
    });

    DatabaseReference ref = FirebaseDatabase.instance.ref('message');

    usersList.clear();
    tmpsearchusersList.clear();
    unreadUsersSet.clear(); // Clear previous unread users

    ref.once().then((event) async {
      var temp = event.snapshot.value;

      Map<dynamic, dynamic> allChanels = temp as Map<dynamic, dynamic>;
      String cleanFirebaseId = firebaseId.replaceFirst('-', '');

      for (var entry in allChanels.entries) {
        String key = entry.key;
        var value = entry.value;

        List<String> parts = key.split('--');
        if (parts.length < 3) continue;

        String part1 = parts[1];
        String part2 = parts[2];

        if (part1 == cleanFirebaseId || part2 == cleanFirebaseId) {
          DatabaseReference userListRef = FirebaseDatabase.instance
              .ref()
              .child('users')
              .child('-${key.split('--')[1]}');

          await userListRef.once().then((snapshot) {
            Map<dynamic, dynamic> userData =
                snapshot.snapshot.value as Map<dynamic, dynamic>;

            Map<dynamic, dynamic> messages = value as Map<dynamic, dynamic>;
            if (messages.isNotEmpty) {
              int unreadCount = messages.values
                  .where((message) =>
                      message['idTo'] != null &&
                      firebaseId.contains(message['idTo']) &&
                      !(message['isSeen'] ?? false))
                  .length;

              if (unreadCount > 0) {
                unreadUsersSet.add(userData['id']);
                userData['isSeen'] = unreadCount;
                usersList.add(userData);
                tmpsearchusersList.add(userData);
              }
            }
          });
        }
      }

      setState(() {
        matchcount = unreadUsersSet.length;
        API.messageunreadcount = matchcount + meetingcount;
      });
    });

    ref.onValue.listen((DatabaseEvent event) {
      var temp = event.snapshot.value;
      Map<dynamic, dynamic> allChanels = temp as Map<dynamic, dynamic>;
      String cleanFirebaseId = firebaseId.replaceFirst('-', '');

      allChanels.forEach((key, value) async {
        List<String> parts = key.split('--');

        if (parts.length < 3) return;

        String part1 = parts[1];
        String part2 = parts[2];

        if (part1 == cleanFirebaseId || part2 == cleanFirebaseId) {
          DatabaseReference userListRef = FirebaseDatabase.instance
              .ref()
              .child('users')
              .child('-${key.split('--')[1]}');

          await userListRef.once().then((snapshot) {
            Map<dynamic, dynamic> userData =
                snapshot.snapshot.value as Map<dynamic, dynamic>;

            Map<dynamic, dynamic> messages = value as Map<dynamic, dynamic>;
            if (messages.isNotEmpty) {
              int unreadCount = messages.values
                  .where((message) =>
                      message['idTo'] != null &&
                      firebaseId.contains(message['idTo']) &&
                      !(message['isSeen'] ?? false))
                  .length;

              if (unreadCount > 0) {
                unreadUsersSet.add(userData['id']);
              } else {
                unreadUsersSet.remove(userData['id']);
              }
            }
            setState(() {});
          });
        }
      });
    });
  }

  MeetingRequestResponseModel meetingRequestResponseModel =
      MeetingRequestResponseModel();
  bool isLoading = false;
  String userid = "";

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
  }

  getMeetingRequestAPI() async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<MeetingViewModel>(context, listen: false)
            .getMeetingRequest(userid);
        if (Provider.of<MeetingViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<MeetingViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              meetingRequestResponseModel =
                  Provider.of<MeetingViewModel>(context, listen: false)
                      .meetingtrequestresponse
                      .response as MeetingRequestResponseModel;
              meetingcount = meetingRequestResponseModel.requestMeeting!.length;

              API.messageunreadcount = matchcount + meetingcount;
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

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: pageList[pageIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
            backgroundColor: AppColors.whiteclr,
            landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
            elevation: 0,
            iconSize: 30,
            selectedItemColor: AppColors.blueclr,
            unselectedItemColor: AppColors.borgergreyclr,
            selectedLabelStyle: Appstyle.quicksand12w600.copyWith(height: 2.2),
            unselectedLabelStyle:
                Appstyle.quicksand12w600.copyWith(height: 2.2),
            currentIndex: pageIndex,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  AppAssets.activehomeicon,
                  color: AppColors.borgergreyclr,
                  height: 30,
                ),
                activeIcon: Image.asset(
                  AppAssets.activehomeicon,
                  height: 30,
                ),
                label: Languages.of(context)!.hometxt,
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  AppAssets.activelikeicon,
                  height: 30,
                  color: AppColors.borgergreyclr,
                ),
                activeIcon: Image.asset(
                  AppAssets.activelikeicon,
                  height: 30,
                ),
                label: Languages.of(context)!.likestxt,
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  AppAssets.activecaladericon,
                  height: 30,
                  color: AppColors.borgergreyclr,
                ),
                activeIcon: Image.asset(
                  AppAssets.activecaladericon,
                  height: 30,
                ),
                label: Languages.of(context)!.liveeventsnavtxt,
              ),
              BottomNavigationBarItem(
                icon: API.messageunreadcount > 0
                    ? badges.Badge(
                        badgeAnimation: const badges.BadgeAnimation.rotation(),
                        badgeContent: Text(
                          API.messageunreadcount.toString(),
                          style: Appstyle.quicksand13w600
                              .copyWith(color: Colors.white),
                        ),
                        position:
                            badges.BadgePosition.custom(start: 15, bottom: 10),
                        child: Image.asset(
                          AppAssets.activemassageicon,
                          height: 30,
                          color: AppColors.borgergreyclr,
                        ),
                      )
                    : Image.asset(
                        AppAssets.activemassageicon,
                        height: 30,
                        color: AppColors.borgergreyclr,
                      ),
                activeIcon: API.messageunreadcount > 0
                    ? badges.Badge(
                        badgeAnimation: const badges.BadgeAnimation.rotation(),
                        badgeContent: Text(
                          API.messageunreadcount.toString(),
                          style: Appstyle.quicksand13w600
                              .copyWith(color: Colors.white),
                        ),
                        position:
                            badges.BadgePosition.custom(start: 15, bottom: 10),
                        child: Image.asset(
                          AppAssets.activemassageicon,
                          height: 30,
                        ),
                      )
                    : Image.asset(
                        AppAssets.activemassageicon,
                        height: 30,
                      ),
                label: Languages.of(context)!.chatstxt,
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  AppAssets.activeprofileicon,
                  height: 30,
                  color: AppColors.borgergreyclr,
                ),
                activeIcon: Image.asset(
                  AppAssets.activeprofileicon,
                  height: 30,
                ),
                label: Languages.of(context)!.profilenavtxt,
              ),
            ]),
      ),
    );
  }
}
