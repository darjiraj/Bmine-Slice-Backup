import 'package:app_links/app_links.dart';
import 'package:bmine_slice/screen/bottemnavbar.dart';
import 'package:bmine_slice/screen/home.dart';
import 'package:bmine_slice/screen/myprofilescreen.dart';
import 'package:flutter/material.dart';

class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  bool isFromDeeplink = false;
  final GlobalKey<NavigatorState> navigatorKey;
  DeepLinkHandler({required this.navigatorKey});

  Future<void> initDeepLinks() async {
// Handle deep link when app is started
    // final appLink = await _appLinks.getInitialAppLink();
    final appLink = await _appLinks.getInitialLink();
    if (appLink != null) {
      _handleDeepLink(appLink);
    }
// Handle deep link when app is already running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
// Parse the URI
    print("_handleDeepLink - uri $uri");
    List<String> segments = uri.pathSegments;
// Handle profile deep links
    if (segments.length >= 2 && segments[0] == 'profile') {
      String username = segments[1];
      if (username == "home") {
        navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (_) => BottomNavBar(
                  index: 0,
                )));
      } else {
        _navigateToProfile(username);
      }
    } else if (segments.length >= 2 && segments[0] == 'home') {
      print("_handleDeepLink - home");

      // navigatorKey.currentState?.push(MaterialPageRoute(
      //     builder: (_) => BottomNavBar(
      //           index: 0,
      //         )));
    }
// Handle other deep links if needed
  }

  void _navigateToProfile(String username) {
// Navigate to profile page
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => MyProfileScreen(
          isScreen: "Friend-Profile",
          frdId: username,
        ),
      ),
    );
  }
}
