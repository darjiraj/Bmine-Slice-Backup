import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:bmine_slice/Utils/TypingService.dart';
import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/chatmodel.dart';
import 'package:bmine_slice/models/commonresponsemodel.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/myprofilescreen.dart';
import 'package:bmine_slice/viewmodels/notificationsviewmodel.dart';
import 'package:bmine_slice/viewmodels/userreportviewmodel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatScreen extends StatefulWidget {
  String oppId = "";
  // String firebaseUId = "";
  // String name = "";
  // String dob = "";
  // String userImg = "";
  String frdId = "";
  ChatScreen({
    super.key,
    required this.oppId,
    // required this.firebaseUId,
    // required this.name,
    // required this.dob,
    // required this.userImg,
    required this.frdId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _recordingPath;
  bool _isRecording = false;
  bool _showControls = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  DatabaseReference? _chatmessagesRef;
  List<ChatMessage> chatMessages = [];
  int prevDate = 0;
  String firebaseId = "";
  String channelId = "";
  bool isLoading = false;
  bool _isInChatScreen = false;
  final _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  File? audioFile;
  File? imageFile;
  String currentUserPhotoUrl = "";
  String opponentUserPhotoUrl = "";
  final ImagePicker _picker = ImagePicker();
  Map<dynamic, dynamic> userMap = {};
  String userid = "";
  bool isReqLoading = false;
  bool _isDisposed = false;
  late TypingService typingService;
  DatabaseReference? typingRef;
  bool isUserTyping = false;

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
    setState(() {});
  }

  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  String? recordedFilePath;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String selectedLang = "";
  StreamSubscription<DatabaseEvent>? _userSubscription;

  getIds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      firebaseId = prefs.getString('firebaseId') ?? "";
      isLoading = true;
    });

    DatabaseReference ref = FirebaseDatabase.instance.ref('message');

    currentUserPhotoUrl = await _getProfilePhoto(firebaseId);
    opponentUserPhotoUrl = await _getProfilePhoto(widget.oppId);

    setState(() {});
    print("Current User Photo URL: $currentUserPhotoUrl");
    print("Opponent User Photo URL: $opponentUserPhotoUrl");

    ref.once().then((event) {
      print("ref.once() called");
      var temp = event.snapshot.value;

      Map<dynamic, dynamic> allChannels = temp as Map<dynamic, dynamic>;

      allChannels.forEach((key, value) async {
        List<String> parts = key.split('--');

        if (parts.contains(firebaseId.replaceFirst('-', ''))) {
          print("parts == $parts");
          print("key == $key");
          int idPosition = parts.indexOf(firebaseId.replaceFirst('-', ''));

          print("idPosition = $idPosition");
          print("widget.oppId = ${widget.oppId}");
          if (idPosition == 1) {
            if (parts[2] == widget.oppId.replaceFirst("-", "")) {
              channelId = key;
              ///////////
              typingService = TypingService(roomId: key, userId: firebaseId);
              typingService.setupDisconnect();
              typingRef = FirebaseDatabase.instance.ref('typingStatus/$key');
              typingRef!.onValue.listen((event) {
                final data = event.snapshot.value as Map?;
                print("typingRef ${data}");
                if (data != null) {
                  print("typingRef 12121 ${data.keys}");
                  data.forEach((uid, isTyping) {
                    // print("typingRef isTyping ${isTyping}");
                    // if (isTyping) {
                    //   setState(() {
                    //     isUserTyping = true;
                    //   });
                    // } else {
                    //   setState(() {
                    //     isUserTyping = false;
                    //   });
                    // }
                    if (uid != firebaseId) {
                      setState(() {
                        isUserTyping = isTyping;
                      });
                    }
                  });
                }
              });
              //////////////
              _chatmessagesRef = FirebaseDatabase.instance
                  .ref()
                  .child('message')
                  .child(channelId);
              print("if _chatmessagesRef == ${_chatmessagesRef!.key}");
              _chatmessagesRef!.onValue.listen((event) {
                var tempMessages = event.snapshot.value;

                if (tempMessages != null) {
                  Map<dynamic, dynamic> allMessages =
                      tempMessages as Map<dynamic, dynamic>;

                  allMessages.forEach((key, value) {
                    Map message = value as Map;

                    print("New message value == $message");

                    if (_isInChatScreen &&
                        message['idTo'] == firebaseId &&
                        message['isSeen'] == false) {
                      DatabaseReference messageRef =
                          _chatmessagesRef!.child(key);
                      print(
                          "Updating isSeen for messageRef = ${messageRef.key}");
                      messageRef.update({'isSeen': true});
                    }
                  });
                }
              });

              setState(() {
                isLoading = false;
              });
            }
          } else if (idPosition == 2) {
            print("widget.oppId positon 2 === ${widget.oppId}");
            print("parts[1] positon 2 === ${parts[1]}");
            if (parts[1] == widget.oppId.replaceFirst("-", "")) {
              channelId = key;
              ///////////
              typingService = TypingService(roomId: key, userId: firebaseId);
              typingService.setupDisconnect();
              typingRef = FirebaseDatabase.instance.ref('typingStatus/$key');
              typingRef!.onValue.listen((event) {
                final data = event.snapshot.value as Map?;
                print("typingRef ${data}");
                if (data != null) {
                  print("typingRef 12121 ${data.keys}");
                  data.forEach((uid, isTyping) {
                    if (uid != firebaseId) {
                      setState(() {
                        isUserTyping = isTyping;
                      });
                    }
                  });
                }
              });
              //////////////
              _chatmessagesRef = FirebaseDatabase.instance
                  .ref()
                  .child('message')
                  .child(channelId);
              print("else _chatmessagesRef == ${_chatmessagesRef!.key}");
              _chatmessagesRef!.onValue.listen((event) {
                var tempMessages = event.snapshot.value;
                if (tempMessages != null) {
                  Map<dynamic, dynamic> allMessages =
                      tempMessages as Map<dynamic, dynamic>;
                  allMessages.forEach((key, value) {
                    Map message = value as Map;
                    print("New message value == ${value['isSeen']}");
                    if (_isInChatScreen &&
                        message['idTo'] == firebaseId &&
                        message['isSeen'] == false) {
                      DatabaseReference messageRef =
                          _chatmessagesRef!.child(key);
                      print(
                          "Updating isSeen for messageRef = ${messageRef.key}");
                      messageRef.update({'isSeen': true});
                    }
                  });
                }
              });

              setState(() {
                isLoading = false;
              });
            } else {
              print("id position 2 else ");
            }
          }
          scrollToBottom();
        }
      });
    });

    // typingRef!.onValue.listen((event) {
    //   final data = event.snapshot.value as Map?;
    //   print("data ${data}");
    //   if (data != null) {
    //     print("data ${data.keys}");
    //     data.forEach((uid, isTyping) {
    //       print(isUserTyping);
    //       setState(() {
    //         isUserTyping = true;
    //       });
    //       // if (uid != firebaseId && isTyping == true) {
    //       //   isUserTyping = true;
    //       // }
    //     });
    //   }
    // });
  }

  void _initializeChatStatus() async {
    try {
      // Update chat status to true when entering the chat
      await updateUserChatStatus(true);
    } catch (e) {
      print('Error initializing chat status: $e');
    }
  }

  Future<String> _getProfilePhoto(String userId) async {
    try {
      if (userId.isEmpty) {
        return "";
      }
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('users/$userId');

      // Cancel any existing subscription before creating a new one
      await _userSubscription?.cancel();

      _userSubscription = userRef.onValue.listen((DatabaseEvent event) {
        // Only update if the widget is still mounted
        if (!_isDisposed && mounted) {
          if (event.snapshot.value != null) {
            setState(() {
              userMap = event.snapshot.value as Map<dynamic, dynamic>;
            });
            // print("Updated userMap: $userMap");
          }
        }
      });
      return userMap['photoUrl'] ?? "";
    } catch (e) {
      print('Error fetching profile photo from Realtime Database: $e');
      return '';
    }
  }

  Future<void> updateUserChatStatus(bool isInChat) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String fbId = prefs.getString('firebaseId') ?? "";

      if (fbId.isNotEmpty) {
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref('users/$fbId');
        await userRef.update({'inChat': isInChat});
      }
    } catch (e) {
      print('Error updating user chat status: $e');
    }
  }

  @override
  void initState() {
    _isInChatScreen = true;
    _initializeChatStatus();
    getIds();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
    super.initState();
  }

  @override
  void dispose() {
    _isInChatScreen = false;
    _isDisposed = true;
    _userSubscription?.cancel();
    updateUserChatStatus(false);

    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _recorder?.closeRecorder();
    typingService.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(
          const Duration(milliseconds: 100),
          () => _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ));
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    var kSize = MediaQuery.of(context).size;

    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppColors.chatbgclr,
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
                  InkWell(
                    onTap: () {
                      print("widget.userImg == ${widget.frdId}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyProfileScreen(
                            isScreen: "Friend-Profile",
                            frdId: widget.frdId,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            userMap['photoUrl'] != ""
                                ? CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(
                                        "${API.baseUrl}/upload/${userMap['photoUrl']}"))
                                : CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        AssetImage(AppAssets.personicon),
                                  ),
                            Container(
                              height: 12,
                              width: 12,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 1.5, color: AppColors.whiteclr),
                                  borderRadius: BorderRadius.circular(20),
                                  color: userMap['status'] == "online"
                                      ? AppColors.greenclr
                                      : AppColors.timetxtgrey),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${userMap['nickname'] != null ? userMap['nickname'].split(" ")[0] : ""}'
                              '${userMap['nickname'] != null && userMap['nickname'].split(" ").length > 1 ? " ${userMap['nickname'].split(" ").last.substring(0, 1)}" : ""}'
                              '${userMap['dob'] != null ? ", ${calculateAge(DateTime.parse(userMap['dob']))}" : ""}',
                              style: Appstyle.quicksand16w500
                                  .copyWith(color: AppColors.blackclr),
                            ),
                            SizedBox(
                              height: 3,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 2,
                                ),
                                Text(
                                  isUserTyping
                                      ? "typing...."
                                      : userMap['status'] ?? "offline",
                                  style: Appstyle.quicksand12w500
                                      .copyWith(color: AppColors.blackclr),
                                ),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              InkWell(
                  onTap: () {
                    showMenu(
                      context: context,
                      color: AppColors.whiteclr,
                      menuPadding: EdgeInsets.zero,
                      position: RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: [
                        PopupMenuItem(
                          value: 'report',
                          padding: EdgeInsets.only(left: 10),
                          child: Text(
                            Languages.of(context)!.reporttxt,
                            style: Appstyle.quicksand16w500
                                .copyWith(color: AppColors.blackclr),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block-user',
                          padding: EdgeInsets.only(left: 10),
                          child: Text(
                            Languages.of(context)!.blocktxt,
                            style: Appstyle.quicksand16w500
                                .copyWith(color: AppColors.blackclr),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'unmatch',
                          padding: EdgeInsets.only(left: 10),
                          child: Text(
                            Languages.of(context)!.unmatchtxt,
                            style: Appstyle.quicksand16w500
                                .copyWith(color: AppColors.blackclr),
                          ),
                        ),
                      ],
                    ).then((value) {
                      _showReportUserAlertDialog(
                          '${userMap['nickname'] != null ? userMap['nickname'].split(" ")[0] : ""}'
                          '${userMap['nickname'] != null && userMap['nickname'].split(" ").length > 1 ? " ${userMap['nickname'].split(" ").last.substring(0, 1)}" : ""}',
                          userMap['photoUrl'],
                          widget.frdId,
                          value ?? "");
                    });
                  },
                  child: Image.asset(AppAssets.threedotcon))
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: <Widget>[
                const SizedBox(height: 15),
                _chatmessagesRef == null
                    ? Expanded(child: Container())
                    : isLoading
                        ? Expanded(
                            child: Container(
                              color: Colors.transparent,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.bminetxtclr,
                                ),
                              ),
                            ),
                          )
                        : Expanded(
                            child: FirebaseAnimatedList(
                              sort: (DataSnapshot a, DataSnapshot b) =>
                                  b.key!.compareTo(a.key!),
                              query: _chatmessagesRef!,
                              shrinkWrap: true,
                              reverse: true,
                              controller: _scrollController,
                              itemBuilder:
                                  (context, snapshot, animation, index) {
                                Map message = snapshot.value as Map;
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    message['timestamp'] == null
                                        ? Container()
                                        : Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              DateFormat('dd MMM').format(DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      message['timestamp'])),
                                              style: const TextStyle(
                                                color: AppColors.blackclr,
                                                fontFamily: "Quicksand",
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                    message['content'] == null ||
                                            message['content'] == ""
                                        ? Container()
                                        : ChatBubble(
                                            content: message['content'] ?? "",
                                            isSender:
                                                message['idFrom'] == firebaseId
                                                    ? true
                                                    : false,
                                            color:
                                                message['idFrom'] == firebaseId
                                                    ? AppColors.bordergclr
                                                    : AppColors.whiteclr,
                                            tail: true,
                                            textStyle: Appstyle.quicksand14w500
                                                .copyWith(
                                                    color: AppColors.blackclr),
                                            createdAt: message['createdAt'],
                                            type: message['type'],
                                            currentUserPhoto:
                                                currentUserPhotoUrl,
                                            opositeUserPhoto:
                                                opponentUserPhotoUrl,
                                          ),
                                  ],
                                );
                              },
                            ),
                          ),
                const SizedBox(
                  height: 10,
                ),
                // Inside your widget build method
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.borgergreyclr),
                    ),
                    child: Row(
                      children: [
                        if (_isRecording) ...[
                          // Cancel recording button
                          InkWell(
                            onTap: () async {
                              await _cancelRecording();
                            },
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                          const SizedBox(width: 10),

                          // Recording timer
                          Text(
                            _formatDuration(_recordingDuration),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                        ] else ...[
                          // Text input
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              maxLines: 5,
                              minLines: 1,
                              onChanged: (value) {
                                typingService.onTextChanged(value);
                              },
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                hintText: Languages.of(context)!.typemsgtxt,
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Camera icon
                          InkWell(
                            onTap: _sendImage,
                            child: Image.asset(
                              AppAssets.camera,
                              width: 25,
                              height: 25,
                              color: AppColors.btngrey,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],

                        // Mic or Send button
                        _isRecording
                            ? InkWell(
                                onTap: () async {
                                  await _stopRecordingAndSend();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.signinclr1,
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    // AppAssets.send,
                                    AppAssets.sendicon,
                                    width: 20,
                                    height: 20,
                                    color: AppColors.whiteclr,
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: () async {
                                  await _startRecording();
                                },
                                // child: const Icon(Icons.mic_none,
                                //     color: Colors.black, size: 25),
                                child: Image.asset(
                                  AppAssets.micicon,
                                  width: 23,
                                  height: 23,
                                  // color: AppColors.btngrey,
                                ),
                              ),
                        const SizedBox(width: 5),

                        // Send text message
                        if (!_isRecording)
                          InkWell(
                            onTap: () {
                              if (_messageController.text.trim().isNotEmpty) {
                                sendMessage(
                                    _messageController.text.trim(), "0");
                              }
                            },
                            child: Image.asset(
                              width: 25,
                              AppAssets.sendicon,
                              height: 25,
                            ),
                            // child: Container(
                            //   decoration: BoxDecoration(
                            //     shape: BoxShape.circle,
                            //     color: _messageController.text.isEmpty
                            //         ? AppColors.lightgreyclr
                            //         : AppColors.signinclr1,
                            //   ),
                            //   padding: const EdgeInsets.all(8.0),
                            //   child: Image.asset(
                            //     width: 20,
                            //     // AppAssets.send,
                            //     AppAssets.sendicon,
                            //     height: 20,
                            //     // color: _messageController.text.isEmpty
                            //     //     ? AppColors.btngrey
                            //     //     : Colors.transparent,
                            //   ),
                            // ),
                          ),
                      ],
                    ),
                  ),
                )

                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 10),
                //   child: Container(
                //     margin: const EdgeInsets.only(bottom: 20),
                //     padding:
                //         const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                //     decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.circular(25),
                //         border: Border.all(color: AppColors.borgergreyclr)),
                //     child: Row(
                //       children: [
                //         Expanded(
                //           child: TextField(
                //             controller: _messageController,
                //             maxLines: 5,
                //             minLines: 1,
                //             // onTapOutside: (event) {
                //             //   FocusScope.of(context).requestFocus(FocusNode());
                //             // },
                //             onChanged: (value) {
                //               setState(() {});
                //             },
                //             textInputAction: TextInputAction.done,
                //             decoration: InputDecoration(
                //               contentPadding:
                //                   EdgeInsets.symmetric(horizontal: 10),
                //               hintText: Languages.of(context)!.typemsgtxt,
                //               isDense: true,
                //               border: InputBorder.none,
                //             ),
                //           ),
                //         ),
                //         const SizedBox(width: 10),
                //         InkWell(
                //             onTap: () {
                //               _sendImage();
                //             },
                //             child: Image.asset(
                //               AppAssets.camera,
                //               width: 25,
                //               height: 25,
                //               color: AppColors.btngrey,
                //             )),
                //         const SizedBox(width: 5),
                //         // Icon(
                //         //   _isRecording ? Icons.mic : Icons.mic_none,
                //         //   key: ValueKey(_isRecording),
                //         //   size: 25,
                //         //   color: Colors.black,
                //         // ),
                //         VoiceMessageButton(
                //           onVoiceMessageComplete: _handleVoiceMessage,
                //         ),
                //         const SizedBox(width: 5),

                //         InkWell(
                //           onTap: () {
                //             if (_messageController.text.isNotEmpty) {
                //               sendMessage(_messageController.text.trim(), "0");
                //             }
                //           },
                //           child: Container(
                //             decoration: BoxDecoration(
                //               shape: BoxShape.circle,
                //               color: _messageController.text.isEmpty
                //                   ? AppColors.lightgreyclr
                //                   : AppColors.signinclr1,
                //             ),
                //             child: Padding(
                //                 padding: const EdgeInsets.all(8.0),
                //                 child: Image.asset(
                //                   AppAssets.send,
                //                   width: 20,
                //                   height: 20,
                //                   color: _messageController.text.isEmpty
                //                       ? AppColors.btngrey
                //                       : AppColors.whiteclr,
                //                 )),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        print("directioroty---- ${dir}");
        _recordingPath =
            '${dir.path}/audio_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
        print("_recordingPath---- ${_recordingPath}");
        await _audioRecorder.start(
          const RecordConfig(
              // encoder: AudioEncoder.wav,
              // bitRate: 128000,
              // sampleRate: 44100,
              ),
          path: _recordingPath!,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });

        _recordingTimer?.cancel(); // Ensure only one timer
        _recordingTimer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            setState(() {
              _recordingDuration++;
            });
          },
        );
      } else {
        _showPermissionDialog();
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final path = await _audioRecorder.stop();

      _recordingTimer?.cancel();
      _recordingTimer = null;
      setState(() {
        _recordingDuration = 0;
        _isRecording = false;
        _showControls = false;
      });
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final fileStat = await file.stat();
          if (fileStat.size > 1000) {
            _handleVoiceMessage(path);
          } else {
            print('Recording too short, not sending.');
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      _recordingTimer?.cancel();

      _recordingTimer?.cancel();
      _recordingTimer = null;
      setState(() {
        _recordingDuration = 0;
        _isRecording = false;
        _showControls = false;
      });

      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Languages.of(context)!.permissionRequiredtxt),
        content: Text(Languages.of(context)!.microphonepermissionmessagestxt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Languages.of(context)!.oktxt),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Languages.of(context)!.recordingerrortxt),
        content:
            Text('${Languages.of(context)!.failedstartrecordingtxt} $message'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Languages.of(context)!.oktxt),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVoiceMessage(String audioPath) async {
    try {
      setState(() {
        isLoading = true;
      });
      final storageRef = FirebaseStorage.instance.ref();
      final audioRef = storageRef
          .child('voice_messages/${DateTime.now().millisecondsSinceEpoch}.m4a');

      await audioRef.putFile(
        File(audioPath),
        SettableMetadata(contentType: 'audio/m4a'),
      );

      // Get download URL
      String downloadUrl = await audioRef.getDownloadURL();
      setState(() {
        isLoading = false;
      });
      // Send message with audio URL
      await sendMessage(downloadUrl, '2'); // '2' indicates voice message type
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(Languages.of(context)!.errortxt),
            content: Text(Languages.of(context)!.failedvoicemessagetxt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(Languages.of(context)!.oktxt),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> sendMessage(String content, String type) async {
    // type = 0 for msg, 1 for img, 2 for audio
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref().child('message');
    if (channelId != "") {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('message');
      var channelKey =
          'chat--${firebaseId.replaceFirst("-", "")}-${widget.oppId}';
      var channel2Key =
          'chat-${widget.oppId}--${firebaseId.replaceFirst("-", "")}';
      DatabaseEvent channelSnapshot = await userRef.child(channelKey).once();
      DatabaseEvent channel2Snapshot = await userRef.child(channel2Key).once();
      if (channelSnapshot.snapshot.exists) {
        DatabaseReference chatRef =
            FirebaseDatabase.instance.ref().child('message').child(channelId);
        if (content.isNotEmpty) {
          int timestamp = DateTime.now().millisecondsSinceEpoch;
          Map<String, dynamic> message = {
            'content': content,
            'idFrom': firebaseId,
            'idTo': widget.oppId,
            'createdAt': timestamp,
            'isSeen': false,
            'type': type,
          };
          chatRef.child(timestamp.toString()).set(message);
          if (userMap['inChat'] == false) {
            await sendPushNotification(
                widget.frdId,
                type == "1"
                    ? "📷 Image"
                    : type == "2"
                        ? "🎤 Voice Message"
                        : content);
          }

          _messageController.clear();
        }
      } else if (channel2Snapshot.snapshot.exists) {
        DatabaseReference chatRef =
            FirebaseDatabase.instance.ref().child('message').child(channelId);
        if (content.isNotEmpty) {
          int timestamp = DateTime.now().millisecondsSinceEpoch;
          print("timestamp == $timestamp");
          Map<String, dynamic> message = {
            'content': content,
            'idFrom': firebaseId,
            'idTo': widget.oppId,
            'createdAt': timestamp,
            'isSeen': false,
            'type': type,
          };
          chatRef.child(timestamp.toString()).set(message);
          if (userMap['inChat'] == false) {
            await sendPushNotification(
                widget.frdId,
                type == "1"
                    ? "📷 Image"
                    : type == "2"
                        ? "🎤 Voice Message"
                        : content);
          }
          _messageController.clear();
          setState(() {});
        }
      }
    } else {
      var channelKey =
          'chat--${firebaseId.replaceFirst('-', "")}-${widget.oppId}';
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      DatabaseReference messagesRef =
          userRef.child(channelKey).child(timestamp.toString());
      await messagesRef.set({
        'content': content,
        'idFrom': firebaseId,
        'idTo': widget.oppId,
        'createdAt': timestamp,
        'isSeen': false,
        'type': type,
      });
      if (userMap['inChat'] == false) {
        await sendPushNotification(
            widget.frdId,
            type == "1"
                ? "📷 Image"
                : type == "2"
                    ? "🎤 Voice Message"
                    : content);
      }
      _messageController.clear();
      setState(() {});
      getIds();
    }
  }

  Future<void> sendImageMessage(XFile image) async {
    try {
      setState(() {
        isLoading = true;
      });
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      String downloadUrl = await imageRef.getDownloadURL();
      setState(() {
        isLoading = false;
      });
      await sendMessage(downloadUrl, '1');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imageFile = File(image.path);
      });
      await sendImageMessage(image);
    }
  }

  Future<void> sendVoiceMessage(String localPath) async {
    if (localPath.isEmpty) return;
    try {
      setState(() {
        isLoading = true;
      });
      final storageRef = FirebaseStorage.instance.ref();
      final audioRef = storageRef
          .child('voice_messages/${DateTime.now().millisecondsSinceEpoch}.m4a');
      await audioRef.putFile(
        File(localPath),
        SettableMetadata(contentType: 'audio/m4a'),
      );
      String downloadUrl = await audioRef.getDownloadURL();
      await sendMessage(downloadUrl, '2');
    } catch (e) {
      showToast(Languages.of(context)!.failedvoicemessagetxt);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                          "${type == "report" ? Languages.of(context)!.reportusermsgtxt : type == "unmatch" ? Languages.of(context)!.unmatchusermsgtxt : Languages.of(context)!.blockusermsgtxt} ${name.isNotEmpty ? name : Languages.of(context)!.thisusertxt}?",
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
                                  }
                                } else if (type == "unmatch") {
                                  unmatchUsersAPI(frdId);
                                  Navigator.pop(context);
                                } else {
                                  await userBlockAPI(frdId, "1");
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
                                        : type == "unmatch"
                                            ? Languages.of(context)!.unmatchtxt
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
              Navigator.pop(context);
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
              Navigator.pop(context);
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

  unmatchUsersAPI(String frdId) async {
    print("unmatchUsersAPI function call");
    setState(() {
      isReqLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<UserReportViewModel>(context, listen: false)
            .unmatchUsersAPI(userid, frdId);
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
                      .unmatchusersresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);

              Navigator.pop(context);
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            showToast(Provider.of<UserReportViewModel>(context, listen: false)
                .unmatchusersresponse
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

  sendPushNotification(String to_id, String message) async {
    print("sendPushNotification function call");
    setState(() {
      isReqLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<NotificationsViewModel>(context, listen: false)
            .sendNotification(userid, to_id, message);
        if (Provider.of<NotificationsViewModel>(context, listen: false)
                .isLoading ==
            false) {
          if (Provider.of<NotificationsViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isReqLoading = false;
              print("Success");
              CommonResponseModel model =
                  Provider.of<NotificationsViewModel>(context, listen: false)
                      .sendnotificationsresponse
                      .response as CommonResponseModel;
              // showToast(model.message!);
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            // showToast(Provider.of<NotificationsViewModel>(context, listen: false)
            //     .sendnotificationsresponse
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

class ChatBubble extends StatelessWidget {
  final String content;
  final String currentUserPhoto;
  final String opositeUserPhoto;
  final String type;
  final bool isSender;
  final Color color;
  final bool tail;
  final TextStyle textStyle;
  final int createdAt;

  const ChatBubble({
    super.key,
    required this.content,
    required this.type,
    required this.currentUserPhoto,
    required this.opositeUserPhoto,
    required this.isSender,
    required this.color,
    required this.tail,
    required this.textStyle,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            !isSender ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Displaying the content based on message type (text, image, or audio)
          type == "1"
              ? _buildImage(content, createdAt, isSender)
              : type == "2"
                  ? AudioMessagePlayer(
                      audioUrl: content,
                      sentTime: DateFormat('hh:mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(createdAt)),
                      isSender: isSender,
                      currentUserPhoto: currentUserPhoto,
                      opponentUserPhoto: opositeUserPhoto,
                    )
                  : Container(
                      padding: const EdgeInsets.all(10),
                      margin:
                          const EdgeInsets.only(top: 10, left: 10, right: 10),
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                            color: !isSender
                                ? AppColors.bordergclr
                                : Colors.transparent),
                        borderRadius: BorderRadius.only(
                          topLeft: !isSender
                              ? Radius.zero
                              : const Radius.circular(15),
                          topRight: isSender
                              ? Radius.zero
                              : const Radius.circular(15),
                          bottomLeft: const Radius.circular(15),
                          bottomRight: const Radius.circular(15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                content,
                                textAlign: TextAlign.left,
                                style: textStyle,
                              ),
                              Text(
                                DateFormat('h:mm a').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        createdAt)),
                                textAlign: TextAlign.end,
                                style: textStyle.copyWith(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl, int time, bool isSend) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Column(
        crossAxisAlignment:
            !isSender ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: !isSender ? Radius.zero : const Radius.circular(15),
              topRight: isSender ? Radius.zero : const Radius.circular(15),
              bottomLeft: const Radius.circular(15),
              bottomRight: const Radius.circular(15),
            ),
            child: Image.network(
              imageUrl,
              width: 200,
              height: 250,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  width: 200,
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.bordergclr,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.btngreyclr,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 200,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            DateFormat('h:mm a')
                .format(DateTime.fromMillisecondsSinceEpoch(time)),
            style: textStyle.copyWith(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final String currentUserPhoto;
  final String opponentUserPhoto;
  final String sentTime;
  final bool isSender;

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.sentTime,
    required this.currentUserPhoto,
    required this.opponentUserPhoto,
    required this.isSender,
  });

  @override
  _AudioMessagePlayerState createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer>
    with SingleTickerProviderStateMixin {
  late AudioPlayer audioPlayer;
  late AnimationController _animationController;
  bool isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero; // Uncommented this line

  final List<int> _waves = [
    24,
    40,
    28,
    45,
    32,
    48,
    36,
    42,
    30,
    46,
    34,
    44,
    28,
    42,
    32,
    44,
    30,
    45,
    35,
    40,
    28,
    43,
    31,
    48,
    35,
    40,
    29,
    43,
    32,
    45
  ];

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _setupAudioPlayer();
    _loadAudioDuration();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _setupAudioPlayer() {
    audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _duration = duration;
      });
    });
    audioPlayer.onPositionChanged.listen((Duration position) {
      if (isPlaying) {
        setState(() {
          _position = position;
        });
      }
    });
    audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
      });
      _stopAnimation();
    });
  }

  Future<void> _loadAudioDuration() async {
    try {
      await audioPlayer.setSourceUrl(widget.audioUrl);
    } catch (e) {
      print('Error loading audio duration: $e');
    }
  }

  Future<void> _playPause() async {
    try {
      if (isPlaying) {
        await audioPlayer.pause();
        _stopAnimation();
      } else {
        await audioPlayer.play(UrlSource(widget.audioUrl));
        _startAnimation();
      }

      setState(() {
        isPlaying = !isPlaying;
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void _startAnimation() {
    _animationController.repeat();
  }

  void _stopAnimation() {
    _animationController.stop();
    _animationController.value = 0;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size kSize = MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10, left: 10, bottom: 10, top: 10),
      child: Container(
        width: kSize.width / 1.3,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSender ? AppColors.bordergclr : AppColors.whiteclr,
          border: Border.all(
              color:
                  !widget.isSender ? AppColors.bordergclr : Colors.transparent),
          borderRadius: BorderRadius.only(
            topLeft: !widget.isSender ? Radius.zero : const Radius.circular(15),
            topRight: widget.isSender ? Radius.zero : const Radius.circular(15),
            bottomLeft: const Radius.circular(15),
            bottomRight: const Radius.circular(15),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _playPause,
              child: isPlaying
                  ? Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Color(0xff3E26B5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pause,
                        color: AppColors.whiteclr,
                      )

                      // Icon(
                      //   isPlaying ? Icons.pause : Icons.play_arrow,
                      //   color: Colors.white,
                      // ),
                      )
                  : ImageIcon(
                      AssetImage(AppAssets.playicon),
                      size: 35,
                      color: Color(0xff3E26B5),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 32,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            _waves.length,
                            (index) {
                              double heightFactor = isPlaying
                                  ? 0.3 +
                                      (0.7 *
                                              (1 +
                                                  sin((_animationController
                                                              .value *
                                                          2 *
                                                          3.14) +
                                                      index * 0.2))) /
                                          2
                                  : 0.5;

                              return Container(
                                width: 2,
                                height: _waves[index] * heightFactor,
                                decoration: BoxDecoration(
                                  color: isPlaying
                                      ? AppColors.signinclr1
                                      : AppColors.btngrey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPlaying
                            ? _formatDuration(_position)
                            : _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        widget.sentTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.btngrey,
                  backgroundImage: widget.isSender
                      ? (widget.currentUserPhoto.isEmpty
                          ? AssetImage(AppAssets.femaleUser) as ImageProvider
                          : NetworkImage(
                              "${API.baseUrl}/upload/${widget.currentUserPhoto}"))
                      : (widget.opponentUserPhoto.isEmpty
                          ? AssetImage(AppAssets.femaleUser) as ImageProvider
                          : NetworkImage(
                              "${API.baseUrl}/upload/${widget.opponentUserPhoto}")),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Image.asset(
                    AppAssets.micicon,
                    width: 18,
                    height: 18,
                    // color: AppColors.btngrey,
                  ),

                  // Icon(Icons.mic, size: 16, color: AppColors.signinclr1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
