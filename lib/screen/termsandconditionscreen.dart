import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:flutter/material.dart';

class TermsandConditionsScreen extends StatefulWidget {
  const TermsandConditionsScreen({super.key});

  @override
  State<TermsandConditionsScreen> createState() =>
      _TermsandConditionsScreenState();
}

class _TermsandConditionsScreenState extends State<TermsandConditionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                onTap: () {
                  Navigator.pop(context);
                },
                child: Image.asset(
                  AppAssets.backarraowicon,
                  height: 24,
                  width: 24,
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              Text(
                Languages.of(context)!.termsconditionstxt,
                style: Appstyle.marcellusSC20w500
                    .copyWith(color: AppColors.blackclr),
              )
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Languages.of(context)!.termsdatingprivacypolicytxt,
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.termsatbminesecuritytxt,
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.termsweadviseyoutxt,
                style:
                    Appstyle.quicksand16w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termsrequestmoneyordonationtxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termspicturesthatlooktxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termsitssimplesomeonetxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termsifanyoneistryingtxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termsifsomeoneisaskingtxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termsnevereverevergivetxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termsharassmentinappropriatetxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termsalwaysprotectyourtxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termsalwaysmeetpublicplacetxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                '● ${Languages.of(context)!.termsneverevereverevermeettxt}',
                style: Appstyle.quicksand16w400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
