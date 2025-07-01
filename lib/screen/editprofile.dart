import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/emoji_mapper.dart';
import 'package:bmine_slice/Utils/utils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/profileresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/bottemnavbar.dart';
import 'package:bmine_slice/viewmodels/profileviewmodel.dart';
import 'package:bmine_slice/widgets/video_widgets.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:reorderables/reorderables.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class EditProfileScreen extends StatefulWidget {
  String isScreen = "";
  EditProfileScreen({super.key, required this.isScreen});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController fNameController = TextEditingController();
  TextEditingController lNameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController hometownController = TextEditingController();
  ProfileResponseModel profileResponseModel = ProfileResponseModel();
  SharedPreferences? prefs;

  int bioImageLen = 10;

  List<XFile?> selectedImages = List<XFile?>.filled(10, null, growable: false);
  List<ImageData?> imageList =
      List<ImageData?>.filled(10, null, growable: false);
  // List<XFile?> selectedImages = List.filled(6, null);
  // List<ImageData?> imageList = List.filled(6, null);
  // List<XFile?> selectedFiles = List.filled(6, null);
  // List<MediaData?> fileList = List.filled(6, null);

  int _currentIntroPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  String userid = "";
  String firebaseId = "";
  String measurementtype = "";
  bool isLoading = false;

  String interest = "";
  List<String> myIntrest = [];
  XFile? selectedProfileImages;
  String language = "";

  Map<String, Map<String, dynamic>> aboutData = {
    'About you': {
      'Work': {'value': '', 'icon': AppAssets.workicon},
      'Education': {'value': '', 'icon': AppAssets.educationcon},
      'Gender': {'value': '', 'icon': AppAssets.relationshipicon},
      'Hometown': {'value': '', 'icon': AppAssets.home_town},
    },
    'More about you': {
      'Height': {'value': "", 'icon': AppAssets.heighticon},
      'Exercise': {'value': '', 'icon': AppAssets.dumbbell},
      'Education Level': {'value': "", 'icon': AppAssets.educationcon},
      'Language': {'value': '', 'icon': AppAssets.language},
      'Smoking': {'value': '', 'icon': AppAssets.smokingicon},
      'Drinking': {'value': '', 'icon': AppAssets.drinkicon},
      'Ethnicity': {'value': '', 'icon': AppAssets.humanicon},
      'Horoscope': {'value': '', 'icon': AppAssets.horoscopicon},
      'Have Kids': {'value': "", 'icon': AppAssets.kidsicon},
      'Relationship': {'value': '', 'icon': AppAssets.relationshipicon},
      'Looking for': {'value': '', 'icon': AppAssets.search},
    },
  };

  Map<String, dynamic> jsonBody = {};

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImages[index] = image;
        imageList[index] = null;
      });

      Future.delayed(const Duration(seconds: 1), () async {
        if (index == 0) {
          await uploadPhotosAPI(selectedImages, 0);
        } else {
          if (profileResponseModel.postData!.isEmpty) {
            await uploadPhotosAPI(selectedImages, 1);
          } else {
            int lastSeq = profileResponseModel.postData!.last.seq ?? 1;
            int seq = index == 0 ? 0 : (lastSeq + 1);
            await uploadPhotosAPI(selectedImages, seq);
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    try {
      setState(() {
        if (index >= 0 && index < selectedImages.length) {
          int? imageIdToRemove;
          if (imageList[index] != null) {
            imageIdToRemove = imageList[index]!.id;
          }
          selectedImages[index] = null;
          for (int i = index; i < selectedImages.length - 1; i++) {
            selectedImages[i] = selectedImages[i + 1];
          }
          selectedImages[selectedImages.length - 1] = null;
          if (index >= 0 && index < imageList.length) {
            imageList[index] = null;
            for (int i = index; i < imageList.length - 1; i++) {
              imageList[i] = imageList[i + 1];
            }
            imageList[imageList.length - 1] = null;
          }
          if (imageIdToRemove != null) {
            removePhotosAPI(imageIdToRemove.toString());
          }
        }
      });
    } catch (e) {}
  }

  bool isVideoFile(String path) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.3gp', '.webm'];
    final extension = path.toLowerCase().split('.').last;
    return videoExtensions.contains('.$extension');
  }

  Future<void> _pickMedia(int index) async {
    final List<XFile>? files = await _picker.pickMultipleMedia();

    if (files != null && files.isNotEmpty) {
      for (var fi = 0; fi < files.length; fi++) {
        XFile? file = files[fi];
        if (file != null) {
          final isVideo = isVideoFile(file.path);
          if (isVideo) {
            final controller = VideoPlayerController.file(File(file.path));
            await controller.initialize();
            final duration = controller.value.duration;
            if (duration.inSeconds > 30) {
              showToast(Languages.of(context)!.upload30secvideotxt);
              await controller.dispose();
              return;
            }
            await controller.dispose();
          }
          setState(() {
            selectedImages[index + fi] = file;
            imageList[index + fi] = null;
            // selectedFiles[index] = file;
            // fileList[index] = null;
          });
          print(selectedImages);
          print(imageList);
          // Future.delayed(const Duration(seconds: 1), () async {
          //   int lastSeq = profileResponseModel.postData!.last.seq ?? 1;
          //   int seq = index == 0 ? 0 : (lastSeq + 1);
          //   await uploadPhotosAPI(selectedImages, seq);
          // });
        }
      }
    }

    print("selectedImages $selectedImages");
    print("imageList $imageList");

    Future.delayed(const Duration(seconds: 1), () async {
      int lastSeq = profileResponseModel.postData!.last.seq ?? 1;
      int seq = index == 0 ? 0 : (lastSeq + 1);
      await uploadPhotosAPI(selectedImages, seq);
    });
  }
  // void _removeMedia(int index) {
  //   try {
  //     setState(() {
  //       if (index >= 0 && index < selectedFiles.length) {
  //         int? imageIdToRemove;
  //         if (fileList[index] != null) {
  //           imageIdToRemove = fileList[index]!.id;
  //         }
  //         selectedFiles[index] = null;
  //         for (int i = index; i < selectedFiles.length - 1; i++) {
  //           selectedFiles[i] = selectedFiles[i + 1];
  //         }
  //         selectedFiles[selectedFiles.length - 1] = null;
  //         if (index >= 0 && index < fileList.length) {
  //           fileList[index] = null;
  //           for (int i = index; i < fileList.length - 1; i++) {
  //             fileList[i] = fileList[i + 1];
  //           }
  //           fileList[fileList.length - 1] = null;
  //         }
  //         if (imageIdToRemove != null) {
  //           removePhotosAPI(imageIdToRemove.toString());
  //         }
  //       }
  //     });
  //   } catch (e) {}
  // }

  getuserid() async {
    prefs = await SharedPreferences.getInstance();
    userid = prefs!.getString('userid') ?? "";
    firebaseId = prefs!.getString('firebaseId') ?? "";
    measurementtype = prefs!.getString('Measurement') ?? "KM";
    setState(() {});
    print("1013");
  }

  @override
  void initState() {
    getProfileDetails();
    super.initState();
  }

  String getValue(String category, String field) {
    return aboutData[category]?[field]?['value'] ?? '';
  }

  double calculateContentHeight(
      BuildContext context, ProfileResponseModel profile) {
    final double screenHeight = MediaQuery.of(context).size.height;
    double totalHeight = 0;
    const double basePadding = 50.0;
    const double sectionSpacing = 50.0;
    const double itemSpacing = 45.0;
    totalHeight += screenHeight;
    totalHeight += basePadding * 3;
    totalHeight += 100.0;
    if (profile.userProfile?.bio != null) {
      totalHeight += 100.0;
    }
    if (profile.aboutMe != null && profile.aboutMe!.isNotEmpty) {
      totalHeight += sectionSpacing;
      totalHeight += 80.0;
      totalHeight += itemSpacing;
      final int itemCount = profile.aboutMe!
          .where((data) => data.value != null && data.value!.isNotEmpty)
          .length;
      totalHeight += (itemCount / 3).ceil() * 80.0;
    }
    if (profile.lookingFor != null && profile.lookingFor!.isNotEmpty) {
      totalHeight += sectionSpacing;
      totalHeight += 80.0;
      totalHeight += itemSpacing;

      final int itemCount =
          profile.lookingFor!.where((item) => item.isNotEmpty).length;
      totalHeight += (itemCount / 3).ceil() * 80.0;
    }

    // Interests section
    if (profile.intrested != null && profile.intrested!.isNotEmpty) {
      totalHeight += sectionSpacing;
      totalHeight += 80.0;
      totalHeight += itemSpacing;

      final int itemCount =
          profile.intrested!.where((item) => item.isNotEmpty).length;
      totalHeight += (itemCount / 3).ceil() * 80.0;
    }
    totalHeight += basePadding * 6;
    return totalHeight;
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
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.isScreen == "New-User") {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => BottomNavBar(
                                        index: 4,
                                      )),
                              (Route<dynamic> route) => false);
                        } else {
                          print(imageList.length);
                          print(selectedImages.length);

                          if (profileResponseModel.postData!.isEmpty) {
                            _showAlert();
                          } else {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Image.asset(
                        AppAssets.backarraowicon,
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ),
                  Text(
                    Languages.of(context)!.editprofiletxt,
                    style: Appstyle.marcellusSC20w500
                        .copyWith(color: AppColors.blackclr),
                  ),
                ],
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
            : SingleChildScrollView(
                child: LayoutBuilder(builder: (context, constraints) {
                  final double contentHeight = calculateContentHeight(
                    context,
                    profileResponseModel,
                  );
                  return Container(
                    height: contentHeight,
                    color: Colors.white,
                    child: Stack(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 1.5,
                          child: Stack(
                            children: [
                              (profileResponseModel.postData?.isEmpty ?? true)
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
                                      itemCount:
                                          profileResponseModel.postData!.length,
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
                                        final isVideo = isVideoUrl(mediaUrl);

                                        return Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            if (isVideo)
                                              VideoWidget(videoUrl: mediaUrl)
                                            else
                                              Image.network(
                                                mediaUrl,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color:
                                                          AppColors.bminetxtclr,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
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
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: List.generate(
                                    profileResponseModel.postData == null
                                        ? 0
                                        : profileResponseModel.postData!.length,
                                    (index) {
                                  return Expanded(
                                    child: Container(
                                      alignment: Alignment.topCenter,
                                      decoration: BoxDecoration(
                                          color: _currentIntroPage == index
                                              ? AppColors.whiteclr
                                              : AppColors.indexclrgreyclr
                                                  .withAlpha(50),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 15),
                                      height: 5,
                                      width:
                                          _currentIntroPage == index ? 50 : 50,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).size.height / 1.7,
                          left: 10,
                          right: 10,
                          child: Container(
                            decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.textfieldclr.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                color: AppColors.whiteclr,
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "${fNameController.text} "
                                            "${lNameController.text}"
                                            "${dobController.text.isNotEmpty ? ", ${calculateAge(DateFormat("dd/MM/yyyy").parse(dobController.text))}" : ""}",
                                            style: Appstyle.quicksand19w600
                                                .copyWith(
                                                    color: AppColors.blackclr),
                                          ),
                                          // const SizedBox(width: 10),
                                          // InkWell(
                                          //   onTap: () {
                                          //     _showCustomDialog(context);
                                          //   },
                                          //   child: Image.asset(
                                          //     AppAssets.editicon,
                                          //     height: 18,
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${Languages.of(context)!.biotxt} ",
                                            style: Appstyle.quicksand13w600
                                                .copyWith(
                                                    color: AppColors.blackclr),
                                          ),
                                          Expanded(
                                            child: Text(
                                              bioController.text,
                                              style: Appstyle.quicksand13w500
                                                  .copyWith(
                                                      color:
                                                          AppColors.blackclr),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          InkWell(
                                            onTap: () {
                                              _showBioDialog(context);
                                            },
                                            child: Image.asset(
                                              AppAssets.editicon,
                                              height: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                          Languages.of(context)!
                                              .mainprofileimage,
                                          style: Appstyle.quicksand18w600),
                                      const SizedBox(height: 10),

                                      // ReorderableWrap(
                                      //   spacing: 10,
                                      //   runSpacing: 10,
                                      //   minMainAxisCount: 3,
                                      //   maxMainAxisCount: 3,
                                      //   needsLongPressDraggable: true,
                                      //   onReorder: (oldIndex, newIndex) {
                                      //     if (oldIndex == 0 || newIndex == 0)
                                      //       return;
                                      //     final oldItem =
                                      //         selectedImages[oldIndex] ??
                                      //             imageList[oldIndex];
                                      //     final newItem =
                                      //         selectedImages[newIndex] ??
                                      //             imageList[newIndex];
                                      //     if (oldItem == null ||
                                      //         newItem == null)
                                      //       return; // ⛔ Skip empty slots
                                      //     setState(() {
                                      //       final temp1 =
                                      //           selectedImages[oldIndex];
                                      //       final temp2 = imageList[oldIndex];
                                      //       selectedImages[oldIndex] =
                                      //           selectedImages[newIndex];
                                      //       selectedImages[newIndex] = temp1;
                                      //       imageList[oldIndex] =
                                      //           imageList[newIndex];
                                      //       imageList[newIndex] = temp2;
                                      //     });
                                      //   },
                                      //   children: List.generate(6, (index) {
                                      //     final hasMedia =
                                      //         (selectedImages[index]
                                      //                     ?.path
                                      //                     .isNotEmpty ??
                                      //                 false) ||
                                      //             (imageList[index]
                                      //                     ?.path
                                      //                     .isNotEmpty ??
                                      //                 false);
                                      //     Widget item = SizedBox(
                                      //       height: 100,
                                      //       width: 100,
                                      //       child: _buildItem(index),
                                      //     );
                                      //     // ✅ Skip draggable behavior for index 0 or no media
                                      //     return (index == 0 || !hasMedia)
                                      //         ? item
                                      //         : Container(
                                      //             key: ValueKey(index),
                                      //             child: item,
                                      //           );
                                      //   }),
                                      // ),

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Fixed item at position 0
                                          SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: _buildItem(0,
                                                draggable:
                                                    false), // not draggable
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                              Languages.of(context)!
                                                  .mediagallery,
                                              style: Appstyle.quicksand18w600),
                                          const SizedBox(height: 1),
                                          Text(
                                              Languages.of(context)!
                                                  .longpresstosortmediatxt,
                                              style: Appstyle.quicksand13w500
                                                  .copyWith(
                                                      color: AppColors.blackclr
                                                          .withOpacity(0.7))),
                                          const SizedBox(height: 15),

                                          // Draggable items starting from index 1
                                          ReorderableWrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            minMainAxisCount: 3,
                                            maxMainAxisCount: 3,
                                            needsLongPressDraggable: true,
                                            onReorder: (oldIndex, newIndex) {
                                              print(
                                                  "Reordering from $oldIndex to $newIndex");

                                              print(imageList);
                                              // if (imageList[oldIndex] == null)
                                              //   return; // Skip if old index is empty
                                              // if (imageList[newIndex] == null)
                                              //   return; // Skip if either slot is empty

                                              // Shift by 1 since index 0 is excluded from drag
                                              final realOld = oldIndex + 1;
                                              final realNew = newIndex + 1;
                                              if (imageList[realOld] == null)
                                                return; // Skip if old index is empty
                                              if (imageList[realNew] == null)
                                                return; // Skip if either slot is empty

                                              if (realOld == 0 || realNew == 0)
                                                return; // just in case

                                              setState(() {
                                                final temp1 =
                                                    selectedImages[realOld];
                                                final temp2 =
                                                    imageList[realOld];

                                                selectedImages[realOld] =
                                                    selectedImages[realNew];
                                                selectedImages[realNew] = temp1;

                                                imageList[realOld] =
                                                    imageList[realNew];
                                                imageList[realNew] = temp2;
                                              });
                                              // print(
                                              //     " old ${imageList[realOld]!.id.toString()} - seq ${realOld}");
                                              // print(
                                              //     " new ${imageList[realNew]!.id.toString()} - seq ${realNew}");

                                              Future.delayed(
                                                  const Duration(seconds: 1),
                                                  () async {
                                                String imageId1 =
                                                    imageList[realNew]!
                                                        .id
                                                        .toString();
                                                String imageId2 =
                                                    imageList[realOld]!
                                                        .id
                                                        .toString();
                                                await updatePostSeqAPI(imageId1,
                                                    realNew, imageId2, realOld);
                                                /////
                                              });
                                            },
                                            children: List.generate(
                                                bioImageLen - 1, (i) {
                                              int actualIndex =
                                                  i + 1; // skip index 0
                                              return Container(
                                                key: ValueKey(actualIndex),
                                                height: 100,
                                                width: 100,
                                                child: _buildItem(actualIndex),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),

                                      // ReorderableWrap(
                                      //   spacing: 10,
                                      //   runSpacing: 10,
                                      //   minMainAxisCount: 3,
                                      //   maxMainAxisCount: 3,
                                      //   needsLongPressDraggable: true,
                                      //   onReorder: (oldIndex, newIndex) {
                                      //     setState(() {
                                      //       final temp =
                                      //           selectedImages[oldIndex];
                                      //       selectedImages[oldIndex] =
                                      //           selectedImages[newIndex];
                                      //       selectedImages[newIndex] = temp;
                                      //       final temp2 = imageList[oldIndex];
                                      //       imageList[oldIndex] =
                                      //           imageList[newIndex];
                                      //       imageList[newIndex] = temp2;
                                      //     });
                                      //     List<XFile?> reorderedImages = [];
                                      //     imageList
                                      //         .asMap()
                                      //         .forEach((index, image) {
                                      //       if (image != null) {
                                      //         reorderedImages
                                      //             .add(XFile(image.path));
                                      //       } else {
                                      //         reorderedImages.add(null);
                                      //       }
                                      //     });
                                      //     imageList.forEach((element) =>
                                      //         element != null
                                      //             ? print(
                                      //                 "element: ${element.id}")
                                      //             : "--");
                                      //     // Future.delayed(
                                      //     //     const Duration(seconds: 1),
                                      //     //     () async {
                                      //     //   await uploadPhotosAPI(
                                      //     //       reorderedImages);
                                      //     // });
                                      //   },
                                      //   children: List.generate(6, (index) {
                                      //     return SizedBox(
                                      //       key: ValueKey(index),
                                      //       height: 100,
                                      //       width: 100,
                                      //       child: Stack(
                                      //         children: [
                                      //           Container(
                                      //             width: 100,
                                      //             height: 100,
                                      //             decoration: BoxDecoration(
                                      //               color: Colors.grey[300],
                                      //               borderRadius:
                                      //                   BorderRadius.circular(
                                      //                       8),
                                      //             ),
                                      //             child: ClipRRect(
                                      //               borderRadius:
                                      //                   BorderRadius.circular(
                                      //                       8),
                                      //               child:
                                      //                   FutureBuilder<Widget>(
                                      //                 future: () async {
                                      //                   final file =
                                      //                       selectedImages[
                                      //                           index];
                                      //                   final netImage =
                                      //                       imageList[index];
                                      //                   String? path =
                                      //                       file?.path ??
                                      //                           netImage?.path;
                                      //                   if (path == null ||
                                      //                       path.isEmpty) {
                                      //                     return _buildDotted();
                                      //                   }
                                      //                   final ext = path
                                      //                       .split('.')
                                      //                       .last
                                      //                       .toLowerCase();
                                      //                   final isVideo = [
                                      //                     'mp4',
                                      //                     'mov',
                                      //                     'avi',
                                      //                     'mkv'
                                      //                   ].contains(ext);
                                      //                   if (file != null) {
                                      //                     if (isVideo) {
                                      //                       final thumb =
                                      //                           await VideoThumbnail
                                      //                               .thumbnailData(
                                      //                         video: file.path,
                                      //                         imageFormat:
                                      //                             ImageFormat
                                      //                                 .JPEG,
                                      //                         quality: 75,
                                      //                       );
                                      //                       return thumb != null
                                      //                           ? await buildThumbnail(
                                      //                               thumb, true)
                                      //                           : _buildDotted();
                                      //                     } else {
                                      //                       return Image.file(
                                      //                         File(file.path),
                                      //                         fit: BoxFit.cover,
                                      //                         width: double
                                      //                             .infinity,
                                      //                         height: double
                                      //                             .infinity,
                                      //                       );
                                      //                     }
                                      //                   } else if (netImage !=
                                      //                           null &&
                                      //                       netImage.path
                                      //                           .isNotEmpty) {
                                      //                     final url =
                                      //                         "${API.baseUrl}/upload/${netImage.path}";
                                      //                     if (isVideo) {
                                      //                       try {
                                      //                         final response =
                                      //                             await http.get(
                                      //                                 Uri.parse(
                                      //                                     url));
                                      //                         if (response
                                      //                                 .statusCode ==
                                      //                             200) {
                                      //                           final tempDir =
                                      //                               await getTemporaryDirectory();
                                      //                           final tempVideoPath =
                                      //                               "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext";
                                      //                           final tempVideoFile =
                                      //                               File(
                                      //                                   tempVideoPath);
                                      //                           await tempVideoFile
                                      //                               .writeAsBytes(
                                      //                                   response
                                      //                                       .bodyBytes);
                                      //                           final thumb = await VideoThumbnail.thumbnailData(
                                      //                               video:
                                      //                                   tempVideoFile
                                      //                                       .path,
                                      //                               imageFormat:
                                      //                                   ImageFormat
                                      //                                       .JPEG,
                                      //                               quality:
                                      //                                   75);
                                      //                           if (thumb ==
                                      //                               null) {
                                      //                             print(
                                      //                                 "❌ Thumbnail generation returned null for video at $url");
                                      //                             return _buildDotted();
                                      //                           }
                                      //                           return await buildThumbnail(
                                      //                               thumb,
                                      //                               true);
                                      //                         } else {
                                      //                           print(
                                      //                               "❌ Failed to fetch video: ${response.statusCode} from $url");
                                      //                           return _buildDotted();
                                      //                         }
                                      //                       } catch (e) {
                                      //                         print(
                                      //                             "❌ Error downloading/generating thumbnail: $e");
                                      //                         return _buildDotted();
                                      //                       }
                                      //                     } else {
                                      //                       return Image
                                      //                           .network(
                                      //                         url,
                                      //                         fit: BoxFit.cover,
                                      //                         width: double
                                      //                             .infinity,
                                      //                         height: double
                                      //                             .infinity,
                                      //                         loadingBuilder:
                                      //                             (context,
                                      //                                 child,
                                      //                                 loadingProgress) {
                                      //                           if (loadingProgress ==
                                      //                               null)
                                      //                             return child;
                                      //                           return Center(
                                      //                             child: CircularProgressIndicator(
                                      //                                 color: AppColors
                                      //                                     .bminetxtclr,
                                      //                                 value: loadingProgress.expectedTotalBytes !=
                                      //                                         null
                                      //                                     ? loadingProgress.cumulativeBytesLoaded /
                                      //                                         loadingProgress.expectedTotalBytes!
                                      //                                     : null),
                                      //                           );
                                      //                         },
                                      //                         errorBuilder:
                                      //                             (context,
                                      //                                 error,
                                      //                                 stackTrace) {
                                      //                           return Image.asset(
                                      //                               AppAssets
                                      //                                   .femaleUser,
                                      //                               fit: BoxFit
                                      //                                   .fill,
                                      //                               width: double
                                      //                                   .infinity,
                                      //                               height: double
                                      //                                   .infinity);
                                      //                         },
                                      //                       );
                                      //                     }
                                      //                   }
                                      //                   return _buildDotted();
                                      //                 }(),
                                      //                 builder:
                                      //                     (context, snapshot) {
                                      //                   if (snapshot
                                      //                           .connectionState ==
                                      //                       ConnectionState
                                      //                           .done) {
                                      //                     return snapshot
                                      //                             .data ??
                                      //                         _buildDotted();
                                      //                   } else {
                                      //                     return const Center(
                                      //                         child:
                                      //                             CircularProgressIndicator());
                                      //                   }
                                      //                 },
                                      //               ),
                                      //             ),
                                      //             // child: ClipRRect(
                                      //             //   borderRadius:
                                      //             //       BorderRadius.circular(
                                      //             //           8),
                                      //             //   child: selectedImages[
                                      //             //               index] !=
                                      //             //           null
                                      //             //       ? Image.file(
                                      //             //           File(selectedImages[
                                      //             //                   index]!
                                      //             //               .path),
                                      //             //           fit: BoxFit.cover,
                                      //             //           width:
                                      //             //               double.infinity,
                                      //             //           height:
                                      //             //               double.infinity,
                                      //             //         )
                                      //             //       : imageList[index] !=
                                      //             //                   null &&
                                      //             //               imageList[
                                      //             //                       index]!
                                      //             //                   .path
                                      //             //                   .isNotEmpty
                                      //             //           ? Image.network(
                                      //             //               "${API.baseUrl}/upload/${imageList[index]!.path}",
                                      //             //               fit: BoxFit
                                      //             //                   .cover,
                                      //             //               width: double
                                      //             //                   .infinity,
                                      //             //               height: double
                                      //             //                   .infinity,
                                      //             //               loadingBuilder:
                                      //             //                   (context,
                                      //             //                       child,
                                      //             //                       loadingProgress) {
                                      //             //                 if (loadingProgress ==
                                      //             //                     null)
                                      //             //                   return child;
                                      //             //                 return Center(
                                      //             //                   child:
                                      //             //                       CircularProgressIndicator(
                                      //             //                     color: AppColors
                                      //             //                         .bminetxtclr,
                                      //             //                     value: loadingProgress.expectedTotalBytes !=
                                      //             //                             null
                                      //             //                         ? loadingProgress.cumulativeBytesLoaded /
                                      //             //                             loadingProgress.expectedTotalBytes!
                                      //             //                         : null,
                                      //             //                   ),
                                      //             //                 );
                                      //             //               },
                                      //             //               errorBuilder:
                                      //             //                   (context,
                                      //             //                       error,
                                      //             //                       stackTrace) {
                                      //             //                 return Image
                                      //             //                     .asset(
                                      //             //                   AppAssets
                                      //             //                       .femaleUser,
                                      //             //                   fit: BoxFit
                                      //             //                       .fill,
                                      //             //                   width: double
                                      //             //                       .infinity,
                                      //             //                   height: double
                                      //             //                       .infinity,
                                      //             //                 );
                                      //             //               },
                                      //             //             )
                                      //             //           : DottedBorder(
                                      //             //               color: Colors
                                      //             //                   .black87,
                                      //             //               borderType:
                                      //             //                   BorderType
                                      //             //                       .RRect,
                                      //             //               radius:
                                      //             //                   const Radius
                                      //             //                       .circular(
                                      //             //                       8),
                                      //             //               strokeWidth: 1,
                                      //             //               child:
                                      //             //                   Container(),
                                      //             //             ),
                                      //             // ),
                                      //           ),
                                      //           Positioned(
                                      //             bottom: 0,
                                      //             right: 0,
                                      //             child: selectedImages[
                                      //                         index] ==
                                      //                     null
                                      //                 ? imageList[index] !=
                                      //                             null &&
                                      //                         imageList[index]!
                                      //                             .path
                                      //                             .isNotEmpty
                                      //                     ? InkWell(
                                      //                         onTap: () =>
                                      //                             _removeImage(
                                      //                                 index),
                                      //                         child:
                                      //                             Image.asset(
                                      //                           AppAssets
                                      //                               .deleteicon,
                                      //                           height: 25,
                                      //                         ),
                                      //                       )
                                      //                     : InkWell(
                                      //                         onTap: () {
                                      //                           if (index ==
                                      //                               3) {
                                      //                             _pickImage(
                                      //                                 index); // only image for index 0
                                      //                           } else {
                                      //                             _pickMedia(
                                      //                                 index); // image or video for other indexes
                                      //                           }
                                      //                         },
                                      //                         child:
                                      //                             Image.asset(
                                      //                           AppAssets
                                      //                               .addicon,
                                      //                           height: 25,
                                      //                         ),
                                      //                       )
                                      //                 : InkWell(
                                      //                     onTap: () =>
                                      //                         _removeImage(
                                      //                             index),
                                      //                     child: Image.asset(
                                      //                       AppAssets
                                      //                           .deleteicon,
                                      //                       height: 25,
                                      //                     ),
                                      //                   ),
                                      //           ),
                                      //         ],
                                      //       ),
                                      //     );
                                      //   }),
                                      // ),

                                      // GridView.builder(
                                      //   shrinkWrap: true,
                                      //   physics:
                                      //       const NeverScrollableScrollPhysics(),
                                      //   gridDelegate:
                                      //       const SliverGridDelegateWithFixedCrossAxisCount(
                                      //     crossAxisCount: 3,
                                      //     crossAxisSpacing: 10,
                                      //     mainAxisSpacing: 20,
                                      //   ),
                                      //   itemCount: 6,
                                      //   itemBuilder: (context, index) {
                                      //     return SizedBox(
                                      //       height: 120,
                                      //       width: 120,
                                      //       child: Stack(
                                      //         children: [
                                      //           Container(
                                      //             width: 100,
                                      //             height: 100,
                                      //             decoration: BoxDecoration(
                                      //               color: Colors.grey[300],
                                      //               borderRadius:
                                      //                   BorderRadius.circular(
                                      //                       8),
                                      //             ),
                                      //             child: ClipRRect(
                                      //               borderRadius:
                                      //                   BorderRadius.circular(
                                      //                       8),
                                      //               child: selectedImages[
                                      //                           index] !=
                                      //                       null
                                      //                   ? Image.file(
                                      //                       File(selectedImages[
                                      //                               index]!
                                      //                           .path),
                                      //                       fit: BoxFit.cover,
                                      //                       width:
                                      //                           double.infinity,
                                      //                       height:
                                      //                           double.infinity,
                                      //                     )
                                      //                   : imageList[index] !=
                                      //                               null &&
                                      //                           imageList[index]!
                                      //                                   .path !=
                                      //                               ""
                                      //                       ? Image.network(
                                      //                           "${API.baseUrl}/upload/${imageList[index]!.path}",
                                      //                           fit: BoxFit
                                      //                               .cover,
                                      //                           width: double
                                      //                               .infinity,
                                      //                           height: double
                                      //                               .infinity,
                                      //                           loadingBuilder:
                                      //                               (context,
                                      //                                   child,
                                      //                                   loadingProgress) {
                                      //                             if (loadingProgress ==
                                      //                                 null) {
                                      //                               return child;
                                      //                             } else {
                                      //                               return SizedBox(
                                      //                                 width: double
                                      //                                     .infinity,
                                      //                                 height: double
                                      //                                     .infinity,
                                      //                                 child:
                                      //                                     Center(
                                      //                                   child:
                                      //                                       CircularProgressIndicator(
                                      //                                     color:
                                      //                                         AppColors.bminetxtclr,
                                      //                                     value: loadingProgress.expectedTotalBytes != null
                                      //                                         ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      //                                         : null,
                                      //                                   ),
                                      //                                 ),
                                      //                               );
                                      //                             }
                                      //                           },
                                      //                           errorBuilder:
                                      //                               (context,
                                      //                                   error,
                                      //                                   stackTrace) {
                                      //                             return Image
                                      //                                 .asset(
                                      //                               AppAssets
                                      //                                   .femaleUser,
                                      //                               fit: BoxFit
                                      //                                   .fill,
                                      //                               width: double
                                      //                                   .infinity,
                                      //                               height: double
                                      //                                   .infinity,
                                      //                             );
                                      //                           },
                                      //                         )
                                      //                       : DottedBorder(
                                      //                           color: Colors
                                      //                               .black87,
                                      //                           borderType:
                                      //                               BorderType
                                      //                                   .RRect,
                                      //                           radius:
                                      //                               const Radius
                                      //                                   .circular(
                                      //                                   8),
                                      //                           strokeWidth: 1,
                                      //                           child:
                                      //                               Container(),
                                      //                         ),
                                      //             ),
                                      //           ),
                                      //           Positioned(
                                      //               bottom: 5,
                                      //               right: 5,
                                      //               child: selectedImages[
                                      //                           index] ==
                                      //                       null
                                      //                   ? imageList[index] !=
                                      //                               null &&
                                      //                           imageList[index]!
                                      //                                   .path !=
                                      //                               ""
                                      //                       ? InkWell(
                                      //                           onTap: () =>
                                      //                               _removeImage(
                                      //                                   index),
                                      //                           child:
                                      //                               Image.asset(
                                      //                             AppAssets
                                      //                                 .deleteicon,
                                      //                             height: 25,
                                      //                           ),
                                      //                         )
                                      //                       : InkWell(
                                      //                           onTap: () =>
                                      //                               _pickImage(
                                      //                                   index),
                                      //                           child:
                                      //                               Image.asset(
                                      //                             AppAssets
                                      //                                 .addicon,
                                      //                             height: 25,
                                      //                           ),
                                      //                         )
                                      //                   : InkWell(
                                      //                       onTap: () =>
                                      //                           _removeImage(
                                      //                               index),
                                      //                       child: Image.asset(
                                      //                         AppAssets
                                      //                             .deleteicon,
                                      //                         height: 25,
                                      //                       ),
                                      //                     )),
                                      //         ],
                                      //       ),
                                      //     );
                                      //   },
                                      // ),

                                      // GridView.builder(
                                      //   shrinkWrap: true,
                                      //   physics:
                                      //       const NeverScrollableScrollPhysics(),
                                      //   gridDelegate:
                                      //       const SliverGridDelegateWithFixedCrossAxisCount(
                                      //     crossAxisCount: 3,
                                      //     crossAxisSpacing: 10,
                                      //     mainAxisSpacing: 20,
                                      //   ),
                                      //   itemCount: 6,
                                      //   itemBuilder: (context, index) {
                                      //     final localFile =
                                      //         selectedFiles[index];
                                      //     final networkFile = fileList[index];
                                      //     final hasLocal = localFile != null;
                                      //     final hasNetwork =
                                      //         networkFile != null &&
                                      //             networkFile.path.isNotEmpty;
                                      //     Widget content;
                                      //     if (hasLocal) {
                                      //       final isVideo =
                                      //           isVideoFile(localFile.path);
                                      //       content = isVideo
                                      //           ? const Center(
                                      //               child: Icon(Icons.videocam,
                                      //                   size: 40,
                                      //                   color: Colors.black54))
                                      //           : Image.file(
                                      //               File(localFile.path),
                                      //               fit: BoxFit.cover,
                                      //               width: double.infinity,
                                      //               height: double.infinity,
                                      //             );
                                      //     } else if (hasNetwork) {
                                      //       final isVideo = networkFile.isVideo;
                                      //       content = isVideo
                                      //           ? const Center(
                                      //               child: Icon(Icons.videocam,
                                      //                   size: 40,
                                      //                   color: Colors.black54))
                                      //           : Image.network(
                                      //               "${API.baseUrl}/upload/${networkFile.path}",
                                      //               fit: BoxFit.cover,
                                      //               width: double.infinity,
                                      //               height: double.infinity,
                                      //               loadingBuilder: (context,
                                      //                   child,
                                      //                   loadingProgress) {
                                      //                 if (loadingProgress ==
                                      //                     null) {
                                      //                   return child;
                                      //                 }
                                      //                 return Center(
                                      //                   child:
                                      //                       CircularProgressIndicator(
                                      //                     color: AppColors
                                      //                         .bminetxtclr,
                                      //                     value: loadingProgress
                                      //                                 .expectedTotalBytes !=
                                      //                             null
                                      //                         ? loadingProgress
                                      //                                 .cumulativeBytesLoaded /
                                      //                             loadingProgress
                                      //                                 .expectedTotalBytes!
                                      //                         : null,
                                      //                   ),
                                      //                 );
                                      //               },
                                      //               errorBuilder: (context,
                                      //                   error, stackTrace) {
                                      //                 return Image.asset(
                                      //                   AppAssets.femaleUser,
                                      //                   fit: BoxFit.fill,
                                      //                   width: double.infinity,
                                      //                   height: double.infinity,
                                      //                 );
                                      //               },
                                      //             );
                                      //     } else {
                                      //       content = DottedBorder(
                                      //         color: Colors.black87,
                                      //         borderType: BorderType.RRect,
                                      //         radius: const Radius.circular(8),
                                      //         strokeWidth: 1,
                                      //         child: Container(),
                                      //       );
                                      //     }
                                      //     return SizedBox(
                                      //       height: 120,
                                      //       width: 120,
                                      //       child: Stack(
                                      //         children: [
                                      //           Container(
                                      //             width: 100,
                                      //             height: 100,
                                      //             decoration: BoxDecoration(
                                      //               color: Colors.grey[300],
                                      //               borderRadius:
                                      //                   BorderRadius.circular(
                                      //                       8),
                                      //             ),
                                      //             child: ClipRRect(
                                      //               borderRadius:
                                      //                   BorderRadius.circular(
                                      //                       8),
                                      //               child: content,
                                      //             ),
                                      //           ),
                                      //           Positioned(
                                      //             bottom: 5,
                                      //             right: 5,
                                      //             child: hasLocal || hasNetwork
                                      //                 ? InkWell(
                                      //                     onTap: () =>
                                      //                         _removeImage(
                                      //                             index),
                                      //                     // _removeMedia(
                                      //                     //     index),
                                      //                     child: Image.asset(
                                      //                       AppAssets
                                      //                           .deleteicon,
                                      //                       height: 25,
                                      //                     ),
                                      //                   )
                                      //                 : InkWell(
                                      //                     onTap: () =>
                                      //                         _pickImage(index),
                                      //                     // _pickMedia(index),
                                      //                     child: Image.asset(
                                      //                       AppAssets.addicon,
                                      //                       height: 25,
                                      //                     ),
                                      //                   ),
                                      //           ),
                                      //         ],
                                      //       ),
                                      //     );
                                      //   },
                                      // ),

                                      const SizedBox(height: 20),
                                      _buildInfoSection(
                                          Languages.of(context)!.aboutmetxt,
                                          aboutData['About you']!),
                                      const SizedBox(height: 10),
                                      _buildInfoSection(
                                        Languages.of(context)!
                                            .moreabouttitletxt,
                                        aboutData['More about you']!,
                                        subtitle: Languages.of(context)!
                                            .moreaboutsubtitletxt,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildInfoSectionforInterest(
                                          Languages.of(context)!.myIntereststxt,
                                          [
                                            ListView(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              children: [
                                                Wrap(
                                                  spacing: 5.0,
                                                  runSpacing: 0.0,
                                                  children:
                                                      myIntrest.map((option3) {
                                                    return Chip(
                                                      avatar: Text(
                                                          getEmojiForInterest(
                                                              option3)),
                                                      label: Text(
                                                        option3,
                                                        style: Appstyle
                                                            .quicksand14w500
                                                            .copyWith(
                                                                color: AppColors
                                                                    .blackclr),
                                                      ),
                                                      backgroundColor: AppColors
                                                          .lightgreyclr,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10.0,
                                                          vertical: 6.0),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        side: const BorderSide(
                                                            color: AppColors
                                                                .lightgreyclr),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      elevation: 4,
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ]),
                                      const SizedBox(height: 10),
                                      InkWell(
                                        onTap: () {
                                          _showInterestSelectionBottomSheet(
                                              interest);
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.add),
                                            const SizedBox(width: 10),
                                            Text(
                                              Languages.of(context)!.addMoretxt,
                                              style: Appstyle.quicksand13w600,
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
      ),
    );
  }

  Widget _buildInfoSectionforInterest(String title, List<Widget> rows,
      {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Appstyle.quicksand18w600),
        Text(subtitle ?? "",
            style:
                Appstyle.quicksand14w500.copyWith(color: AppColors.blackclr)),
        const SizedBox(height: 10),
        ...rows,
      ],
    );
  }

  Widget _buildInfoSection(String title, Map<String, dynamic> sectionData,
      {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Appstyle.quicksand16w600.copyWith(color: AppColors.blackclr),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: Appstyle.quicksand13w500
                .copyWith(color: AppColors.blackclr.withOpacity(0.7)),
          ),
        const SizedBox(height: 10),
        ...sectionData.entries
            .map((entry) => _buildInfoRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildInfoRow(String title, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: () {
          _showEditDialog(title, data['value']);
        },
        child: Row(
          children: [
            Image.asset(data['icon'], height: 24, width: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style:
                  Appstyle.quicksand14w600.copyWith(color: AppColors.blackclr),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: Text(data['value'],
                          maxLines: data['key'] == "Looking for" ? 2 : 1,
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
    );
  }

  void _showEditDialog(String title, String currentValue) {
    switch (title) {
      case 'Gender':
        // _showGenderDialog(currentValue);
        break;
      case 'Hometown':
        _buildHomeTownTextField(
            controller: hometownController,
            hintText: currentValue,
            title: title);
        break;
      case 'Height':
        _showHeightPickerDialog(currentValue);
        break;
      case 'Language':
        _showLanguageSelectionBottomSheet(currentValue);
        break;
      case 'Exercise':
        _showExerciseDialog(title, currentValue);
        break;
      case 'Education Level':
        _showEducationLevelDialog(title, currentValue);
        break;
      case 'Smoking':
        _showSmokingDialog(title, currentValue);
        break;
      case 'Drinking':
        _showDrinkingDialog(title, currentValue);
        break;
      case 'Ethnicity':
        _showEthnicityDialog(title, currentValue);
        break;
      case 'Relationship':
        _showRelationshipDialog(title, currentValue);
        break;
      case 'Have Kids':
        _showKidsDialog(title, currentValue);
        break;
      case 'Horoscope':
        _showHoroscopeDialog(title, currentValue);
        break;
      case 'Looking for':
        _showLookingForBottomSheet(currentValue);
        break;
      default:
        _showDefaultEditDialog(title, currentValue);
    }
  }

  void _showGenderDialog(String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedGender = currentValue;
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            Languages.of(context)!.selectGendertxt,
            style: Appstyle.quicksand18w600,
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RadioListTile<String>(
                    value: 'Man - Straight',
                    title: Text(
                      Languages.of(context)!.manstraighttxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    groupValue: selectedGender,
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    onChanged: (value) {
                      setState(() => selectedGender = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(
                      Languages.of(context)!.mangaytxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: 'Man - Gay',
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() => selectedGender = value!);
                    },
                  ),
                  RadioListTile<String>(
                    dense: true,
                    title: Text(
                      Languages.of(context)!.manbitxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    contentPadding: EdgeInsets.zero,
                    value: 'Man - Bi',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() => selectedGender = value!);
                    },
                  ),
                  RadioListTile<String>(
                    dense: true,
                    title: Text(
                      Languages.of(context)!.womanstraighttxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    contentPadding: EdgeInsets.zero,
                    value: 'Woman - Straight',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() => selectedGender = value!);
                    },
                  ),
                  RadioListTile<String>(
                    dense: true,
                    title: Text(
                      Languages.of(context)!.womanlesbiantxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    contentPadding: EdgeInsets.zero,
                    value: 'Woman - Lesbian',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() => selectedGender = value!);
                    },
                  ),
                  RadioListTile<String>(
                    dense: true,
                    title: Text(
                      Languages.of(context)!.womanbitxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    contentPadding: EdgeInsets.zero,
                    value: 'Woman - Bi',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() => selectedGender = value!);
                    },
                  ),
                  RadioListTile<String>(
                    dense: true,
                    title: Text(
                      Languages.of(context)!.transMantxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    contentPadding: EdgeInsets.zero,
                    value: 'Trans-Man',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() => selectedGender = value!);
                    },
                  ),
                  RadioListTile<String>(
                    dense: true,
                    title: Text(
                      Languages.of(context)!.transWomantxt,
                      style: Appstyle.quicksand14w500.copyWith(
                        color: AppColors.blackclr,
                      ),
                    ),
                    visualDensity: VisualDensity.comfortable,
                    activeColor: AppColors.bminetxtclr,
                    contentPadding: EdgeInsets.zero,
                    value: 'Trans-Woman',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() => selectedGender = value!);
                    },
                  ),
                  const SizedBox(
                    height: 35,
                  ),
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
                                style: Appstyle.quicksand15w600
                                    .copyWith(color: AppColors.bminetxtclr),
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
                          onTap: () async {
                            Map<String, String> updatedData = {
                              'gender': selectedGender,
                            };
                            await updateProfileAPI(updatedData);
                            _updateaboutData('Gender', selectedGender);
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
                                style: Appstyle.quicksand15w600
                                    .copyWith(color: AppColors.whiteclr),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          //textAlign: TextAlign.center,
          Languages.of(context)!.pleaseaddatleastoneimagetxt,
          style: Appstyle.quicksand15w500.copyWith(color: AppColors.blackclr),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
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
                        style: Appstyle.quicksand15w600
                            .copyWith(color: AppColors.bminetxtclr),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.of(context).pop();
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
                        Languages.of(context)!.continuetxt,
                        style: Appstyle.quicksand15w600
                            .copyWith(color: AppColors.whiteclr),
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void _showHeightPickerDialog(String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int feet =
            int.parse(currentValue.isEmpty ? "-1" : currentValue.split("'")[0]);
        int inches = int.parse(currentValue.isEmpty
            ? "-1"
            : currentValue.split("'")[1].replaceAll('"', ''));

        return StatefulBuilder(builder: (context, myState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              Languages.of(context)!.selectheighttxt,
              style: Appstyle.quicksand18w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: <Widget>[
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.textfieldclr),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.textfieldclr),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.textfieldclr),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: feet.isNegative ? null : feet,
                            hint: Text(Languages.of(context)!.feettxt,
                                style: TextStyle(color: AppColors.hinttextclr)),
                            isExpanded: true,
                            isDense: true,
                            icon: Image.asset(
                              AppAssets.dropArrow,
                              width: 25,
                              height: 25,
                            ),
                            style: const TextStyle(color: Colors.black),
                            dropdownColor: Colors.white,
                            items: List.generate(8, (index) => index + 4)
                                .map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value ft'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              myState(() {
                                feet = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.textfieldclr),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.textfieldclr),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.textfieldclr),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: inches.isNegative ? null : inches,
                            hint: Text(Languages.of(context)!.inchestxt,
                                style: TextStyle(color: AppColors.hinttextclr)),
                            isExpanded: true,
                            isDense: true,
                            icon: Image.asset(
                              AppAssets.dropArrow,
                              width: 25,
                              height: 25,
                            ),
                            style: const TextStyle(color: Colors.black),
                            dropdownColor: Colors.white,
                            items: List.generate(12, (index) => index)
                                .map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value in'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              myState(() {
                                inches = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'height': "$feet'$inches\"",
                          };
                          await updateProfileAPI(updatedData);
                          _updateaboutData('Height', "$feet'$inches\"");
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showDrinkingDialog(String title, String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedValue = currentValue;

        // Define the options for drinking habits
        final List<String> drinkingOptions = [
          'Non-drinker',
          'Rarely drink',
          'Social drinker',
          'Regular drinker',
          'Recovering alcoholic',
          'Prefer not to say',
        ];

        return StatefulBuilder(builder: (context, myState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: Appstyle.quicksand18w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue.isEmpty ? null : selectedValue,
                      hint: Text(title,
                          style: const TextStyle(color: AppColors.hinttextclr)),
                      isExpanded: true,
                      isDense: true,
                      icon: Image.asset(
                        AppAssets.dropArrow,
                        width: 25,
                        height: 25,
                      ),
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: drinkingOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        myState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'drinking': selectedValue,
                          };
                          await updateProfileAPI(updatedData);
                          _updateaboutData(title, selectedValue);
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showEthnicityDialog(String title, String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedValue = currentValue;

        final List<String> ethnicityOptions = [
          'White/Caucasian',
          'Black/African American',
          'Hispanic/Latino',
          'Asian',
          'Middle Eastern',
          'Native American/Indigenous',
          'Pacific Islander',
          'Mixed/Multiracial',
          'Other',
          'Prefer not to say',
        ];
        return StatefulBuilder(builder: (context, myState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: Appstyle.quicksand18w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue.isEmpty ? null : selectedValue,
                      hint: Text(title,
                          style: const TextStyle(color: AppColors.hinttextclr)),
                      isExpanded: true,
                      isDense: true,
                      icon: Image.asset(
                        AppAssets.dropArrow,
                        width: 25,
                        height: 25,
                      ),
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: ethnicityOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        myState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'ethnicity': selectedValue,
                          };
                          await updateProfileAPI(updatedData);
                          _updateaboutData(title, selectedValue);
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showSmokingDialog(String title, String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedValue = currentValue;
        final List<String> smokingOptions = [
          'Never smoker',
          'Non-smoker',
          'Social smoker',
          'Regular smoker',
          'Former smoker',
          'Vaper',
          'Prefer not to say',
        ];
        return StatefulBuilder(builder: (context, myState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: Appstyle.quicksand18w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue.isEmpty ? null : selectedValue,
                      hint: Text(title,
                          style: const TextStyle(color: AppColors.hinttextclr)),
                      isExpanded: true,
                      isDense: true,
                      icon: Image.asset(
                        AppAssets.dropArrow,
                        width: 25,
                        height: 25,
                      ),
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: smokingOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        myState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'smoking': selectedValue,
                          };
                          await updateProfileAPI(updatedData);
                          _updateaboutData(title, selectedValue);
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showKidsDialog(String title, String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedValue = currentValue;

        // Define the options for having kids
        final List<String> kidsOptions = [
          'No kids',
          'Wants kids',
          'Have kids and want more',
          "Have kids and don't want more",
          "Don't have kids but want them in the future",
          "Don't have kids and don't want any",
          'Prefer not to say',
        ];

        return StatefulBuilder(builder: (context, myState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: Appstyle.quicksand18w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue.isEmpty ? null : selectedValue,
                      hint: Text(title,
                          style: const TextStyle(color: AppColors.hinttextclr)),
                      isExpanded: true,
                      isDense: true,
                      icon: Image.asset(
                        AppAssets.dropArrow,
                        width: 25,
                        height: 25,
                      ),
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: kidsOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        myState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'have_kids': selectedValue,
                          };
                          await updateProfileAPI(updatedData);
                          _updateaboutData(title, selectedValue);
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showRelationshipDialog(String title, String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedValue = currentValue;

        // Define the options for relationship statuses
        final List<String> relationshipOptions = [
          'Single',
          'In a relationship',
          'Married',
          'Divorced',
          'Separated',
          'Widowed',
          "It's complicated",
          'In an open relationship',
          'Polyamorous',
          'Prefer not to say',
        ];

        return StatefulBuilder(builder: (context, myState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: Appstyle.quicksand18w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue.isEmpty ? null : selectedValue,
                      hint: Text(title,
                          style: const TextStyle(color: AppColors.hinttextclr)),
                      isExpanded: true,
                      isDense: true,
                      icon: Image.asset(
                        AppAssets.dropArrow,
                        width: 25,
                        height: 25,
                      ),
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: relationshipOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        myState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'relationship': selectedValue,
                          };
                          await updateProfileAPI(updatedData);
                          _updateaboutData(title, selectedValue);
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showHoroscopeDialog(String title, String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedValue = currentValue;

        // Define the options for relationship statuses
        final List<String> horoscopeOptions = [
          'Aries (March 21 - April 19)',
          'Taurus (April 20 - May 20)',
          'Gemini (May 21 - June 20)',
          'Cancer (June 21 - July 22)',
          'Leo (July 23 - August 22)',
          'Virgo (August 23 - September 22)',
          'Libra (September 23 - October 22)',
          'Scorpio (October 23 - November 21)',
          'Sagittarius (November 22 - December 21)',
          'Capricorn (December 22 - January 19)',
          'Aquarius (January 20 - February 18)',
          'Pisces (February 19 - March 20)',
          "Don't believe in astrology",
        ];

        return StatefulBuilder(builder: (context, myState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: Appstyle.quicksand18w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue.isEmpty ? null : selectedValue,
                      hint: Text(title,
                          style: const TextStyle(color: AppColors.hinttextclr)),
                      isExpanded: true,
                      isDense: true,
                      icon: Image.asset(
                        AppAssets.dropArrow,
                        width: 25,
                        height: 25,
                      ),
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: horoscopeOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        myState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'horoscope': selectedValue,
                          };
                          await updateProfileAPI(updatedData);
                          _updateaboutData(title, selectedValue);
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showExerciseDialog(String title, String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedValue = currentValue;
        final List<String> exerciseOptions = [
          'Never',
          'Rarely',
          'Sometimes',
          'Regularly',
          'Daily',
          'Multiple times per day',
          'Professional athlete',
        ];

        return StatefulBuilder(builder: (context, myState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: Appstyle.quicksand18w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue.isEmpty ? null : selectedValue,
                      isExpanded: true,
                      isDense: true,
                      icon: Image.asset(
                        AppAssets.dropArrow,
                        width: 25,
                        height: 25,
                      ),
                      hint: Text(title,
                          style: const TextStyle(color: AppColors.hinttextclr)),
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: exerciseOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        myState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'exercise': selectedValue,
                          };
                          await updateProfileAPI(updatedData);
                          _updateaboutData(title, selectedValue);
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showEducationLevelDialog(String title, String currentValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedValue = currentValue;

        // Define the options for relationship statuses
        final List<String> educationLevelOptions = [
          'Some high school',
          'High school diploma',
          'Some college',
          'Associate\'s degree',
          'Bachelor\'s degree',
          'Master\'s degree',
          'Doctorate',
          'Professional degree (e.g. MD, JD)',
          'Trade school',
          'Prefer not to say',
        ];

        return StatefulBuilder(builder: (context, myState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: Appstyle.quicksand18w600,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.textfieldclr),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue.isEmpty ? null : selectedValue,
                      hint: Text(title,
                          style: const TextStyle(color: AppColors.hinttextclr)),
                      isExpanded: true,
                      isDense: true,
                      icon: Image.asset(
                        AppAssets.dropArrow,
                        width: 25,
                        height: 25,
                      ),
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: educationLevelOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        myState(() {
                          selectedValue = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'education_level': selectedValue,
                          };
                          await updateProfileAPI(updatedData);
                          _updateaboutData(title, selectedValue);
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _showDefaultEditDialog(String title, String currentValue) {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TextField(controller: controller),
              Text("$title:", style: Appstyle.quicksand18w600),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 13, horizontal: 10),
                    hintText: "Enter ${title.toLowerCase()}",
                    hintStyle: const TextStyle(color: AppColors.hinttextclr),
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
                height: 35,
              ),
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
                            style: Appstyle.quicksand15w600
                                .copyWith(color: AppColors.bminetxtclr),
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
                      onTap: () async {
                        Map<String, String> updatedData = {
                          title.toLowerCase(): controller.text,
                        };
                        await updateProfileAPI(updatedData);
                        _updateaboutData(title, controller.text);
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
                            style: Appstyle.quicksand15w600
                                .copyWith(color: AppColors.whiteclr),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _updateaboutData(String field, String newValue) {
    setState(() {
      for (var section in aboutData.values) {
        if (section.containsKey(field)) {
          section[field]['value'] = newValue;
          break;
        }
      }
    });
  }

  void _showLookingForBottomSheet(String currentValue) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        List<String> options = [
          'A Long-Term Relationship',
          'Fun Casual Dates',
          'Open to short term',
          'Humor',
          'Kindness',
          'Playfulness',
          'Marriage',
          'Intimacy Without Commitment',
          'A Life Partner',
          'Ethical Non-Monogamy',
        ];
        List<String> selectedOptions =
            currentValue.isNotEmpty ? currentValue.split(', ') : [];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter myState) {
            // Sort options with selected items first, then alphabetically
            List<String> sortedOptions = [
              ...selectedOptions,
              ...options.where((option) => !selectedOptions.contains(option))
            ]..sort((a, b) {
                if (selectedOptions.contains(a) &&
                    !selectedOptions.contains(b)) {
                  return -1;
                } else if (!selectedOptions.contains(a) &&
                    selectedOptions.contains(b)) {
                  return 1;
                } else {
                  return a.compareTo(b);
                }
              });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        Languages.of(context)!.whatarelookingfortxt,
                        style: Appstyle.quicksand18w600,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: sortedOptions.map((option) {
                          bool isSelected = selectedOptions.contains(option);
                          return ChoiceChip(
                            label: Text(
                              option,
                              style: Appstyle.quicksand12w500.copyWith(
                                color: AppColors.blackclr,
                              ),
                            ),
                            selected: isSelected,
                            backgroundColor: AppColors.lightgreyclr,
                            surfaceTintColor: Colors.transparent,
                            selectedColor:
                                AppColors.bminetxtclr.withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 6.0),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.transparent),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                            onSelected: (bool selected) {
                              myState(() {
                                if (selected) {
                                  selectedOptions.add(option);
                                } else {
                                  selectedOptions.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(),
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
                                  border:
                                      Border.all(color: AppColors.bminetxtclr),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Text(
                                    Languages.of(context)!.canceltxt,
                                    style: Appstyle.quicksand15w600
                                        .copyWith(color: AppColors.bminetxtclr),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                String newValue = selectedOptions.join(', ');

                                Map<String, String> updatedData = {
                                  'looking_for': newValue,
                                };
                                await updateProfileAPI(updatedData);
                                _updateaboutData('Looking for', newValue);
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
                                    style: Appstyle.quicksand15w600
                                        .copyWith(color: AppColors.whiteclr),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // void _showInterestSelectionBottomSheet(String currentValue) {
  //   showModalBottomSheet(
  //     backgroundColor: Colors.white,
  //     context: context,
  //     builder: (BuildContext context) {
  //       // Define a list of available interest options
  //       List<String> interestOptions = [
  //         'Art',
  //         'Foodie',
  //         'Makeup',
  //         'Traveling',
  //         'Music',
  //         'Reading',
  //         'Fitness',
  //         'Dancing',
  //         'Gaming',
  //         'Photography',
  //         'Cooking',
  //         'Hiking',
  //         'Fashion',
  //         'Sports',
  //         'Tech',
  //         'Writing',
  //         'Yoga',
  //         'Movies',
  //         'Swimming',
  //         'Socializing',
  //         'Gardening',
  //         'Crafting',
  //         'Martial Arts',
  //         'Volunteering',
  //         'Blogging',
  //         'Collecting',
  //         'Board Games',
  //         'Astrology',
  //         'DIY Projects',
  //         'Pets',
  //         'Gym',
  //         'Self Development',
  //         'Self Made',
  //         'Songwriting',
  //         'Freelancing',
  //         'Investing',
  //         'Expositions',
  //         'Singing',
  //         'Learning Languages',
  //         'Tattoos',
  //         'Painting',
  //         'Stock Exchange',
  //         'Brunch',
  //         'Coffee',
  //         'Tea',
  //         'Ice Cream',
  //         'Enjoying the Sun',
  //         'Tanning',
  //         'Travel the World',
  //         'Sushi',
  //         'Riding Motorcycle',
  //         'Working Out',
  //         'Lounges',
  //         'Clubs',
  //         'Restaurants',
  //         'Shopping',
  //         'Thrifting',
  //         'Comedy Shows',
  //         'Playing Instruments',
  //         'Bars',
  //         'Parties',
  //         'Nightlife',
  //         'Film Festival',
  //         'Pubs',
  //         'Concerts',
  //         'Town Festivities',
  //         'Gospel Music',
  //         'Rock Music',
  //         'Poetry',
  //         'Pizza',
  //         'Burgers',
  //         'Rowing',
  //         'Nature',
  //         'Skydiving',
  //         'Wine & Dine',
  //         'Clean Freak',
  //         'Jazz',
  //         'Hip Hop',
  //         'Camping',
  //         'Outdoors',
  //         'Picnicking',
  //         'Instagram',
  //         'Tik Tok',
  //         'Snowboarding',
  //         'Walking My Dog',
  //         'Walking',
  //         'Fishing',
  //         'Christmas Holidays',
  //         'Ramadan',
  //         'Religious',
  //         'Going to Church',
  //         'Making Lists',
  //         'Making Puzzles',
  //         'Hard Alcohol',
  //         'Visiting Farms',
  //         'Farmer',
  //         'Opera',
  //         'Heavy Metal',
  //         'Working on Cars',
  //         'Renovations',
  //         'Comicon',
  //         'Sailing',
  //         'Paragliding',
  //         'Diving',
  //         'Deep Diving',
  //         'Jet Skiing',
  //         'Snorkeling',
  //         'Mexican Food',
  //         'Chinese Food',
  //         'Arabic Food',
  //         'Learning New Cultures',
  //         'Trying New Ways',
  //         'Politics',
  //         'Self Care',
  //         'Easy Going',
  //         'Meditation',
  //         'Documentaries'
  //       ];

  //       // Convert the incoming currentValue to a list
  //       List<String> selectedInterests =
  //           currentValue.isNotEmpty ? currentValue.split(', ') : [];

  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter myState) {
  //           List<String> sortedInterests = [
  //             ...selectedInterests,
  //             ...interestOptions
  //                 .where((option) => !selectedInterests.contains(option))
  //           ]..sort((a, b) {
  //               if (selectedInterests.contains(a) &&
  //                   !selectedInterests.contains(b)) {
  //                 return -1;
  //               } else if (!selectedInterests.contains(a) &&
  //                   selectedInterests.contains(b)) {
  //                 return 1;
  //               } else {
  //                 return a.compareTo(b);
  //               }
  //             });
  //           return Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: SingleChildScrollView(
  //               child: Column(
  //                 children: [
  //                   Text(
  //                     Languages.of(context)!.selectintresttxt,
  //                     style: Appstyle.quicksand18w600,
  //                   ),
  //                   const SizedBox(height: 16),
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: InkWell(
  //                           onTap: () {
  //                             Navigator.of(context).pop();
  //                           },
  //                           child: Container(
  //                             height: 35,
  //                             decoration: BoxDecoration(
  //                               border:
  //                                   Border.all(color: AppColors.bminetxtclr),
  //                               borderRadius: BorderRadius.circular(25),
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 Languages.of(context)!.canceltxt,
  //                                 style: Appstyle.quicksand15w600
  //                                     .copyWith(color: AppColors.bminetxtclr),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                       const SizedBox(width: 10),
  //                       Expanded(
  //                         child: InkWell(
  //                           onTap: () async {
  //                             String newValue = selectedInterests.join(', ');
  //                             interest = newValue;

  //                             setState(() {
  //                               myIntrest = interest.isNotEmpty
  //                                   ? interest.split(', ')
  //                                   : [];
  //                             });
  //                             Map<String, String> updatedData = {
  //                               'interests': interest,
  //                             };
  //                             await updateProfileAPI(updatedData);
  //                             Navigator.of(context).pop();
  //                           },
  //                           child: Container(
  //                             height: 35,
  //                             decoration: BoxDecoration(
  //                               color: AppColors.bminetxtclr,
  //                               borderRadius: BorderRadius.circular(25),
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 Languages.of(context)!.savetxt,
  //                                 style: Appstyle.quicksand15w600
  //                                     .copyWith(color: AppColors.whiteclr),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       )
  //                     ],
  //                   ),
  //                   SizedBox(
  //                     height: 16,
  //                   ),
  //                   Wrap(
  //                     spacing: 8.0,
  //                     runSpacing: 4.0,
  //                     children: sortedInterests.map((interest) {
  //                       bool isSelected = selectedInterests.contains(interest);
  //                       return ChoiceChip(
  //                         label: Text(
  //                           interest,
  //                           style: Appstyle.quicksand12w500.copyWith(
  //                             color: AppColors.blackclr,
  //                           ),
  //                         ),
  //                         selected: isSelected,
  //                         backgroundColor: AppColors.lightgreyclr,
  //                         surfaceTintColor: Colors.transparent,
  //                         selectedColor: AppColors.bminetxtclr.withOpacity(0.4),
  //                         padding: const EdgeInsets.symmetric(
  //                             horizontal: 8.0, vertical: 6.0),
  //                         shape: RoundedRectangleBorder(
  //                           side: const BorderSide(color: Colors.transparent),
  //                           borderRadius: BorderRadius.circular(20),
  //                         ),
  //                         elevation: 0,
  //                         // onSelected: (bool selected) {
  //                         //   myState(() {
  //                         //     if (selected) {
  //                         //       selectedInterests.add(interest);
  //                         //     } else {
  //                         //       selectedInterests.remove(interest);
  //                         //     }
  //                         //   });
  //                         // },
  //                         onSelected: (bool selected) {
  //                           myState(() {
  //                             if (selected) {
  //                               if (selectedInterests.length >= 20) {
  //                                 // Show popup if max limit is reached
  //                                 ScaffoldMessenger.of(context).showSnackBar(
  //                                   SnackBar(
  //                                     content: Text(
  //                                         "You can select up to 20 interests only."),
  //                                     duration: Duration(seconds: 2),
  //                                   ),
  //                                 );
  //                               } else {
  //                                 selectedInterests.add(interest);
  //                               }
  //                             } else {
  //                               selectedInterests.remove(interest);
  //                             }
  //                           });
  //                         },
  //                       );
  //                     }).toList(),
  //                   ),
  //                   const SizedBox(height: 35),
  //                   // Row(
  //                   //   children: [
  //                   //     Expanded(
  //                   //       child: InkWell(
  //                   //         onTap: () {
  //                   //           Navigator.of(context).pop();
  //                   //         },
  //                   //         child: Container(
  //                   //           height: 35,
  //                   //           decoration: BoxDecoration(
  //                   //             border:
  //                   //                 Border.all(color: AppColors.bminetxtclr),
  //                   //             borderRadius: BorderRadius.circular(25),
  //                   //           ),
  //                   //           child: Center(
  //                   //             child: Text(
  //                   //               Languages.of(context)!.canceltxt,
  //                   //               style: Appstyle.quicksand15w600
  //                   //                   .copyWith(color: AppColors.bminetxtclr),
  //                   //             ),
  //                   //           ),
  //                   //         ),
  //                   //       ),
  //                   //     ),
  //                   //     const SizedBox(width: 10),
  //                   //     Expanded(
  //                   //       child: InkWell(
  //                   //         onTap: () async {
  //                   //           String newValue = selectedInterests.join(', ');
  //                   //           interest = newValue;
  //                   //           setState(() {
  //                   //             myIntrest = interest.isNotEmpty
  //                   //                 ? interest.split(', ')
  //                   //                 : [];
  //                   //           });
  //                   //           Map<String, String> updatedData = {
  //                   //             'interests': interest,
  //                   //           };
  //                   //           await updateProfileAPI(updatedData);
  //                   //           Navigator.of(context).pop();
  //                   //         },
  //                   //         child: Container(
  //                   //           height: 35,
  //                   //           decoration: BoxDecoration(
  //                   //             color: AppColors.bminetxtclr,
  //                   //             borderRadius: BorderRadius.circular(25),
  //                   //           ),
  //                   //           child: Center(
  //                   //             child: Text(
  //                   //               Languages.of(context)!.savetxt,
  //                   //               style: Appstyle.quicksand15w600
  //                   //                   .copyWith(color: AppColors.whiteclr),
  //                   //             ),
  //                   //           ),
  //                   //         ),
  //                   //       ),
  //                   //     )
  //                   //   ],
  //                   // )
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void _showInterestSelectionBottomSheet(String currentValue) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        List<String> interestOptions = [
          'Art',
          'Foodie',
          'Makeup',
          'Traveling',
          'Music',
          'Reading',
          'Fitness',
          'Dancing',
          'Gaming',
          'Photography',
          'Cooking',
          'Hiking',
          'Fashion',
          'Sports',
          'Tech',
          'Writing',
          'Yoga',
          'Movies',
          'Swimming',
          'Socializing',
          'Gardening',
          'Crafting',
          'Martial Arts',
          'Volunteering',
          'Blogging',
          'Collecting',
          'Board Games',
          'Astrology',
          'DIY Projects',
          'Pets',
          'Gym',
          'Self Development',
          'Self Made',
          'Songwriting',
          'Freelancing',
          'Investing',
          'Expositions',
          'Singing',
          'Learning Languages',
          'Tattoos',
          'Painting',
          'Stock Exchange',
          'Brunch',
          'Coffee',
          'Tea',
          'Ice Cream',
          'Enjoying the Sun',
          'Tanning',
          'Travel the World',
          'Sushi',
          'Riding Motorcycle',
          'Working Out',
          'Lounges',
          'Clubs',
          'Restaurants',
          'Shopping',
          'Thrifting',
          'Comedy Shows',
          'Playing Instruments',
          'Bars',
          'Parties',
          'Nightlife',
          'Film Festival',
          'Pubs',
          'Concerts',
          'Town Festivities',
          'Gospel Music',
          'Rock Music',
          'Poetry',
          'Pizza',
          'Burgers',
          'Rowing',
          'Nature',
          'Skydiving',
          'Wine & Dine',
          'Clean Freak',
          'Jazz',
          'Hip Hop',
          'Camping',
          'Outdoors',
          'Picnicking',
          'Instagram',
          'Tik Tok',
          'Snowboarding',
          'Walking My Dog',
          'Walking',
          'Fishing',
          'Christmas Holidays',
          'Ramadan',
          'Religious',
          'Going to Church',
          'Making Lists',
          'Making Puzzles',
          'Hard Alcohol',
          'Visiting Farms',
          'Farmer',
          'Opera',
          'Heavy Metal',
          'Working on Cars',
          'Renovations',
          'Comicon',
          'Sailing',
          'Paragliding',
          'Diving',
          'Deep Diving',
          'Jet Skiing',
          'Snorkeling',
          'Mexican Food',
          'Chinese Food',
          'Arabic Food',
          'Learning New Cultures',
          'Trying New Ways',
          'Politics',
          'Self Care',
          'Easy Going',
          'Meditation',
          'Documentaries'
        ];

        List<String> selectedInterests =
            currentValue.isNotEmpty ? currentValue.split(', ') : [];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter myState) {
            List<String> sortedInterests = [
              ...selectedInterests,
              ...interestOptions
                  .where((option) => !selectedInterests.contains(option))
            ]..sort((a, b) {
                if (selectedInterests.contains(a) &&
                    !selectedInterests.contains(b)) {
                  return -1;
                } else if (!selectedInterests.contains(a) &&
                    selectedInterests.contains(b)) {
                  return 1;
                } else {
                  return a.compareTo(b);
                }
              });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      Languages.of(context)!.selectintresttxt,
                      style: Appstyle.quicksand18w600,
                    ),
                    const SizedBox(height: 16),
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
                                border:
                                    Border.all(color: AppColors.bminetxtclr),
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
                              if (selectedInterests.length > 20) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Limit Exceeded"),
                                    content: Text(
                                        "You can select up to 20 interests only."),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              String newValue = selectedInterests.join(', ');
                              interest = newValue;

                              setState(() {
                                myIntrest = interest.isNotEmpty
                                    ? interest.split(', ')
                                    : [];
                              });

                              Map<String, String> updatedData = {
                                'interests': interest,
                              };

                              await updateProfileAPI(updatedData);
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
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: sortedInterests.map((interest) {
                        bool isSelected = selectedInterests.contains(interest);
                        return ChoiceChip(
                          label: Text(
                            interest,
                            style: Appstyle.quicksand12w500.copyWith(
                              color: AppColors.blackclr,
                            ),
                          ),
                          selected: isSelected,
                          backgroundColor: AppColors.lightgreyclr,
                          surfaceTintColor: Colors.transparent,
                          selectedColor: AppColors.bminetxtclr.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          onSelected: (bool selected) {
                            myState(() {
                              if (selected) {
                                if (selectedInterests.length >= 20) {
                                  // Do not show anything here – warning only on Save
                                } else {
                                  selectedInterests.add(interest);
                                }
                              } else {
                                selectedInterests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 35),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguageSelectionBottomSheet(String currentValue) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        // Define a list of available interest options
        List<String> languageOptions = [
          'English',
          'French',
          'Spanish',
          'Arabic',
          'German',
          'Greek',
          'Italian',
          'Dutch',
          'Portuguese',
          'Mandarin Chinese',
          'Hindi',
          'Russian',
          'Japanese',
          'Korean',
          'Vietnamese',
          'Turkish',
        ];

        List<String> selectedLanguage =
            currentValue.isNotEmpty ? currentValue.split(', ') : [];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter myState) {
            List<String> sortedLanguage = [
              ...selectedLanguage,
              ...languageOptions
                  .where((option) => !selectedLanguage.contains(option))
            ]..sort((a, b) {
                if (selectedLanguage.contains(a) &&
                    !selectedLanguage.contains(b)) {
                  return -1;
                } else if (!selectedLanguage.contains(a) &&
                    selectedLanguage.contains(b)) {
                  return 1;
                } else {
                  return a.compareTo(b);
                }
              });
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      Languages.of(context)!.selectlanguagetxt,
                      style: Appstyle.quicksand18w600,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: sortedLanguage.map((language) {
                        bool isSelected = selectedLanguage.contains(language);
                        return ChoiceChip(
                          label: Text(
                            language,
                            style: Appstyle.quicksand12w500.copyWith(
                              color: AppColors.blackclr,
                            ),
                          ),
                          selected: isSelected,
                          backgroundColor: AppColors.lightgreyclr,
                          surfaceTintColor: Colors.transparent,
                          selectedColor: AppColors.bminetxtclr.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          onSelected: (bool selected) {
                            myState(() {
                              if (selected) {
                                selectedLanguage.add(language);
                              } else {
                                selectedLanguage.remove(language);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                                border:
                                    Border.all(color: AppColors.bminetxtclr),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  Languages.of(context)!.canceltxt,
                                  style: Appstyle.quicksand15w600
                                      .copyWith(color: AppColors.bminetxtclr),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              String newValue = selectedLanguage.join(', ');
                              language = newValue;

                              setState(() {
                                myIntrest = language.isNotEmpty
                                    ? language.split(', ')
                                    : [];
                              });
                              Map<String, String> updatedData = {
                                'language': language,
                              };
                              await updateProfileAPI(updatedData);
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
                                  style: Appstyle.quicksand15w600
                                      .copyWith(color: AppColors.whiteclr),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCustomTextField(
                    controller: fNameController,
                    hintText: Languages.of(context)!.firstnamehinttxt,
                    title: Languages.of(context)!.fistNametxt),
                const SizedBox(height: 16),
                _buildCustomTextField(
                    controller: lNameController,
                    hintText: Languages.of(context)!.lastnamehinttxt,
                    title: Languages.of(context)!.lastNametxt),
                const SizedBox(height: 16),
                _buildDateField(context, Languages.of(context)!.dobtxt),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'first_name': fNameController.text.trim(),
                            'last_name': lNameController.text.trim(),
                            'dob': DateFormat('yyyy-MM-dd').format(
                                DateFormat('dd/MM/yyyy')
                                    .parse(dobController.text.trim())),
                            'firebase_id': firebaseId
                          };
                          await updateProfileAPI(updatedData);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BottomNavBar(
                                      index: 4,
                                    )),
                          );
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCustomTextField(
                  controller: bioController,
                  hintText: "Enter bio",
                  title: Languages.of(context)!.biolbltxt,
                ),
                const SizedBox(
                  height: 35,
                ),
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.bminetxtclr),
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
                        onTap: () async {
                          Map<String, String> updatedData = {
                            'bio': bioController.text.trim(),
                          };
                          await updateProfileAPI(updatedData);
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
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.whiteclr),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTextField(
      {required TextEditingController controller,
      required String hintText,
      required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$title:", style: Appstyle.quicksand18w600),
        const SizedBox(
          height: 10,
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.hinttextclr),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.textfieldclr),
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.textfieldclr),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.textfieldclr),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  _buildHomeTownTextField(
      {required TextEditingController controller,
      required String hintText,
      required String title}) async {
    List<Map<String, dynamic>> predictions = [];
    String selectedPlaceId = "";
    String hometownLat = "";
    String hometownLong = "";
    String country = "";
    Future<void> fetchPredictions(
        String input, StateSetter setBottomState) async {
      const apiKey = "AIzaSyCRNjykxoRKwqenOpoqBdoYz1CTvPYI5So";
      const apiUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json";
      final response = await http
          .get(Uri.parse('$apiUrl?input=$input&types=geocode&key=$apiKey'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          setBottomState(() {
            predictions = List<Map<String, dynamic>>.from(data['predictions']
                .map((prediction) => {
                      'description': prediction['description'],
                      'place_id': prediction['place_id']
                    }));
          });
        } else {
          setBottomState(() {
            predictions = [];
          });
        }
      } else {
        throw Exception('Failed to fetch predictions');
      }
    }

    Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
      const apiKey = "AIzaSyCRNjykxoRKwqenOpoqBdoYz1CTvPYI5So";
      const apiUrl = "https://maps.googleapis.com/maps/api/place/details/json";
      print("placeId = $placeId");
      final response =
          await http.get(Uri.parse('$apiUrl?place_id=$placeId&key=$apiKey'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final address = data['result']['formatted_address'] ?? '';

          // Get additional details if available
          final name = data['result']['name'] ?? '';
          Map<String, dynamic> details = {
            'latitude': location['lat'],
            'longitude': location['lng'],
            'address': address,
            'name': name,
            'place_id': placeId
          };

          // Store additional components if available
          if (data['result']['address_components'] != null) {
            for (var component in data['result']['address_components']) {
              final types = component['types'];
              if (types.contains('country')) {
                details['country'] = component['long_name'];
                details['country_code'] = component['short_name'];
              } else if (types.contains('administrative_area_level_1')) {
                details['state'] = component['long_name'];
              } else if (types.contains('locality')) {
                details['city'] = component['long_name'];
              }
            }
          }

          return details;
        } else {
          throw Exception('Failed to fetch place details: ${data['status']}');
        }
      } else {
        throw Exception(
            'Failed to fetch place details: ${response.statusCode}');
      }
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("$title:", style: Appstyle.quicksand18w600),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: controller,
                      onSubmitted: (value) {
                        predictions.clear();
                        setBottomState(() {});
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          fetchPredictions(value, setBottomState);
                        } else {
                          setBottomState(() {
                            predictions.clear();
                          });
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: hintText,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 10),
                        hintStyle:
                            const TextStyle(color: AppColors.hinttextclr),
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
                        ),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        child: predictions.isEmpty
                            ? const SizedBox.shrink()
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: predictions.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10),
                                      leading: const Icon(
                                          Icons.location_on_outlined),
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      title: Text(
                                        predictions[index]['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () async {
                                        try {
                                          setBottomState(() {
                                            controller.text = predictions[index]
                                                ['description'];
                                          });
                                          final String selectedPlaceId =
                                              predictions[index]['place_id'];
                                          final placeDetails =
                                              await fetchPlaceDetails(
                                                  selectedPlaceId);

                                          hometownLat = placeDetails['latitude']
                                              .toString();

                                          country = placeDetails['country']
                                              .toString();
                                          hometownLong =
                                              placeDetails['longitude']
                                                  .toString();
                                          setBottomState(() {
                                            predictions.clear();
                                          });
                                        } catch (e) {
                                          print(
                                              "Error fetching place details: $e");
                                          // Show error to user if needed
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(
                      height: 35,
                    ),
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
                                border:
                                    Border.all(color: AppColors.bminetxtclr),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  Languages.of(context)!.canceltxt,
                                  style: Appstyle.quicksand15w600
                                      .copyWith(color: AppColors.bminetxtclr),
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
                            onTap: () async {
                              Map<String, String> updatedData = {
                                title.toLowerCase(): controller.text,
                                "country": country,
                                "latitude": hometownLat,
                                "longitude": hometownLong
                              };
                              await updateProfileAPI(updatedData);
                              _updateaboutData(title, controller.text);
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
                                  style: Appstyle.quicksand15w600
                                      .copyWith(color: AppColors.whiteclr),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateField(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$title:", style: Appstyle.quicksand18w600),
        const SizedBox(
          height: 10,
        ),
        TextField(
          controller: dobController,
          readOnly: true,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today, color: AppColors.blackclr),
              onPressed: () => _selectDate(context),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
            hintText: Languages.of(context)!.dobtxt,
            hintStyle: const TextStyle(color: AppColors.hinttextclr),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.textfieldclr),
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.textfieldclr),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.textfieldclr),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  updateProfileAPI(Map<String, String> jsonBody) async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .updateProfileAPI(
          userid,
          jsonBody,
        );
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              showToast(Provider.of<ProfileViewModel>(context, listen: false)
                  .editProfileresponse
                  .msg
                  .toString());
            });
            await getProfileDetails();
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<ProfileViewModel>(context, listen: false)
                .editProfileresponse
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

  getProfileDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoading = true;
    });

    getuserid();

    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .getProfileAPI(userid, "", "", measurementtype);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            try {
              setState(() {
                isLoading = false;
                profileResponseModel =
                    Provider.of<ProfileViewModel>(context, listen: false)
                        .profileresponse
                        .response as ProfileResponseModel;
                fNameController = TextEditingController(
                    text: profileResponseModel.userProfile!.firstName ?? "");
                lNameController = TextEditingController(
                    text: profileResponseModel.userProfile!.lastName ?? "");
                dobController = TextEditingController(
                  text: profileResponseModel.userProfile!.dob == null
                      ? ""
                      : DateFormat('dd/MM/yyyy').format(
                          profileResponseModel.userProfile!.dob!,
                        ),
                );
                bioController = TextEditingController(
                    text: profileResponseModel.userProfile!.bio ?? "");
                _currentIntroPage = _pageController.initialPage;
                hometownController = TextEditingController(
                    text: profileResponseModel.userProfile!.hometown ?? "");
                interest = profileResponseModel.intrested!.isNotEmpty
                    ? profileResponseModel.intrested!.join(", ")
                    : "";
                myIntrest = interest.isNotEmpty ? interest.split(', ') : [];
                if (profileResponseModel.postData!.isNotEmpty) {
                  imageList.fillRange(0, bioImageLen, null);
                  for (int i = 0;
                      i < profileResponseModel.postData!.length &&
                          i < bioImageLen;
                      i++) {
                    imageList[i] = ImageData(
                      path: profileResponseModel.postData![i].images ?? "",
                      id: profileResponseModel.postData![i].id ?? -1,
                    );
                    // do image code here for change in firebased
                  }
                } else {
                  imageList.fillRange(0, bioImageLen, null);
                }
                while (imageList.length < bioImageLen) {
                  imageList.add(null);
                }
//                 if (profileResponseModel.postData!.isNotEmpty) {
//                   fileList.fillRange(0, 6, null);
//                   for (int i = 0;
//                       i < profileResponseModel.postData!.length && i < 6;
//                       i++) {
//                     final postItem = profileResponseModel.postData![i];

//                     final path = postItem.images ?? "";
//                     final isVideo =
//                         isVideoFile(path); // Use your helper function

//                     fileList[i] = MediaData(
//                       path: path,
//                       id: postItem.id ?? -1,
//                       isVideo: isVideo,
//                     );
//                   }
//                 } else {
//                   fileList.fillRange(0, 6, null);
//                 }

// // Ensure list always has 6 entries
//                 while (fileList.length < 6) {
//                   fileList.add(null);
//                 }

                if (profileResponseModel.aboutMe != null &&
                    profileResponseModel.aboutMe!.isNotEmpty) {
                  for (var aboutItem in profileResponseModel.aboutMe!) {
                    if (aboutItem.type != null && aboutItem.value != null) {
                      if (aboutData['About you']!
                          .containsKey(aboutItem.type!)) {
                        aboutData['About you']![aboutItem.type!]!['value'] =
                            aboutItem.value!;
                      } else if (aboutData['More about you']!
                          .containsKey(aboutItem.type!)) {
                        aboutData['More about you']![aboutItem.type!]![
                            'value'] = aboutItem.value!;
                      }
                    }
                  }
                }
                if (profileResponseModel.userProfile?.hometown != null) {
                  aboutData['About you']!['Hometown']!['value'] =
                      profileResponseModel.userProfile!.hometown!;
                }
                String lookingForString =
                    profileResponseModel.lookingFor?.join(', ') ?? '';
                aboutData['More about you']!['Looking for']!['value'] =
                    lookingForString;

                isLoading = false;
              });
              print(imageList[0]!.path);
              DatabaseReference userRef =
                  FirebaseDatabase.instance.ref('users/$firebaseId');
              await userRef.update({'photoUrl': imageList[0]!.path});
            } catch (e) {
              print("object errorr - $e");
            }
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

  uploadPhotosAPI(List<XFile?> images, int seq) async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .uploadPhotosAPI(userid, firebaseId, images, seq);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              showToast(Provider.of<ProfileViewModel>(context, listen: false)
                  .uploadphotosresponse
                  .msg
                  .toString());
              selectedImages = List.filled(bioImageLen, null);
            });
            await getProfileDetails();
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<ProfileViewModel>(context, listen: false)
                .uploadphotosresponse
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

  removePhotosAPI(String imageId) async {
    setState(() {
      isLoading = true;
    });
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .removePhotosAPI(imageId);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              showToast(Provider.of<ProfileViewModel>(context, listen: false)
                  .removephotosresponse
                  .msg
                  .toString());
            });
            await getProfileDetails();
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<ProfileViewModel>(context, listen: false)
                .removephotosresponse
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

  updatePostSeqAPI(String imageId1, int seq1, String imageId2, int seq2) async {
    setState(() {
      isLoading = true;
    });
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .updatePostSeqAPI(imageId1, seq1, imageId2, seq2);
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              showToast(Provider.of<ProfileViewModel>(context, listen: false)
                  .updatePostSEQResponse
                  .msg
                  .toString());
            });
            await getProfileDetails();
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<ProfileViewModel>(context, listen: false)
                .removephotosresponse
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

  Future<Widget> buildThumbnail(Uint8List thumbBytes, bool showPlayIcon) async {
    return Stack(
      children: [
        Image.memory(
          thumbBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        if (showPlayIcon)
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white70,
              size: 48,
            ),
          ),
      ],
    );
  }

  Widget _buildDotted() {
    return DottedBorder(
      color: Colors.black87,
      borderType: BorderType.RRect,
      radius: const Radius.circular(8),
      strokeWidth: 1,
      child: Container(),
    );
  }

  Widget _buildItem(int index, {bool draggable = true}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Widget>(
              future: () async {
                final file = selectedImages[index];
                final netImage = imageList[index];
                final path = file?.path ?? netImage?.path;

                if (path == null || path.isEmpty) return _buildDotted();

                final ext = path.split('.').last.toLowerCase();
                final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);

                if (file != null) {
                  if (isVideo) {
                    final thumb = await VideoThumbnail.thumbnailData(
                      video: file.path,
                      imageFormat: ImageFormat.JPEG,
                      quality: 75,
                    );
                    return thumb != null
                        ? await buildThumbnail(thumb, true)
                        : _buildDotted();
                  } else {
                    return Image.file(
                      File(file.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  }
                } else if (netImage != null && netImage.path.isNotEmpty) {
                  final url = "${API.baseUrl}/upload/${netImage.path}";
                  if (isVideo) {
                    try {
                      final response = await http.get(Uri.parse(url));
                      if (response.statusCode == 200) {
                        final tempDir = await getTemporaryDirectory();
                        final tempPath =
                            "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext";
                        final file = File(tempPath);
                        await file.writeAsBytes(response.bodyBytes);
                        final thumb = await VideoThumbnail.thumbnailData(
                          video: file.path,
                          imageFormat: ImageFormat.JPEG,
                          quality: 75,
                        );
                        return thumb != null
                            ? await buildThumbnail(thumb, true)
                            : _buildDotted();
                      }
                    } catch (_) {}
                    return _buildDotted();
                  } else {
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.bminetxtclr,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, _) {
                        return Image.asset(
                          AppAssets.femaleUser,
                          fit: BoxFit.fill,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      },
                    );
                  }
                }

                return _buildDotted();
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return snapshot.data ?? _buildDotted();
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: selectedImages[index] == null
              ? (imageList[index] != null && imageList[index]!.path.isNotEmpty)
                  ? InkWell(
                      onTap: () {
                        if (index == 0) {
                          _pickImage(index);
                        } else {
                          _removeImage(index);
                        }
                      },
                      child: Image.asset(
                          index == 0 ? AppAssets.addicon : AppAssets.deleteicon,
                          height: 25),
                    )
                  : InkWell(
                      onTap: () {
                        if (index == 0) {
                          _pickImage(index);
                        } else {
                          _pickMedia(index);
                        }
                      },
                      child: Image.asset(AppAssets.addicon, height: 25),
                    )
              : InkWell(
                  onTap: () {
                    if (index != 0) {
                      _removeImage(index);
                    }
                  },
                  child: Image.asset(
                      index == 0 ? AppAssets.addicon : AppAssets.deleteicon,
                      height: 25),
                ),
        ),
      ],
    );
  }
}
