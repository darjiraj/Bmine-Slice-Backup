import 'dart:async';
import 'dart:ui';

import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/grediant_text.dart';
import 'package:bmine_slice/Utils/user_status_service.dart';
import 'package:bmine_slice/Utils/utils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/homefeedresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/models/swipecountresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/filterscreen.dart';
import 'package:bmine_slice/screen/giftscreen.dart';
import 'package:bmine_slice/screen/myprofilescreen.dart';
import 'package:bmine_slice/screen/notificationscreen.dart';
import 'package:bmine_slice/screen/subscriptionscreen.dart';
import 'package:bmine_slice/screen/swipescreen.dart';
import 'package:bmine_slice/screen/virtualmeetingrequestscreen.dart';
import 'package:bmine_slice/viewmodels/homefeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/likefeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/meetingviewmodel.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:bmine_slice/viewmodels/userreportviewmodel.dart';
import 'package:bmine_slice/widgets/video_widgets.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_badge_manager/flutter_badge_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  TextEditingController dateandtimecontroller = TextEditingController();
  SharedPreferences? prefs;
  String userid = "";
  String measurementtype = "";
  bool isLoading = false;
  bool isReqLoading = false;
  bool isLikeLoading = false;
  int unreadNotiCount = 0;

  List<HomeFeedData> homeFeedData = [];
  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();
  SwipeCountResponseModel swipeCountResponseModel = SwipeCountResponseModel();
  PageController _pagecontroller = PageController();
  int _currentPage = 0;
  int _lastPage = 0;
  int maxFreeSwipes = 10;
  int lastRemainSwipe = 10;
  bool hasShownAlert = false;
  String firebaseId = "";

  getuserid() async {
    FlutterBadgeManager.remove();
    prefs = await SharedPreferences.getInstance();
    userid = prefs!.getString('userid') ?? "";
    measurementtype = prefs!.getString('Measurement') ?? "KM";
    firebaseId = prefs!.getString("firebaseId") ?? "";
    if (firebaseId.isNotEmpty) {
      UserStatusService().init(firebaseId);
    }
    setState(() {});
  }

  final List<int> _currentIntroPage = [];
  final List<PageController> _pageController = [];
  late AnimationController _controller;
  bool serviceEnabled = false;
  LocationPermission? permission;
  List<List<Map<String, String>>> userInfoData = [];
  Position? _currentPosition;
  final RouteObserver<ModalRoute<void>> _routeObserver =
      RouteObserver<ModalRoute<void>>();
  StreamSubscription<DatabaseEvent>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _pagecontroller = PageController();
    getHomeDataFeedAPI();
    getSwipeCountAPI(0);
    getPurchaseDetailsAPI();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _saveLastPosition();
    _routeObserver.unsubscribe(this);
    _userSubscription?.cancel();

    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _pagecontroller.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    print("User navigated away from feed screen");
    _saveLastPosition();
  }

  @override
  void didPopNext() {
    print("User returned to feed screen");
    _loadLastPosition();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("AppLifecycleState changed to: $state");

    if (state == AppLifecycleState.paused) {
      print("App paused - saving position: $_currentPage");
      _saveLastPosition();
    } else if (state == AppLifecycleState.resumed) {
      FlutterBadgeManager.remove();
      print("App resumed");
    }
  }

  Future<void> _saveLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_feed_position', _currentPage);
    await prefs.setInt('last_leave_page', _lastPage);
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPosition = prefs.getInt('last_feed_position') ?? 0;
    _lastPage = prefs.getInt('last_leave_page') ?? 0;
    print("last_feed_position=== $lastPosition");
    if (homeFeedData.isNotEmpty && lastPosition < homeFeedData.length) {
      setState(() {
        _currentPage = lastPosition;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_pagecontroller.hasClients) {
          _pagecontroller.jumpToPage(lastPosition);
        }
      });
    }
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
                    Languages.of(context)!.maxswipesreachtxt,
                    style: Appstyle.quicksand18w600,
                  ),
                  SizedBox(height: 10),
                  Text(
                    Languages.of(context)!.youreachmax20swipestxt,
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
                          await getPurchaseDetailsAPI();
                        },
                      );
                    },
                    filled: true,
                  ),
                  SizedBox(height: 10),
                  _buildDialogButton(
                    text: Languages.of(context)!.purchaseswipestxt,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return SwipesScreen();
                        },
                      )).then(
                        (value) async {
                          print("value == $value");
                          await getPurchaseDetailsAPI(message: value);
                          await getSwipeCountAPI(0);
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
          width: double.infinity,
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
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.applogo,
                    height: 25,
                    width: 35,
                    fit: BoxFit.fill,
                  ),
                  GradientText(
                    text: Languages.of(context)!.bminetxt,
                    style: Appstyle.marcellusSC24w500,
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        ).then(
                          (value) async {
                            await getHomeDataFeedAPI();
                            await getSwipeCountAPI(0);
                            await getPurchaseDetailsAPI();
                          },
                        );
                      },
                      child: unreadNotiCount >= 1
                          ? badges.Badge(
                              badgeAnimation:
                                  const badges.BadgeAnimation.rotation(),
                              badgeContent: Text(
                                unreadNotiCount.toString(),
                                style: Appstyle.quicksand13w600
                                    .copyWith(color: Colors.white),
                              ),
                              position: badges.BadgePosition.custom(
                                  start: 13, bottom: 10),
                              child: Image.asset(
                                AppAssets.notificationicon,
                                height: 25,
                                width: 25,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationScreen(),
                                  ),
                                ).then(
                                  (value) async {
                                    await getHomeDataFeedAPI();
                                    await getSwipeCountAPI(0);
                                    await getPurchaseDetailsAPI();
                                  },
                                );
                              },
                            )
                          : Image.asset(
                              AppAssets.notificationicon,
                              height: 25,
                              width: 25,
                            )),
                  const SizedBox(
                    width: 15,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FiltersScreen(),
                        ),
                      ).then(
                        (value) async {
                          await getHomeDataFeedAPI();
                          await getSwipeCountAPI(0);
                          await getPurchaseDetailsAPI();
                        },
                      );
                    },
                    child: Image.asset(
                      AppAssets.filtericon,
                      height: 30,
                      width: 30,
                    ),
                  ),
                ],
              )
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
            :
            // RefreshIndicator(
            //     onRefresh: () async {
            //       await getHomeDataFeedAPI();
            //     },
            // child:
            Stack(
                children: [
                  homeFeedData.isEmpty
                      ? SizedBox(
                          height: kSize.height,
                          width: kSize.width,
                          child: Center(
                            child: Text(
                              Languages.of(context)!.nodatafoundtxt,
                              style: Appstyle.quicksand16w500
                                  .copyWith(color: AppColors.blackclr),
                            ),
                          ),
                        )
                      : PageView.builder(
                          controller: _pagecontroller,
                          itemCount: homeFeedData.length,
                          physics: _currentPage >= maxFreeSwipes - 1
                              ? const ClampingScrollPhysics()
                              : const AlwaysScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          onPageChanged: (value) {
                            print("on page changes");
                            setState(() {
                              _currentPage = value;
                            });
                            if (_pagecontroller.position.userScrollDirection ==
                                ScrollDirection.reverse) {
                              if (_lastPage < value) {
                                final swipeCount = swipeCountResponseModel
                                        .userSwipe?.first.swipeCount ??
                                    0;

                                if (swipeCount <= 0) {
                                  _pagecontroller
                                      .jumpToPage(value > 0 ? (value - 1) : 0);
                                  setState(() {
                                    _lastPage = _currentPage;
                                  });
                                  _showSubscriptionAlert();
                                  return;
                                } else {
                                  getSwipeCountAPI(1);
                                  setState(() {
                                    _lastPage = _currentPage;
                                  });
                                }
                              }
                            }
                          },
                          itemBuilder: (context, index) {
                            List<String> imageList = [];
                            if (homeFeedData[index].posts != null &&
                                homeFeedData[index].posts!.isNotEmpty) {
                              imageList = homeFeedData[index]
                                  .posts!
                                  .map((post) => post.images ?? "")
                                  .toList();
                            } else {
                              imageList = [];
                            }

                            userInfoData.clear();
                            userInfoData = filterValidUserData(
                                homeFeedData[index].toJson());
                            // print("userInfoData == $userInfoData");

                            return homeFeedDataWidget(
                                context, index, imageList);
                          }),
                  isLikeLoading
                      ? Container(
                          height: kSize.height,
                          width: kSize.width,
                          color: Colors.transparent,
                        )
                      : Container(),
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
        // ),
      ),
    );
  }

  List<List<Map<String, String>>> filterValidUserData(
      Map<String, dynamic> userData) {
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

  homeFeedDataWidget(BuildContext context, int index, List<String> imageList) {
    return SizedBox(
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
                    frdId: homeFeedData[index].id.toString(),
                  ),
                ),
              ).then(
                (value) async {
                  await getPurchaseDetailsAPI();
                },
              );
            },
            child: ClipRRect(
              // borderRadius: BorderRadius.circular(25),
              child: PageView.builder(
                itemCount: imageList.isEmpty ? 1 : imageList.length,
                controller: _pageController[index],
                onPageChanged: (pageIndex) {
                  setState(() {
                    _currentIntroPage[index] = pageIndex;
                  });
                },
                itemBuilder: (context, i) {
                  final mediaUrl = imageList.isNotEmpty ? imageList[i] : null;

                  final isVideo = isVideoUrl(mediaUrl ?? "");
                  // String status =
                  // _getStatus(homeFeedData[index].firebaseId ?? "")
                  //         as String? ??
                  //     "";

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        // borderRadius:
                        //     BorderRadius.circular(10),
                        child: mediaUrl == null
                            ? Image.asset(
                                AppAssets.femaleUser,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : isVideo
                                ? VideoWidget(
                                    videoUrl: "${API.baseUrl}/upload/$mediaUrl")
                                : Image.network(
                                    "${API.baseUrl}/upload/$mediaUrl",
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      } else {
                                        return SizedBox(
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.bminetxtclr,
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
                                    errorBuilder: (context, error, stackTrace) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(
                                          AppAssets.femaleUser,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder(
                              future: _getStatus(
                                  homeFeedData[index].firebaseId ?? ""),
                              builder: (context, snapshot) {
                                return Row(
                                  children: [
                                    Container(
                                      height: 10,
                                      width: 10,
                                      decoration: BoxDecoration(
                                          color: snapshot.data == "online"
                                              ? Colors.green
                                              : snapshot.data == "offline"
                                                  ? AppColors.darkwhiteclr
                                                  : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      snapshot.data ?? "",
                                      style: Appstyle.quicksand13w500.copyWith(
                                        color: snapshot.data == "online"
                                            ? AppColors.darkwhiteclr
                                            : snapshot.data == "offline"
                                                ? AppColors.darkwhiteclr
                                                : Colors.transparent,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            Row(
                              children: [
                                Text(
                                    "${homeFeedData[index].firstName}"
                                    "${homeFeedData[index].dob != null ? ", ${calculateAge(homeFeedData[index].dob!)}" : ""}",
                                    style: Appstyle.quicksand21w600
                                        .copyWith(color: AppColors.whiteclr)),
                                homeFeedData[index].isVerify == 1
                                    ? Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: Image.asset(
                                          AppAssets.verifiedicon,
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
                                        CrossAxisAlignment.start,
                                    children: [
                                      homeFeedData[index].hometown == null
                                          ? Container()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 5),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                    AppAssets.home_town,
                                                    color: AppColors.whiteclr,
                                                    height: 14,
                                                    width: 14,
                                                  ),
                                                  SizedBox(
                                                    width: 4,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      homeFeedData[index]
                                                              .hometown ??
                                                          "",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                            ),
                                      homeFeedData[index].work == null
                                          ? Container()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    AppAssets.workicon,
                                                    color: AppColors.whiteclr,
                                                    height: 14,
                                                    width: 14,
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      homeFeedData[index]
                                                              .work ??
                                                          "",
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
                                            ),
                                      homeFeedData[index].education == null
                                          ? Container()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    AppAssets.educationcon,
                                                    color: AppColors.whiteclr,
                                                    height: 14,
                                                    width: 14,
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                        homeFeedData[index]
                                                                .education ??
                                                            "",
                                                        style: Appstyle
                                                            .quicksand16w600
                                                            .copyWith(
                                                                color: AppColors
                                                                    .darkwhiteclr)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      homeFeedData[index].distance == null
                                          ? Container()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    AppAssets.locationicon,
                                                    color: AppColors.whiteclr,
                                                    height: 14,
                                                    width: 14,
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                        '${homeFeedData[index].distance != null ? homeFeedData[index].distance!.round() : 0} ${measurementtype == "MI" ? Languages.of(context)!.milesawaytxt : Languages.of(context)!.kilometerawaytxt}',
                                                        style: Appstyle
                                                            .quicksand16w600
                                                            .copyWith(
                                                                color: AppColors
                                                                    .darkwhiteclr)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: (userInfoData.isNotEmpty
                                            ? (i < userInfoData.length
                                                ? userInfoData[i]
                                                : userInfoData.last)
                                            : [])
                                        .map((entry) {
                                      if (entry["type"] == "bio") {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            '${entry["value"]}',
                                            style: Appstyle.quicksand16w600
                                                .copyWith(
                                              color: AppColors.darkwhiteclr,
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Row(
                                            children: [
                                              Image.asset(
                                                _getIconForType(
                                                    entry["type"] ?? ""),
                                                color: AppColors.whiteclr,
                                                height: 14,
                                                width: 14,
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  '${entry["value"]}',
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(imageList.length, (indx) {
                    return Expanded(
                      child: Container(
                        //color: Colors.amber,
                        alignment: Alignment.topCenter,
                        decoration: BoxDecoration(
                            color: _currentIntroPage[index] == indx
                                ? AppColors.whiteclr
                                : AppColors.indexclrgreyclr.withAlpha(50),
                            borderRadius: BorderRadius.circular(5)),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 15),
                        height: 5,
                        width: 50,
                      ),
                    );
                  }),
                ),
          Positioned(
            right: 3,
            top: 5,
            child: InkWell(
              onTap: () {
                showMenu(
                  context: context,
                  color: AppColors.whiteclr,
                  menuPadding: EdgeInsets.zero,
                  position: RelativeRect.fromLTRB(100, 100, 0, 0),
                  items: [
                    PopupMenuItem<String>(
                      // padding: EdgeInsets.zero,
                      value: 'share',
                      onTap: () {
                        showShareOptions(
                            context,
                            homeFeedData[index].id.toString(),
                            homeFeedData[index].firstName.toString());
                      },
                      child: Text(
                        Languages.of(context)!.shareText,
                        style: Appstyle.quicksand16w500
                            .copyWith(color: AppColors.blackclr),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      padding: EdgeInsets.only(left: 10),
                      onTap: () {
                        _showReportUserAlertDialog(
                            homeFeedData[index].firstName ?? "",
                            homeFeedData[index].posts!.isNotEmpty
                                ? homeFeedData[index].posts![0].images ?? ""
                                : "",
                            homeFeedData[index].id.toString(),
                            "report",
                            index);
                      },
                      child: Text(
                        Languages.of(context)!.reporttxt,
                        style: Appstyle.quicksand16w500
                            .copyWith(color: AppColors.blackclr),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block-user',
                      onTap: () {
                        _showReportUserAlertDialog(
                            homeFeedData[index].firstName ?? "",
                            homeFeedData[index].posts!.isNotEmpty
                                ? homeFeedData[index].posts![0].images ?? ""
                                : "",
                            homeFeedData[index].id.toString(),
                            "block-user",
                            index);
                      },
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        Languages.of(context)!.blocktxt,
                        style: Appstyle.quicksand16w500
                            .copyWith(color: AppColors.blackclr),
                      ),
                    ),
                  ],
                ).then((value) {
                  print(value);
                  // _showReportUserAlertDialog(
                  //     homeFeedData[index].firstName ?? "",
                  //     homeFeedData[index].posts!.isNotEmpty
                  //         ? homeFeedData[index].posts![0].images ?? ""
                  //         : "",
                  //     homeFeedData[index].id.toString(),
                  //     value ?? "",
                  //     index);
                });
              },
              child: Icon(
                Icons.more_vert_rounded,
                size: 30,
                color: AppColors.whiteclr,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final swipeCount = swipeCountResponseModel
                                  .userSwipe?.first.swipeCount ??
                              0;

                          if (swipeCount <= 0 && index >= _lastPage) {
                            _showSubscriptionAlert();
                            return;
                          }
                          await userLikeAPI(userid,
                              homeFeedData[index].id.toString(), "2", index);
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
                        onTap: () async {
                          final swipeCount = swipeCountResponseModel
                                  .userSwipe?.first.swipeCount ??
                              0;

                          if (swipeCount <= 0 && index >= _lastPage) {
                            _showSubscriptionAlert();
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GiftScreen(
                                frd_id: homeFeedData[index].id.toString(),
                                isSettingScreen: false,
                              ),
                            ),
                          ).then(
                            (value) async {
                              await getPurchaseDetailsAPI();
                              print("value ====> $value");
                              if (value == "send-gift") {
                                userLikeAPI(
                                    userid,
                                    homeFeedData[index].id.toString(),
                                    "1",
                                    index);
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
                        onTap: () {
                          final swipeCount = swipeCountResponseModel
                                  .userSwipe?.first.swipeCount ??
                              0;

                          if (swipeCount <= 0 && index >= _lastPage) {
                            _showSubscriptionAlert();
                            return;
                          }
                          if (purchaseDetailsResponseModel
                                  .userVirtualMeetingReq!.totalCount! >=
                              1) {
                            _showAlertDialog(
                                homeFeedData[index].firstName ?? "",
                                homeFeedData[index].posts!.isNotEmpty
                                    ? homeFeedData[index].posts![0].images ?? ""
                                    : "",
                                homeFeedData[index].id.toString(),
                                index);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VirtualMeetingRequestsScreen(),
                              ),
                            ).then(
                              (value) async {
                                await getSwipeCountAPI(0);
                                await getPurchaseDetailsAPI();
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
                        onTap: () {
                          final swipeCount = swipeCountResponseModel
                                  .userSwipe?.first.swipeCount ??
                              0;

                          if (swipeCount <= 0 && index >= _lastPage) {
                            _showSubscriptionAlert();
                            return;
                          }
                          userLikeAPI(userid, homeFeedData[index].id.toString(),
                              "1", index);
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
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showAlertDialog(String name, String img, String frdId, int index) {
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
                              await sendMeetingRequestAPI(frdId, index);
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
                                  // purchaseDetailsResponseModel
                                  //             .userVirtualMeetingReq!
                                  //             .totalCount! >=
                                  //         1
                                  //     ?
                                  Languages.of(context)!.confirmtxt,
                                  // : purchaseDetailsResponseModel
                                  //             .userMembership!.planName ==
                                  //         "Plus"
                                  //     ? Languages.of(context)!.pay34_99txt
                                  //     : purchaseDetailsResponseModel
                                  //                 .userMembership!
                                  //                 .planName ==
                                  //             "Pro"
                                  //         ? Languages.of(context)!
                                  //             .pay29_99txt
                                  //         : purchaseDetailsResponseModel
                                  //                     .userMembership!
                                  //                     .planName ==
                                  //                 "Elite"
                                  //             ? Languages.of(context)!
                                  //                 .pay29_99txt
                                  //             : Languages.of(context)!
                                  //                 .pay39_99txt,
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
                          "${type == "report" ? Languages.of(context)!.reportusermsgtxt : Languages.of(context)!.blockusermsgtxt} ${name.isNotEmpty ? name : Languages.of(context)!.thisusertxt}?",
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
                                      itemBuilder: (context, index) {
                                        return Row(
                                          children: [
                                            Radio(
                                              value: reasons.values
                                                  .elementAt(index),
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
                                            Text(reasons.keys.elementAt(index))
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

  userLikeAPI(String id_from, String id_to, String is_like, int index) async {
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
            setState(() {
              isLikeLoading = false;
              ForgotPasswordResponseModel model =
                  Provider.of<LikeFeedViewModel>(context, listen: false)
                      .userlikeresponse
                      .response as ForgotPasswordResponseModel;
              // showToast(model.message!);
            });

            setState(() {
              if (index < homeFeedData.length) {
                _currentPage = index + 1;
                _lastPage = _lastPage - 1;
                homeFeedData.removeAt(index);
              }
            });
            await getSwipeCountAPI(1);

            // if (swipeCountResponseModel.userSwipe != null ||
            //     swipeCountResponseModel.userSwipe!.isNotEmpty ||
            //     swipeCountResponseModel.userSwipe![0].swipeCount != null ||
            //     swipeCountResponseModel.userSwipe![0].swipeCount! >= 0) {
            //   await getSwipeCountAPI(1);
            // }
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

  getFilterValuefroomPrefs() async {
    prefs = await SharedPreferences.getInstance();
    userid = prefs!.getString('userid') ?? "";
    measurementtype = prefs!.getString('Measurement') ?? "KM";
    firebaseId = prefs!.getString("firebaseId") ?? "";
    setState(() {});
  }

  getHomeDataFeedAPI() async {
    setState(() {
      homeFeedData = [];
      isLoading = true;
    });
    await getLocation();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<HomeFeedViewModel>(context, listen: false)
            .getHomeFeedAPI(
                userid,
                _currentPosition != null
                    ? _currentPosition!.latitude.toString()
                    : "",
                _currentPosition != null
                    ? _currentPosition!.longitude.toString()
                    : "",
                prefs!.getString("finGender") ?? "",
                prefs!.getString("finAge") ?? "",
                prefs!.getString("finDistanceAway") ?? "",
                prefs!.getString("finisVerify") ?? "",
                prefs!.getString("finHeight") ?? "",
                prefs!.getString("finLookingFor") ?? "",
                prefs!.getString("finSelLanguage") ?? "",
                prefs!.getBool("finisShowHeight") ?? false,
                prefs!.getBool("finisShowLookingFor") ?? false,
                measurementtype);
        if (Provider.of<HomeFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<HomeFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              HomeFeedResponseModel model =
                  Provider.of<HomeFeedViewModel>(context, listen: false)
                      .homefeedresponse
                      .response as HomeFeedResponseModel;

              homeFeedData = model.homeFeedData ?? [];
              unreadNotiCount = model.unreadCount ?? 0;
              for (var element in homeFeedData) {
                _pageController.add(PageController(initialPage: 0));
                _currentIntroPage.add(0);
              }
              _loadLastPosition();

              isLoading = false;
            });
          } else {
            setState(() {
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

  getLocation() async {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }
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
      // isLoading = true;
      _currentPosition = position;
    });
    prefs = await SharedPreferences.getInstance();
    bool isLocation = prefs!.getBool("IsLocationStart") ?? false;
    print("isLocation == $isLocation");
    if (!isLocation) {
      APIService.startPeriodicApiCall((result) async {
        print("RESULT ===== $result");
      });
    }
  }

  Map<dynamic, dynamic> userMap = {};
  Future<String> _getStatus(String userId) async {
    try {
      if (userId.isEmpty) {
        return "";
      }

      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('users/$userId');
      print("userRef == $userRef");
      await _userSubscription?.cancel();
      _userSubscription = userRef.onValue.listen((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          // print("event.snapshot.value == ${event.snapshot.value}");

          setState(() {
            userMap = event.snapshot.value as Map<dynamic, dynamic>;
          });
        }
      });
      // print("userMap == $userMap");

      return userMap['status'] ?? "";
    } catch (e) {
      print('Error fetching profile photo from Realtime Database: $e');
      return '';
    }
  }

  sendMeetingRequestAPI(String frdId, int index) async {
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

              // showToast(model.message!);
            });
            await getPurchaseDetailsAPI();
            userLikeAPI(userid, frdId, "1", index);
          } else {
            setState(() {
              isReqLoading = false;
            });
            // showToast(Provider.of<MeetingViewModel>(context, listen: false)
            //     .sendmeetingtrequestresponse
            //     .msg
            //     .toString());
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

  updateSwipesCountAPI(int rmainCount) async {
    print("updateMeetingRequestCountAPI function call");
    setState(() {
      // isReqLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<PurchaseViewModel>(context, listen: false)
            .updateSwipesCount(
                purchaseDetailsResponseModel.userSwipe!.swipes![0].id
                    .toString(),
                rmainCount.toString());
        if (Provider.of<PurchaseViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<PurchaseViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              lastRemainSwipe = rmainCount;
            });

            // await getPurchaseDetailsAPI();
          } else {
            setState(() {
              // isReqLoading = false;
            });
            // showToast(Provider.of<PurchaseViewModel>(context, listen: false)
            //     .swipescountresponse
            //     .msg
            //     .toString());
          }
        }
      } else {
        setState(() {
          // isReqLoading = false;
        });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
  }

  getPurchaseDetailsAPI({String? message}) async {
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
              if (message != null) {
                maxFreeSwipes = maxFreeSwipes +
                    purchaseDetailsResponseModel.userSwipe!.totalCount!;
                lastRemainSwipe =
                    purchaseDetailsResponseModel.userSwipe!.totalCount ?? 0;
              } else {
                maxFreeSwipes =
                    purchaseDetailsResponseModel.userSwipe!.totalCount ?? 0;
                lastRemainSwipe =
                    purchaseDetailsResponseModel.userSwipe!.totalCount ?? 0;
              }
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            // showToast(Provider.of<PurchaseViewModel>(context, listen: false)
            //     .purchasedetailsresponse
            //     .msg
            //     .toString());
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

  getSwipeCountAPI(int isValue) async {
    print("getSwipeCountAPI function call");

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
              // isReqLoading = false;
              print("Success");
              swipeCountResponseModel =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .swipecountresponse
                      .response as SwipeCountResponseModel;
            });
          } else {
            // showToast(Provider.of<PurchaseViewModel>(context, listen: false)
            //     .swipecountresponse
            //     .msg
            //     .toString());
          }
        }
      } else {
        // setState(() {
        //   isReqLoading = false;
        // });
        showToast(Languages.of(context)!.nointernettxt);
      }
    });
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
              // showToast(model.message!);
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            // showToast(Provider.of<UserReportViewModel>(context, listen: false)
            //     .userreportresponse
            //     .msg
            //     .toString());
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
              // showToast(model.message!);
              homeFeedData.removeAt(index);
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            // showToast(Provider.of<UserReportViewModel>(context, listen: false)
            //     .userblockresponse
            //     .msg
            //     .toString());
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
