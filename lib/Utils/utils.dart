import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/main.dart';
import 'package:bmine_slice/screen/bottemnavbar.dart';
import 'package:bmine_slice/screen/chatscreen.dart';
import 'package:bmine_slice/screen/giftscreen.dart';
import 'package:bmine_slice/screen/login.dart';
import 'package:bmine_slice/screen/subscriptionscreen.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

openScreenFromNotitification(Map data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLogin = prefs.getBool("isLogin") ?? false;
  if (isLogin == true) {
    if (data['data']['type'] == "meeting_request") {
      isMessageTab = 1;
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => BottomNavBar(
                index: 3,
              )));
    } else if (data['data']['type'] == "match") {
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => ChatScreen(
              oppId: data['data']['sender_firebase_id'],
              frdId: data['data']['sender_id'])));
    } else if (data['data']['type'] == "low_on_profile") {
      navigatorKey.currentState
          ?.push(MaterialPageRoute(builder: (_) => BottomNavBar(index: 4)));
    } else if (data['data']['type'] == "low_on_gift") {
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => GiftScreen(
                frd_id: "",
                isSettingScreen: true,
              )));
    } else if (data['data']['type'] == "no_more_likes") {
      navigatorKey.currentState
          ?.push(MaterialPageRoute(builder: (_) => SubscriptionScreen()));
    } else if (data['data']['type'] == "virtual_meeting_reminder") {
      isMessageTab = 1;
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => BottomNavBar(
                index: 3,
              )));
    } else if (data['data']['type'] == "live_event_reminder") {
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => BottomNavBar(
                index: 2,
              )));
    } else {
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => BottomNavBar(
                index: 0,
              )));
    }
  } else {
    navigatorKey.currentState
        ?.push(MaterialPageRoute(builder: (_) => LoginScreen()));
  }
}

bool isVideoUrl(String url) {
  final ext = url.toLowerCase();
  return ext.endsWith('.mp4') ||
      ext.endsWith('.mov') ||
      ext.endsWith('.avi') ||
      ext.endsWith('.mkv') ||
      ext.endsWith('.3gp') ||
      ext.endsWith('.webm') ||
      ext.endsWith('.flv') ||
      ext.endsWith('.wmv') ||
      ext.endsWith('.mpeg') ||
      ext.endsWith('.mpg') ||
      ext.endsWith('.m4v');
}

int isMessageTab = 0;

Future showShareOptions(BuildContext context, String username, String name) {
  //https://bminedating.com/profile/testuser
  final String profileUrl = '${API.baseUrl}/profile/$username';
  return showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext builder) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('Show QR Code'),
                onTap: () {
                  Navigator.pop(context);
                  _showQrCode(context, username, name);
                },
              ),
              ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share Profile Link'),
                  onTap: () {
                    Share.share(
                      'Check out $name\'s profile on BMine: $profileUrl',
                    );
                    Navigator.pop(context);
                  }),
            ],
          ),
        );
      });
}

void _showQrCode(
  BuildContext context,
  String username,
  String name,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Container(
              height: (MediaQuery.sizeOf(context).height * 25) / 100,
              width: (MediaQuery.sizeOf(context).height * 25) / 100,
              child: QrImageView(
                data: "${API.baseUrl}/profile/${username}",
                version: QrVersions.auto,
                size: (MediaQuery.sizeOf(context).height * 25) / 100,
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(Languages.of(context)!.scan_to_view_profile,
                style: Appstyle.quicksand16w500.copyWith(color: Colors.black)),
            SizedBox(height: 8),
            SelectableText("${API.baseUrl}/profile/${username}",
                style: Appstyle.quicksand12w500.copyWith(color: Colors.black)),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                height: 45,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[AppColors.signinclr1, AppColors.signinclr2],
                  ),
                ),
                child: Center(
                    child: Text("Close", style: Appstyle.quicksand16w500)),
              ),
            ),
            // Container(
            //   height: (MediaQuery.sizeOf(context).height * 40) / 100,
            //   width: MediaQuery.sizeOf(context).width,
            //   child: ProfileShareWidget(username: username),
            // ),
          ],
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () => Navigator.pop(context),
        //     child: const Text('Close'),
        //   ),
        // ],
      );
    },
  );
}
