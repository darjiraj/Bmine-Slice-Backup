import 'dart:ui';

import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/emoji_mapper.dart';
import 'package:bmine_slice/Utils/utils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/profileresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/editprofile.dart';
import 'package:bmine_slice/screen/giftscreen.dart';
import 'package:bmine_slice/screen/settingscreen.dart';
import 'package:bmine_slice/screen/subscriptionscreen.dart';
import 'package:bmine_slice/screen/virtualmeetingrequestscreen.dart';
import 'package:bmine_slice/viewmodels/likefeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/meetingviewmodel.dart';
import 'package:bmine_slice/viewmodels/profileviewmodel.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:bmine_slice/viewmodels/userreportviewmodel.dart';
import 'package:bmine_slice/widgets/video_widgets.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyProfileScreen extends StatefulWidget {
  String isScreen = "";
  String? frdId;
  MyProfileScreen({super.key, required this.isScreen, this.frdId});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  // Color _hexToColor(String hex) {
  //   hex = hex.toUpperCase().replaceAll("#", "");
  //   if (hex.length == 6) {
  //     hex = "FF$hex"; // Add opacity if not provided
  //   }
  //   return Color(int.parse(hex, radix: 16));
  // }

  int _currentIntroPage = 0;
  final PageController _pageController = PageController(initialPage: 0);
  late AnimationController _controller;
  SharedPreferences? prefs;
  String frdid = "";
  String userid = "";
  String firebaseId = "";
  String measurementtype = "";
  bool isLoading = false;
  bool isLikeLoading = false;
  bool isReqLoading = false;
  bool serviceEnabled = false;
  int availableVirtualReq = 2;
  LocationPermission? permission;
  Position? _currentPosition;

  TextEditingController dateandtimecontroller = TextEditingController();
  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();

  ProfileResponseModel profileResponseModel = ProfileResponseModel();
  List<String> imageList = [];
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  getuserid() async {
    prefs = await SharedPreferences.getInstance();
    userid = prefs!.getString('userid') ?? "";
    firebaseId = prefs!.getString('firebaseId') ?? "";
    measurementtype = prefs!.getString('Measurement') ?? "KM";
    setState(() {});
    print("measurementtype === $measurementtype");
  }

  @override
  void initState() {
    super.initState();
    print("widget.isScreen === ${widget.isScreen}");
    _controller = AnimationController(vsync: this);
    getProfileDetails();
    // getPurchaseDetailsAPI();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double calculateContentHeight(
      BuildContext context, ProfileResponseModel profile) {
    final double screenHeight = MediaQuery.of(context).size.height;
    double totalHeight = 0;
    double basePadding = widget.isScreen == "Friend-Profile" ? 25.0 : 35.0;
    double sectionSpacing = widget.isScreen == "Friend-Profile" ? 22.0 : 32.0;
    double itemSpacing = widget.isScreen == "Friend-Profile" ? 15.0 : 25.0;
    totalHeight += screenHeight / 1.9;
    if (widget.isScreen == "Friend-Profile") {
      totalHeight += 120.0;
    }
    totalHeight += basePadding * 2;
    totalHeight += 35.0;
    if (profile.userProfile?.bio != null) {
      totalHeight += 40.0;
    }
    if (widget.isScreen == "Friend-Profile" &&
        profile.userProfile?.distance != null) {
      totalHeight += 40.0;
    }
    if (profile.aboutMe != null && profile.aboutMe!.isNotEmpty) {
      totalHeight += sectionSpacing;
      totalHeight += 40.0;
      totalHeight += itemSpacing;
      final int itemCount = profile.aboutMe!
          .where((data) => data.value != null && data.value!.isNotEmpty)
          .length;
      totalHeight += (itemCount / 3).ceil() * 60.0;
    }
    if (profile.lookingFor != null && profile.lookingFor!.isNotEmpty) {
      totalHeight += sectionSpacing;
      totalHeight += 40.0;
      totalHeight += itemSpacing;

      final int itemCount =
          profile.lookingFor!.where((item) => item.isNotEmpty).length;
      totalHeight += (itemCount / 3).ceil() * 60.0;
    }
    if (profile.intrested != null && profile.intrested!.isNotEmpty) {
      totalHeight += sectionSpacing;
      totalHeight += 40.0;
      totalHeight += itemSpacing;

      final int itemCount =
          profile.intrested!.where((item) => item.isNotEmpty).length;
      totalHeight += (itemCount / 3).ceil() * 60.0;
    }
    totalHeight += 85.0;
    if (widget.isScreen == "My-Profile") {
      totalHeight += 85.0;
    } else {
      totalHeight += 70.0;
    }
    totalHeight += basePadding * 2;

    return totalHeight;
  }

  @override
  Widget build(BuildContext context) {
    var kSize = MediaQuery.of(context).size;
    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppColors.whiteclr,
        appBar: widget.isScreen == "Friend-Profile"
            ? AppBar(
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
                  children: [
                    // const SizedBox(
                    //   width: 10,
                    // ),
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
                      Languages.of(context)!.profiletxt,
                      style: Appstyle.marcellusSC20w500
                          .copyWith(color: AppColors.blackclr),
                    )
                  ],
                ),
                actions: [
                  InkWell(
                    onTap: () {
                      showMenu(
                        context: context,
                        color: AppColors.whiteclr,
                        menuPadding: EdgeInsets.zero,
                        position: RelativeRect.fromLTRB(100, 80, 0, 0),
                        items: [
                          PopupMenuItem(
                            value: 'share',
                            padding: EdgeInsets.only(left: 10),
                            onTap: () {
                              showShareOptions(
                                  context,
                                  profileResponseModel.userProfile!.id
                                      .toString(),
                                  profileResponseModel.userProfile!.firstName
                                      .toString());
                            },
                            height: 40,
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
                                  profileResponseModel.userProfile!.firstName ??
                                      "",
                                  profileResponseModel.postData!.isNotEmpty
                                      ? profileResponseModel
                                              .postData![0].images ??
                                          ""
                                      : "",
                                  profileResponseModel.userProfile!.id
                                      .toString(),
                                  'report');
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
                                  profileResponseModel.userProfile!.firstName ??
                                      "",
                                  profileResponseModel.postData!.isNotEmpty
                                      ? profileResponseModel
                                              .postData![0].images ??
                                          ""
                                      : "",
                                  profileResponseModel.userProfile!.id
                                      .toString(),
                                  'block-user');
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
                        // _showReportUserAlertDialog(
                        //     profileResponseModel.userProfile!.firstName ?? "",
                        //     profileResponseModel.postData!.isNotEmpty
                        //         ? profileResponseModel.postData![0].images ?? ""
                        //         : "",
                        //     profileResponseModel.userProfile!.id.toString(),
                        //     value ?? "");
                      });
                    },
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 30,
                      color: AppColors.blackclr,
                    ),
                  ),
                ],
              )
            : AppBar(
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
                    Text(Languages.of(context)!.myprofiletxt,
                        style: Appstyle.marcellusSC24w500
                            .copyWith(color: AppColors.blackclr)),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingScreen(),
                            )).then(
                          (value) async {
                            await getProfileDetails();
                            await getPurchaseDetailsAPI();
                          },
                        );
                      },
                      child: Image.asset(
                        AppAssets.setting,
                        width: 25,
                        height: 25,
                      ),
                    )
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
                      child: LayoutBuilder(builder: (context, constraints) {
                        final double contentHeight = calculateContentHeight(
                          context,
                          profileResponseModel,
                        );
                        return SizedBox(
                          height: contentHeight + 50,
                          child: Stack(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height / 1.5,
                                child: Stack(
                                  children: [
                                    (profileResponseModel.postData?.isEmpty ??
                                            true)
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.asset(
                                                AppAssets.femaleUser,
                                                fit: BoxFit.fitHeight,
                                              ),
                                            ],
                                          )
                                        : PageView.builder(
                                            itemCount: profileResponseModel
                                                .postData!.length,
                                            controller: _pageController,
                                            onPageChanged: (pageIndex) {
                                              setState(() {
                                                _currentIntroPage = pageIndex;
                                              });
                                            },
                                            itemBuilder: (context, index) {
                                              final media = profileResponseModel
                                                  .postData![index];
                                              final mediaUrl =
                                                  "${API.baseUrl}/upload/${media.images}";
                                              final isVideo =
                                                  isVideoUrl(mediaUrl);
                                              return Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  if (isVideo)
                                                    VideoWidget(
                                                        videoUrl: mediaUrl)
                                                  else
                                                    Image.network(
                                                      mediaUrl,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            color: AppColors
                                                                .bminetxtclr,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Image.asset(
                                                          AppAssets.femaleUser,
                                                          fit: BoxFit.cover,
                                                        );
                                                      },
                                                    ),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.black
                                                              .withOpacity(0.1),
                                                          Colors.black
                                                              .withOpacity(0.4),
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                    profileResponseModel.postData == null ||
                                            profileResponseModel
                                                .postData!.isEmpty ||
                                            profileResponseModel
                                                    .postData!.length ==
                                                1
                                        ? Container()
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: List.generate(
                                                profileResponseModel
                                                    .postData!.length, (index) {
                                              return Expanded(
                                                child: Container(
                                                  alignment:
                                                      Alignment.topCenter,
                                                  decoration: BoxDecoration(
                                                      color: _currentIntroPage ==
                                                              index
                                                          ? AppColors.whiteclr
                                                          : AppColors
                                                              .indexclrgreyclr
                                                              .withAlpha(50),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5)),
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 5,
                                                      vertical: 15),
                                                  height: 5,
                                                  width:
                                                      _currentIntroPage == index
                                                          ? 50
                                                          : 50,
                                                ),
                                              );
                                            }),
                                          ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: MediaQuery.of(context).size.height / 2.0,
                                left: 10,
                                right: 10,
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    widget.isScreen == "Friend-Profile"
                                        ? Row(
                                            children: [
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    userLikeAPI(
                                                        userid,
                                                        profileResponseModel
                                                            .userProfile!.id
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
                                                          frd_id:
                                                              profileResponseModel
                                                                  .userProfile!
                                                                  .id
                                                                  .toString(),
                                                          isSettingScreen:
                                                              false,
                                                        ),
                                                      ),
                                                    ).then((value) async {
                                                      await getProfileDetails();
                                                      await getPurchaseDetailsAPI();
                                                    });
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
                                                    if (purchaseDetailsResponseModel
                                                            .userVirtualMeetingReq!
                                                            .totalCount! >=
                                                        1) {
                                                      _showAlertDialog(
                                                          profileResponseModel
                                                                  .userProfile!
                                                                  .firstName ??
                                                              "",
                                                          profileResponseModel
                                                                  .postData![
                                                                      _currentIntroPage]
                                                                  .images ??
                                                              "",
                                                          profileResponseModel
                                                              .userProfile!.id
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
                                                          await getProfileDetails();
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
                                                    userLikeAPI(
                                                        userid,
                                                        profileResponseModel
                                                            .userProfile!.id
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
                                          )
                                        : Container(
                                            height: 80,
                                          ),
                                    Container(
                                      decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.textfieldclr
                                                  .withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          color: AppColors.whiteclr,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20, right: 20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  height: 20,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "${profileResponseModel.userProfile == null ? "" : profileResponseModel.userProfile!.firstName ?? ""}"
                                                      "${profileResponseModel.userProfile == null ? "" : profileResponseModel.userProfile!.dob != null ? ", ${calculateAge(profileResponseModel.userProfile == null ? DateTime(0000) : profileResponseModel.userProfile!.dob!)}" : ""}",
                                                      style: Appstyle
                                                          .quicksand19w600
                                                          .copyWith(
                                                              color: AppColors
                                                                  .blackclr),
                                                    ),
                                                    widget.isScreen ==
                                                            "My-Profile"
                                                        ? InkWell(
                                                            onTap: () {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            EditProfileScreen(
                                                                      isScreen:
                                                                          "Edit-Profile",
                                                                    ),
                                                                  )).then(
                                                                (value) async {
                                                                  await getProfileDetails();
                                                                  await getPurchaseDetailsAPI();
                                                                },
                                                              );
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                    Languages.of(
                                                                            context)!
                                                                        .edittxt,
                                                                    style: Appstyle
                                                                        .marcellusSC18w500
                                                                        .copyWith(
                                                                            color:
                                                                                AppColors.blackclr)),
                                                                const SizedBox(
                                                                    width: 5),
                                                                Image.asset(
                                                                  AppAssets
                                                                      .editicon,
                                                                  height: 18,
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        : Container()
                                                  ],
                                                ),
                                                profileResponseModel
                                                            .userProfile ==
                                                        null
                                                    ? Container()
                                                    : profileResponseModel
                                                                .userProfile!
                                                                .bio ==
                                                            null
                                                        ? Container()
                                                        : Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 4),
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  "${Languages.of(context)!.biotxt} ",
                                                                  style: Appstyle
                                                                      .quicksand15w600
                                                                      .copyWith(
                                                                          color:
                                                                              AppColors.blackclr),
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    profileResponseModel.userProfile ==
                                                                            null
                                                                        ? ""
                                                                        : profileResponseModel.userProfile!.bio ??
                                                                            "",
                                                                    style: Appstyle
                                                                        .quicksand14w500
                                                                        .copyWith(
                                                                            color:
                                                                                AppColors.blackclr),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                profileResponseModel
                                                            .userProfile ==
                                                        null
                                                    ? Container()
                                                    : profileResponseModel
                                                                .userProfile!
                                                                .hometown ==
                                                            null
                                                        ? Container()
                                                        : Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 4),
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Image.asset(
                                                                  AppAssets
                                                                      .home_town,
                                                                  height: 15,
                                                                  width: 15,
                                                                ),
                                                                SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  profileResponseModel
                                                                              .userProfile ==
                                                                          null
                                                                      ? ""
                                                                      : profileResponseModel
                                                                              .userProfile!
                                                                              .hometown ??
                                                                          "",
                                                                  style: Appstyle
                                                                      .quicksand13w500
                                                                      .copyWith(
                                                                          color:
                                                                              AppColors.blackclr),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                widget.isScreen ==
                                                        "Friend-Profile"
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 4),
                                                        child: Row(
                                                          children: [
                                                            Image.asset(
                                                              AppAssets
                                                                  .locationicon,
                                                              height: 15,
                                                              width: 15,
                                                              color: AppColors
                                                                  .blackclr,
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                                '${profileResponseModel.userProfile == null ? "" : profileResponseModel.userProfile!.distance != 0 ? profileResponseModel.userProfile!.distance!.round() : 0} ${measurementtype == "MI" ? Languages.of(context)!.milesawaytxt : Languages.of(context)!.kilometerawaytxt}',
                                                                style: Appstyle
                                                                    .quicksand13w500
                                                                    .copyWith(
                                                                        color: AppColors
                                                                            .blackclr)),
                                                          ],
                                                        ),
                                                      )
                                                    : Container(),
                                                widget.isScreen ==
                                                        "Friend-Profile"
                                                    ? Container()
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const SizedBox(
                                                              height: 16),
                                                          Text(
                                                            Languages.of(
                                                                    context)!
                                                                .myMembershiptxt,
                                                            style: Appstyle
                                                                .quicksand18w600
                                                                .copyWith(
                                                                    color: AppColors
                                                                        .blackclr),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              border: Border.all(
                                                                  color: Color(
                                                                      0xffD875CB)),
                                                              gradient: LinearGradient(
                                                                  begin: Alignment
                                                                      .topCenter,
                                                                  end: Alignment
                                                                      .bottomCenter,
                                                                  colors: <Color>[
                                                                    Color(
                                                                        0xffFBFDFC),
                                                                    Color(
                                                                        0xffF7D9FF),
                                                                    Color(
                                                                        0xffF2ADFC),
                                                                  ]),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          25),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Text(
                                                                      Languages.of(
                                                                              context)!
                                                                          .bminetxt,
                                                                      style: Appstyle
                                                                          .marcellusSC24w500
                                                                          .copyWith(
                                                                              color: AppColors.bminetxtclr)),
                                                                  SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                      gradient: LinearGradient(
                                                                          begin: Alignment
                                                                              .topLeft,
                                                                          end: Alignment
                                                                              .bottomRight,
                                                                          colors: <Color>[
                                                                            Color(0xffE789FE),
                                                                            Color(0xffD757F8),
                                                                          ]),
                                                                    ),
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              25,
                                                                          vertical:
                                                                              5),
                                                                      child: Text(
                                                                          purchaseDetailsResponseModel.userMembership == null
                                                                              ? Languages.of(context)!.freetxt
                                                                              : purchaseDetailsResponseModel.userMembership!.planName == "Plus"
                                                                                  ? Languages.of(context)!.plustxt
                                                                                  : purchaseDetailsResponseModel.userMembership!.planName == "Pro"
                                                                                      ? Languages.of(context)!.protxt
                                                                                      : purchaseDetailsResponseModel.userMembership!.planName == "Elite"
                                                                                          ? Languages.of(context)!.elitetxt
                                                                                          : Languages.of(context)!.freetxt,
                                                                          style: Appstyle.quicksand14w600.copyWith(color: AppColors.whiteclr)),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 15,
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        35),
                                                            child: InkWell(
                                                              onTap: () {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              SubscriptionScreen(),
                                                                    )).then(
                                                                  (value) async {
                                                                    await getProfileDetails();
                                                                    await getPurchaseDetailsAPI();
                                                                  },
                                                                );
                                                              },
                                                              child: Container(
                                                                height: 45,
                                                                width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  gradient:
                                                                      const LinearGradient(
                                                                    begin: Alignment
                                                                        .topCenter,
                                                                    end: Alignment
                                                                        .bottomCenter,
                                                                    colors: <Color>[
                                                                      AppColors
                                                                          .signinclr1,
                                                                      AppColors
                                                                          .signinclr2
                                                                    ],
                                                                  ),
                                                                ),
                                                                child: Center(
                                                                    child: Text(
                                                                        Languages.of(context)!
                                                                            .upgradetxt,
                                                                        style: Appstyle
                                                                            .quicksand16w500)),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                profileResponseModel.aboutMe ==
                                                            null ||
                                                        profileResponseModel
                                                            .aboutMe!.isEmpty
                                                    ? Container()
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const SizedBox(
                                                              height: 16),
                                                          Text(
                                                            Languages.of(
                                                                    context)!
                                                                .aboutmetxt,
                                                            style: Appstyle
                                                                .quicksand18w600
                                                                .copyWith(
                                                                    color: AppColors
                                                                        .blackclr),
                                                          ),
                                                          const SizedBox(
                                                              height: 10),
                                                          ListView(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            shrinkWrap: true,
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            children: [
                                                              Wrap(
                                                                spacing:
                                                                    5.0, // gap between adjacent chips
                                                                runSpacing:
                                                                    0.0, // gap between lines
                                                                children: profileResponseModel
                                                                    .aboutMe!
                                                                    .where((data) =>
                                                                        data.value !=
                                                                            null &&
                                                                        data.value!
                                                                            .isNotEmpty)
                                                                    .map(
                                                                        (data) {
                                                                  return Chip(
                                                                    color: const WidgetStatePropertyAll(
                                                                        AppColors
                                                                            .lightgreyclr),
                                                                    labelPadding: const EdgeInsets
                                                                        .only(
                                                                        left: 0,
                                                                        right:
                                                                            5),
                                                                    avatar: Image
                                                                        .asset(
                                                                      _getIconForType(
                                                                          data.type ??
                                                                              ""),
                                                                      height:
                                                                          15,
                                                                      width: 15,
                                                                    ),
                                                                    label: Text(
                                                                      data.value ??
                                                                          "",
                                                                      style: Appstyle
                                                                          .quicksand14w500
                                                                          .copyWith(
                                                                              color: AppColors.blackclr),
                                                                    ),
                                                                    backgroundColor:
                                                                        AppColors
                                                                            .lightgreyclr,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            5.0,
                                                                        vertical:
                                                                            5.0),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      side: const BorderSide(
                                                                          color:
                                                                              AppColors.lightgreyclr),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                    ),
                                                                    elevation:
                                                                        4,
                                                                  );
                                                                }).toList(),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                profileResponseModel
                                                                .lookingFor ==
                                                            null ||
                                                        profileResponseModel
                                                            .lookingFor!.isEmpty
                                                    ? Container()
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          Text(
                                                            Languages.of(
                                                                    context)!
                                                                .imlookingfortxt,
                                                            style: Appstyle
                                                                .quicksand18w600
                                                                .copyWith(
                                                                    color: AppColors
                                                                        .blackclr),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          ListView(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            shrinkWrap: true,
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            children: [
                                                              Wrap(
                                                                spacing:
                                                                    5.0, // gap between adjacent chips
                                                                runSpacing:
                                                                    0.0, // gap between lines
                                                                children: profileResponseModel
                                                                    .lookingFor!
                                                                    .where((data) =>
                                                                        data
                                                                            .isNotEmpty)
                                                                    .map(
                                                                        (data) {
                                                                  return Chip(
                                                                    color: const WidgetStatePropertyAll(
                                                                        AppColors
                                                                            .lightgreyclr),
                                                                    label: Text(
                                                                      data,
                                                                      style: Appstyle
                                                                          .quicksand14w500
                                                                          .copyWith(
                                                                              color: AppColors.blackclr),
                                                                    ),
                                                                    backgroundColor:
                                                                        AppColors
                                                                            .lightgreyclr,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            8.0,
                                                                        vertical:
                                                                            6.0),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      side: const BorderSide(
                                                                          color:
                                                                              AppColors.lightgreyclr),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                    ),
                                                                    elevation:
                                                                        4,
                                                                  );
                                                                }).toList(),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                profileResponseModel
                                                                .intrested ==
                                                            null ||
                                                        profileResponseModel
                                                            .intrested!.isEmpty
                                                    ? Container()
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const SizedBox(
                                                              height: 16),
                                                          Text(
                                                            Languages.of(
                                                                    context)!
                                                                .myIntereststxt,
                                                            style: Appstyle
                                                                .quicksand18w600
                                                                .copyWith(
                                                                    color: AppColors
                                                                        .blackclr),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          ListView(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            shrinkWrap: true,
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            children: [
                                                              Wrap(
                                                                spacing: 5.0,
                                                                runSpacing: 0.0,
                                                                children: profileResponseModel
                                                                    .intrested!
                                                                    .where((intrest) =>
                                                                        intrest
                                                                            .isNotEmpty)
                                                                    .map(
                                                                        (intrest) {
                                                                  return Chip(
                                                                    color: const WidgetStatePropertyAll(
                                                                        AppColors
                                                                            .lightgreyclr),
                                                                    avatar: Text(
                                                                        getEmojiForInterest(
                                                                            intrest)),
                                                                    label: Text(
                                                                      intrest,
                                                                      style: Appstyle
                                                                          .quicksand14w500
                                                                          .copyWith(
                                                                              color: AppColors.blackclr),
                                                                    ),
                                                                    backgroundColor:
                                                                        AppColors
                                                                            .lightgreyclr,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            10.0,
                                                                        vertical:
                                                                            6.0),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      side: const BorderSide(
                                                                          color:
                                                                              AppColors.lightgreyclr),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                    ),
                                                                    elevation:
                                                                        4,
                                                                  );
                                                                }).toList(),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                const SizedBox(
                                                  height: 15,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    isLikeLoading
                        ? Container(
                            height: kSize.height,
                            width: kSize.width,
                            color: Colors.transparent,
                          )
                        : Container()
                  ],
                ),
        ),
      ),
    );
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
        print('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
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

  void _showReportUserAlertDialog(
      String name, String img, String frdId, String type) {
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
                                  await userBlockAPI(frdId, "1");
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

  userBlockAPI(String frdId, String isBlock) async {
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

  getProfileDetails() async {
    setState(() {
      isLoading = true;
    });
    // await getLocation();
    getuserid();

    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .getProfileAPI(
                widget.isScreen == "Friend-Profile"
                    ? widget.frdId ?? ""
                    : userid,
                _currentPosition != null
                    ? _currentPosition!.latitude.toString()
                    : "",
                _currentPosition != null
                    ? _currentPosition!.longitude.toString()
                    : "",
                measurementtype);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              _currentIntroPage = _pageController.initialPage;
              profileResponseModel =
                  Provider.of<ProfileViewModel>(context, listen: false)
                      .profileresponse
                      .response as ProfileResponseModel;

              isLoading = false;
            });
            DatabaseReference userRef =
                FirebaseDatabase.instance.ref('users/$firebaseId');
            await userRef.update(
                {'photoUrl': profileResponseModel.postData![0].images ?? ""});
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
                        "${Languages.of(context)!.doyouwanttosendavirtualmeetrequesttojennytxt} $name?",
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
            setState(() {
              isLikeLoading = false;
              ForgotPasswordResponseModel model =
                  Provider.of<LikeFeedViewModel>(context, listen: false)
                      .userlikeresponse
                      .response as ForgotPasswordResponseModel;

              showToast(model.message!);
            });
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

  String _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'work':
        return AppAssets.workicon;
      case 'education':
      case 'education level':
        return AppAssets.educationcon;
      case 'gender':
        return AppAssets.relationshipicon;
      case 'height':
        return AppAssets.heighticon;
      case 'language':
        return AppAssets.language;
      case 'exercise':
        return AppAssets.dumbbell;
      case 'smoking':
        return AppAssets.smokingicon;
      case 'drinking':
        return AppAssets.drinkicon;
      case 'ethnicity':
        return AppAssets.humanicon;
      case 'horoscope':
        return AppAssets.horoscopicon;
      case 'have kids':
        return AppAssets.kidsicon;
      case 'relationship':
      case 'relationship status':
        return AppAssets.relationshipicon;
      default:
        return "";
    }
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
}
