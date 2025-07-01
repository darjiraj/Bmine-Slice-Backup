import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
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
                Languages.of(context)!.faqstxt,
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
                Languages.of(context)!.faqsgeneralquestiontxt,
                style:
                    Appstyle.quicksand19w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.faqsChangeaccountInfotxt,
                style:
                    Appstyle.quicksand16w500.copyWith(color: AppColors.blackclr),
              ),
              Text(
                Languages.of(context)!.faqslogingotomyaccounttxt,
                style: Appstyle.quicksand16w400,
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.faqscancelmembershiptxt,
                style:
                    Appstyle.quicksand16w500.copyWith(color: AppColors.blackclr),
              ),
              Text(
                Languages.of(context)!.faqstherearemanyplantxt,
                style: Appstyle.quicksand16w400,
              ),
              RichText(
                text: TextSpan(
                  text: '${Languages.of(context)!.faqsattxt} ',
                  style: Appstyle.quicksand16w400,
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
                          ' ${Languages.of(context)!.faqswetakeyoursecuritytxt}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.faqstechnicalissuestxt,
                style:
                    Appstyle.quicksand19w600.copyWith(color: AppColors.blackclr),
              ),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqscookiestxt,
                      style: Appstyle.quicksand18w600,
                    ),
                    TextSpan(
                      text:
                          Languages.of(context)!.faqsissuescanoftenberesolvedtxt,
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqsbrowserstxt,
                      style: Appstyle.quicksand18w600,
                    ),
                    TextSpan(
                      text: Languages.of(context)!
                          .faqsunfortunatlysomeolderbrowserstxt,
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqschangingyourPasswordtxt,
                      style: Appstyle.quicksand18w600,
                    ),
                    TextSpan(
                      text: Languages.of(context)!
                          .faqschanginsyourpasswordisdonethroughtthetxt,
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqssignininformationtxt,
                      style: Appstyle.quicksand18w600,
                    ),
                    TextSpan(
                      text: Languages.of(context)!
                          .faqsiftheemailaddressandpasswordtxt,
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!
                          .faqsifyourarestillexperiencingtxt,
                      style: Appstyle.quicksand16w400,
                    ),
                    TextSpan(
                      text: ' ${Languages.of(context)!.forgotPasswordHeader} ',
                      style:
                          Appstyle.quicksand16w600.copyWith(color: Colors.blue),
                    ),
                    TextSpan(
                      text: Languages.of(context)!
                          .faqspageandentertheemailaddressyouvetxt,
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqsneedhelptxt,
                      style: Appstyle.quicksand16w600
                          .copyWith(color: AppColors.blackclr),
                    ),
                    TextSpan(
                      text:
                          ' ${Languages.of(context)!.faqsClicktheContactUsoptiononthispagetxt}',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.faqsclearingcachecookiestxt,
                style:
                    Appstyle.quicksand19w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!
                          .faqsclearingyourbrowserscacheandcookiestxt,
                      style: Appstyle.quicksand16w400,
                    ),
                    TextSpan(
                      text: Languages.of(context)!.faqsinternetExplorer11txt,
                      style: Appstyle.quicksand16w500
                          .copyWith(color: AppColors.blackclr),
                    ),
                    TextSpan(
                      text: '''
      \n\t\t● ${Languages.of(context)!.faqsclicktheinternetexplorericontxt}
      \t\t● ${Languages.of(context)!.faqsClicktheToolsbuttonpointtotxt}''',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqsfirefoxtxt,
                      style: Appstyle.quicksand16w500
                          .copyWith(color: AppColors.blackclr),
                    ),
                    TextSpan(
                      text: '''
      \n\t\t● ${Languages.of(context)!.faqsClicktheFirefoxiconinthetaskbartxt}
      \t\t● ${Languages.of(context)!.faqsHoveroverHistoryandclickonCleartxt}
      \t\t● ${Languages.of(context)!.faqsclickonthedropdownforTimerangetocleartxt}
      \t\t● ${Languages.of(context)!.faqsClickonthedownarrownexttoDetailstxt}
      \t\t● ${Languages.of(context)!.faqsClickonClearNowtxt}''',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqssafaritxt,
                      style: Appstyle.quicksand16w500
                          .copyWith(color: AppColors.blackclr),
                    ),
                    TextSpan(
                      text: '''
      \n\t\t● ${Languages.of(context)!.faqsclicktheSafariiconinthetaskbartopenSafaritxt}
      \t\t● ${Languages.of(context)!.faqsselectSafarifromthemenubartxt}
      \t\t● ${Languages.of(context)!.faqsselectPreferencestxt}
      \t\t● ${Languages.of(context)!.faqsclickPrivacytxt}
      \t\t● ${Languages.of(context)!.faqsclickremoveallwebsitedatatxt}
      \t\t● ${Languages.of(context)!.faqsclosesafarirestartthebrowserandtrytxt}''',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqschrometxt,
                      style: Appstyle.quicksand16w500
                          .copyWith(color: AppColors.blackclr),
                    ),
                    TextSpan(
                      text: '''
      \n\t\t● ${Languages.of(context)!.faqsclickthechromeiconinthetaskbartoopentxt}
      \t\t● ${Languages.of(context)!.faqsclickthethreedoticonintheChrometxt}
      \t\t● ${Languages.of(context)!.faqsselectSettingstxt}
      \t\t● ${Languages.of(context)!.faqsscrolldownandclicktxt}
      \t\t● ${Languages.of(context)!.faqsInthePrivacyandsecuritysectiontxt}
      \t\t● ${Languages.of(context)!.faqsInthedropdownmenuforTimeRangetxt}
      \t\t● ${Languages.of(context)!.faqscheckoffBrowsinghistoryDownloadhistorytxt}
      \t\t● ${Languages.of(context)!.faqsclickthecleardatabuttontxt}
      \t\t● ${Languages.of(context)!.faqsCloseChromerestartthebrowserandtrytxt}''',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqsedgetxt,
                      style: Appstyle.quicksand16w500
                          .copyWith(color: AppColors.blackclr),
                    ),
                    TextSpan(
                      text: '''
      \n\t\t● ${Languages.of(context)!.faqsclicktheedgeiconinthetaskbartoopentxt}
      \t\t● ${Languages.of(context)!.faqstclickthethreelineiconintxt}
      \t\t● ${Languages.of(context)!.faqsclicktheclockshapedtxt}
      \t\t● ${Languages.of(context)!.faqsselectcookiesandsavedwebsitedatatxt}''',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!
                          .faqsifyoudonotuseoneoftheabovementionedtxt,
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.faqsacceptingcookiestxt,
                style:
                    Appstyle.quicksand19w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!
                          .faqsforoptimalsiteperformancewerecommendthattxt,
                      style: Appstyle.quicksand16w400,
                    ),
                    TextSpan(
                      text: Languages.of(context)!.faqsinternetexplorer11userstxt,
                      style: Appstyle.quicksand16w500
                          .copyWith(color: AppColors.blackclr),
                    ),
                    TextSpan(
                      text: '''
      \n\t\t● ${Languages.of(context)!.faqsselectthecogwheelintheupperrighttxt}
      \t\t● ${Languages.of(context)!.faqsselectInternetOptionstxt}
      \t\t● ${Languages.of(context)!.faqsselectthePrivacytabtxt}
      \t\t● ${Languages.of(context)!.faqSelectAdvancedtxt}
      \t\t● ${Languages.of(context)!.faqscheckoverrideAutomaticCookieHandlingtxt}
      \t\t● ${Languages.of(context)!.faqsclickOKtxt}
      \t\t● ${Languages.of(context)!.faqsclickoKoncemoretxt}''',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqssafariuserstxt,
                      style: Appstyle.quicksand16w500
                          .copyWith(color: AppColors.blackclr),
                    ),
                    TextSpan(
                      text: '''
      \n\t\t● ${Languages.of(context)!.faqsselectsafariatthetopofyourscreentxt}
      \t\t● ${Languages.of(context)!.faqsgotoPreferencestxt}
      \t\t● ${Languages.of(context)!.faqsselectPrivacytxt}
      \t\t● ${Languages.of(context)!.faqsunderblockcookiesselectNevertxt}''',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!.faqsiPhoneoriPadtxt,
                      style: Appstyle.quicksand16w500
                          .copyWith(color: AppColors.blackclr),
                    ),
                    TextSpan(
                      text: '''
      \n\t\t● ${Languages.of(context)!.faqsOpenyourSettingsapptxt}
      \t\t● ${Languages.of(context)!.faqsselectsafaritxt}
      \t\t● ${Languages.of(context)!.faqsselectblockCookiestxt}
      \t\t● ${Languages.of(context)!.faqsselectnevertxt}''',
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                Languages.of(context)!.faqsnotrecievingnotificationonsitetxt,
                style:
                    Appstyle.quicksand19w600.copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: '',
                  children: [
                    TextSpan(
                      text: Languages.of(context)!
                          .faqsThesuccessofBmineisbuiltaroundcommunicationbetweentxt,
                      style: Appstyle.quicksand16w400,
                    ),
                  ],
                ),
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
