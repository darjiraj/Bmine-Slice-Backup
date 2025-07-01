import 'dart:async';
import 'dart:ui';

import 'package:blur/blur.dart';
import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/utils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/likefeedresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/giftscreen.dart';
import 'package:bmine_slice/screen/myprofilescreen.dart';
import 'package:bmine_slice/screen/subscriptionscreen.dart';
import 'package:bmine_slice/screen/virtualmeetingrequestscreen.dart';
import 'package:bmine_slice/viewmodels/likefeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/meetingviewmodel.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:bmine_slice/viewmodels/userreportviewmodel.dart';
import 'package:bmine_slice/widgets/video_widgets.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikeScreen extends StatefulWidget {
  const LikeScreen({super.key});

  @override
  State<LikeScreen> createState() => _LikeScreenState();
}

class _LikeScreenState extends State<LikeScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController dateandtimecontroller = TextEditingController();

  late TabController _tabController;
  SharedPreferences? prefs;
  List<LikeFeedData> likedFeedData = [];
  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();
  List<List<Map<String, String>>> userInfoData = [];
  String userid = "";
  String measurementtype = "";
  bool isLoading = false;
  bool isLikeLoading = false;
  bool serviceEnabled = false;
  bool isReqLoading = false;
  LocationPermission? permission;
  Position? _currentPosition;
  int availableVirtualReq = 2;

  getuserid() async {
    prefs = await SharedPreferences.getInstance();
    userid = prefs!.getString('userid') ?? "";
    measurementtype = prefs!.getString('Measurement') ?? "KM";
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() async {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          await getLikeFeedData('like_you');
        } else if (_tabController.index == 1) {
          await getLikeFeedData('you_like');
        } else if (_tabController.index == 2) {
          await getLikeFeedData('you_dislike');
        }
      }
    });
    getLikeFeedData('like_you');
    getPurchaseDetailsAPI();
  }

  @override
  void dispose() {
    for (var sub in _userSubscriptions.values) {
      sub.cancel();
    }
    _tabController.dispose();
    super.dispose();
  }

  // Color _hexToColor(String hex) {
  //   hex = hex.toUpperCase().replaceAll("#", "");
  //   if (hex.length == 6) {
  //     hex = "FF$hex"; // Add opacity if not provided
  //   }
  //   return Color(int.parse(hex, radix: 16));
  // }

  final List<int> _currentIntroPage = [];
  // late PageController ;
  final List<PageController> _pageController = [];

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
              Text(Languages.of(context)!.likestxt,
                  style: Appstyle.marcellusSC24w500
                      .copyWith(color: AppColors.blackclr)),
              InkWell(
                onTap: () async {
                  if (likedFeedData.isEmpty) {
                    showToast(Languages.of(context)!.dataalreadyclearedtxt);
                  } else {
                    _showClearListAlertDialog();
                  }
                },
                child: Text(Languages.of(context)!.clearlisttxt,
                    style:
                        Appstyle.quicksand16w600.copyWith(color: Colors.red)),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.signinclr1,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                // onTap: (value) async {
                //   if (value == 0) {
                //     await getLikeFeedData('like_you');
                //   } else if (value == 1) {
                //     await getLikeFeedData('you_like');
                //   } else if (value == 2) {
                //     await getLikeFeedData('you_dislike');
                //   }
                // },
                labelStyle: Appstyle.quicksand15w600
                    .copyWith(color: AppColors.blackclr),
                unselectedLabelStyle:
                    Appstyle.quicksand15w600.copyWith(color: Colors.black54),
                tabs: [
                  Tab(text: Languages.of(context)!.likedyoutxt),
                  Tab(text: Languages.of(context)!.youlikedtxt),
                  Tab(text: Languages.of(context)!.youdislikedtxt),
                ],
              ),
            ),
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
                : Expanded(
                    child: Stack(
                      children: [
                        TabBarView(
                          controller: _tabController,
                          children: [
                            buildDataWidget(likedFeedData),
                            buildDataWidget(likedFeedData),
                            buildDataWidget(likedFeedData),
                          ],
                        ),
                        isReqLoading
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
                  )
          ],
        ),
      ),
    );
  }

  String _getIconForType(String type) {
    Map<String, String> iconMap = {
      "work": AppAssets.workicon,
      "education": AppAssets.educationcon,
      "gender": AppAssets.relationshipicon,
      "hometown": AppAssets.home_town,
      "height": AppAssets.heighticon,
      "exercise": AppAssets.dumbbell,
      "education_level": AppAssets.educationcon,
      "language": AppAssets.language,
      "smoking": AppAssets.smokingicon,
      "drinking": AppAssets.drinkicon,
      "ethnicity": AppAssets.humanicon,
      "horoscope": AppAssets.horoscopicon,
      "have_kid": AppAssets.kidsicon,
      "relationship": AppAssets.relationshipicon,
      "looking_for": AppAssets.search,
    };
    return iconMap[type] ?? AppAssets.search;
  }

  List<List<Map<String, String>>> filterValidUserData(
      Map<String, dynamic> userData) {
    print("filterValidUserData userData ==== $userData");
    List<String> keysToCheck = [
      "bio",
      "language",
      "gender",
      "height",
      "exercise",
      "education_level",
      "smoking",
      "drinking",
      "ethnicity",
      "horoscope",
      "have_kid",
      "relationship",
      "looking_for",
      "intrested"
    ];

    List<Map<String, String>> validData = [];

    if (userData["bio"] != null && userData["bio"].toString().isNotEmpty) {
      validData.add({"type": "bio", "value": userData["bio"].toString()});
    }

    validData.addAll(keysToCheck
        .where((key) =>
            userData[key] != null &&
            userData[key].toString().isNotEmpty &&
            key != "bio")
        .map((key) => {"type": key, "value": userData[key].toString()}));

    int numPosts = userData["posts"] != null ? userData["posts"].length : 0;
    int chunkSize = (numPosts <= 2) ? 4 : 3;

    List<List<Map<String, String>>> chunks = [];
    for (int i = 0; i < validData.length; i += chunkSize) {
      chunks.add(validData.sublist(
          i,
          (i + chunkSize < validData.length)
              ? i + chunkSize
              : validData.length));
    }

    return chunks;
  }

  Map<String, String> _userStatuses = {};
  Map<String, StreamSubscription<DatabaseEvent>> _userSubscriptions = {};
  void _subscribeToUserStatus(String userId) {
    if (userId.isEmpty || _userSubscriptions.containsKey(userId)) return;

    DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$userId');

    final subscription = userRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final status = data['status']?.toString() ?? "";

        setState(() {
          _userStatuses[userId] = status;
        });
      }
    });

    _userSubscriptions[userId] = subscription;
  }

  buildDataWidget(List<LikeFeedData> likeData) {
    return likeData.isEmpty
        ? Center(
            child: Text(
              Languages.of(context)!.nodatafoundtxt,
              style:
                  Appstyle.quicksand16w500.copyWith(color: AppColors.blackclr),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 5,
                    right: 5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: likeData.length,
                    itemBuilder: (BuildContext context, int index) {
                      List<String> imageList = [];

                      if (likeData[index].posts != null &&
                          likeData[index].posts!.isNotEmpty) {
                        imageList = likeData[index]
                            .posts!
                            .map((post) => post.images ?? "")
                            .toList();
                      } else {
                        imageList = [];
                      }
                      userInfoData.clear();
                      userInfoData =
                          filterValidUserData(likeData[index].toJson());
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: SizedBox(
                          height: 550,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyProfileScreen(
                                        isScreen: "Friend-Profile",
                                        frdId:
                                            likeData[index].userId.toString(),
                                      ),
                                    ),
                                  ).then(
                                    (value) async {
                                      if (_tabController.index == 0) {
                                        await getLikeFeedData('like_you');
                                        await getPurchaseDetailsAPI();
                                      } else if (_tabController.index == 1) {
                                        await getLikeFeedData('you_like');
                                        await getPurchaseDetailsAPI();
                                      } else if (_tabController.index == 2) {
                                        await getLikeFeedData('you_dislike');
                                        await getPurchaseDetailsAPI();
                                      }
                                    },
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: PageView.builder(
                                    itemCount: imageList.isEmpty
                                        ? 1
                                        : imageList.length,
                                    controller: _pageController[index],
                                    onPageChanged: (pageIndex) {
                                      print(pageIndex);
                                      setState(() {
                                        _currentIntroPage[index] = pageIndex;
                                      });
                                    },
                                    itemBuilder: (context, i) {
                                      final mediaUrl = imageList.isNotEmpty
                                          ? imageList[i]
                                          : null;
                                      final isVideo =
                                          isVideoUrl(mediaUrl ?? "");
                                      final firebaseId =
                                          likeData[index].firebaseId ?? "";
                                      _subscribeToUserStatus(
                                          firebaseId); // Call only once

                                      final status =
                                          _userStatuses[firebaseId] ?? "";

                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: mediaUrl == null
                                                ? Image.asset(
                                                    AppAssets.femaleUser,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  )
                                                : isVideo
                                                    ? VideoWidget(
                                                        videoUrl:
                                                            "${API.baseUrl}/upload/$mediaUrl")
                                                    : Image.network(
                                                        "${API.baseUrl}/upload/${imageList[i]}",
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context,
                                                            child,
                                                            loadingProgress) {
                                                          if (loadingProgress ==
                                                              null) {
                                                            return child;
                                                          } else {
                                                            return SizedBox(
                                                              width: double
                                                                  .infinity,
                                                              height: double
                                                                  .infinity,
                                                              child: Center(
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  color: AppColors
                                                                      .bminetxtclr,
                                                                  value: loadingProgress
                                                                              .expectedTotalBytes !=
                                                                          null
                                                                      ? loadingProgress
                                                                              .cumulativeBytesLoaded /
                                                                          loadingProgress
                                                                              .expectedTotalBytes!
                                                                      : null,
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            child: Image.asset(
                                                              AppAssets
                                                                  .femaleUser,
                                                              fit: BoxFit.cover,
                                                              width: double
                                                                  .infinity,
                                                              height: double
                                                                  .infinity,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.1),
                                                  Colors.black.withOpacity(0.4),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 120,
                                            left: 20,
                                            right: 20,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      height: 10,
                                                      width: 10,
                                                      decoration: BoxDecoration(
                                                        color: status ==
                                                                "online"
                                                            ? Colors.green
                                                            : status ==
                                                                    "offline"
                                                                ? AppColors
                                                                    .darkwhiteclr
                                                                : Colors
                                                                    .transparent,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      status,
                                                      style: Appstyle
                                                          .quicksand13w500
                                                          .copyWith(
                                                        color: status ==
                                                                "online"
                                                            ? AppColors
                                                                .darkwhiteclr
                                                            : status ==
                                                                    "offline"
                                                                ? AppColors
                                                                    .darkwhiteclr
                                                                : Colors
                                                                    .transparent,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                        "${likeData[index].firstName}"
                                                        "${likeData[index].dob != null ? ", ${calculateAge(likeData[index].dob!)}" : ""}",
                                                        style: Appstyle
                                                            .quicksand21w600
                                                            .copyWith(
                                                                color: AppColors
                                                                    .whiteclr)),
                                                    likeData[index].isVerify ==
                                                            1
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 5),
                                                            child: Image.asset(
                                                              AppAssets
                                                                  .verifiedicon,
                                                              height: 18,
                                                              width: 18,
                                                            ),
                                                          )
                                                        : Container()
                                                  ],
                                                ),
                                                i == 0
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          likeData[index]
                                                                      .hometown ==
                                                                  null
                                                              ? Container()
                                                              : Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                  child: Row(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Image
                                                                          .asset(
                                                                        AppAssets
                                                                            .home_town,
                                                                        color: AppColors
                                                                            .whiteclr,
                                                                        height:
                                                                            14,
                                                                        width:
                                                                            14,
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            4,
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          likeData[index].hometown ??
                                                                              "",
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          style: Appstyle
                                                                              .quicksand16w600
                                                                              .copyWith(
                                                                            color:
                                                                                AppColors.darkwhiteclr,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                          likeData[index]
                                                                      .work ==
                                                                  null
                                                              ? Container()
                                                              : Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                  child: Row(
                                                                    children: [
                                                                      Image
                                                                          .asset(
                                                                        AppAssets
                                                                            .workicon,
                                                                        color: AppColors
                                                                            .whiteclr,
                                                                        height:
                                                                            14,
                                                                        width:
                                                                            14,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          likeData[index].work ??
                                                                              "",
                                                                          style: Appstyle
                                                                              .quicksand16w600
                                                                              .copyWith(
                                                                            color:
                                                                                AppColors.darkwhiteclr,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                          likeData[index]
                                                                      .education ==
                                                                  null
                                                              ? Container()
                                                              : Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                  child: Row(
                                                                    children: [
                                                                      Image
                                                                          .asset(
                                                                        AppAssets
                                                                            .educationcon,
                                                                        color: AppColors
                                                                            .whiteclr,
                                                                        height:
                                                                            14,
                                                                        width:
                                                                            14,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                      Expanded(
                                                                        child: Text(
                                                                            likeData[index].education ??
                                                                                "",
                                                                            style:
                                                                                Appstyle.quicksand16w600.copyWith(color: AppColors.darkwhiteclr)),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                          likeData[index]
                                                                      .distance ==
                                                                  null
                                                              ? Container()
                                                              : Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                  child: Row(
                                                                    children: [
                                                                      Image
                                                                          .asset(
                                                                        AppAssets
                                                                            .locationicon,
                                                                        color: AppColors
                                                                            .whiteclr,
                                                                        height:
                                                                            14,
                                                                        width:
                                                                            14,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                      Expanded(
                                                                        child: Text(
                                                                            '${likeData[index].distance != null ? likeData[index].distance!.round() : 0} ${measurementtype == "MI" ? Languages.of(context)!.milesawaytxt : Languages.of(context)!.kilometerawaytxt}',
                                                                            style:
                                                                                Appstyle.quicksand16w600.copyWith(color: AppColors.darkwhiteclr)),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                        ],
                                                      )
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: (userInfoData
                                                                    .isNotEmpty
                                                                ? (i <
                                                                        userInfoData
                                                                            .length
                                                                    ? userInfoData[
                                                                        i]
                                                                    : userInfoData
                                                                        .last)
                                                                : [])
                                                            .map((entry) {
                                                          if (entry["type"] ==
                                                              "bio") {
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 5),
                                                              child: Text(
                                                                '${entry["value"]}',
                                                                style: Appstyle
                                                                    .quicksand16w600
                                                                    .copyWith(
                                                                  color: AppColors
                                                                      .darkwhiteclr,
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 5),
                                                              child: Row(
                                                                children: [
                                                                  Image.asset(
                                                                    _getIconForType(
                                                                        entry["type"] ??
                                                                            ""),
                                                                    color: AppColors
                                                                        .whiteclr,
                                                                    height: 14,
                                                                    width: 14,
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 5),
                                                                  Expanded(
                                                                    child: Text(
                                                                      '${entry["value"]}',
                                                                      style: Appstyle
                                                                          .quicksand16w600
                                                                          .copyWith(
                                                                        color: AppColors
                                                                            .darkwhiteclr,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }
                                                        }).toList(),
                                                      )
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              imageList.isEmpty || imageList.length == 1
                                  ? Container()
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(imageList.length,
                                          (indx) {
                                        return Expanded(
                                          child: Container(
                                            //color: Colors.amber,
                                            alignment: Alignment.topCenter,
                                            decoration: BoxDecoration(
                                                color:
                                                    _currentIntroPage[index] ==
                                                            indx
                                                        ? AppColors.whiteclr
                                                        : AppColors
                                                            .indexclrgreyclr
                                                            .withAlpha(50),
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 15),
                                            height: 5,
                                            width:
                                                _currentIntroPage[index] == indx
                                                    ? 50
                                                    : 50,
                                            // color: Color(0xff5B9EE1),
                                          ),
                                        );
                                      }),
                                    ),
                              Positioned(
                                right: 3,
                                top: 5,
                                child: PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    size: 30,
                                    color: AppColors.whiteclr,
                                  ),
                                  padding: EdgeInsets.zero,
                                  color: AppColors.whiteclr,
                                  onSelected: (value) {
                                    if (value == "share") {
                                      showShareOptions(
                                          context,
                                          likeData[index].id.toString(),
                                          likeData[index].firstName.toString());
                                    } else {
                                      _showReportUserAlertDialog(
                                          likeData[index].firstName ?? "",
                                          likeData[index].posts!.isNotEmpty
                                              ? likeData[index]
                                                      .posts![0]
                                                      .images ??
                                                  ""
                                              : "",
                                          likeData[index].id.toString(),
                                          value,
                                          index);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'share',
                                      padding: EdgeInsets.only(left: 10),
                                      height: 40,
                                      child: Text(
                                        Languages.of(context)!.shareText,
                                        style: Appstyle.quicksand16w500
                                            .copyWith(
                                                color: AppColors.blackclr),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'report',
                                      padding: EdgeInsets.only(left: 10),
                                      height: 40,
                                      child: Text(
                                        Languages.of(context)!.reporttxt,
                                        style: Appstyle.quicksand16w500
                                            .copyWith(
                                                color: AppColors.blackclr),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'block-user',
                                      height: 40,
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        Languages.of(context)!.blocktxt,
                                        style: Appstyle.quicksand16w500
                                            .copyWith(
                                                color: AppColors.blackclr),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'remove-user',
                                      height: 40,
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        Languages.of(context)!.removetxt,
                                        style: Appstyle.quicksand16w500
                                            .copyWith(
                                                color: AppColors.blackclr),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            await userLikeAPI(
                                                userid,
                                                likeData[index]
                                                    .userId
                                                    .toString(),
                                                "2");
                                          },
                                          child: Image.asset(
                                            AppAssets.dislikeicon,
                                            height: 80,
                                            width: 80,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    GiftScreen(
                                                  frd_id: likeData[index]
                                                      .userId
                                                      .toString(),
                                                  isSettingScreen: false,
                                                ),
                                              ),
                                            ).then(
                                              (value) async {
                                                if (_tabController.index == 0) {
                                                  await getLikeFeedData(
                                                      'like_you');
                                                  await getPurchaseDetailsAPI();
                                                } else if (_tabController
                                                        .index ==
                                                    1) {
                                                  await getLikeFeedData(
                                                      'you_like');
                                                  await getPurchaseDetailsAPI();
                                                } else if (_tabController
                                                        .index ==
                                                    2) {
                                                  await getLikeFeedData(
                                                      'you_dislike');
                                                  await getPurchaseDetailsAPI();
                                                }
                                              },
                                            );
                                          },
                                          child: Image.asset(
                                            AppAssets.gifticon,
                                            height: 80,
                                            width: 80,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            if (purchaseDetailsResponseModel
                                                    .userVirtualMeetingReq!
                                                    .totalCount! >=
                                                1) {
                                              _showAlertDialog(
                                                  likeData[index].firstName ??
                                                      "",
                                                  likeData[index]
                                                          .posts!
                                                          .isNotEmpty
                                                      ? likeData[index]
                                                              .posts![0]
                                                              .images ??
                                                          ""
                                                      : "",
                                                  likeData[index]
                                                      .userId
                                                      .toString());
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      VirtualMeetingRequestsScreen(),
                                                ),
                                              ).then(
                                                (value) async {
                                                  if (_tabController.index ==
                                                      0) {
                                                    await getLikeFeedData(
                                                        'like_you');
                                                    await getPurchaseDetailsAPI();
                                                  } else if (_tabController
                                                          .index ==
                                                      1) {
                                                    await getLikeFeedData(
                                                        'you_like');
                                                    await getPurchaseDetailsAPI();
                                                  } else if (_tabController
                                                          .index ==
                                                      2) {
                                                    await getLikeFeedData(
                                                        'you_dislike');
                                                    await getPurchaseDetailsAPI();
                                                  }
                                                },
                                              );
                                            }
                                          },
                                          child: Image.asset(
                                            AppAssets.livecallicon,
                                            height: 80,
                                            width: 80,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            await userLikeAPI(
                                                userid,
                                                likeData[index]
                                                    .userId
                                                    .toString(),
                                                "1");
                                          },
                                          child: Image.asset(
                                            AppAssets.likegreenicon,
                                            height: 80,
                                            width: 80,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              _tabController.index == 0
                                  ? purchaseDetailsResponseModel
                                              .userMembership!.planName ==
                                          null
                                      ? InkWell(
                                          onTap: () {
                                            _showSubscriptionAlert();
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Blur(
                                              blur: 15.0,
                                              blurColor: Colors.transparent,
                                              child: Container(),
                                            ),
                                          ),
                                        )
                                      : Container()
                                  : Container(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }

  void _showSubscriptionAlert() {
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
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.whiteclr,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Languages.of(context)!.upgradeyouraccounttxt,
                    style: Appstyle.quicksand18w600,
                  ),
                  SizedBox(height: 10),
                  Text(
                    Languages.of(context)!.upgradeyouraccountmsgtxt,
                    style: Appstyle.quicksand15w400,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  _buildDialogButton(
                    text: Languages.of(context)!.upgradeaccounttxt,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return SubscriptionScreen();
                        },
                      )).then(
                        (value) async {
                          if (_tabController.index == 0) {
                            await getLikeFeedData('like_you');
                            await getPurchaseDetailsAPI();
                          } else if (_tabController.index == 1) {
                            await getLikeFeedData('you_like');
                            await getPurchaseDetailsAPI();
                          } else if (_tabController.index == 2) {
                            await getLikeFeedData('you_dislike');
                            await getPurchaseDetailsAPI();
                          }
                        },
                      );
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

  void _showAlertDialog(String name, String img, String frdId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: AlertDialog(
            actionsAlignment: MainAxisAlignment.start,
            //actionsPadding: EdgeInsets.all(0.8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            // title:
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
                      height: 10,
                    ),
                    img.isEmpty
                        ? Center(
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: AppColors.lightgreyclr,
                                borderRadius: BorderRadius.circular(30),
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage(
                                      AppAssets.femaleUser,
                                    )),
                              ),
                            ),
                          )
                        : Center(
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: AppColors.lightgreyclr,
                                borderRadius: BorderRadius.circular(30),
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(
                                      "${API.baseUrl}/upload/$img",
                                    )),
                              ),
                            ),
                          ),
                    const SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: Text(
                        "${Languages.of(context)!.doyouwanttosendavirtualmeetrequesttojennytxt} ${name.isNotEmpty ? name : Languages.of(context)!.thisusertxt}?",
                        textAlign: TextAlign.center,
                        style: Appstyle.quicksand14w600
                            .copyWith(color: AppColors.blackclr),
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              await sendMeetingRequestAPI(frdId);
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

  void _showReportUserAlertDialog(
      String name, String img, String frdId, String type, int index) {
    Map<String, String> reasons = {
      Languages.of(context)!.harassmenttxt: "Harassment",
      Languages.of(context)!.verbalAbusetxt: "Verbal Abuse",
      Languages.of(context)!.fakeAccounttxt: "Fake Account",
      Languages.of(context)!.bullyingtxt: "Bullying",
      Languages.of(context)!.scamtxt: "Scam",
    };

    String selectedReason = "";
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
                        height: 10,
                      ),
                      img.isEmpty
                          ? Center(
                              child: Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.lightgreyclr,
                                  borderRadius: BorderRadius.circular(30),
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: AssetImage(
                                        AppAssets.femaleUser,
                                      )),
                                ),
                              ),
                            )
                          : Center(
                              child: Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.lightgreyclr,
                                  borderRadius: BorderRadius.circular(30),
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(
                                        "${API.baseUrl}/upload/$img",
                                      )),
                                ),
                              ),
                            ),
                      const SizedBox(
                        height: 10,
                      ),
                      Center(
                        child: Text(
                          "${type == "report" ? Languages.of(context)!.reportusermsgtxt : type == "remove-user" ? Languages.of(context)!.removeusermsgtxt : Languages.of(context)!.blockusermsgtxt} ${name.isNotEmpty ? name : Languages.of(context)!.thisusertxt}?",
                          textAlign: TextAlign.center,
                          style: Appstyle.quicksand14w600
                              .copyWith(color: AppColors.blackclr),
                        ),
                      ),
                      type == "report"
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    Languages.of(context)!.selectreasontitletxt,
                                    textAlign: TextAlign.center,
                                    style: Appstyle.quicksand14w600
                                        .copyWith(color: AppColors.blackclr),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: SizedBox(
                                    height: 180,
                                    child: ListView.builder(
                                      itemCount: reasons.length,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, i) {
                                        return Row(
                                          children: [
                                            Radio(
                                              value:
                                                  reasons.values.elementAt(i),
                                              groupValue: selectedReason,
                                              activeColor: AppColors.blueclr,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onChanged: (value) {
                                                setAState(() {
                                                  selectedReason = value ?? "";
                                                });
                                              },
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(reasons.keys.elementAt(i))
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                if (type == "report") {
                                  if (selectedReason.isEmpty) {
                                    showToast(
                                        "${Languages.of(context)!.selectreasontoasttxt} ${name.isNotEmpty ? name : Languages.of(context)!.thisusertxt}");
                                  } else {
                                    await userReportAPI(frdId, selectedReason);
                                    Navigator.pop(context);
                                  }
                                } else if (type == "remove-user") {
                                  await userRemoveAPI(frdId, index);
                                  Navigator.pop(context);
                                } else {
                                  await userBlockAPI(frdId, "1", index);
                                  Navigator.pop(context);
                                }
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
                                    type == "report"
                                        ? Languages.of(context)!.reporttxt
                                        : type == "remove-user"
                                            ? Languages.of(context)!.removetxt
                                            : Languages.of(context)!.blocktxt,
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
            );
          }),
        );
      },
    );
  }

  void _showClearListAlertDialog() {
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
                          Languages.of(context)!.clearlistalerttxt,
                          textAlign: TextAlign.center,
                          style: Appstyle.quicksand14w600
                              .copyWith(color: AppColors.blackclr),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                if (_tabController.index == 0) {
                                  await removeAllLikeUserAPI("1", "2");
                                } else if (_tabController.index == 1) {
                                  await removeAllLikeUserAPI("1", "1");
                                } else if (_tabController.index == 2) {
                                  await removeAllLikeUserAPI("2", "1");
                                }
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
                                    Languages.of(context)!.clearlisttxt,
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
            );
          }),
        );
      },
    );
  }

  userReportAPI(String frdId, String reason) async {
    print("userReportAPI function call");
    setState(() {
      isReqLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<UserReportViewModel>(context, listen: false)
            .userReportAPI(userid, frdId, reason);
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
                      .userreportresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            showToast(Provider.of<UserReportViewModel>(context, listen: false)
                .userreportresponse
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
              likedFeedData.removeAt(index);
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

  userRemoveAPI(String frdId, int index) async {
    print("userRemovePI function call");
    setState(() {
      isReqLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<UserReportViewModel>(context, listen: false)
            .userRemoveAPI(userid, frdId);
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
                      .userremoveresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
              likedFeedData.removeAt(index);
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            showToast(Provider.of<UserReportViewModel>(context, listen: false)
                .userremoveresponse
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

  userLikeAPI(
    String id_from,
    String id_to,
    String is_like,
  ) async {
    setState(() {
      isLikeLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<LikeFeedViewModel>(context, listen: false)
            .userLikeAPI(id_from, id_to, is_like);
        if (Provider.of<LikeFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<LikeFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            ForgotPasswordResponseModel model = ForgotPasswordResponseModel();
            setState(() {
              isLikeLoading = false;
              model = Provider.of<LikeFeedViewModel>(context, listen: false)
                  .userlikeresponse
                  .response as ForgotPasswordResponseModel;

              showToast(model.message!);
            });
            // if (model.message != 'User already liked.' &&
            //     model.message != 'User already disliked.') {
            if (_tabController.index == 0) {
              getLikeFeedData('like_you');
            } else if (_tabController.index == 1) {
              getLikeFeedData('you_like');
            } else if (_tabController.index == 2) {
              getLikeFeedData('you_dislike');
            }
            // }
            //     model.message !=  "User already disliked." ) {
            //        if (_tabController.index == 0) {
            //   await getLikeFeedData('like_you');
            // } else if (_tabController.index == 1) {
            //   await getLikeFeedData('you_like');
            // } else if (_tabController.index == 2) {
            //   await getLikeFeedData('you_dislike');
            // }
            //     }
          }
        }
      } else {
        setState(() {
          isLikeLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  getLocation() async {
    // Check if location services are enabled

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // Request permissions if they are not already granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message
        print('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, handle accordingly
      print('Location permissions are permanently denied.');
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("position === $position");
    setState(() {
      _currentPosition = position;
    });
  }

  getLikeFeedData(String tabType) async {
    print("getLikeFeedData === $tabType");
    setState(() {
      isLoading = true;
    });
    await getLocation();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<LikeFeedViewModel>(context, listen: false)
            .getLikeFeedDataAPI(
                userid,
                tabType,
                _currentPosition != null
                    ? _currentPosition!.latitude.toString()
                    : "",
                _currentPosition != null
                    ? _currentPosition!.longitude.toString()
                    : "",
                measurementtype);
        if (Provider.of<LikeFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<LikeFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              LikeFeedResponseModel model =
                  Provider.of<LikeFeedViewModel>(context, listen: false)
                      .likefeedresponse
                      .response as LikeFeedResponseModel;
              likedFeedData = model.likeFeedData ?? [];
              for (var element in likedFeedData) {
                _pageController.add(PageController(initialPage: 0));
                _currentIntroPage.add(0);
              }
              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = false;
              likedFeedData = [];
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

  sendMeetingRequestAPI(String frdId) async {
    print("sendMeetingRequestAPI function call");
    setState(() {
      isReqLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<MeetingViewModel>(context, listen: false)
            .sendMeetingRequest(userid, frdId);
        if (Provider.of<MeetingViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<MeetingViewModel>(context, listen: false).isSuccess ==
              true) {
            ForgotPasswordResponseModel model = ForgotPasswordResponseModel();

            setState(() {
              isReqLoading = false;
              print("Success");
              model = Provider.of<MeetingViewModel>(context, listen: false)
                  .sendmeetingtrequestresponse
                  .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
            await getPurchaseDetailsAPI();
          } else {
            setState(() {
              isReqLoading = false;
            });
            showToast(Provider.of<MeetingViewModel>(context, listen: false)
                .sendmeetingtrequestresponse
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

  removeAllLikeUserAPI(String is_like, String is_me) async {
    print("removeAllLikeUserAPI function call");
    setState(() {
      isReqLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<LikeFeedViewModel>(context, listen: false)
            .removeAllLikeUser(userid, is_like, is_me);
        if (Provider.of<LikeFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<LikeFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            ForgotPasswordResponseModel model = ForgotPasswordResponseModel();

            setState(() {
              isReqLoading = false;
              print("Success");
              model = Provider.of<LikeFeedViewModel>(context, listen: false)
                  .removealluserlikeresponse
                  .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
            if (_tabController.index == 0) {
              await getLikeFeedData('like_you');
              await getPurchaseDetailsAPI();
            } else if (_tabController.index == 1) {
              await getLikeFeedData('you_like');
              await getPurchaseDetailsAPI();
            } else if (_tabController.index == 2) {
              await getLikeFeedData('you_dislike');
              await getPurchaseDetailsAPI();
            }
            Navigator.pop(context);
          } else {
            setState(() {
              isReqLoading = false;
            });
            showToast(Provider.of<LikeFeedViewModel>(context, listen: false)
                .removealluserlikeresponse
                .msg
                .toString());
            Navigator.pop(context);
          }
        }
      } else {
        setState(() {
          isReqLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
        Navigator.pop(context);
      }
    });
  }

  getPurchaseDetailsAPI() async {
    print("getPurchaseDetailsAPI function call");
    setState(() {
      isReqLoading = true;
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
              isReqLoading = false;
              print("Success");
              purchaseDetailsResponseModel =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .purchasedetailsresponse
                      .response as PurchaseDetailsResponseModel;
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .purchasedetailsresponse
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
