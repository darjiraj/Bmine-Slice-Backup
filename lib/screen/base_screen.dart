import 'package:bmine_slice/Utils/user_status_service.dart';
import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  final Widget child;
  const BaseScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => UserStatusService().userActive(),
      onPanDown: (_) => UserStatusService().userActive(),
      child: child,
    );
  }
}
