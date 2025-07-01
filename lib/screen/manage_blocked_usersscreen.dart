import 'dart:ui';

import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/apis.dart';
import '../Utils/commonfunctions.dart';
import '../models/blockedusersresponsemodel.dart';
import '../models/forgotpasswordresponsemodel.dart';
import '../viewmodels/userreportviewmodel.dart';

class ManageBlockedUsersScreen extends StatefulWidget {
  const ManageBlockedUsersScreen({super.key});

  @override
  State<ManageBlockedUsersScreen> createState() =>
      _ManageBlockedUsersScreenState();
}

class _ManageBlockedUsersScreenState extends State<ManageBlockedUsersScreen> {
  String userid = "";
  bool isLoading = false;
  bool isReqLoading = false;
  List<BlockedUsersDatum> blockedUsersDatum = [];
  @override
  void initState() {
    getBlockedUsersAPI();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var kSize = MediaQuery.of(context).size;
    return Scaffold(
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
              Languages.of(context)!.manageblockeduserstxt,
              style: Appstyle.marcellusSC20w500
                  .copyWith(color: AppColors.blackclr),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              isLoading
                  ? Expanded(
                      child: Container(
                        width: kSize.width,
                        color: Colors.white,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.bminetxtclr,
                          ),
                        ),
                      ),
                    )
                  : blockedUsersDatum.isEmpty
                      ? Expanded(
                          child: Center(
                          child: Text(
                            Languages.of(context)!.nodatafoundtxt,
                            style: Appstyle.quicksand16w500
                                .copyWith(color: AppColors.blackclr),
                          ),
                        ))
                      : Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ListView.builder(
                              itemCount: blockedUsersDatum.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20, right: 20, top: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color:
                                                    AppColors.borgergreyclr))),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                                "${blockedUsersDatum[index].firstName}"
                                                "${blockedUsersDatum[index].dob != null ? ", ${calculateAge(blockedUsersDatum[index].dob!)}" : ""}",
                                                style: Appstyle.quicksand16w500
                                                    .copyWith(
                                                        color: AppColors
                                                            .blackclr)),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              _showBlockUserAlertDialog(
                                                  blockedUsersDatum[index]
                                                          .firstName ??
                                                      "",
                                                  blockedUsersDatum[index]
                                                      .id
                                                      .toString(),
                                                  index);
                                            },
                                            child: Container(
                                              height: 35,
                                              width: 135,
                                              decoration: BoxDecoration(
                                                color: AppColors.blueclr,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  Languages.of(context)!
                                                      .unblocktxt,
                                                  style:
                                                      Appstyle.quicksand16w600,
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
            ],
          ),
          isReqLoading
              ? Container(
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
    );
  }

  void _showBlockUserAlertDialog(String name, String frdId, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: StatefulBuilder(builder: (context, setAState) {
            return AlertDialog(
              actionsAlignment: MainAxisAlignment.start,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              backgroundColor: AppColors.whiteclr,
              alignment: Alignment.center,
              contentPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.only(left: 10, right: 10),
              actions: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 25,
                      ),
                      Center(
                        child: Text(
                          "${Languages.of(context)!.unblockusermsgtxt} ${name.isNotEmpty ? name : Languages.of(context)!.thisusertxt}?",
                          textAlign: TextAlign.center,
                          style: Appstyle.quicksand18w600
                              .copyWith(color: AppColors.blackclr),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await userBlockAPI(frdId, "0", index);
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      AppColors.signinclr1,
                                      AppColors.signinclr2
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    Languages.of(context)!.unblocktxt,
                                    style: Appstyle.quicksand14w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: AppColors.cancelbtnclr),
                                child: Center(
                                  child: Text(
                                    Languages.of(context)!.canceltxt,
                                    style: Appstyle.quicksand14w500
                                        .copyWith(color: AppColors.blackclr),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                    ],
                  ),
                )
              ],
            );
          }),
        );
      },
    );
  }

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
    setState(() {});
  }

  getBlockedUsersAPI() async {
    print("userBlockAPI function call");
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<UserReportViewModel>(context, listen: false)
            .getBlockedUsersAPI(userid);
        if (Provider.of<UserReportViewModel>(context, listen: false)
                .isLoading ==
            false) {
          if (Provider.of<UserReportViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              print("Success");
              BlockedUsersResponseModel model =
                  Provider.of<UserReportViewModel>(context, listen: false)
                      .blockedusersresponse
                      .response as BlockedUsersResponseModel;
              blockedUsersDatum = model.data;
            });
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<UserReportViewModel>(context, listen: false)
                .blockedusersresponse
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

  userBlockAPI(String frdId, String isBlock, int index) async {
    print("userBlockAPI function call");
    setState(() {
      isReqLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<UserReportViewModel>(context, listen: false)
            .userBlockAPI(userid, frdId, isBlock);
        if (Provider.of<UserReportViewModel>(context, listen: false)
                .isLoading ==
            false) {
          if (Provider.of<UserReportViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isReqLoading = false;
              print("Success");
              ForgotPasswordResponseModel model =
                  Provider.of<UserReportViewModel>(context, listen: false)
                      .userblockresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
              blockedUsersDatum.removeAt(index);
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            showToast(Provider.of<UserReportViewModel>(context, listen: false)
                .userblockresponse
                .msg
                .toString());
          }
        }
      } else {
        setState(() {
          isReqLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }
}
