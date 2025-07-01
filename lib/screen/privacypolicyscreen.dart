import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
                Languages.of(context)!.privacypolicytxt,
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
                  text: '${Languages.of(context)!.privacyattxt} ',
                  style: Appstyle.quicksand16w400,
                  children: [
                    TextSpan(
                      text: 'bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      text: ', ${Languages.of(context)!.privacyaccessibletxt} ',
                      style: Appstyle.quicksand16w400,
                    ),
                    TextSpan(
                      text: 'https://bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      text: ', ${Languages.of(context)!.privacyoneofourmaintxt} ',
                      style: Appstyle.quicksand16w400,
                    ),
                    TextSpan(
                      text: 'bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      text: ' ${Languages.of(context)!.privacyandhowweuseittxt}',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.privacyifyouhaveadditionaltxt,
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: "${Languages.of(context)!.privacythisprivacypolicytxt} ",
                  style: Appstyle.quicksand16w400,
                  children: [
                    TextSpan(
                      text: 'bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      text:
                          ' ${Languages.of(context)!.privacythispolicyisnottxt} ',
                      style: Appstyle.quicksand16w400,
                    ),
                    TextSpan(
                      text: Languages.of(context)!.privacypolicygeneratortxt,
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl(
                            'https://www.privacypolicygenerator.info/'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacyconsenttxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              Text(
                Languages.of(context)!.privacybyusingourwebsitetxt,
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacyinformationwecollecttxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              Text(
                Languages.of(context)!.privacythepersonalinformationtxt,
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.privacyifyouconactustxt,
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.privacywhenyouregisterfortxt,
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacyhowweuseyourtxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              Text(
                Languages.of(context)!.privacyweusetheinformationwecollecttxt,
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 5),
              Text(
                '● ${Languages.of(context)!.privacyprovideoperateandmaintaintxt}\n'
                '● ${Languages.of(context)!.privacyimprovepersonalizetxt}\n'
                '● ${Languages.of(context)!.privacyunderstandandanalyzetxt}\n'
                '● ${Languages.of(context)!.privacydevelopnewproductstxt}\n'
                '● ${Languages.of(context)!.privacycommunicatewithyoutxt}\n'
                '● ${Languages.of(context)!.privacysendyouemailtxt}\n'
                '● ${Languages.of(context)!.privacyfindandpreventfraudtxt}',
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacylogfilestxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  text: '',
                  style: Appstyle.quicksand16w400,
                  children: [
                    TextSpan(
                      text: 'bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      style: Appstyle.quicksand16w400,
                      text:
                          ' ${Languages.of(context)!.privacyfollowsastandardproceduretxt}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacycookiesandwebtxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  text:
                      '${Languages.of(context)!.privacylikeanyotherwebsitestxt} ',
                  style: Appstyle.quicksand16w400,
                  children: [
                    TextSpan(
                      text: 'bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      text:
                          ' ${Languages.of(context)!.privacyusecookiesthesecookietxt}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacyadvertisingpartnertxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  text: '${Languages.of(context)!.privacyyoumayconsulttxt} ',
                  style: Appstyle.quicksand16w400,
                  children: [
                    TextSpan(
                      text: 'bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      text:
                          '\n${Languages.of(context)!.privacythirdpartyasserverstxt} ',
                    ),
                    TextSpan(
                      text: 'bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      text:
                          ', ${Languages.of(context)!.privacywhicharesentdirectlytxt} ',
                    ),
                    TextSpan(
                      text: 'bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      text:
                          ' ${Languages.of(context)!.privacyhasnoaccesstoorcontroltxt}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacythirdpartyprivacytxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  text: '',
                  style: Appstyle.quicksand16w400,
                  children: [
                    TextSpan(
                      text: 'bmine.ca',
                      style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchUrl('https://bmine.ca/'),
                    ),
                    TextSpan(
                      text: Languages.of(context)!.privacyprivacypolicydoesnottxt,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacyccpaprivacyrightstxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  text: Languages.of(context)!.privacyundertheccpatxt,
                  style: Appstyle.quicksand16w400,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacygdprdataprotectiontxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  text: Languages.of(context)!.privacywewouldliketomakesuretxt,
                  style: Appstyle.quicksand16w400,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Languages.of(context)!.privacychildrentxt,
                style:
                    Appstyle.quicksand18w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                    text: Languages.of(context)!.privacyanotherpartofourtxt,
                    style: Appstyle.quicksand16w400,
                    children: [
                      TextSpan(
                        text: '\nbmine.ca',
                        style: Appstyle.quicksand16w500.copyWith(
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchUrl('https://bmine.ca/'),
                      ),
                      TextSpan(
                        text:
                            ' ${Languages.of(context)!.privacydoesnotknowinglytxt}',
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
