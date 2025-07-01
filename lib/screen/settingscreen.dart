import 'dart:io';
import 'dart:ui';

import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/localization/locale_constants.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/profileresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/models/swipecountresponsemodel.dart';
import 'package:bmine_slice/screen/aboutusscreen.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/contactusscreen.dart';
import 'package:bmine_slice/screen/faqsscreen.dart';
import 'package:bmine_slice/screen/giftscreen.dart';
import 'package:bmine_slice/screen/liveeventticketsscreen.dart';
import 'package:bmine_slice/screen/login.dart';
import 'package:bmine_slice/screen/manage_blocked_usersscreen.dart';
import 'package:bmine_slice/screen/privacypolicyscreen.dart';
import 'package:bmine_slice/screen/restore_purchasescreen.dart';
import 'package:bmine_slice/screen/safetytipsandsecurityscreen.dart';
import 'package:bmine_slice/screen/subscriptionscreen.dart';
import 'package:bmine_slice/screen/swipescreen.dart';
import 'package:bmine_slice/screen/termsandconditionscreen.dart';
import 'package:bmine_slice/screen/virtualmeetingrequestscreen.dart';
import 'package:bmine_slice/viewmodels/profileviewmodel.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String userid = "";
  bool isLoading = false;
  bool isUploadLoading = false;
  String selectedLanguage = "";
  String selectedMeasurement = "";
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  ProfileResponseModel profileResponseModel = ProfileResponseModel();
  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();
  SwipeCountResponseModel swipeCountResponseModel = SwipeCountResponseModel();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  @override
  void initState() {
    super.initState();
    getLocale();
    getSwipeCountAPI(0);
    getPurchaseDetails();
    getProfileDetails();
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

  getPurchaseDetails() async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<PurchaseViewModel>(context, listen: false)
            .getPurchaseDetailsAPI(userid);
        if (Provider.of<PurchaseViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<PurchaseViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              purchaseDetailsResponseModel =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .purchasedetailsresponse
                      .response as PurchaseDetailsResponseModel;

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
                Languages.of(context)!.settingtxt,
                style: Appstyle.marcellusSC20w500
                    .copyWith(color: AppColors.blackclr),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: isLoading
              ? Container(
                  height: kSize.height,
                  width: kSize.width,
                  color: Colors.white,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.bminetxtclr,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              Languages.of(context)!.accounttxt,
                              style: Appstyle.quicksand16w600
                                  .copyWith(color: AppColors.blackclr),
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          _buildInfoRow(
                              Languages.of(context)!.emailtxt,
                              profileResponseModel.userProfile == null ||
                                      profileResponseModel.userProfile!.email ==
                                          null
                                  ? ""
                                  : profileResponseModel.userProfile!.email ??
                                      ""),
                          _buildInfoRow(
                              Languages.of(context)!.phonenumbertxt,
                              profileResponseModel.userProfile == null ||
                                      profileResponseModel
                                              .userProfile!.phoneNumber ==
                                          null
                                  ? ""
                                  : profileResponseModel
                                          .userProfile!.phoneNumber ??
                                      ""),
                          _buildInfoRow(
                              Languages.of(context)!.languagetxt,
                              selectedLanguage.isEmpty
                                  ? ""
                                  : selectedLanguage == "French"
                                      ? Languages.of(context)!.frenchxt
                                      : Languages.of(context)!.englishtxt),
                          _buildInfoRow(
                              Languages.of(context)!.measurementsystemtxt,
                              selectedMeasurement),
                          _buildInfoRow(
                              Languages.of(context)!.verifyprofiletxt, ""),
                          _buildInfoRow(
                              Languages.of(context)!.manageblockeduserstxt, ""),
                          _buildInfoRow(
                              Languages.of(context)!.restorepurchasetxt, ""),
                          SizedBox(
                            height: 25,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              Languages.of(context)!.membershipcaptxt,
                              style: Appstyle.quicksand16w600
                                  .copyWith(color: AppColors.blackclr),
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          _buildInfoRow(
                              Languages.of(context)!.membershiptxt,
                              purchaseDetailsResponseModel.userMembership ==
                                      null
                                  ? "Free"
                                  : purchaseDetailsResponseModel
                                          .userMembership!.planName ??
                                      "Free"),
                          _buildInfoRow(
                              Languages.of(context)!.availablegiftstxt,
                              purchaseDetailsResponseModel.userGift == null
                                  ? "0"
                                  : purchaseDetailsResponseModel
                                      .userGift!.totalCount
                                      .toString()),
                          _buildInfoRow(
                              Languages.of(context)!.availableswipesstxt,
                              swipeCountResponseModel.userSwipe == null ||
                                      swipeCountResponseModel
                                              .userSwipe![0].swipeCount ==
                                          null
                                  ? "0"
                                  : swipeCountResponseModel
                                      .userSwipe![0].swipeCount
                                      .toString()),
                          _buildInfoRow(
                              Languages.of(context)!.availablevirtualReqtxt,
                              purchaseDetailsResponseModel
                                          .userVirtualMeetingReq ==
                                      null
                                  ? "0"
                                  : purchaseDetailsResponseModel
                                      .userVirtualMeetingReq!.totalCount
                                      .toString()),
                          _buildInfoRow(
                              Languages.of(context)!.availableliveeventticketxt,
                              purchaseDetailsResponseModel
                                          .userLiveEventTickets ==
                                      null
                                  ? "0"
                                  : purchaseDetailsResponseModel
                                      .userLiveEventTickets!.remainTicket
                                      .toString()),
                          SizedBox(
                            height: 25,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              Languages.of(context)!.abouttxt,
                              style: Appstyle.quicksand16w600
                                  .copyWith(color: AppColors.blackclr),
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          _buildInfoRow(
                              Languages.of(context)!.privacypolicytxt, ""),
                          _buildInfoRow(Languages.of(context)!.aboutustxt, ""),
                          _buildInfoRow(Languages.of(context)!.faqstxt, ""),
                          _buildInfoRow(
                              Languages.of(context)!.safetysecuritytxt, ""),
                          _buildInfoRow(
                              Languages.of(context)!.termsconditionstxt, ""),
                          _buildInfoRow(
                              Languages.of(context)!.contactuspagetxt, ""),
                          _buildInfoRow(
                              Languages.of(context)!.deleteaccounttxt, ""),
                          _buildInfoRow(Languages.of(context)!.logouttxt, ""),
                        ],
                      ),
                    ),
                    isUploadLoading
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
        ),
      ),
    );
  }

  void _showLanguageDialog(String initialLanguage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            Languages.of(context)!.selectlanguagetxt,
            style: Appstyle.quicksand18w600,
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setAState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RadioListTile<String>(
                    value: 'English',
                    title: Text(
                      Languages.of(context)!.englishtxt,
                      // 'English',
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    groupValue: initialLanguage,
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    onChanged: (value) {
                      setAState(() {
                        initialLanguage = value!; // Update dialog state
                      });
                      setState(() {});
                    },
                  ),
                  RadioListTile<String>(
                    value: 'French',
                    title: Text(
                      Languages.of(context)!.frenchxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    groupValue: initialLanguage,
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    onChanged: (value) {
                      setAState(() {
                        initialLanguage = value!; // Update dialog state
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 35),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 35,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.bminetxtclr),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                Languages.of(context)!.canceltxt,
                                style: Appstyle.quicksand15w600.copyWith(
                                  color: AppColors.bminetxtclr,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            setState(() {
                              selectedLanguage = initialLanguage;
                            });
                            if (selectedLanguage == "English") {
                              changeLanguage(context, "en");
                            } else {
                              changeLanguage(context, "fr");
                            }
                            await getLocale();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 35,
                            decoration: BoxDecoration(
                              color: AppColors.bminetxtclr,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                Languages.of(context)!.savetxt,
                                style: Appstyle.quicksand15w600.copyWith(
                                  color: AppColors.whiteclr,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showMeasurementDialog(String initialMeasurement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            Languages.of(context)!.selectmeasurementsystemtxt,
            style: Appstyle.quicksand18w600,
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setAState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RadioListTile<String>(
                    value: 'KM',
                    title: Text(
                      Languages.of(context)!.kmtxt,
                      // 'English',
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    groupValue: initialMeasurement,
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    onChanged: (value) {
                      setAState(() {
                        initialMeasurement = value!; // Update dialog state
                      });
                      setState(() {});
                    },
                  ),
                  RadioListTile<String>(
                    value: 'MI',
                    title: Text(
                      Languages.of(context)!.mitxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    groupValue: initialMeasurement,
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    onChanged: (value) {
                      setAState(() {
                        initialMeasurement = value!; // Update dialog state
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 35),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 35,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.bminetxtclr),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                Languages.of(context)!.canceltxt,
                                style: Appstyle.quicksand15w600.copyWith(
                                  color: AppColors.bminetxtclr,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            setState(() {
                              selectedMeasurement = initialMeasurement;
                            });
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            prefs.setString("Measurement", selectedMeasurement);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 35,
                            decoration: BoxDecoration(
                              color: AppColors.bminetxtclr,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                Languages.of(context)!.savetxt,
                                style: Appstyle.quicksand15w600.copyWith(
                                  color: AppColors.whiteclr,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            Languages.of(context)!.logouttxt,
            style: Appstyle.quicksand18w600,
          ),
          content: Text(
            Languages.of(context)!.logoutalertmsgtxt,
            style: Appstyle.quicksand17w500.copyWith(
              color: AppColors.blackclr,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                Languages.of(context)!.canceltxt,
                style: Appstyle.quicksand15w600.copyWith(
                  color: AppColors.bminetxtclr,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                if (Platform.isAndroid) {
                  await _googleSignIn.signOut();
                }
                String email = prefs.getString('Email') ?? "";
                String password = prefs.getString('Password') ?? "";
                bool isRemember = prefs.getBool('isRemember') ?? false;

                await prefs.clear();
                await prefs.setString("Email", email);
                await prefs.setString("Password", password);
                await prefs.setBool("isRemember", isRemember);
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false);
              },
              child: Text(
                Languages.of(context)!.logouttxt,
                style: Appstyle.quicksand15w600.copyWith(
                  color: AppColors.bminetxtclr,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            Languages.of(context)!.deleteaccounttxt,
            style: Appstyle.quicksand18w600,
          ),
          content: Text(
            Languages.of(context)!.deleteaccountmsgtxt,
            style: Appstyle.quicksand17w500.copyWith(
              color: AppColors.blackclr,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                Languages.of(context)!.canceltxt,
                style: Appstyle.quicksand15w600.copyWith(
                  color: AppColors.bminetxtclr,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                deleteUserAPI();
              },
              child: Text(
                Languages.of(context)!.deletetxt,
                style: Appstyle.quicksand15w600.copyWith(
                  color: AppColors.bminetxtclr,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  uploadVerifyVideoAPI(XFile video) async {
    print("uploadVerifyVideoAPI function call");
    Navigator.pop(context);
    setState(() {
      isUploadLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .uploadVerifyVideoAPI(userid, video);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              isUploadLoading = false;
              print("Success");
              ForgotPasswordResponseModel model =
                  Provider.of<ProfileViewModel>(context, listen: false)
                      .uploadverifyvideoresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
          } else {
            setState(() {
              isUploadLoading = false;
            });
            showToast(Provider.of<ProfileViewModel>(context, listen: false)
                .uploadverifyvideoresponse
                .msg
                .toString());
          }
        }
      } else {
        setState(() {
          isUploadLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  deleteUserAPI() async {
    print("deleteUserAPI function call");

    Navigator.pop(context);
    setState(() {
      isUploadLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .deleteAccountAPI(userid);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              isUploadLoading = false;
              print("Success");
              ForgotPasswordResponseModel model =
                  Provider.of<ProfileViewModel>(context, listen: false)
                      .deleteaccountresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            if (Platform.isAndroid) {
              await _googleSignIn.signOut();
            }
            await prefs.clear();
            Navigator.of(context).pop();
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false);
          } else {
            setState(() {
              isUploadLoading = false;
            });
            showToast(Provider.of<ProfileViewModel>(context, listen: false)
                .deleteaccountresponse
                .msg
                .toString());
          }
        }
      } else {
        setState(() {
          isUploadLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  getSwipeCountAPI(int isValue) async {
    print("getSwipeCountAPI function call");
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<PurchaseViewModel>(context, listen: false)
            .getSwipeCountAPI(userid, isValue);
        if (Provider.of<PurchaseViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<PurchaseViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              print("Success");
              swipeCountResponseModel =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .swipecountresponse
                      .response as SwipeCountResponseModel;
            });
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .swipecountresponse
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

  void _showVerifyProfileDialog() async {
    final ImagePicker picker = ImagePicker();

    Future<void> pickVideo(ImageSource source) async {
      final XFile? video = await picker.pickVideo(
          source: source,
          preferredCameraDevice: CameraDevice.front, // Use front camera
          maxDuration: Duration(seconds: 15));
      if (video != null) {
        await uploadVerifyVideoAPI(video);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.symmetric(horizontal: 15),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.whiteclr,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Languages.of(context)!.verifyprofiletxt,
                    style: Appstyle.quicksand18w600,
                  ),
                  SizedBox(height: 10),
                  Text(
                    Languages.of(context)!.pleasetakeashortvideotxt,
                    style: Appstyle.quicksand15w400,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Image.asset(
                    AppAssets.verificationperson,
                    height: 180,
                  ),
                  SizedBox(height: 20),
                  _buildDialogButton(
                    text: Languages.of(context)!.takevideotxt,
                    onTap: () async {
                      // _initializeCamera();
                      // await _startRecording();
                      // await Future.delayed(
                      //     Duration(seconds: 30)); // Record for 30 seconds
                      // await _stopRecording();
                      pickVideo(ImageSource.camera);
                    },
                    filled: true,
                  ),
                  SizedBox(height: 10),
                  _buildDialogButton(
                    text: Languages.of(context)!.canceltxt,
                    onTap: () => Navigator.pop(context),
                    filled: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton({
    required String text,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          width: double.infinity, // Full width
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: AppColors.bminetxtclr),
            color: filled ? AppColors.bminetxtclr : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Center(
            child: Text(
              text,
              style: Appstyle.quicksand16w600.copyWith(
                color: filled ? AppColors.whiteclr : AppColors.bminetxtclr,
              ),
            ),
          ),
        ),
      ),
    );
  }

  getLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String tmpselectedLanguage =
          prefs.getString("SelectedLanguageCode") ?? "en";
      if (tmpselectedLanguage == "en") {
        selectedLanguage = "English";
      } else if (tmpselectedLanguage == "fr") {
        selectedLanguage = "French";
      }
      print("selectedLanguage = $selectedLanguage");
    });
  }

  Widget _buildInfoRow(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteclr,
        border: Border(
          top: BorderSide(
              color: title == Languages.of(context)!.emailtxt ||
                      title == Languages.of(context)!.membershiptxt ||
                      title == Languages.of(context)!.privacypolicytxt
                  ? AppColors.hinttextclr
                  : Colors.transparent),
          bottom: BorderSide(color: AppColors.hinttextclr),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
        ),
        child: InkWell(
          onTap: () {
            _handleNavigation(title);
          },
          child: Row(
            children: [
              Text(
                title,
                style: Appstyle.quicksand14w600
                    .copyWith(color: AppColors.blackclr),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                        child: Text(value,
                            maxLines: 1,
                            style: Appstyle.quicksand13w500
                                .copyWith(color: AppColors.blackclr),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end)),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavigation(String title) async {
    Map<String, Widget Function()> routes = {
      Languages.of(context)!.membershiptxt: () => SubscriptionScreen(),
      Languages.of(context)!.privacypolicytxt: () => PrivacyPolicyScreen(),
      Languages.of(context)!.aboutustxt: () => AboutUsScreen(),
      Languages.of(context)!.manageblockeduserstxt: () =>
          ManageBlockedUsersScreen(),
      Languages.of(context)!.termsconditionstxt: () =>
          TermsandConditionsScreen(),
      Languages.of(context)!.safetysecuritytxt: () =>
          SafetyTipsandSecurityScreen(),
      Languages.of(context)!.faqstxt: () => FAQsScreen(),
      Languages.of(context)!.availablegiftstxt: () =>
          GiftScreen(frd_id: "", isSettingScreen: true),
      Languages.of(context)!.availableswipesstxt: () => SwipesScreen(),
      // Languages.of(context)!.restorepurchasetxt: () => RestorePurchaseScreen(),
      Languages.of(context)!.availablevirtualReqtxt: () =>
          VirtualMeetingRequestsScreen(),
      Languages.of(context)!.availableliveeventticketxt: () =>
          LiveEventTicketsScreen(),
      Languages.of(context)!.contactuspagetxt: () => ContactUsScreen(
            email: profileResponseModel.userProfile!.email != null
                ? ""
                : profileResponseModel.userProfile!.email!,
          ),
    };

    if (routes.containsKey(title)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => routes[title]!()),
      ).then(
        (value) async {
          await getPurchaseDetails();
          await getProfileDetails();
          await getSwipeCountAPI(0);
        },
      );
    } else if (title == Languages.of(context)!.measurementsystemtxt) {
      _showMeasurementDialog(selectedMeasurement);
    } else if (title == Languages.of(context)!.languagetxt) {
      _showLanguageDialog(selectedLanguage);
    } else if (title == Languages.of(context)!.logouttxt) {
      _showLogoutDialog();
    } else if (title == Languages.of(context)!.verifyprofiletxt) {
      _showVerifyProfileDialog();
    } else if (title == Languages.of(context)!.deleteaccounttxt) {
      _showDeleteAccountDialog();
    } else if (title == Languages.of(context)!.restorepurchasetxt) {
      await _inAppPurchase.restorePurchases();
    }
  }
}
