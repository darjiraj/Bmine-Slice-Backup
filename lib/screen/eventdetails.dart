import 'dart:async';
import 'dart:ui';

import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/speed_dating_service.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/alreadyjoincallresponsemodel.dart';
import 'package:bmine_slice/models/eventdetailsresponsemodel.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/joineventcallresponsemodel.dart';
import 'package:bmine_slice/models/profileresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/eventlivescreen.dart';
import 'package:bmine_slice/screen/liveeventticketsscreen.dart';
import 'package:bmine_slice/viewmodels/eventfeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/profileviewmodel.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/appstyle.dart';

class EventsDetailsScreen extends StatefulWidget {
  String eventId = "";
  EventsDetailsScreen({super.key, required this.eventId});

  @override
  State<EventsDetailsScreen> createState() => _EventsDetailsScreenState();
}

class _EventsDetailsScreenState extends State<EventsDetailsScreen> {
  String userid = "";
  String measurement = "";
  bool isUserJoined = false;
  bool isLoading = false;
  bool isJoinLoading = false;
  List<String> participantUserIds = [];
  ProfileResponseModel profileResponseModel = ProfileResponseModel();
  AboutMe genderItem = AboutMe();
  SharedPreferences? prefs;
  EventDetailsResponseModel eventDetailsResponseModel =
      EventDetailsResponseModel();
  final SpeedDatingService _speedDatingService = SpeedDatingService();
  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();

  @override
  void initState() {
    super.initState();
    getuserid();
    getProfileDetails();
    getPurchaseDetails();
    getEventDetailsAPI(widget.eventId);
  }

  int remainingSeconds = 300; // 5 minutes in seconds
  late Timer timer;

