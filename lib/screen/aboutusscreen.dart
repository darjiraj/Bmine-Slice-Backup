import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
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
                Languages.of(context)!.aboutustxt,
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
              RichText(
                text: TextSpan(
                    text: Languages.of(context)!.aboutscbminesimplenewwaytxt,
                    style: Appstyle.quicksand16w400,
                    children: [
                      TextSpan(
                          style: Appstyle.quicksand16w400,
                          text:
                              '\n\n${Languages.of(context)!.aboutscbminewayinteracttxt}')
                    ]),
              ),
              const SizedBox(height: 15),
              RichText(
                text: TextSpan(
                    text:
                        '${Languages.of(context)!.aboutscthereavailablelivetxt} ',
                    style: Appstyle.quicksand16w400,
                    children: [
                      TextSpan(
                        text: 'Bmine.ca',
                        style: Appstyle.quicksand16w500
                            .copyWith(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchUrl('https://bmine.ca/'),
                      ),
                      TextSpan(
                        style: Appstyle.quicksand16w400,
                        text:
                            '. ${Languages.of(context)!.aboutscsomeeventfreetxt}',
                      ),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    print("uri === $uri");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
