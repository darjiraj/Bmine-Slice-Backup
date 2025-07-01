import 'package:flutter/material.dart';

import '../Utils/appassets.dart';
import '../Utils/appstyle.dart';
import '../Utils/colorutils.dart';
import '../localization/language/languages.dart';
import 'base_screen.dart';

class RestorePurchaseScreen extends StatefulWidget {
  const RestorePurchaseScreen({super.key});

  @override
  State<RestorePurchaseScreen> createState() => _RestorePurchaseScreenState();
}

class _RestorePurchaseScreenState extends State<RestorePurchaseScreen> {
  @override
  Widget build(BuildContext context) {
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
                Languages.of(context)!.restorepurchasetxt,
                style: Appstyle.marcellusSC20w500
                    .copyWith(color: AppColors.blackclr),
              )
            ],
          ),
        ),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [],
          ),
        )),
      ),
    );
  }
}
