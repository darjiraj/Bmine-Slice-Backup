import 'package:flutter/material.dart';
import 'user_status_service.dart';

class UserActivityObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    UserStatusService().userActive();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    UserStatusService().userActive();
  }
}
