import 'dart:async';
import 'dart:io';
import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/signaling_service.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/meetingrequestresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/viewmodels/likefeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/meetingviewmodel.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveStreamPage extends StatefulWidget {
  final String callId;
  Meeting? meetingModel;

  LiveStreamPage({super.key, required this.callId, this.meetingModel});

  @override
  _LiveStreamPageState createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  bool isLoading = false;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final SignalingService _signalingService = SignalingService();
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isCallInitiator = false;
  bool isLikeLoading = false;
  String userid = "";
  int remainingSeconds = 0;
  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();
  int selectedPlan = 0;
  String selectedGiftType = "";
  Timer? timer;
  static const MethodChannel _channel = MethodChannel('com.example.audio');

  @override
  void initState() {
    super.initState();
    getPurchaseDetailsAPI();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      await _getUserMedia();
      await _createPeerConnection();
      await _setupSignaling();
    } catch (e) {
      print('Error initializing call: $e');
    }
  }

  Future<void> _getUserMedia() async {
    final mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'channelCount': 2,
        'sampleRate': 48000,
        'sampleSize': 16,
      },
      'video': {
        'mandatory': {
          'minWidth': 1280, // HD width
          'minHeight': 720, // HD height
          'minFrameRate': 30,
        },
        'facingMode': 'user',
        'optional': [],
      },
    };
    try {
      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      _localStream?.getVideoTracks().forEach((track) {
        track.applyConstraints({
          'width': 1280,
          'height': 720,
          'frameRate': 30,
        });
      });
      setState(() {});
    } catch (e) {
      print('Error getting user media: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
          ]
        },
      ],
      'sdpSemantics': 'unified-plan',
      'iceTransportPolicy': 'all',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };
    _peerConnection = await createPeerConnection(configuration);
    final transceivers = await _peerConnection!.getTransceivers();
    for (var transceiver in transceivers) {
      if (transceiver.sender.track?.kind == 'video') {
        transceiver.setCodecPreferences([
          RTCRtpCodecCapability(
            mimeType: 'video/H264',
            clockRate: 90000,
            sdpFmtpLine: 'profile-level-id=42e01f;packetization-mode=1',
          ),
          RTCRtpCodecCapability(
            mimeType: 'video/VP8',
            clockRate: 90000,
          ),
        ]);
      } else if (transceiver.sender.track?.kind == 'audio') {
        transceiver.setCodecPreferences([
          RTCRtpCodecCapability(
            mimeType: 'audio/opus',
            clockRate: 48000,
            channels: 2, // Added channels parameter for audio
            sdpFmtpLine: 'minptime=10;useinbandfec=1',
          ),
        ]);
      }
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _signalingService.addIceCandidate(widget.callId, candidate);
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video') {
        _remoteRenderer.srcObject = event.streams[0];
      }
      setState(() {});
    };

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
    await _setPeerConnectionBitrates();
  }

  Future<void> _setPeerConnectionBitrates() async {
    final senders = await _peerConnection!.getSenders();
    for (var sender in senders) {
      if (sender.track?.kind == 'video') {
        final parameters =
            sender.parameters; // Changed from getParameters() to parameters
        // Add null check
        parameters.encodings ??= [
          RTCRtpEncoding(
            maxBitrate: 2500000, // 2.5 Mbps for HD
            minBitrate: 1000000, // 1 Mbps minimum
            maxFramerate: 30,
            scaleResolutionDownBy: 1.0,
            active: true,
          ),
        ];
        await sender.setParameters(parameters);
      } else if (sender.track?.kind == 'audio') {
        final parameters =
            sender.parameters; // Changed from getParameters() to parameters
        // Add null check
        parameters.encodings ??= [
          RTCRtpEncoding(
            maxBitrate: 128000, // 128 kbps for high-quality audio
            minBitrate: 64000, // 64 kbps minimum
            active: true,
          ),
        ];
        await sender.setParameters(parameters);
      }
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> answer) async {
    try {
      RTCSessionDescription remoteDescription = RTCSessionDescription(
        answer['sdp'],
        answer['type'],
      );
      await _peerConnection!.setRemoteDescription(remoteDescription);
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> iceCandidate) async {
    try {
      RTCIceCandidate candidate = RTCIceCandidate(
        iceCandidate['candidate'],
        iceCandidate['sdpMid'],
        iceCandidate['sdpMLineIndex'],
      );

      // Add the ICE candidate to the peer connection
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      print('Error adding ICE candidate: $e');
    }
  }

  void _handleSignalingMessage(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>?;
    if (data == null) return;

    if (data['answer'] != null && _isCallInitiator) {
      _handleAnswer(data['answer']);
    }

    if (data['candidate'] != null) {
      _handleIceCandidate(data['candidate']);
    }
  }

  Future<void> _setupSignaling() async {
    final callDoc = await _signalingService.getCallDocument(widget.callId);
    final data = callDoc.data() as Map<String, dynamic>?;

    if (data == null || data['offer'] == null) {
      _isCallInitiator = true;
      await _createOffer();
    } else {
      await _handleOffer(data['offer']);
    }

    _signalingService
        .getCallStream(widget.callId)
        .listen(_handleSignalingMessage);
    startTimer();

    _signalingService
        .getIceCandidates(widget.callId)
        .listen(_handleIceCandidateStream);
  }

  Future<void> _handleIceCandidateStream(
      QuerySnapshot iceCandidatesSnapshot) async {
    for (var doc in iceCandidatesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null && data['candidate'] != null) {
        await _handleIceCandidate(data['candidate']);
      }
    }
  }

  Future<void> _createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    await _signalingService.createOffer(widget.callId, offer);
  }

  Future<void> _handleOffer(Map<String, dynamic> offer) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );
    await _createAnswer();
  }

  Future<void> _createAnswer() async {
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    await _signalingService.createAnswer(widget.callId, answer);
  }

  void _toggleAudio() {
    setState(() {
      _isAudioMuted = !_isAudioMuted;
      _localStream?.getAudioTracks().forEach((track) {
        track.enabled = !_isAudioMuted;
      });
    });
  }

  void _toggleVideo() {
    setState(() {
      _isVideoMuted = !_isVideoMuted;
      _localStream?.getVideoTracks().forEach((track) {
        track.enabled = !_isVideoMuted;
      });
    });
  }

  void _swapCamera() {
    _localStream?.getVideoTracks().forEach((track) {
      track.switchCamera();
    });
  }

  static Future<void> enableSpeaker() async {
    try {
      await _channel.invokeMethod('enableSpeaker');
    } on PlatformException catch (e) {
      print("Failed to enable speaker: ${e.message}");
    }
  }

  Future<void> startTimer() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (Platform.isIOS) {
        enableSpeaker();
      }
      final serverTimestamp =
          await _signalingService.getServerTime(widget.callId);
      DateTime currentServerTime = DateTime.parse(serverTimestamp);
      final callRef =
          FirebaseFirestore.instance.collection('calls').doc(widget.callId);
      final callSnapshot = await callRef.get();
      DateTime callStartTime;
      if (callSnapshot.exists &&
          callSnapshot.data()!.containsKey('startTime')) {
        callStartTime = (callSnapshot['startTime'] as Timestamp).toDate();
      } else {
        await callRef
            .set({'startTime': currentServerTime}, SetOptions(merge: true));
        callStartTime = currentServerTime;
      }
      DateTime expectedEndTime = callStartTime.add(Duration(minutes: 10));
      Duration remainingDuration =
          expectedEndTime.difference(currentServerTime);
      remainingSeconds = remainingDuration.inSeconds;
      if (remainingSeconds < 0) {
        remainingSeconds = 0;
      }
      _startCountdown();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatElapsedTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startCountdown() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        _endCall();
      }
    });
  }

  void _endCall() async {
    _localStream?.dispose();
    _peerConnection?.close();
    timer?.cancel();
    if (widget.meetingModel != null) {
      await rejectMeetingRequestAPI(widget.meetingModel!.id.toString());
    }
    Navigator.of(context).pop();
  }

  void _showEndCallConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.whiteclr,
          surfaceTintColor: AppColors.whiteclr,
          title: Text(
            Languages.of(context)!.endvirtualmeetingcallalerttitletxt,
            style: Appstyle.quicksand20w600.copyWith(color: AppColors.blackclr),
          ),
          content: Text(
            Languages.of(context)!.endvirtualmeetingcallalertmsgtxt,
            style: Appstyle.quicksand18w500.copyWith(color: AppColors.blackclr),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                Languages.of(context)!.canceltxt,
                style: Appstyle.quicksand19w500
                    .copyWith(color: AppColors.blackclr),
              ),
            ),
            TextButton(
              onPressed: () async {
                _endCall();
                Navigator.pop(context);
              },
              child: Text(
                Languages.of(context)!.endvirtualmeetingcallalerttitletxt,
                style: Appstyle.quicksand19w500.copyWith(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showGiftSelectionDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setAState) {
          return Dialog(
            backgroundColor: AppColors.whiteclr,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            insetPadding: EdgeInsets.symmetric(horizontal: 7),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10),
                  Text(
                    Languages.of(context)!.selectgiftstxt,
                    style: Appstyle.quicksand20w600
                        .copyWith(color: AppColors.blackclr),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      _buildSelectGiftIcon(AppAssets.bouquet, 'bouquet', index,
                          context, setAState),
                      _buildSelectGiftIcon(AppAssets.chocolateBox,
                          'chocolateBox', index, context, setAState),
                      _buildSelectGiftIcon(
                          AppAssets.candy, 'candy', index, context, setAState),
                      _buildSelectGiftIcon(AppAssets.teddyBear, 'teddyBear',
                          index, context, setAState),
                      _buildSelectGiftIcon(AppAssets.redWineGlass,
                          'redWineGlass', index, context, setAState),
                    ],
                  ),
                  SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      if (selectedGiftType.isEmpty) {
                        showToast(Languages.of(context)!.selectgiftmsgtxt);
                      } else {
                        await sendGifttoFriendApi(
                            widget.meetingModel!.userId.toString(),
                            "1",
                            selectedGiftType);
                      }
                    },
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 1, color: AppColors.whiteclr),
                          color: AppColors.bminetxtclr,
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Center(
                          child: Text(Languages.of(context)!.sendgifttitletxt,
                              style: Appstyle.quicksand19w500
                                  .copyWith(color: AppColors.whiteclr)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                          border: Border.all(
                              width: 1, color: AppColors.bminetxtclr),
                          color: AppColors.whiteclr,
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Center(
                          child: Text(Languages.of(context)!.canceltxt,
                              style: Appstyle.quicksand19w500
                                  .copyWith(color: AppColors.bminetxtclr)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
  }

  getPurchaseDetailsAPI() async {
    setState(() {
      isLikeLoading = true;
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
              isLikeLoading = false;
              purchaseDetailsResponseModel =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .purchasedetailsresponse
                      .response as PurchaseDetailsResponseModel;
            });
          } else {
            setState(() {
              isLikeLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .purchasedetailsresponse
                .msg
                .toString());
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

  sendGifttoFriendApi(String to_id, String quantity, String gift_type) async {
    setState(() {
      isLikeLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<PurchaseViewModel>(context, listen: false)
            .sendGiftsApi(userid, to_id, quantity, gift_type);
        if (Provider.of<PurchaseViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<PurchaseViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLikeLoading = false;
              ForgotPasswordResponseModel model =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .sendgiftsresponse
                      .response as ForgotPasswordResponseModel;
              selectedGiftType = "";
              showToast(model.message!);
            });
            await getPurchaseDetailsAPI();
            Navigator.pop(context);
          } else {
            setState(() {
              isLikeLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .sendgiftsresponse
                .msg
                .toString());
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

  Widget _buildSelectGiftIcon(
    String iconPath,
    String giftKey,
    int planIndex,
    BuildContext context,
    StateSetter setAState,
  ) {
    bool isSelected = selectedPlan == planIndex && selectedGiftType == giftKey;

    return GestureDetector(
      onTap: () {
        setAState(() {
          if (selectedPlan == planIndex) {
            selectedGiftType = giftKey;
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.blueclr, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Image.asset(
              iconPath,
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppColors.blackclr,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _remoteRenderer.srcObject != null &&
                        _remoteRenderer.srcObject!.getVideoTracks().isNotEmpty
                    ? RTCVideoView(
                        _remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : SizedBox(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Image.asset(
                          AppAssets.femaleUser,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              Positioned(
                right: 10,
                top: 50,
                child: Container(
                  width: 90,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _isVideoMuted
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          child: Image.asset(
                            AppAssets.femaleUser,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _localRenderer.srcObject != null &&
                              _localRenderer.srcObject!
                                  .getVideoTracks()
                                  .isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: RTCVideoView(
                                _localRenderer,
                                mirror: true,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                              ),
                            )
                          : SizedBox(
                              height: MediaQuery.of(context).size.height,
                              width: MediaQuery.of(context).size.width,
                              child: Image.asset(
                                AppAssets.femaleUser,
                                fit: BoxFit.cover,
                              ),
                            ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.4),
                    ])),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // const SizedBox(
                        //   width: 10,
                        // ),

                        widget.meetingModel != null
                            ? Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: widget.meetingModel !=
                                              null
                                          ? NetworkImage(
                                              "${API.baseUrl}/upload/${widget.meetingModel!.images}")
                                          : AssetImage(AppAssets.femaleUser)
                                              as ImageProvider,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                        "${widget.meetingModel!.firstName} "
                                        "${widget.meetingModel!.lastName != null && widget.meetingModel!.lastName!.isNotEmpty ? widget.meetingModel!.lastName![0] : ''}"
                                        "${widget.meetingModel!.dob != null ? ", ${calculateAge(widget.meetingModel!.dob!)}" : ""}",
                                        style: Appstyle.quicksand16w600),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          AssetImage(AppAssets.femaleUser),
                                    ),
                                    const SizedBox(width: 10),
                                    Text("", style: Appstyle.quicksand13w500),
                                  ],
                                ),
                              ),

                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //       horizontal: 15, vertical: 6),
                        //   decoration: BoxDecoration(
                        //     color: AppColors.livetimerbgClr,
                        //     borderRadius: BorderRadius.circular(10),
                        //   ),
                        //   child: Row(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       Image.asset(
                        //         AppAssets.clockicon,
                        //         height: 20,
                        //       ),
                        //       const SizedBox(width: 5),
                        //       Text(
                        //           "${AppText.timelefttxt} \n${_formatElapsedTime(_secondsElapsed)}s",
                        //           style: Appstyle.quicksand13w500),
                        //     ],
                        //   ),
                        // ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.livetimerbgClr,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                AppAssets.clockicon,
                                height: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                  "${Languages.of(context)!.timelefttxt} \n${formatElapsedTime(remainingSeconds)}s",
                                  style: Appstyle.quicksand13w500),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        Row(
                          children: [
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 10, vertical: 4),
                            //   decoration: BoxDecoration(
                            //       color: Colors.green,
                            //       borderRadius: BorderRadius.circular(5)),
                            //   child: Text(AppText.livetxt,
                            //       style: Appstyle.quicksand13w500),
                            // ),
                            // const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                _showEndCallConfirmation();
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          InkWell(
                            onTap: () {
                              _toggleAudio();
                            },
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Image.asset(
                                  !_isAudioMuted
                                      ? AppAssets.mic
                                      : AppAssets.mic_off,
                                  width: _isAudioMuted ? 30 : 25,
                                  height: _isAudioMuted ? 30 : 25,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          InkWell(
                            onTap: () {
                              _toggleVideo();
                            },
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Image.asset(
                                  !_isVideoMuted
                                      ? AppAssets.video_camera
                                      : AppAssets.no_camera,
                                  width: !_isVideoMuted ? 30 : 25,
                                  height: !_isVideoMuted ? 30 : 25,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          InkWell(
                            onTap: () {
                              _swapCamera();
                            },
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(25)),
                              child: Center(
                                child: Image.asset(
                                  AppAssets.swap_camera,
                                  width: 25,
                                  height: 25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                userLikeAPI(
                                    widget.meetingModel!.userId.toString(),
                                    "2");
                              },
                              child: Container(
                                alignment: Alignment.topLeft,
                                child: Image.asset(
                                  AppAssets.dislikeicon,
                                  height: 80,
                                  width: 80,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.topLeft,
                              child: InkWell(
                                onTap: () {
                                  if (purchaseDetailsResponseModel.userGift ==
                                          null ||
                                      purchaseDetailsResponseModel
                                              .userGift!.totalCount ==
                                          null ||
                                      purchaseDetailsResponseModel
                                              .userGift!.totalCount! <=
                                          0) {
                                    showToast(
                                        Languages.of(context)!.nogiftmsgtxt);
                                  } else {
                                    _showGiftSelectionDialog(context, 0);
                                  }
                                },
                                child: Image.asset(
                                  AppAssets.gifticon,
                                  height: 80,
                                  width: 80,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                _showEndCallConfirmation();
                              },
                              child: Container(
                                alignment: Alignment.topLeft,
                                child: Image.asset(
                                  AppAssets.endcallicon,
                                  height: 80,
                                  width: 80,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                userLikeAPI(
                                    widget.meetingModel!.userId.toString(),
                                    "1");
                              },
                              child: Container(
                                alignment: Alignment.topLeft,
                                child: Image.asset(
                                  AppAssets.likegreenicon,
                                  height: 80,
                                  width: 80,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
              isLikeLoading
                  ? Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.transparent,
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }

  rejectMeetingRequestAPI(String reqId) async {
    setState(() {
      isLoading = true;
    });
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<MeetingViewModel>(context, listen: false)
            .rejectMeetingRequest(reqId);
        if (Provider.of<MeetingViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<MeetingViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              ForgotPasswordResponseModel model =
                  Provider.of<MeetingViewModel>(context, listen: false)
                      .acceptmeetingtrequestresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
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

  userLikeAPI(
    String id_to,
    String is_like,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      isLikeLoading = true;
      userid = prefs.getString('userid') ?? "";
    });

    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<LikeFeedViewModel>(context, listen: false)
            .userLikeAPI(userid, id_to, is_like);
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
}