  String convertDate(DateTime serverDateTime) {
    DateTime utcDateTime = serverDateTime.add(Duration(hours: 4));
    var dateTimeUtc = DateFormat(
      "yyyy-MM-dd HH:mm:ss",
    ).parse(utcDateTime.toString(), true);
    DateTime localDateTime = dateTimeUtc.toLocal();
    String formattedDate = DateFormat(
      'EEE, d MMMM yyyy \'at\' hh:mm a',
    ).format(localDateTime);
    return formattedDate;
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2.0),
            child: Container(color: AppColors.textfieldclr, height: 1.0),
          ),
          automaticallyImplyLeading: false,
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
              const SizedBox(width: 15),
              Text(
                Languages.of(context)!.eventdetailstxt,
                style: Appstyle.marcellusSC20w500.copyWith(
                  color: AppColors.blackclr,
                ),
              ),
            ],
          ),
        ),
        body: isLoading
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
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12.0,
                            ),
                          ],
                          color: AppColors.whiteclr,
                          borderRadius: BorderRadius.circular(17.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eventDetailsResponseModel.data!.eventName ?? "",
                                style: Appstyle.quicksand19w600.copyWith(
                                  color: AppColors.blackclr,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 3.0),
                                        Expanded(
                                          child: Text(
                                            convertDate(
                                              eventDetailsResponseModel
                                                  .data!.startTime!,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Appstyle.quicksand15w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '${Languages.of(context)!.locationtxt}: ${eventDetailsResponseModel.data!.city}',
                                style: Appstyle.quicksand14w400,
                              ),
                              Text(
                                '${Languages.of(context)!.deadlinetxt} ${convertDate(eventDetailsResponseModel.data!.deadline!)}',
                                style: Appstyle.quicksand14w400,
                              ),
                              Text(
                                '${Languages.of(context)!.agegrouptxt} ${eventDetailsResponseModel.data!.ageGroup}',
                                style: Appstyle.quicksand14w400,
                              ),
                              Text(
                                '${Languages.of(context)!.maxparticipatetxt} ${eventDetailsResponseModel.data!.maxParticipant}',
                                style: Appstyle.quicksand14w400,
                              ),
                              Text(
                                '${Languages.of(context)!.remainingtxt} ${eventDetailsResponseModel.data!.remaining}',
                                style: Appstyle.quicksand14w400,
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '${Languages.of(context)!.participantstxt} (${eventDetailsResponseModel.data!.participants!.isNotEmpty ? eventDetailsResponseModel.data!.participants!.length : 0})',
                                style: Appstyle.quicksand14w600.copyWith(
                                  color: AppColors.blackclr,
                                ),
                              ),
                              ListView.builder(
                                itemCount: eventDetailsResponseModel
                                    .data!.participants!.length,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemBuilder: (context, i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage:
                                              eventDetailsResponseModel
                                                          .data!
                                                          .participants![i]
                                                          .post ==
                                                      null
                                                  ? AssetImage(
                                                      AppAssets.femaleUser,
                                                    ) as ImageProvider
                                                  : eventDetailsResponseModel
                                                              .data!
                                                              .participants![i]
                                                              .post!
                                                              .images !=
                                                          null
                                                      ? NetworkImage(
                                                          "${API.baseUrl}/upload/${eventDetailsResponseModel.data!.participants![i].post!.images}",
                                                        )
                                                      : AssetImage(
                                                          AppAssets.femaleUser,
                                                        ) as ImageProvider,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "${eventDetailsResponseModel.data!.participants![i].firstName ?? ""} "
                                          "${eventDetailsResponseModel.data!.participants![i].lastName != null && eventDetailsResponseModel.data!.participants![i].lastName!.isNotEmpty ? eventDetailsResponseModel.data!.participants![i].lastName![0] : ''}"
                                          "${eventDetailsResponseModel.data!.participants![i].dob != null ? ", ${calculateAge(eventDetailsResponseModel.data!.participants![i].dob!)}" : ""}",
                                          style:
                                              Appstyle.quicksand14w600.copyWith(
                                            color: AppColors.blackclr,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 25.0),
                              isUserJoined
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              await checkJoinEventAPI(
                                                eventDetailsResponseModel
                                                    .data!.id
                                                    .toString(),
                                              );
                                            },
                                            child: Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: <Color>[
                                                    // AppColors.signinclr1,
                                                    // AppColors.signinclr2,
                                                    AppColors.gradientclr1,
                                                    AppColors.gradientclr2
                                                  ],
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  Languages.of(
                                                    context,
                                                  )!
                                                      .startsessiontxt,
                                                  style:
                                                      Appstyle.quicksand16w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              _showWithdrawEventAlertDialog(
                                                eventDetailsResponseModel.data!,
                                              );
                                            },
                                            child: Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: AppColors.cancelbtnclr,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  width: 1,
                                                  color:
                                                      AppColors.bordergreyclr,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  Languages.of(
                                                    context,
                                                  )!
                                                      .withdrawtxt,
                                                  style: Appstyle
                                                      .quicksand16w500
                                                      .copyWith(
                                                    color: AppColors.blackclr,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Align(
                                      alignment: Alignment.topCenter,
                                      child: InkWell(
                                        onTap: () {
                                          // if (purchaseDetailsResponseModel
                                          //         .userLiveEventTickets!
                                          //         .remainTicket! >=
                                          //     1) {
                                          _showAlertDialog(
                                            eventDetailsResponseModel.data!,
                                          );
                                          // } else {
                                          //   Navigator.push(
                                          //     context,
                                          //     MaterialPageRoute(
                                          //       builder: (context) =>
                                          //           LiveEventTicketsScreen(),
                                          //     ),
                                          //   ).then(
                                          //     (value) async {
                                          //       await getPurchaseDetails();
                                          //     },
                                          //   );
                                          // }
                                        },
                                        child: Container(
                                          height: 50,
                                          width: MediaQuery.of(
                                                context,
                                              ).size.width /
                                              2,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: <Color>[
                                                // AppColors.signinclr1,
                                                // AppColors.signinclr2,
                                                AppColors.gradientclr1,
                                                AppColors.gradientclr2
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              Languages.of(
                                                context,
                                              )!
                                                  .joineventtxt,
                                              style: Appstyle.quicksand16w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 10.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  isJoinLoading
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
                      : Container(),
                ],
              ),
      ),
    );
  }

  getuserid() async {
    prefs = await SharedPreferences.getInstance();
    userid = prefs!.getString('userid') ?? "";
    measurement = prefs!.getString('Measurement') ?? "";
  }

  void _showAlertDialog(Data event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: AlertDialog(
            actionsAlignment: MainAxisAlignment.start,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
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
                    const SizedBox(height: 25),
                    Center(
                      child: Text(
                        "${Languages.of(context)!.doyouwanttojoineventtxt} ${event.eventName ?? ""}?",
                        textAlign: TextAlign.center,
                        style: Appstyle.quicksand14w600.copyWith(
                          color: AppColors.blackclr,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (event.remaining == "0") {
                                showToast(
                                  Languages.of(context)!.eventfullybookedtxt,
                                );
                                return;
                              }
                              if (profileResponseModel.userProfile?.dob ==
                                  null) {
                                showToast(Languages.of(context)!.updatedobtxt);
                                return;
                              }
                              int age = calculateAge(
                                profileResponseModel.userProfile!.dob!,
                              );
                              if (age < 18) {
                                showToast(
                                  Languages.of(context)!.joinafter18txt,
                                );
                                return;
                              }
                              List<String> ageGroup = event.ageGroup!.split(
                                '-',
                              );
                              int minAge = int.parse(ageGroup[0]) - 3;
                              int maxAge = int.parse(ageGroup[1]) + 3;

                              if (age < minAge || age > maxAge) {
                                showToast(
                                  Languages.of(
                                    context,
                                  )!
                                      .agerestrictionineventtxt,
                                );
                                return;
                              }
                              if (genderItem.value == null) {
                                showToast(
                                  Languages.of(context)!.updategendertxt,
                                );
                                return;
                              }
                              Map<String, int> genderCounts = {};
                              for (var participant in event.participants!) {
                                String? gender = participant.gender;
                                if (gender != null) {
                                  genderCounts[gender] =
                                      (genderCounts[gender] ?? 0) + 1;
                                }
                              }

                              Map<String, List<String>> eventGenders = {
                                'Straight Men & Woman': [
                                  'Man - Straight',
                                  'Woman - Straight',
                                  'Man - Bi',
                                  'Woman - Bi',
                                ],
                                'Lesbian Woman': [
                                  'Woman - Lesbian',
                                  'Woman - Bi',
                                ],
                                'Gay Men': ['Man - Gay', 'Man - Bi'],
                                'Gay & Lesbian': [
                                  'Man - Gay',
                                  'Woman - Lesbian',
                                  // 'Man - Bi',
                                  // 'Woman - Bi',
                                ],
                                'Trans all Woman': ['Trans-Woman'],
                                'Trans all Men': ['Trans-Man'],
                                'Trans Men & Woman': [
                                  'Trans-Man',
                                  'Trans-Woman',
                                ],
                              };

                              List<String>? allowedGenders =
                                  eventGenders[event.eventType];

                              if (allowedGenders != null) {
                                String userGender = genderItem.value ?? "";

                                if (allowedGenders.contains(userGender)) {
                                  int maxPerGender = (event.maxParticipant! /
                                          allowedGenders.length)
                                      .floor();

                                  if ((genderCounts[userGender] ?? 0) >=
                                      maxPerGender) {
                                    showToast(
                                      "${Languages.of(context)!.eventfullforgendertxt} $userGender",
                                    );
                                    return;
                                  }
                                  if ((purchaseDetailsResponseModel
                                              .userLiveEventTickets
                                              ?.remainTicket ??
                                          0) >=
                                      1) {
                                    await joinLiveAPI(event.id.toString());
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LiveEventTicketsScreen(),
                                      ),
                                    ).then((value) async {
                                      await getPurchaseDetails();
                                    });
                                  }
                                } else {
                                  String allowedGenderText =
                                      allowedGenders.join(" and ");
                                  showToast(
                                    "${Languages.of(context)!.openonlygendertxt} ${allowedGenderText.toLowerCase()}.",
                                  );
                                }
                              } else {
                                showToast(
                                  Languages.of(context)!.invalideventtypetxt,
                                );
                              }
                            },
                            // onTap: () async {
                            //   if (event.remaining == "0") {
                            //     showToast(
                            //         Languages.of(context)!.eventfullybookedtxt);
                            //     return;
                            //   }

                            //   int age = 0;
                            //   if (profileResponseModel.userProfile!.dob ==
                            //       null) {
                            //     showToast(Languages.of(context)!.updatedobtxt);
                            //     return;
                            //   }
                            //   age = calculateAge(
                            //       profileResponseModel.userProfile!.dob!);
                            //   if (age < 18) {
                            //     showToast(
                            //         Languages.of(context)!.joinafter18txt);
                            //     return;
                            //   }
                            //   List<String> ageGroup =
                            //       event.ageGroup!.split('-');
                            //   int minAge = int.parse(ageGroup[0]) - 3;
                            //   int maxAge = int.parse(ageGroup[1]) + 3;
                            //   if (age < minAge || age > maxAge) {
                            //     showToast(Languages.of(context)!
                            //         .agerestrictionineventtxt);
                            //     return;
                            //   }
                            //   if (genderItem.value == null) {
                            //     showToast(
                            //         Languages.of(context)!.updategendertxt);
                            //     return;
                            //   }
                            //   int menCount = 0;
                            //   int womenCount = 0;
                            //   int transManCount = 0;
                            //   int transWomanCount = 0;

                            //   for (var participant in event.participants!) {
                            //     String? gender = participant.gender;
                            //     if (gender == 'Man') {
                            //       menCount++;
                            //     } else if (gender == 'Woman') {
                            //       womenCount++;
                            //     } else if (gender == 'Trans-Man') {
                            //       transManCount++;
                            //     } else if (gender == 'Trans-Woman') {
                            //       transWomanCount++;
                            //     }
                            //   }
                            //   Map<String, List<String>> eventGenders = {
                            //     'Straight Men & Woman': ['Man', 'Woman'],
                            //     'Lesbian Woman': ['Woman'],
                            //     'Gay Men': ['Man'],
                            //     'Trans all Woman': ['Trans-Woman'],
                            //     'Trans all Men': ['Trans-Man'],
                            //     'Trans Men & Woman': [
                            //       'Trans-Man',
                            //       'Trans-Woman'
                            //     ],
                            //   };
                            //   List<String>? allowedGenders =
                            //       eventGenders[event.eventType];
                            //   if (allowedGenders != null) {
                            //     if (allowedGenders.contains(genderItem.value)) {
                            //       int maxPerGender = (event.maxParticipant! /
                            //               allowedGenders.length)
                            //           .floor();
                            //       if (genderItem.value == 'Man' &&
                            //           menCount >= maxPerGender) {
                            //         showToast(Languages.of(context)!
                            //             .eventfullformentxt);
                            //         return;
                            //       }
                            //       if (genderItem.value == 'Woman' &&
                            //           womenCount >= maxPerGender) {
                            //         showToast(Languages.of(context)!
                            //             .eventfullforwomentxt);
                            //         return;
                            //       }
                            //       if (genderItem.value == 'Trans-Man' &&
                            //           transManCount >= maxPerGender) {
                            //         showToast(Languages.of(context)!
                            //             .eventfullfortransmentxt);
                            //         return;
                            //       }
                            //       if (genderItem.value == 'Trans-Woman' &&
                            //           transWomanCount >= maxPerGender) {
                            //         showToast(Languages.of(context)!
                            //             .eventfullfortranswomentxt);
                            //         return;
                            //       }
                            //       await joinLiveAPI(event.id.toString());
                            //       Navigator.pop(context);
                            //     } else {
                            //       String allowedGenderText =
                            //           allowedGenders.join(" and ");
                            //       showToast(
                            //           "${Languages.of(context)!.openonlygendertxt} ${allowedGenderText.toLowerCase()}.");
                            //     }
                            //   } else {
                            //     showToast(
                            //         Languages.of(context)!.invalideventtypetxt);
                            //   }
                            // },
                            child: Container(
                              height: 40,
                              // width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    // AppColors.signinclr1,
                                    // AppColors.signinclr2,
                                    AppColors.gradientclr1,
                                    AppColors.gradientclr2
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  Languages.of(context)!.confirmtxt,
                                  style: Appstyle.quicksand14w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 40,
                              // width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.cancelbtnclr,
                              ),
                              child: Center(
                                child: Text(
                                  Languages.of(context)!.canceltxt,
                                  style: Appstyle.quicksand14w500.copyWith(
                                    color: AppColors.blackclr,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWithdrawEventAlertDialog(Data event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: AlertDialog(
            actionsAlignment: MainAxisAlignment.start,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
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
                    const SizedBox(height: 25),
                    Center(
                      child: Text(
                        "${Languages.of(context)!.doyouwanttowithdraweventtxt} ${event.eventName ?? ""}?",
                        textAlign: TextAlign.center,
                        style: Appstyle.quicksand14w600.copyWith(
                          color: AppColors.blackclr,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              await withdrawEventAPI(event.id.toString());
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
                                    // AppColors.signinclr1,
                                    // AppColors.signinclr2,
                                    AppColors.gradientclr1,
                                    AppColors.gradientclr2
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  Languages.of(context)!.confirmtxt,
                                  style: Appstyle.quicksand14w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.cancelbtnclr,
                              ),
                              child: Center(
                                child: Text(
                                  Languages.of(context)!.canceltxt,
                                  style: Appstyle.quicksand14w500.copyWith(
                                    color: AppColors.blackclr,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  joinLiveAPI(String eventId) async {
    setState(() {
      isJoinLoading = true;
    });
    ForgotPasswordResponseModel model = ForgotPasswordResponseModel();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(
          context,
          listen: false,
        ).joinEventAPI(eventId, userid);
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).isSuccess ==
              true) {
            setState(() {
              model = Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).joinEventresponse.response as ForgotPasswordResponseModel;
              isJoinLoading = false;
              showToast(model.message ?? "");
            });

            getEventDetailsAPI(eventId);
          } else {
            isJoinLoading = false;
            showToast(
              Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).joinEventresponse.msg,
            );
          }
        }
      } else {
        setState(() {
          isJoinLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  withdrawEventAPI(String eventId) async {
    setState(() {
      isJoinLoading = true;
    });
    ForgotPasswordResponseModel model = ForgotPasswordResponseModel();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(
          context,
          listen: false,
        ).withdrawEventAPI(eventId, userid);
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).isSuccess ==
              true) {
            setState(() {
              model = Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).withdrawEventresponse.response as ForgotPasswordResponseModel;
              isJoinLoading = false;
              showToast(model.message ?? "");
            });
            getEventDetailsAPI(eventId);
          } else {
            isJoinLoading = false;
            showToast(
              Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).withdrawEventresponse.msg,
            );
          }
        }
      } else {
        setState(() {
          isJoinLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  getEventDetailsAPI(String eventId) async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(
          context,
          listen: false,
        ).getEventDetailsAPI(eventId);
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).isSuccess ==
              true) {
            setState(() {
              eventDetailsResponseModel = Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).eventDetailsresponse.response as EventDetailsResponseModel;
              isLoading = false;
              isUserJoined = eventDetailsResponseModel.data!.participants?.any(
                    (participant) => participant.userId.toString() == userid,
                  ) ??
                  false;
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

  addCallIdJoinEventAPI(String eventId) async {
    setState(() {
      isJoinLoading = true;
    });
    List<Map<String, dynamic>> callEvent =
        await _speedDatingService.generateUniqueRoundRobinSchedule(
      eventDetailsResponseModel.data!.participants!,
      eventDetailsResponseModel.data!.id.toString(),
      eventDetailsResponseModel.data!.eventType.toString(),
      eventDetailsResponseModel.data!.startTime!,
    );
    JoinEventCallidResponseModel eventCallidResponseModel =
        JoinEventCallidResponseModel();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(
          context,
          listen: false,
        ).joinEventCallAPI(callEvent, eventId);
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).isSuccess ==
              true) {
            await checkJoinEventAPI(eventId);
          }
        }
      } else {
        setState(() {
          isJoinLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  String convertUTCtoLocalFormatted(String utcDateTimeString) {
    DateTime utcTime = DateTime.parse(utcDateTimeString);
    DateTime localTime = utcTime.toLocal();
    return DateFormat('EEE, d MMM yyyy \'at\' hh:mm a').format(localTime);
  }

  checkJoinEventAPI(String eventId) async {
    setState(() {
      isJoinLoading = true;
    });
    AlreadyJoinEventCallResponseModel alreadyJoinEventCallResponseModel =
        AlreadyJoinEventCallResponseModel();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(
          context,
          listen: false,
        ).checkjoinEventCallAPI(eventId, userid);
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).isSuccess ==
              true) {
            setState(() {
              alreadyJoinEventCallResponseModel =
                  Provider.of<EventFeedViewModel>(
                context,
                listen: false,
              ).alreadyjoinEventCallresponse.response
                      as AlreadyJoinEventCallResponseModel;
              isJoinLoading = false;
            });

            DateTime startTime = DateTime.parse(
              "${DateTime.now().toIso8601String().split('T')[0]} ${alreadyJoinEventCallResponseModel.round!.reqData!.startTime}",
            );
            DateTime endTime = DateTime.parse(
              "${DateTime.now().toIso8601String().split('T')[0]} ${alreadyJoinEventCallResponseModel.round!.reqData!.endTime}",
            );
            DateTime currentTime = DateTime.now();
            DateTime earlyStartTime = startTime.subtract(Duration(minutes: 5));
            if (currentTime.isBefore(earlyStartTime)) {
              setState(() {
                isJoinLoading = false;
              });

              showToast(Languages.of(context)!.waitforeventstarttxt);
            } else if (currentTime.isAfter(endTime)) {
              setState(() {
                isJoinLoading = false;
              });
              showToast(Languages.of(context)!.eventendedtxt);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventLiveScreen(
                    id: alreadyJoinEventCallResponseModel.round!.reqData!.id
                        .toString(),
                    eventId: eventId,
                  ),
                ),
              ).then((value) async {
                await getEventDetailsAPI(widget.eventId);
              });
            }
          } else {
            if (Provider.of<EventFeedViewModel>(
                  context,
                  listen: false,
                ).alreadyjoinEventCallresponse.code ==
                201) {
              setState(() {
                isJoinLoading = false;
              });
              showToast(
                Provider.of<EventFeedViewModel>(
                  context,
                  listen: false,
                ).alreadyjoinEventCallresponse.msg,
              );
            } else {
              setState(() {
                isJoinLoading = false;
                alreadyJoinEventCallResponseModel =
                    Provider.of<EventFeedViewModel>(
                  context,
                  listen: false,
                ).alreadyjoinEventCallresponse.response
                        as AlreadyJoinEventCallResponseModel;
              });
              if (eventDetailsResponseModel.data!.participants!.length >= 2) {
                await addCallIdJoinEventAPI(eventId);
              } else {
                showToast(Languages.of(context)!.twoparticipantsjointxt);
              }
            }
          }
        }
      } else {
        setState(() {
          isJoinLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  DateTime convertEDTtoLocalDate(DateTime serverDateTime) {
    DateTime utcDateTime = serverDateTime.add(Duration(hours: 4));
    var dateTimeUtc = DateFormat(
      "yyyy-MM-dd HH:mm:ss",
    ).parse(utcDateTime.toString(), true);
    DateTime localDateTime = dateTimeUtc.toLocal();
    print("localDateTime == $localDateTime");
    return localDateTime;
  }

  // checkJoinEventAPI(String eventId) async {
  //   setState(() {
  //     isJoinLoading = true;
  //   });
  //   AlreadyJoinEventCallResponseModel alreadyJoinEventCallResponseModel =
  //       AlreadyJoinEventCallResponseModel();
  //   getuserid();
  //   isInternetAvailable().then((isConnected) async {
  //     if (isConnected) {
  //       await Provider.of<EventFeedViewModel>(context, listen: false)
  //           .checkjoinEventCallAPI(eventId, userid);
  //       if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
  //           false) {
  //         if (Provider.of<EventFeedViewModel>(context, listen: false)
  //                 .isSuccess ==
  //             true) {
  //           setState(() {
  //             alreadyJoinEventCallResponseModel =
  //                 Provider.of<EventFeedViewModel>(context, listen: false)
  //                     .alreadyjoinEventCallresponse
  //                     .response as AlreadyJoinEventCallResponseModel;
  //             isJoinLoading = false;
  //           });

  //           // String todayDate = DateTime.now().toIso8601String().split('T')[0];
  //           // DateTime fullStartTimeStr = DateTime.parse(
  //           //     "$todayDate ${alreadyJoinEventCallResponseModel.round!.reqData!.startTime!}");
  //           // DateTime fullEndTimeStr = DateTime.parse(
  //           //     "$todayDate ${alreadyJoinEventCallResponseModel.round!.reqData!.endTime!}");
  //           // DateTime localStartTime = convertEDTtoLocalDate(fullStartTimeStr);
  //           // DateTime localEndTime = convertEDTtoLocalDate(fullEndTimeStr);
  //           // DateTime currentzTime = DateTime.now();
  //           // print("currentTime === $currentzTime");
  //           // print("localStartTime === $localStartTime");
  //           // print("localEndTime === $localEndTime");
  //           // print(
  //           //     "alreadyJoinEventCallResponseModel === ${alreadyJoinEventCallResponseModel.toJson()}");
  //           DateTime startTime = DateTime.parse(
  //             "${DateTime.now().toIso8601String().split('T')[0]} ${alreadyJoinEventCallResponseModel.round!.reqData!.startTime}",
  //           );
  //           DateTime endTime = DateTime.parse(
  //             "${DateTime.now().toIso8601String().split('T')[0]} ${alreadyJoinEventCallResponseModel.round!.reqData!.endTime}",
  //           );
  //           String startDate = eventDetailsResponseModel.data!.startTime!
  //               .toIso8601String()
  //               .split('T')[0];
  //           DateTime fullStartTimeStr = DateTime.parse(
  //               "$startDate ${alreadyJoinEventCallResponseModel.round!.reqData!.startTime!}");
  //           DateTime fullEndTimeStr = DateTime.parse(
  //               "$startDate ${alreadyJoinEventCallResponseModel.round!.reqData!.endTime!}");
  //           DateTime currentTime = DateTime.now();

  //           if (currentTime.isBefore(fullStartTimeStr)) {
  //             setState(() {
  //               isJoinLoading = false;
  //             });
  //             print("wait for event start");

  //             showToast(Languages.of(context)!.waitforeventstarttxt);
  //           } else if (currentTime.isAfter(fullEndTimeStr)) {
  //             setState(() {
  //               isJoinLoading = false;
  //             });
  //             print("event ended");
  //             showToast(Languages.of(context)!.eventendedtxt);
  //           } else {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                   builder: (context) => EventLiveScreen(
  //                         id: alreadyJoinEventCallResponseModel
  //                             .round!.reqData!.id
  //                             .toString(),
  //                         eventId: eventId,
  //                       )),
  //             ).then(
  //               (value) async {
  //                 await getEventDetailsAPI(widget.eventId);
  //               },
  //             );
  //           }
  //         } else {
  //           if (Provider.of<EventFeedViewModel>(context, listen: false)
  //                   .alreadyjoinEventCallresponse
  //                   .code ==
  //               201) {
  //             setState(() {
  //               isJoinLoading = false;
  //             });
  //             showToast(Provider.of<EventFeedViewModel>(context, listen: false)
  //                 .alreadyjoinEventCallresponse
  //                 .msg);
  //           } else {
  //             setState(() {
  //               isJoinLoading = false;
  //               alreadyJoinEventCallResponseModel =
  //                   Provider.of<EventFeedViewModel>(context, listen: false)
  //                       .alreadyjoinEventCallresponse
  //                       .response as AlreadyJoinEventCallResponseModel;
  //             });
  //             if (eventDetailsResponseModel.data!.participants!.length >= 2) {
  //               await addCallIdJoinEventAPI(eventId);
  //             } else {
  //               showToast(Languages.of(context)!.twoparticipantsjointxt);
  //             }
  //           }
  //         }
  //       }
  //     } else {
  //       setState(() {
  //         isJoinLoading = false;
  //       });
  //       showToast(Languages.of(context)!.nointernettxt);
  //     }
  //   });
  // }

  getProfileDetails() async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(
          context,
          listen: false,
        ).getProfileAPI(userid, "", "", measurement);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              profileResponseModel = Provider.of<ProfileViewModel>(
                context,
                listen: false,
              ).profileresponse.response as ProfileResponseModel;

              genderItem = profileResponseModel.aboutMe!.firstWhere(
                (item) => item.type == 'Gender',
                orElse: () => AboutMe(),
              );
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
        await Provider.of<PurchaseViewModel>(
          context,
          listen: false,
        ).getPurchaseDetailsAPI(userid);
        if (Provider.of<PurchaseViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<PurchaseViewModel>(
                context,
                listen: false,
              ).isSuccess ==
              true) {
            setState(() {
              purchaseDetailsResponseModel = Provider.of<PurchaseViewModel>(
                context,
                listen: false,
              ).purchasedetailsresponse.response
                  as PurchaseDetailsResponseModel;

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
