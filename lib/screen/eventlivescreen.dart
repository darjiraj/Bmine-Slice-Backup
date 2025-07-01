import 'dart:async';
import 'dart:io';
import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/speed_dating_service.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/pandingcallresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/viewmodels/eventfeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/likefeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class EventLiveScreen extends StatefulWidget {
  final String eventId;
  final String id;
  const EventLiveScreen({
    super.key,
    required this.eventId,
    required this.id,
  });

  @override
  _EventLiveScreenState createState() => _EventLiveScreenState();
}

class _EventLiveScreenState extends State<EventLiveScreen>
    with WidgetsBindingObserver {
  PendingCallResponseModel pendingCallResponseModel =
      PendingCallResponseModel();
  bool isLoading = true;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final SpeedDatingService _signalingService = SpeedDatingService();
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isCallInitiator = false;
  bool _isCallCompleted = false;
  bool isLikeLoading = false;
  bool _isRemoteStreamAvailable = false;
  String userid = "";
  int remainingSeconds = 0;
  Timer? timer;
  static const MethodChannel _channel = MethodChannel('com.example.audio');
  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();
  int selectedPlan = 0;
  String selectedGiftType = "";

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
  }

  getPendingCallAPI(String eventId, String id) async {
    getuserid();
    final isConnected = await isInternetAvailable();
    if (isConnected) {
      try {
        await Provider.of<EventFeedViewModel>(context, listen: false)
            .getPendingCallAPI(eventId, userid);
        final viewModel =
            Provider.of<EventFeedViewModel>(context, listen: false);

        if (!viewModel.isLoading && viewModel.isSuccess) {
          setState(() {
            pendingCallResponseModel = viewModel.pendingcallsresponse.response
                as PendingCallResponseModel;
          });
          if (pendingCallResponseModel.activeCall!.fromId.toString() ==
              userid) {
            Future.delayed(Duration(seconds: 1), () async {
              await _initializeCall();
            });
          } else {
            Future.delayed(Duration(seconds: 3), () async {
              await _initializeCall();
            });
          }
        }
      } catch (e) {
        print('Error during API calls: $e');
        showToast(Languages.of(context)!.anerroroccurredtxt);
      }
    } else {
      setState(() {
        isLoading = false;
      });
      showToast(Languages.of(context)!.nointernettxt);
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    WakelockPlus.enable();
    Future.delayed(
      Duration.zero,
      () async {
        await getPurchaseDetailsAPI();
        await updateCallStatusAPI(widget.id, 'active');
      },
    );
  }

  Future<void> _initializeCall() async {
    print("_initializeCall function called");
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      setState(() {});
      await _getUserMedia();
      await _createPeerConnection();
      await _setupSignaling();
      _checkVideoTracks();
      _startConnectionMonitoring();
    } catch (e) {
      print('Error initializing call: $e');
    }
  }

  void _startConnectionMonitoring() {
    // Monitor local camera status
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (_localStream != null) {
        final videoTracks = _localStream!.getVideoTracks();
        if (videoTracks.isEmpty || !videoTracks[0].enabled) {
          print("Local camera issue detected, attempting to recover");
          _recoverFromCameraDisconnect();
        }
      }
    });

    // Monitor connection status
    if (_peerConnection != null) {
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        print("Connection state changed to: $state");
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          print("Connection failed or disconnected, attempting reconnection");
          _attemptReconnection();
        }
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        print("ICE connection state changed to: $state");
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
            state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          print(
              "ICE connection failed or disconnected, attempting reconnection");
          _attemptReconnection();
        }
      };
    }
  }

  static Future<void> enableSpeaker() async {
    try {
      await _channel.invokeMethod('enableSpeaker');
    } on PlatformException catch (e) {
      print("Failed to enable speaker: ${e.message}");
    }
  }

  Future<void> _getUserMedia() async {
    final mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': {
        'mandatory': {
          'minWidth': 640,
          'minHeight': 480,
          'minFrameRate': 24,
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

  void _checkVideoTracks() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (_remoteRenderer.srcObject != null) {
        final videoTracks = _remoteRenderer.srcObject!.getVideoTracks();
        print("Remote video tracks: ${videoTracks.length}");
        if (videoTracks.isNotEmpty) {
          for (var track in videoTracks) {
            if (!track.enabled) {
              print("Enabling disabled track: ${track.id}");
              track.enabled = true;
            }
          }
          setState(() {
            _isRemoteStreamAvailable = true;
          });
        } else {
          print("No video tracks found in remote stream");
        }
      } else {
        print("No srcObject attached to remote renderer");
      }
    });
  }

  Future<void> _recoverFromCameraDisconnect() async {
    if (_localStream != null) {
      try {
        print("Attempting to recover from camera disconnect...");
        _localStream!.getTracks().forEach((track) => track.stop());
        await _getUserMedia();
        if (_peerConnection != null) {
          _localStream!.getTracks().forEach((track) {
            _peerConnection!.addTrack(track, _localStream!);
          });
        }
        setState(() {});
        print("Camera recovery attempt completed");
      } catch (e) {
        print("Camera recovery failed: $e");
      }
    }
  }

  Future<void> _attemptReconnection() async {
    print("Attempting reconnection...");
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
    await Future.delayed(Duration(seconds: 1));
    await _createPeerConnection();
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }
    if (_isCallInitiator) {
      await _createOffer();
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
        {
          'urls': 'turn:openrelay.metered.ca:80',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
        {
          'urls': 'turn:openrelay.metered.ca:443',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
      ],
      'sdpSemantics': 'unified-plan',
      'iceTransportPolicy': 'all',
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
            channels: 2,
            sdpFmtpLine: 'minptime=10;useinbandfec=1',
          ),
        ]);
      }
    }
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _signalingService.addIceCandidate(
          pendingCallResponseModel.activeCall!.callId ?? "", candidate);
    };
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video') {
        setState(() {
          event.track.enabled = true;
          _remoteRenderer.srcObject = event.streams[0];
          _isRemoteStreamAvailable = true;
          print(
              "Remote video explicitly set, stream ID: ${event.streams[0].id}");
        });
      }
      setState(() {});
    };
    _peerConnection!.onRemoveTrack =
        (MediaStream stream, MediaStreamTrack track) {
      if (track.kind == 'video') {
        print("Remote video track removed");
        setState(() {
          _remoteRenderer.srcObject = null;
          _isRemoteStreamAvailable = false;
        });
      }
    };

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onRemoveStream = (MediaStream stream) {
      print("Remote stream removed");
      setState(() {
        _remoteRenderer.srcObject = null;
        _isRemoteStreamAvailable = false;
      });
    };
    await _setPeerConnectionBitrates();
  }

  Future<void> _setPeerConnectionBitrates() async {
    final senders = await _peerConnection!.getSenders();
    for (var sender in senders) {
      if (sender.track?.kind == 'video') {
        final parameters = sender.parameters;
        parameters.encodings ??= [
          RTCRtpEncoding(
            maxBitrate: 2500000,
            minBitrate: 1000000,
            maxFramerate: 30,
            scaleResolutionDownBy: 1.0,
            active: true,
          ),
        ];
        await sender.setParameters(parameters);
      } else if (sender.track?.kind == 'audio') {
        final parameters = sender.parameters;
        parameters.encodings ??= [
          RTCRtpEncoding(
            maxBitrate: 128000,
            minBitrate: 64000,
            active: true,
          ),
        ];
        await sender.setParameters(parameters);
      }
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> iceCandidate) async {
    try {
      final String? candidate = iceCandidate['candidate'];
      final String? sdpMid = iceCandidate['sdpMid'];
      final int? sdpMLineIndex = iceCandidate['sdpMLineIndex'];
      if (candidate == null) {
        print('Warning: Received ICE candidate with null candidate string');
        return;
      }
      RTCIceCandidate rtcCandidate = RTCIceCandidate(
        candidate,
        sdpMid,
        sdpMLineIndex ?? 0,
      );
      if (_peerConnection == null) {
        print(
            'Warning: PeerConnection is null when trying to add ICE candidate');
        return;
      }
      await _peerConnection!.addCandidate(rtcCandidate);
    } catch (e) {
      print('Error adding ICE candidate: $e');
      print('ICE candidate data: $iceCandidate');
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
    Future.delayed(Duration(seconds: 1));
    final callDoc = await _signalingService
        .getCallDocument(pendingCallResponseModel.activeCall!.callId ?? "");
    Future.delayed(Duration(seconds: 2));
    final data = callDoc.data() as Map<String, dynamic>?;
    if (data == null || data['offer'] == null) {
      _isCallInitiator = true;
      await _createOffer();
    } else {
      await _handleOffer(data['offer']);
    }
    _signalingService
        .getCallStream(pendingCallResponseModel.activeCall!.callId ?? "")
        .listen(_handleSignalingMessage);

    startTimer();
    _signalingService
        .getIceCandidates(pendingCallResponseModel.activeCall!.callId ?? "")
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
    print("_createOffer ==== $offer");
    await _peerConnection!.setLocalDescription(offer);
    await _signalingService.createOffer(
        pendingCallResponseModel.activeCall!.callId ?? "", offer);
  }

  Future<void> _handleOffer(Map<String, dynamic> offer) async {
    print("_handleOffer ==== $offer");

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );
    await _createAnswer();
  }

  Future<void> _createAnswer() async {
    final answer = await _peerConnection!.createAnswer();
    print("_createAnswer ==== $answer");

    await _peerConnection!.setLocalDescription(answer);
    await _signalingService.createAnswer(
        pendingCallResponseModel.activeCall!.callId ?? "", answer);
  }

  Future<void> _handleAnswer(Map<String, dynamic> answer) async {
    print("_handleAnswer ==== $answer");

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

  void _endCall() async {
    print('Ending call...');
    Navigator.pop(context);
    try {
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) => track.stop());
        await _localStream!.dispose();
      }
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }
      setState(() {
        _isCallInitiator = false;
        _isAudioMuted = false;
        _isVideoMuted = false;
        _localRenderer = RTCVideoRenderer();
        _remoteRenderer = RTCVideoRenderer();
      });
      _peerConnection?.close();
      Navigator.of(context).pop();
    } catch (e) {
      print("Error when end call ======== $e");
    }
  }

  Future<void> _endCurrentCall() async {
    try {
      if (pendingCallResponseModel.activeCall != null) {
        await _signalingService
            .endCall(pendingCallResponseModel.activeCall!.callId ?? "");
        print("Call ended successfully.");
      }
    } catch (e) {
      print("Error ending call: $e");
    }
  }

  @override
  void dispose() {
    print("on dispose");
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();

    _endCurrentCall();
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    if (_localStream != null) {
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
    }
    if (_peerConnection != null) {
      _peerConnection!.close();
      _peerConnection = null;
    }

    _isCallInitiator = false;
    _isAudioMuted = false;
    _isVideoMuted = false;
    _localStream = null;
    _peerConnection = null;
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();

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
        backgroundColor: AppColors.whiteclr,
        body: SafeArea(
          child: isLoading
              ? Container(
                  height: MediaQuery.sizeOf(context).height,
                  width: MediaQuery.sizeOf(context).width,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          child: Image.asset(
                            AppAssets.femaleUser,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.bminetxtclr,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              Languages.of(context)!.waitingforcalltxt,
                              style: Appstyle.quicksand16w600
                                  .copyWith(color: AppColors.bminetxtclr),
                            )
                          ],
                        ),
                      )
                    ],
                  ))
              : Stack(
                  children: [
                    Positioned.fill(
                      child: _remoteRenderer.srcObject != null
                          ? RTCVideoView(
                              _remoteRenderer,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                              mirror: false,
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
                              pendingCallResponseModel.activeCall == null
                                  ? Container()
                                  : Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundImage: pendingCallResponseModel
                                                          .activeCall !=
                                                      null
                                                  ? pendingCallResponseModel
                                                              .activeCall!
                                                              .images !=
                                                          null
                                                      ? NetworkImage(
                                                          "${API.baseUrl}/upload/${pendingCallResponseModel.activeCall!.images}")
                                                      : AssetImage(AppAssets
                                                              .femaleUser)
                                                          as ImageProvider
                                                  : AssetImage(
                                                          AppAssets.femaleUser)
                                                      as ImageProvider,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "${pendingCallResponseModel.activeCall!.firstName} "
                                                "${pendingCallResponseModel.activeCall!.lastName != null && pendingCallResponseModel.activeCall!.lastName!.isNotEmpty ? pendingCallResponseModel.activeCall!.lastName![0] : ''}"
                                                "${pendingCallResponseModel.activeCall!.dob != null ? ", ${calculateAge(pendingCallResponseModel.activeCall!.dob!)}" : ""}",
                                                style: Appstyle.quicksand16w600,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              SizedBox(
                                width: 10,
                              ),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Text(Languages.of(context)!.livetxt,
                                        style: Appstyle.quicksand13w500),
                                  ),
                                  const SizedBox(width: 4),
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
                                        width: _isAudioMuted ? 23 : 25,
                                        height: _isAudioMuted ? 23 : 25,
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
                                        borderRadius:
                                            BorderRadius.circular(25)),
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
                          pendingCallResponseModel.pendingCalls == null
                              ? Container()
                              : Container(
                                  color: Colors.transparent,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      pendingCallResponseModel
                                              .pendingCalls!.isEmpty
                                          ? Container()
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 12, right: 12),
                                              child: Text(
                                                "${Languages.of(context)!.nexttxt} (${pendingCallResponseModel.pendingCalls!.length})",
                                                style: Appstyle.quicksand13w600
                                                    .copyWith(
                                                        color:
                                                            AppColors.whiteclr),
                                              ),
                                            ),
                                      const SizedBox(height: 4),
                                      pendingCallResponseModel
                                              .pendingCalls!.isEmpty
                                          ? Container()
                                          : Container(
                                              margin: const EdgeInsets.only(
                                                  left: 12, right: 12),
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount:
                                                    pendingCallResponseModel
                                                        .pendingCalls!.length,
                                                itemBuilder: (context, index) {
                                                  return SizedBox(
                                                    height: 50,
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 20,
                                                          backgroundImage: pendingCallResponseModel
                                                                      .pendingCalls![
                                                                          index]
                                                                      .images !=
                                                                  null
                                                              ? NetworkImage(
                                                                  "${API.baseUrl}/upload/${pendingCallResponseModel.pendingCalls![index].images}")
                                                              : AssetImage(AppAssets
                                                                      .femaleUser)
                                                                  as ImageProvider,
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Text(
                                                            "${pendingCallResponseModel.pendingCalls![index].firstName} "
                                                            "${pendingCallResponseModel.pendingCalls![index].lastName != null && pendingCallResponseModel.pendingCalls![index].lastName!.isNotEmpty ? pendingCallResponseModel.pendingCalls![index].lastName![0] : ''}"
                                                            "${pendingCallResponseModel.pendingCalls![index].dob != null ? ", ${calculateAge(pendingCallResponseModel.pendingCalls![index].dob!)}" : ""}",
                                                            style: Appstyle
                                                                .quicksand13w500),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      String userId = "";
                                      if (userid ==
                                          pendingCallResponseModel
                                              .activeCall!.fromId
                                              .toString()) {
                                        userId = pendingCallResponseModel
                                            .activeCall!.toId
                                            .toString();
                                      } else if (userid ==
                                          pendingCallResponseModel
                                              .activeCall!.toId
                                              .toString()) {
                                        userId = pendingCallResponseModel
                                            .activeCall!.fromId
                                            .toString();
                                      }
                                      userLikeAPI(userId, "2");
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
                                        String userId = "";
                                        if (userid ==
                                            pendingCallResponseModel
                                                .activeCall!.fromId
                                                .toString()) {
                                          userId = pendingCallResponseModel
                                              .activeCall!.toId
                                              .toString();
                                        } else if (userid ==
                                            pendingCallResponseModel
                                                .activeCall!.toId
                                                .toString()) {
                                          userId = pendingCallResponseModel
                                              .activeCall!.fromId
                                              .toString();
                                        }
                                        if (purchaseDetailsResponseModel
                                                    .userGift ==
                                                null ||
                                            purchaseDetailsResponseModel
                                                    .userGift!.totalCount ==
                                                null ||
                                            purchaseDetailsResponseModel
                                                    .userGift!.totalCount! <=
                                                0) {
                                          showToast(Languages.of(context)!
                                              .nogiftmsgtxt);
                                        } else {
                                          _showGiftSelectionDialog(
                                              context, 0, userId);
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
                                    onTap: () async {
                                      String userId = "";
                                      if (userid ==
                                          pendingCallResponseModel
                                              .activeCall!.fromId
                                              .toString()) {
                                        userId = pendingCallResponseModel
                                            .activeCall!.toId
                                            .toString();
                                      } else if (userid ==
                                          pendingCallResponseModel
                                              .activeCall!.toId
                                              .toString()) {
                                        userId = pendingCallResponseModel
                                            .activeCall!.fromId
                                            .toString();
                                      }
                                      await userLikeAPI(userId, "1");
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

  updateCallStatusAPI(String id, String status) async {
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<EventFeedViewModel>(context, listen: false)
            .updateCallStatusAPI(id, status);
        if (Provider.of<EventFeedViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<EventFeedViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              ForgotPasswordResponseModel model =
                  Provider.of<EventFeedViewModel>(context, listen: false)
                      .updateCallStatusresponse
                      .response as ForgotPasswordResponseModel;
            });
            if (status == 'active') {
              await getPendingCallAPI(widget.eventId, id);
            }
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

  Future<void> startTimer() async {
    setState(() {
      isLoading = true;
    });
    try {
      if (Platform.isIOS) {
        enableSpeaker();
      }

      final serverTimestamp = await _signalingService.getServerTime();
      DateTime currentServerTime = DateTime.parse(serverTimestamp);
      String endTime = pendingCallResponseModel.activeCall!.endTime!;
      String fullEndDateTime =
          "${currentServerTime.toIso8601String().split('T')[0]}T$endTime";
      DateTime endDateTime = DateTime.parse(fullEndDateTime);
      Duration remainingDuration = endDateTime.difference(currentServerTime);
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

  void _startCountdown() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    _isCallCompleted = false;
    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        await stopCall();
      }
    });
  }

  Future<void> stopCall() async {
    if (_localStream != null) {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
    }
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
    setState(() {
      _isCallInitiator = false;
      _isAudioMuted = false;
      _isVideoMuted = false;
      _localStream = null;
      _peerConnection = null;
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
    });
    if (!_isCallCompleted) {
      _isCallCompleted = true;
      await updateCallStatusAPI(
          pendingCallResponseModel.activeCall!.id.toString(), "complete");
      if (pendingCallResponseModel.pendingCalls!.isEmpty) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          isLoading = true;
        });
        await updateCallStatusAPI(
            pendingCallResponseModel.pendingCalls![0].id.toString(), 'active');
      }
      _isCallCompleted = false;
    }
  }

  String formatElapsedTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

  void _showGiftSelectionDialog(BuildContext context, int index, String toId) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents accidental dismissal
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
                        await sendGifttoFriendApi(toId, "1", selectedGiftType);
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
}
