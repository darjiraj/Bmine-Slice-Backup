import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyTipsandSecurityScreen extends StatefulWidget {
  const SafetyTipsandSecurityScreen({super.key});

  @override
  State<SafetyTipsandSecurityScreen> createState() =>
      _SafetyTipsandSecurityScreenState();
}

class _SafetyTipsandSecurityScreenState
    extends State<SafetyTipsandSecurityScreen> {
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
              Expanded(
                child: Text(
                  Languages.of(context)!.safetysecuritytxt,
                  style: Appstyle.marcellusSC20w500
                      .copyWith(color: AppColors.blackclr),
                ),
              )
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroSection(),
              const SizedBox(height: 5),
              _buildSectionTitle(Languages.of(context)!.safetyusedifferenttxt),
              _buildTextSection(Languages.of(context)!.safetyitseasytodotxt),
              const SizedBox(height: 5),
              _buildSectionTitle(
                  Languages.of(context)!.safetyavoidconnectingtxt),
              _buildTextSection(Languages.of(context)!.safetyifthepersonyoutxt),
              const SizedBox(height: 5),
              _buildSectionTitle(Languages.of(context)!.safetycheckoutyourtxt),
              _buildTextSection(
                  Languages.of(context)!.safetyifyouknowyourmatchestxt),
              const SizedBox(height: 5),
              _buildSectionTitle(
                  Languages.of(context)!.safetyblockandreporttxt),
              _buildTextSection(
                  Languages.of(context)!.safetyyoucanblockandreporttxt),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyasksforfincasstxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyclaimstobefromtxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyclaimstoberecentlytxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetydisappearssuddenlyfromtxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetygivesvagueanswertxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyoverlycomplimentarytxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetypressuresyoutoprovidetxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyrequestsyourhometxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetytellsinconsistenttxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyuserdisjointedlanguagetxt}'),
                  ],
                ),
              ),
              _buildTextSection(
                  Languages.of(context)!.safetyexampleofuserbehaviortxt),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyrequestsfinancialasstxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyreqphotographstxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyisaminortxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetysendsharassingoroffensivetxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyattemptstothreatentxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetyseemstohavecreatedtxt}'),
                    _buildTextSection(
                        '● ${Languages.of(context)!.safetytriestosellyouproductstxt}'),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              _buildSectionTitle(
                  Languages.of(context)!.safetywaittosharepersonalinfotxt),
              RichText(
                  text: TextSpan(
                      style: Appstyle.quicksand16w400,
                      text:
                          Languages.of(context)!.safetynevergivesomeoneyoutxt)),
              const SizedBox(height: 5),
              _buildSectionTitle(
                  Languages.of(context)!.safetydontrespondtoreqtxt),
              RichText(
                text: TextSpan(
                    style: Appstyle.quicksand16w400,
                    text:
                        "${Languages.of(context)!.safetynomatterhowconvincingtxt} ",
                    children: [
                      TextSpan(
                        text: 'Bmine.ca',
                        style: Appstyle.quicksand16w500.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchUrl('https://bmine.ca/'),
                      ),
                      TextSpan(
                        style: Appstyle.quicksand16w400,
                        text:
                            ' ${Languages.of(context)!.safetythroughcontactofanytxt}',
                      ),
                    ]),
              )
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

  Widget _buildIntroSection() {
    return Text(
      Languages.of(context)!.safetymorethan40milliontxt,
      style: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextSection(String text) {
    return Text(
      text,
      style: Appstyle.quicksand16w400,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Appstyle.quicksand16w600.copyWith(color: AppColors.blackclr),
    );
  }
}
