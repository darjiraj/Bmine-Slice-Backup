import 'dart:ui';

import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/speed_dating_service.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/alreadyjoincallresponsemodel.dart';
import 'package:bmine_slice/models/eventdetailsresponsemodel.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/joineventcallresponsemodel.dart';
import 'package:bmine_slice/models/liveeventresponsemodel.dart';
import 'package:bmine_slice/models/profileresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/eventdetails.dart';
import 'package:bmine_slice/screen/eventlivescreen.dart';
import 'package:bmine_slice/screen/liveeventticketsscreen.dart';
import 'package:bmine_slice/viewmodels/eventfeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/profileviewmodel.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveEventsList extends StatefulWidget {
  const LiveEventsList({super.key});

  @override
  State<LiveEventsList> createState() => _LiveEventsListState();
}

class _LiveEventsListState extends State<LiveEventsList>
    with WidgetsBindingObserver {
  String userid = "";
  String measurement = "";
  bool isLoading = false;
  bool isJoinEventLoading = false;
  SharedPreferences? prefs;
  List<LiveEventDatum> liveEventData = [];
  ProfileResponseModel profileResponseModel = ProfileResponseModel();
  AboutMe genderItem = AboutMe();
  final SpeedDatingService _speedDatingService = SpeedDatingService();
  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();

  bool serviceEnabled = false;
  LocationPermission? permission;
  Position? _currentPosition;

  getuserid() async {
    prefs = await SharedPreferences.getInstance();
    userid = prefs!.getString('userid') ?? "";
    measurement = prefs!.getString('Measurement') ?? "KM";
    setState(() {});
  }

  Widget avatarCircle(double left, Color bgColor, String imageUrl) {
    return Positioned(
      left: left,
      child: CircleAvatar(
        backgroundColor: bgColor,
        backgroundImage: imageUrl.isNotEmpty
            ? NetworkImage("${API.baseUrl}/upload/$imageUrl")
            : AssetImage(AppAssets.femaleUser) as ImageProvider,
      ),
    );
  }

  getLocation() async {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // _showLocationServiceDialog();
      // setState(() {
      //   isLoading = false;
      // });
      print('Location services are disabled.');
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message
        // setState(() {
        //   isLoading = false;
        // });
        print('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, handle accordingly
      // setState(() {
      //   isLoading = false;
      // });
      print('Location permissions are permanently denied.');
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("position === $position");
    setState(() {
      // isLoading = true;
      _currentPosition = position;
    });
    prefs = await SharedPreferences.getInstance();
    bool isLocation = prefs!.getBool("IsLocationStart") ?? false;
    print("isLocation == $isLocation");
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
    getPurchaseDetails();
    getProfileDetails();
    getLiveEventFeedData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is back in the foreground
      print("App State == $state");
    }
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
            child: Container(
              color: AppColors.textfieldclr,
              height: 1.0,
            ),
          ),
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Languages.of(context)!.liveeventstxt,
                  style: Appstyle.marcellusSC24w500
                      .copyWith(color: AppColors.blackclr)),
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
            : liveEventData.isEmpty
                ? Center(
                    child: Text(
                    Languages.of(context)!.nodatafoundtxt,
                    style: Appstyle.quicksand16w500
                        .copyWith(color: AppColors.blackclr),
                  ))
                : Stack(
                    children: [
                      SingleChildScrollView(
                          child: Column(
                        children: [
                          const SizedBox(height: 10.0),
                          ListView.builder(
                            itemCount: liveEventData.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return _buildLiveEventWidget(
                                  liveEventData[index]);
                            },
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      )),
                      isJoinEventLoading
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
    );
  }

  String convertDate(DateTime serverDateTime) {
    DateTime utcDateTime = serverDateTime.add(Duration(hours: 4));
    var dateTimeUtc =
        DateFormat("yyyy-MM-dd HH:mm:ss").parse(utcDateTime.toString(), true);
    DateTime localDateTime = dateTimeUtc.toLocal();
    String formattedDate =
        DateFormat('EEE, d MMMM yyyy \'at\' hh:mm a').format(localDateTime);
    return formattedDate;
  }

  _buildLiveEventWidget(LiveEventDatum eventModel) {
    final isUserJoined = eventModel.participants
            ?.any((participant) => participant.userId.toString() == userid) ??
        false;
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventsDetailsScreen(
                eventId: eventModel.id.toString(),
              ),
            )).then(
          (value) async {
            await getPurchaseDetails();
            await getProfileDetails();
            await getLiveEventFeedData();
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12.0)
              ],
              color: AppColors.whiteclr,
              borderRadius: BorderRadius.circular(17.5)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventModel.eventName ?? "",
                  style: Appstyle.quicksand19w600
                      .copyWith(color: AppColors.blackclr),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 5.0),
                          Expanded(
                            child: Text(
                              convertDate(eventModel.startTime!),
                              // DateFormat('EEE, d MMMM yyyy \'at\' hh:mm a')
                              //     .format(eventModel.startTime!),
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
                  '${Languages.of(context)!.eventtypetxt}: '
                  '${eventModel.eventType == "Straight Men & Woman" ? Languages.of(context)!.straightmenwomantxt
                      //
                      : eventModel.eventType == "Lesbian Woman" ? Languages.of(context)!.lesbianwomantxt
                          //
                          : eventModel.eventType == "Gay Men" ? Languages.of(context)!.gaymentxt
                              //
                              : eventModel.eventType == "Trans all Woman" ? Languages.of(context)!.transallwomantxt
                                  //
                                  : eventModel.eventType == "Trans all Men" ? Languages.of(context)!.transallmentxt
                                      //
                                      : eventModel.eventType == "Gay & Lesbian" ? Languages.of(context)!.gaylesbiantxt
                                          //
                                          : eventModel.eventType == "Trans Men & Woman" ? Languages.of(context)!.transallmenwomantxt
                                              //
                                              // : eventModel.eventType == "Speed Dating" ? Languages.of(context)!.speeddatingtxt
                                              //
                                              // : eventModel.eventType == "Live Event" ? Languages.of(context)!.liveeventtxt
                                              //
                                              : eventModel.eventType ?? ""}',
                  style: Appstyle.quicksand14w400,
                ),
                Text(
                  '${Languages.of(context)!.locationtxt}: ${eventModel.city}',
                  style: Appstyle.quicksand14w400,
                ),
                Text(
                  '${Languages.of(context)!.deadlinetxt} ${convertDate(eventModel.deadline!)}',
                  style: Appstyle.quicksand14w400,
                ),
                Text(
                  '${Languages.of(context)!.agegrouptxt} ${eventModel.ageGroup}',
                  style: Appstyle.quicksand14w400,
                ),
                Text(
                  '${Languages.of(context)!.maxparticipatetxt} ${eventModel.maxParticipant}',
                  style: Appstyle.quicksand14w400,
                ),
                Text(
                  '${Languages.of(context)!.remainingtxt} ${eventModel.remaining}',
                  style: Appstyle.quicksand14w400,
                ),
                const SizedBox(height: 8.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    eventModel.participants!.isEmpty
                        ? Container()
                        : SizedBox(
                            height: 50,
                            width: eventModel.participants!.length > 5
                                ? 30 * 6
                                : 30 * (eventModel.participants!.length + 1),
                            child: Stack(
                              children: [
                                for (int i = 0;
                                    i < eventModel.participants!.length &&
                                        i < 5;
                                    i++)
                                  avatarCircle(
                                    i * 30.0,
                                    Colors.blueGrey.shade100,
                                    eventModel.participants![i].post == null
                                        ? ""
                                        : eventModel.participants![i].post!
                                                .images ??
                                            "",
                                  ),
                              ],
                            ),
                          ),
                    Text(
                      '${eventModel.participants!.length} ${Languages.of(context)!.participantstxt}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                isUserJoined
                    ? Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await checkJoinEventAPI(eventModel);
                              },
                              child: Container(
                                height: 50,
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
                                        Languages.of(context)!.startsessiontxt,
                                        textAlign: TextAlign.center,
                                        style: Appstyle.quicksand16w500)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                _showWithdrawEventAlertDialog(eventModel);
                              },
                              child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.cancelbtnclr,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        width: 1,
                                        color: AppColors.bordergreyclr),
                                  ),
                                  child: Center(
                                    child: Text(
                                        Languages.of(context)!.withdrawtxt,
                                        style: Appstyle.quicksand16w500
                                            .copyWith(
                                                color: AppColors.blackclr)),
                                  )),
                            ),
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: InkWell(
                          onTap: () {
                            // if (purchaseDetailsResponseModel
                            //         .userLiveEventTickets!.remainTicket! >=
                            //     1) {
                            _showAlertDialog(eventModel);
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
                            width: MediaQuery.of(context).size.width / 2,
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
                                child: Text(Languages.of(context)!.joineventtxt,
                                    textAlign: TextAlign.center,
                                    style: Appstyle.quicksand16w500)),
                          ),
                        ),
                      ),
                const SizedBox(height: 10.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  checkJoinEventAPI(LiveEventDatum eventModel) async {
    setState(() {
      isJoinEventLoading = true;
    });
    AlreadyJoinEventCallResponseModel alreadyJoinEventCallResponseModel =
        AlreadyJoinEventCallResponseModel();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(context, listen: false)
            .checkjoinEventCallAPI(eventModel.id.toString(), userid);
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              alreadyJoinEventCallResponseModel =
                  Provider.of<EventFeedViewModel>(context, listen: false)
                      .alreadyjoinEventCallresponse
                      .response as AlreadyJoinEventCallResponseModel;
              isJoinEventLoading = false;
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
                isJoinEventLoading = false;
              });
              showToast(Languages.of(context)!.waitforeventstarttxt);
            } else if (currentTime.isAfter(endTime)) {
              setState(() {
                isJoinEventLoading = false;
              });
              showToast(Languages.of(context)!.eventendedtxt);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EventLiveScreen(
                          id: alreadyJoinEventCallResponseModel
                              .round!.reqData!.id
                              .toString(),
                          eventId: eventModel.id.toString(),
                        )),
              ).then(
                (value) async {
                  await getLiveEventFeedData();
                  await getPurchaseDetails();
                },
              );
            }
          } else {
            if (Provider.of<EventFeedViewModel>(context, listen: false)
                    .alreadyjoinEventCallresponse
                    .code ==
                201) {
              setState(() {
                isJoinEventLoading = false;
              });
              showToast(Provider.of<EventFeedViewModel>(context, listen: false)
                  .alreadyjoinEventCallresponse
                  .msg);
            } else {
              setState(() {
                alreadyJoinEventCallResponseModel =
                    Provider.of<EventFeedViewModel>(context, listen: false)
                        .alreadyjoinEventCallresponse
                        .response as AlreadyJoinEventCallResponseModel;
                isJoinEventLoading = false;
              });
              if (eventModel.participants!.length >= 2) {
                await addCallIdJoinEventAPI(eventModel);
              } else {
                showToast(Languages.of(context)!.twoparticipantsjointxt);
              }
            }
          }
        }
      } else {
        setState(() {
          isJoinEventLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  addCallIdJoinEventAPI(LiveEventDatum eventModel) async {
    setState(() {
      isJoinEventLoading = true;
    });
    getuserid();
    JoinEventCallidResponseModel eventCallidResponseModel =
        JoinEventCallidResponseModel();
    List<Participants> participants = eventModel.participants!.map((p) {
      return Participants(
        id: p.id,
        eventId: p.eventId,
        userId: p.userId,
        firstName: p.firstName,
        lastName: p.lastName,
        dob: p.dob,
        profileImage: p.profileImage,
        gender: p.gender,
        post: p.post != null
            ? Posts(
                id: p.post!.id,
                userId: p.post!.userId,
                images: p.post!.images,
                createdAt: p.post!.createdAt,
                updatedAt: p.post!.updatedAt,
                deletedAt: p.post!.deletedAt,
              )
            : null,
      );
    }).toList();

    List<Map<String, dynamic>> callEvent =
        await _speedDatingService.generateUniqueRoundRobinSchedule(
            participants,
            eventModel.id.toString(),
            eventModel.eventType.toString(),
            eventModel.startTime!);

    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(context, listen: false)
            .joinEventCallAPI(
          callEvent,
          eventModel.id.toString(),
        );
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            await checkJoinEventAPI(eventModel);
          }
        }
      } else {
        setState(() {
          isJoinEventLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  void _showAlertDialog(LiveEventDatum event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: AlertDialog(
            actionsAlignment: MainAxisAlignment.start,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                        "${Languages.of(context)!.doyouwanttojoineventtxt} ${event.eventName ?? ""}?",
                        textAlign: TextAlign.center,
                        style: Appstyle.quicksand14w600
                            .copyWith(color: AppColors.blackclr),
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
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
                            // onTap: () async {

                            //   if (event.remaining == "0") {
                            //     showToast(
                            //         Languages.of(context)!.eventfullybookedtxt);
                            //     return;
                            //   }

                            //   if (profileResponseModel.userProfile!.dob ==
                            //       null) {
                            //     showToast(Languages.of(context)!.updatedobtxt);
                            //     return;
                            //   }

                            //   int age = calculateAge(
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

                            //   // Count participants based on their full gender label
                            //   Map<String, int> genderCounts = {};
                            //   for (var participant in event.participants!) {
                            //     String? gender = participant.gender;
                            //     if (gender != null) {
                            //       genderCounts[gender] =
                            //           (genderCounts[gender] ?? 0) + 1;
                            //     }
                            //   }

                            //   // Updated mapping based on sexuality and identity
                            //   Map<String, List<String>> eventGenders = {
                            //     'Straight Men & Woman': [
                            //       'Man - Straight',
                            //       'Woman - Straight',
                            //       'Man - Bi',
                            //       'Woman - Bi',
                            //     ],
                            //     'Lesbian Woman': [
                            //       'Woman',
                            //       'Woman - Bi',
                            //     ],
                            //     'Gay Men': [
                            //       'Man',
                            //       'Man - Bi',
                            //     ],
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
                            //     String userGender = genderItem.value ?? "";
                            //     if (allowedGenders.contains(userGender)) {
                            //       int maxPerGender = (event.maxParticipant! /
                            //               allowedGenders.length)
                            //           .floor();

                            //       if ((genderCounts[userGender] ?? 0) >=
                            //           maxPerGender) {
                            //         showToast(
                            //             "${Languages.of(context)!.eventfullforgendertxt} $userGender");
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
                            onTap: () async {
                              if (event.remaining == "0") {
                                showToast(
                                    Languages.of(context)!.eventfullybookedtxt);
                                return;
                              }
                              if (profileResponseModel.userProfile!.dob ==
                                  null) {
                                showToast(Languages.of(context)!.updatedobtxt);
                                return;
                              }
                              int age = calculateAge(
                                  profileResponseModel.userProfile!.dob!);
                              if (age < 18) {
                                showToast(
                                    Languages.of(context)!.joinafter18txt);
                                return;
                              }
                              List<String> ageGroup =
                                  event.ageGroup!.split('-');
                              int minAge = int.parse(ageGroup[0]) - 3;
                              int maxAge = int.parse(ageGroup[1]) + 3;

                              if (age < minAge || age > maxAge) {
                                showToast(Languages.of(context)!
                                    .agerestrictionineventtxt);
                                return;
                              }
                              if (genderItem.value == null) {
                                showToast(
                                    Languages.of(context)!.updategendertxt);
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
                                'Gay Men': [
                                  'Man - Gay',
                                  'Man - Bi',
                                ],
                                'Gay & Lesbian': [
                                  'Man - Gay',
                                  'Woman - Lesbian',
                                ],
                                'Trans all Woman': ['Trans-Woman'],
                                'Trans all Men': ['Trans-Man'],
                                'Trans Men & Woman': [
                                  'Trans-Man',
                                  'Trans-Woman'
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
                                        "${Languages.of(context)!.eventfullforgendertxt} $userGender");
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
                                      "${Languages.of(context)!.openonlygendertxt} ${allowedGenderText.toLowerCase()}.");
                                }
                              } else {
                                showToast(
                                    Languages.of(context)!.invalideventtypetxt);
                              }
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
                                  Languages.of(context)!.confirmtxt,
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
                              // width: 100,
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
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showWithdrawEventAlertDialog(LiveEventDatum event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: AlertDialog(
            actionsAlignment: MainAxisAlignment.start,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                        "${Languages.of(context)!.doyouwanttowithdraweventtxt} ${event.eventName ?? ""}?",
                        textAlign: TextAlign.center,
                        style: Appstyle.quicksand14w600
                            .copyWith(color: AppColors.blackclr),
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
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
                              // width: 100,
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
                                  Languages.of(context)!.confirmtxt,
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
                              // width: 100,
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
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  int calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  getProfileDetails() async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .getProfileAPI(userid, "", "", measurement);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              profileResponseModel =
                  Provider.of<ProfileViewModel>(context, listen: false)
                      .profileresponse
                      .response as ProfileResponseModel;

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

  getLiveEventFeedData() async {
    setState(() {
      isLoading = true;
    });
    await getLocation();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(context, listen: false)
            .getLiveEventFeedDataAPI(
                userid,
                _currentPosition != null
                    ? _currentPosition!.latitude.toString()
                    : "",
                _currentPosition != null
                    ? _currentPosition!.longitude.toString()
                    : "");
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              LiveEventResponseModel model =
                  Provider.of<EventFeedViewModel>(context, listen: false)
                      .liveEventfeedresponse
                      .response as LiveEventResponseModel;

              liveEventData = model.data ?? [];
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

  joinLiveAPI(String eventId) async {
    setState(() {
      isJoinEventLoading = true;
    });
    ForgotPasswordResponseModel model = ForgotPasswordResponseModel();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(context, listen: false)
            .joinEventAPI(eventId, userid);
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isJoinEventLoading = false;
              model = Provider.of<EventFeedViewModel>(context, listen: false)
                  .joinEventresponse
                  .response as ForgotPasswordResponseModel;
              showToast(model.message ?? "");
            });
            await getLiveEventFeedData();
            await getPurchaseDetails();
          } else {
            isJoinEventLoading = false;
            showToast(Provider.of<EventFeedViewModel>(context, listen: false)
                .joinEventresponse
                .msg);
          }
        }
      } else {
        setState(() {
          isJoinEventLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  withdrawEventAPI(String eventId) async {
    setState(() {
      isJoinEventLoading = true;
    });
    ForgotPasswordResponseModel model = ForgotPasswordResponseModel();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(context, listen: false)
            .withdrawEventAPI(eventId, userid);
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              model = Provider.of<EventFeedViewModel>(context, listen: false)
                  .withdrawEventresponse
                  .response as ForgotPasswordResponseModel;
              isJoinEventLoading = false;
              showToast(model.message ?? "");
            });
            await getLiveEventFeedData();
            await getPurchaseDetails();
          } else {
            isJoinEventLoading = false;
            showToast(Provider.of<EventFeedViewModel>(context, listen: false)
                .withdrawEventresponse
                .msg);
          }
        }
      } else {
        setState(() {
          isJoinEventLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }
}
