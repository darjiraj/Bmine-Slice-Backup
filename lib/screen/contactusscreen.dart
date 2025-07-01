import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/profileresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/viewmodels/profileviewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactUsScreen extends StatefulWidget {
  String email;
  ContactUsScreen({super.key, required this.email});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  TextEditingController subjectcontroller = TextEditingController();
  TextEditingController messagecontroller = TextEditingController();
  ProfileResponseModel profileResponseModel = ProfileResponseModel();
  bool isLoading = false;
  String userid = "";
  String selectedMeasurement = "";

  @override
  void initState() {
    super.initState();
    getProfileDetails();
  }

  @override
  Widget build(BuildContext context) {
    Size kSize = MediaQuery.of(context).size;
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
                Languages.of(context)!.contactuspagetxt,
                style: Appstyle.marcellusSC20w500
                    .copyWith(color: AppColors.blackclr),
              )
            ],
          ),
        ),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Text(Languages.of(context)!.subjectfieldtxt,
                      style: Appstyle.quicksand18w600),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: subjectcontroller,
                    keyboardType: TextInputType.text,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textfieldclr),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textfieldclr),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textfieldclr),
                          borderRadius: BorderRadius.circular(8),
                        )),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(Languages.of(context)!.messagestxt,
                      style: Appstyle.quicksand18w600),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: messagecontroller,
                    keyboardType: TextInputType.text,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    maxLines: 5,
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textfieldclr),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textfieldclr),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textfieldclr),
                          borderRadius: BorderRadius.circular(8),
                        )),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  InkWell(
                    onTap: () async {
                      if (subjectcontroller.text.isEmpty) {
                        showToast(Languages.of(context)!.entersubjectfieldtxt);
                      } else if (messagecontroller.text.isEmpty) {
                        showToast(Languages.of(context)!.entermessagefieldtxt);
                      } else {
                        await contactUsAPI(
                            profileResponseModel.userProfile!.email ?? "",
                            subjectcontroller.text.trim(),
                            messagecontroller.text.trim());
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(width: 1, color: AppColors.blackclr),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              AppColors.gradientclr1,
                              AppColors.gradientclr2
                            ],
                          ),
                        ),
                        child: Center(
                            child: Text(Languages.of(context)!.submittxt,
                                style: Appstyle.quicksand16w500)),
                      ),
                    ),
                  ),
                ],
              ),
              isLoading
                  ? Container(
                      height: kSize.height,
                      width: kSize.width,
                      color: Colors.transparent,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.bminetxtclr,
                        ),
                      ),
                    )
                  : Container()
            ],
          ),
        )),
      ),
    );
  }

  contactUsAPI(
    String email,
    String subject,
    String message,
  ) async {
    setState(() {
      isLoading = true;
    });
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .contactUsAPI(email, subject, message);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              ForgotPasswordResponseModel model =
                  Provider.of<ProfileViewModel>(context, listen: false)
                      .contactusresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
            Navigator.pop(context);
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<ProfileViewModel>(context, listen: false)
                .contactusresponse
                .msg
                .toString());
          }
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
    selectedMeasurement = prefs.getString('Measurement') ?? "KM";
  }

  getProfileDetails() async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .getProfileAPI(userid, "", "", selectedMeasurement);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              profileResponseModel =
                  Provider.of<ProfileViewModel>(context, listen: false)
                      .profileresponse
                      .response as ProfileResponseModel;

              isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }
}
