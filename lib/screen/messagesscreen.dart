import 'dart:async';
import 'dart:ui';

import 'package:bmine_slice/Utils/apis.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/Utils/signaling_service.dart';
import 'package:bmine_slice/Utils/utils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/allblockeduserresponsemodel.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/meetingcallidresponsemodel.dart';
import 'package:bmine_slice/models/meetingrequestresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/screen/chatscreen.dart';
import 'package:bmine_slice/screen/myprofilescreen.dart';
import 'package:bmine_slice/screen/userlivescreen.dart';
import 'package:bmine_slice/viewmodels/meetingviewmodel.dart';
import 'package:bmine_slice/viewmodels/userreportviewmodel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SharedPreferences? prefs;
  String userid = "";
  String firebaseId = "";
  bool isLoading = false;
  bool isReqLoading = false;
  bool isChatLoading = false;
  List<Map> usersList = [];
  List<Map> userunreadCountlist = [];
  StreamSubscription? _messageSubscription;
  StreamSubscription? _userStatusSubscription;
  final SignalingService _signalingService = SignalingService();
  MeetingRequestResponseModel meetingRequestResponseModel =
      MeetingRequestResponseModel();
  AllBlockedUserResponseModel allBlockedUserResponseModel =
      AllBlockedUserResponseModel();
  TextEditingController dateandtimecontroller = TextEditingController();
  TextEditingController searchcontroller = TextEditingController();
  List<Map> filteredUsersList = [];
  int matchcount = 0;
  int meetingcount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = isMessageTab;

    _tabController.addListener(() async {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          await initializeMessaging();
          await getMeetingRequestAPI();
        } else if (_tabController.index == 1) {
          searchcontroller.clear();
          await initializeMessaging();
          await getMeetingRequestAPI();
        }
      }
    });
    getCallAPI();
  }

  getCallAPI() async {
    await initializeMessaging();
    await getMeetingRequestAPI();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageSubscription?.cancel();
    _userStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> initializeMessaging() async {
    setState(() => isLoading = true);
    await getAllBlockedUsersAPI();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    firebaseId = prefs.getString('firebaseId') ?? "";
    print("firebaseId == $firebaseId");
    if (firebaseId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }
    await _messageSubscription?.cancel();
    await _userStatusSubscription?.cancel();
    DatabaseReference messageRef = FirebaseDatabase.instance.ref('message');
    _messageSubscription = messageRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        updateMessageList(event.snapshot.value as Map<dynamic, dynamic>);
      }
    }, onError: (error) {
      print("Error in message stream: $error");
      setState(() => isLoading = false);
    });
    DatabaseReference userRef = FirebaseDatabase.instance.ref('users');
    _userStatusSubscription = userRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        updateUserStatus(event.snapshot.value as Map<dynamic, dynamic>);
      }
    }, onError: (error) {
      print("Error in user status stream: $error");
    });
  }

  void updateMessageList(Map<dynamic, dynamic> messages) async {
    try {
      Map<String, Map> userChannels = {};
      String currentFirebaseId = firebaseId.replaceFirst('-', '');
      messages.forEach((key, value) {
        if (value is Map) {
          List<String> parts = key.toString().split('--');

          if (parts.contains(currentFirebaseId)) {
            int currentUserIndex = parts.indexOf(currentFirebaseId);
            String otherUserId = currentUserIndex == 1 ? parts[2] : parts[1];

            Map<dynamic, dynamic> channelMessages = value;
            int maxTimestamp = 0;
            int unreadCount = 0;
            Map<dynamic, dynamic>? latestMessage;

            channelMessages.forEach((messageKey, messageData) {
              if (messageData['idTo'] == firebaseId &&
                  !(messageData['isSeen'] ?? false)) {
                unreadCount++;
              }

              int? timestamp = messageData['createdAt'];
              if (timestamp != null && timestamp > maxTimestamp) {
                maxTimestamp = timestamp;
                latestMessage = messageData;
              }
            });

            if (latestMessage != null) {
              if (!userChannels.containsKey(otherUserId) ||
                  userChannels[otherUserId]!['lastmessagetime'] <
                      maxTimestamp) {
                userChannels[otherUserId] = {
                  'key': key,
                  'lastmessagetime': maxTimestamp,
                  'content': latestMessage!['content'] ?? "",
                  'type': latestMessage!['type'],
                  'unreadCount': unreadCount,
                };
              }
            }
          }
        }
      });

      List<Map> newUsersList = [];
      List<Map> newUnreadCountList = [];
      var sortedUsers = userChannels.entries.toList()
        ..sort((a, b) => (b.value['lastmessagetime'] as int)
            .compareTo(a.value['lastmessagetime'] as int));

      for (var entry in sortedUsers) {
        String userId = entry.key;
        Map channelData = entry.value;

        try {
          DatabaseReference userRef =
              FirebaseDatabase.instance.ref().child('users').child('-$userId');
          await userRef.once().then((snapshot) {
            Map<dynamic, dynamic> userData =
                snapshot.snapshot.value as Map<dynamic, dynamic>;

            userData['lastmessagetime'] = channelData['lastmessagetime'] ?? "";
            userData['content'] = channelData['content'] ?? "";
            userData['type'] = channelData['type'] ?? "";

            newUsersList.add(userData);
            newUnreadCountList.add({
              'userid': userData['id'],
              'unreadCount': channelData['unreadCount']
            });
          });
        } catch (error) {
          print("Error fetching user $userId: $error");
        }
      }
      await getFilteredUsers(newUsersList, firebaseId);
      List<Map<dynamic, dynamic>> filteredUsers = [];
      if (mounted) {
        setState(() {
          userunreadCountlist = newUnreadCountList;
          filteredUsers = userunreadCountlist
              .where((user) => user["unreadCount"] > 0)
              .toList();
          print("filteredUsers ==== $filteredUsers");
          matchcount = filteredUsers.length;
          API.messageunreadcount = matchcount + meetingcount;
          isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> getFilteredUsers(
      List<Map<dynamic, dynamic>> usersList, String myFirebaseID) async {
    try {
      DatabaseReference deletedChatRef =
          FirebaseDatabase.instance.ref().child('deleted_chat');

      DatabaseEvent event = await deletedChatRef.once();
      Map<dynamic, dynamic>? deletedChatData =
          event.snapshot.value as Map<dynamic, dynamic>?;
      print("deletedUsers ==== $deletedChatData");
      if (deletedChatData == null) {
        filteredUsersList = usersList;

        setState(() {});
        return;
      }

      Set<String> blockedUserIds = deletedChatData.entries
          .where((entry) => entry.value['idFrom'] == myFirebaseID)
          .map((entry) => entry.value['idTo'] as String)
          .toSet();
      print("blockedUserIds ==== $blockedUserIds");
      filteredUsersList = usersList
          .where((user) => !blockedUserIds.contains(user['id']))
          .toList();
      print("filteredUsersList === $filteredUsersList");
      Set<String> allblockedUserIds = allBlockedUserResponseModel.data!
          .map((user) => user.firebaseId.toString())
          .toSet();

      filteredUsersList = usersList
          .where((user) => !allblockedUserIds.contains(user['id']))
          .toList();
      print("filteredUsersList  122333=== $filteredUsersList");

      setState(() {});
    } catch (error) {
      print("Error fetching: $error");
    }
  }

  void updateUserStatus(Map<dynamic, dynamic> usersData) {
    if (!mounted) return;

    setState(() {
      for (var i = 0; i < usersList.length; i++) {
        String userId = usersList[i]['id'];
        if (usersData.containsKey('-$userId')) {
          Map<dynamic, dynamic> updatedData = usersData['-$userId'];
          usersList[i]['online'] = updatedData['online'];
          usersList[i]['lastSeen'] = updatedData['lastSeen'];
        }
      }
    });
  }

  String _getFormattedTime(int timestamp, String formattedYesterdayDate) {
    DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();

    if (DateFormat('dd-MM-yyyy').format(now) ==
        DateFormat('dd-MM-yyyy').format(messageTime)) {
      return DateFormat('h:mm a').format(messageTime);
    } else if (DateFormat('dd-MM-yyyy').format(messageTime) ==
        formattedYesterdayDate) {
      return "Yesterday";
    } else {
      return DateFormat('dd-MM-yyyy').format(messageTime);
    }
  }

  String getMessagePreview(int unreadCount, String content) {
    if (unreadCount > 1) {
      return '$unreadCount new messages';
    }
    return content;
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<Map> tempList = [];
      for (var user in usersList) {
        if (user['nickname'].toLowerCase().contains(query.toLowerCase())) {
          tempList.add(user);
        }
      }
      setState(() {
        filteredUsersList = tempList;
      });
    } else {
      setState(() {
        filteredUsersList = usersList;
      });
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
              Text(Languages.of(context)!.chatstxt,
                  style: Appstyle.marcellusSC24w500
                      .copyWith(color: AppColors.blackclr)),
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
                labelStyle: Appstyle.quicksand14w600
                    .copyWith(color: AppColors.blackclr),
                unselectedLabelStyle:
                    Appstyle.quicksand14w600.copyWith(color: Colors.black54),
                // tabs: [
                //   Tab(
                //     text: Languages.of(context)!.matchestxt,
                //   ),
                //   Tab(text: Languages.of(context)!.virtulemeetingstxt),
                // ],
                tabs: [
                  Tab(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          Languages.of(context)!.matchestxt,
                          style: _tabController.index == 0
                              ? Appstyle.quicksand14w600
                                  .copyWith(color: AppColors.blackclr)
                              : Appstyle.quicksand14w600
                                  .copyWith(color: Colors.black54),
                        ),
                        if (matchcount > 0)
                          Positioned(
                            right: -13,
                            top: -8,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                matchcount.toString(),
                                style: Appstyle.quicksand13w600
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          Languages.of(context)!.virtulemeetingstxt,
                          style: _tabController.index == 1
                              ? Appstyle.quicksand14w600
                                  .copyWith(color: AppColors.blackclr)
                              : Appstyle.quicksand14w600
                                  .copyWith(color: Colors.black54),
                        ),
                        if (meetingcount > 0)
                          Positioned(
                            right: -13,
                            top: -8,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                meetingcount.toString(),
                                style: Appstyle.quicksand13w600
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              height: 80,
                              color: AppColors.lightgreycolor2,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20, right: 20),
                                  child: TextField(
                                    controller: searchcontroller,
                                    onChanged: (query) {
                                      filterSearchResults(query);
                                    },
                                    decoration: InputDecoration(
                                        isDense: true,
                                        fillColor: AppColors.whiteclr,
                                        filled: true,
                                        hintText:
                                            Languages.of(context)!.searchtxt,
                                        suffixIcon: const Icon(Icons.search,
                                            size: 30, color: Colors.black45),
                                        hintStyle: Appstyle.quicksand13w500
                                            .copyWith(
                                                color: AppColors.blackclr),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: AppColors.textfieldclr),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: AppColors.textfieldclr),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: AppColors.textfieldclr),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        )),
                                  ),
                                ),
                              ),
                            ),
                            filteredUsersList.isEmpty
                                ? Expanded(
                                    child: Center(
                                      child: Text(
                                        Languages.of(context)!.nodatafoundtxt,
                                        style: Appstyle.quicksand16w500
                                            .copyWith(
                                                color: AppColors.blackclr),
                                      ),
                                    ),
                                  )
                                : Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      child: ListView.builder(
                                        itemCount: filteredUsersList.length,
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          DateTime currentDate = DateTime.now();
                                          DateTime yesterdayDate =
                                              currentDate.subtract(
                                                  const Duration(days: 1));
                                          String formattedYesterdayDate =
                                              DateFormat('dd-MM-yyyy')
                                                  .format(yesterdayDate);

                                          final unreadCount =
                                              userunreadCountlist[index]
                                                  ['unreadCount'];
                                          final messagePreview =
                                              getMessagePreview(
                                                  unreadCount,
                                                  filteredUsersList[index]
                                                      ['content']);

                                          return Dismissible(
                                            key: Key(filteredUsersList[index]
                                                    ['id']
                                                .toString()),
                                            direction:
                                                DismissDirection.endToStart,
                                            confirmDismiss: (direction) async {
                                              await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    backgroundColor:
                                                        AppColors.whiteclr,
                                                    surfaceTintColor:
                                                        AppColors.whiteclr,
                                                    title: Text(
                                                      Languages.of(context)!
                                                          .deletechattxt,
                                                      style: Appstyle
                                                          .quicksand20w600
                                                          .copyWith(
                                                              color: AppColors
                                                                  .blackclr),
                                                    ),
                                                    content: Text(
                                                      Languages.of(context)!
                                                          .deletechataltmsgtxt,
                                                      style: Appstyle
                                                          .quicksand18w500
                                                          .copyWith(
                                                              color: AppColors
                                                                  .blackclr),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context,
                                                                false), // Cancel deletion
                                                        child: Text(
                                                          Languages.of(context)!
                                                              .canceltxt,
                                                          style: Appstyle
                                                              .quicksand19w500
                                                              .copyWith(
                                                                  color: AppColors
                                                                      .blackclr),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          print(
                                                              "blockedUserIdstest ==== ${filteredUsersList[index]['id'] ?? ""}");
                                                          print(
                                                              "firebaseId ==== ${firebaseId}");
                                                          // DatabaseReference
                                                          //     deleteChatRef =
                                                          //     FirebaseDatabase
                                                          //         .instance
                                                          //         .ref()
                                                          //         .child(
                                                          //             'deleted_chat');
                                                          // int timestamp = DateTime
                                                          //         .now()
                                                          //     .millisecondsSinceEpoch;
                                                          // Map<String, dynamic>
                                                          //     deleted_chat = {
                                                          //   'idFrom':
                                                          //       firebaseId,
                                                          //   'idTo':
                                                          //       filteredUsersList[
                                                          //                   index]
                                                          //               [
                                                          //               'id'] ??
                                                          //           "",
                                                          // };
                                                          // await deleteChatRef
                                                          //     .child(timestamp
                                                          //         .toString())
                                                          //     .set(
                                                          //         deleted_chat);
                                                          // filteredUsersList
                                                          //     .removeAt(index);

                                                          DatabaseReference
                                                              userRef =
                                                              FirebaseDatabase
                                                                  .instance
                                                                  .ref()
                                                                  .child(
                                                                      'message');

                                                          var channelKey =
                                                              'chat--${firebaseId.replaceFirst("-", "")}-${filteredUsersList[index]['id']}';
                                                          var channel2Key =
                                                              'chat-${filteredUsersList[index]['id']}--${firebaseId.replaceFirst("-", "")}';

                                                          DatabaseEvent
                                                              channelSnapshot =
                                                              await userRef
                                                                  .child(
                                                                      channelKey)
                                                                  .once();
                                                          DatabaseEvent
                                                              channel2Snapshot =
                                                              await userRef
                                                                  .child(
                                                                      channel2Key)
                                                                  .once();
                                                          if (channelSnapshot
                                                              .snapshot
                                                              .exists) {
                                                            print(
                                                                "ONE ==== ${channelKey}");
                                                            FirebaseDatabase
                                                                .instance
                                                                .ref(
                                                                    'message/$channelKey')
                                                                .remove()
                                                                .then((_) => print(
                                                                    'Chat thread deleted'))
                                                                .catchError(
                                                                    (error) =>
                                                                        print(
                                                                            'Error: $error'));
                                                          } else if (channel2Snapshot
                                                              .snapshot
                                                              .exists) {
                                                            print(
                                                                "TWO ==== ${channel2Key}");
                                                            FirebaseDatabase
                                                                .instance
                                                                .ref(
                                                                    'message/$channel2Key')
                                                                .remove()
                                                                .then((_) => print(
                                                                    'Chat thread deleted'))
                                                                .catchError(
                                                                    (error) =>
                                                                        print(
                                                                            'Error: $error'));
                                                          }
                                                          filteredUsersList
                                                              .removeAt(index);

                                                          setState(() {});
                                                          Navigator.pop(
                                                              context, true);
                                                        },
                                                        child: Text(
                                                          Languages.of(context)!
                                                              .deletetxt,
                                                          style: Appstyle
                                                              .quicksand19w500
                                                              .copyWith(
                                                                  color: Colors
                                                                      .red),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              return false;
                                            },
                                            background: Container(
                                              color: Colors.red,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20),
                                              alignment: Alignment.centerRight,
                                              child: const Icon(Icons.delete,
                                                  color: Colors.white),
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ChatScreen(
                                                      oppId: filteredUsersList[
                                                              index]['id'] ??
                                                          "",
                                                      // firebaseUId: firebaseId,
                                                      // name:
                                                      //     filteredUsersList[index]
                                                      //             ['nickname'] ??
                                                      //         "",
                                                      // dob:
                                                      //     filteredUsersList[index]
                                                      //             ['dob'] ??
                                                      //         "",
                                                      // userImg:
                                                      //     filteredUsersList[index]
                                                      //             ["photoUrl"] ??
                                                      //         "",
                                                      frdId: filteredUsersList[
                                                                  index]
                                                              ["loginuserid"] ??
                                                          "",
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 3,
                                                        vertical: 10),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Stack(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 25,
                                                          backgroundImage: filteredUsersList[
                                                                          index]
                                                                      [
                                                                      'photoUrl'] ==
                                                                  null
                                                              ? AssetImage(
                                                                  AppAssets
                                                                      .femaleUser)
                                                              : NetworkImage(
                                                                      "${API.baseUrl}/upload/${filteredUsersList[index]['photoUrl']}")
                                                                  as ImageProvider,
                                                        ),
                                                        if (filteredUsersList[
                                                                    index]
                                                                ['online'] ==
                                                            true)
                                                          Positioned(
                                                            right: 0,
                                                            bottom: 0,
                                                            child: Container(
                                                              width: 12,
                                                              height: 12,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .green,
                                                                shape: BoxShape
                                                                    .circle,
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                '${filteredUsersList[index]['nickname'] != null ? "${filteredUsersList[index]['nickname']!.split(" ")[0]}" : ""}'
                                                                '${filteredUsersList[index]['nickname'] != null && filteredUsersList[index]['nickname']!.split(" ").length > 1 ? " ${filteredUsersList[index]['nickname']!.split(" ").last.substring(0, 1)}" : ""}'
                                                                '${filteredUsersList[index]['dob'] != null ? ", ${calculateAge(DateTime.parse(filteredUsersList[index]['dob']))}" : ""}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                              const Spacer(),
                                                              Text(
                                                                _getFormattedTime(
                                                                  filteredUsersList[
                                                                          index]
                                                                      [
                                                                      'lastmessagetime'],
                                                                  formattedYesterdayDate,
                                                                ),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              filteredUsersList[
                                                                              index]
                                                                          [
                                                                          'type'] ==
                                                                      "0"
                                                                  ? Expanded(
                                                                      child:
                                                                          Text(
                                                                        filteredUsersList[index]
                                                                            [
                                                                            'content'],
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.grey,
                                                                          fontSize:
                                                                              14,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    )
                                                                  : filteredUsersList[index]
                                                                              [
                                                                              'type'] ==
                                                                          "1"
                                                                      ? Row(
                                                                          children: [
                                                                            Icon(Icons.camera_alt_outlined,
                                                                                size: 20,
                                                                                color: Colors.grey),
                                                                            SizedBox(width: 5),
                                                                            Text(Languages.of(context)!.phototxt)
                                                                          ],
                                                                        )
                                                                      : filteredUsersList[index]['type'] ==
                                                                              "2"
                                                                          ? Row(
                                                                              children: [
                                                                                Icon(Icons.mic, size: 20, color: Colors.grey),
                                                                                SizedBox(width: 5),
                                                                                Text(Languages.of(context)!.audiotxt)
                                                                              ],
                                                                            )
                                                                          : Container(),
                                                              if (unreadCount >
                                                                  0)
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          6),
                                                                  decoration:
                                                                      const BoxDecoration(
                                                                    color: Colors
                                                                        .blue,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  child: Text(
                                                                    unreadCount
                                                                        .toString(),
                                                                    style:
                                                                        const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                )
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
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
                        (meetingRequestResponseModel.requestMeeting == null ||
                                    meetingRequestResponseModel
                                        .requestMeeting!.isEmpty) &&
                                (meetingRequestResponseModel.scheduleMeeting ==
                                        null ||
                                    meetingRequestResponseModel
                                        .scheduleMeeting!.isEmpty) &&
                                (meetingRequestResponseModel.liveEventMeeting ==
                                        null ||
                                    meetingRequestResponseModel
                                        .liveEventMeeting!.isEmpty)
                            ? Center(
                                child: Text(
                                  Languages.of(context)!.nodatafoundtxt,
                                  style: Appstyle.quicksand16w500
                                      .copyWith(color: AppColors.blackclr),
                                ),
                              )
                            : ListView(
                                children: [
                                  meetingRequestResponseModel
                                          .requestMeeting!.isEmpty
                                      ? Container()
                                      : _buildSectionHeader(
                                          'Request (${meetingRequestResponseModel.requestMeeting!.length})'),
                                  _buildRequestList(meetingRequestResponseModel
                                      .requestMeeting!),
                                  meetingRequestResponseModel
                                          .scheduleMeeting!.isEmpty
                                      ? Container()
                                      : _buildSectionHeader(
                                          'Scheduled 1-on-1 Meetings'),
                                  _buildOneOnOneMeetingList(
                                      meetingRequestResponseModel
                                          .scheduleMeeting!),
                                  meetingRequestResponseModel
                                          .liveEventMeeting!.isEmpty
                                      ? Container()
                                      : _buildSectionHeader(
                                          'Scheduled Live Event Meetings'),
                                  _buildLiveEventMeetingList(
                                      meetingRequestResponseModel
                                          .liveEventMeeting!),
                                ],
                              )
                      ],
                    ),
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRequestList(List<Meeting> requestList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requestList.length,
      itemBuilder: (context, index) {
        return _buildMeetingCard(requestList[index], "Request-Meeting");
      },
    );
  }

  Widget _buildOneOnOneMeetingList(List<Meeting> scheduleMeetingList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scheduleMeetingList.length,
      itemBuilder: (context, index) {
        return _buildMeetingCard(
            scheduleMeetingList[index], "Live-Event-Meeting");
      },
    );
  }

  Widget _buildLiveEventMeetingList(List<Meeting> liveEventMeeting) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: liveEventMeeting.length,
      itemBuilder: (context, index) {
        return _buildMeetingCard(liveEventMeeting[index], "Live-Event-Meeting");
      },
    );
  }

  String _formatDateWithSuffix(DateTime date) {
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final month = DateFormat('MMM').format(date);
    final year = date.year;
    return '$month $day$suffix, $year';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String formatScheduledDateTime(DateTime dateTime) {
    print("dateTime === $dateTime");

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString = DateFormat('hh:mm a').format(dateTime);

    if (dateOnly == today) {
      return 'Scheduled at $timeString Today';
    } else if (dateOnly == tomorrow) {
      return 'Scheduled at $timeString Tomorrow';
    } else {
      final formattedDate = _formatDateWithSuffix(dateTime);
      return 'Scheduled at $timeString on $formattedDate';
    }
  }

  Widget _buildMeetingCard(Meeting item, String type) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyProfileScreen(
              isScreen: "Friend-Profile",
              frdId: item.userId.toString(),
            ),
          ),
        ).then(
          (value) async {
            if (_tabController.index == 0) {
              await initializeMessaging();
              await getMeetingRequestAPI();
            } else if (_tabController.index == 1) {
              searchcontroller.clear();
              await initializeMessaging();
              await getMeetingRequestAPI();
            }
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: const BoxDecoration(
            color: AppColors.whiteclr,
            border: Border(bottom: BorderSide(color: AppColors.borderclr))),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: item.images != null
                    ? NetworkImage("${API.baseUrl}/upload/${item.images}")
                    : AssetImage(AppAssets.femaleUser) as ImageProvider,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item.firstName} "
                      "${item.lastName != null && item.lastName!.isNotEmpty ? item.lastName![0] : ''}"
                      "${item.dob != null ? ", ${calculateAge(item.dob!)}" : ""}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    type != "Request-Meeting"
                        ? Text(
                            item.scheduleAt == null
                                ? ""
                                : formatScheduledDateTime(
                                    item.scheduleAt!.toLocal()),
                            // 'Scheduled at ${item.scheduleAt}',
                            style: const TextStyle(color: Colors.grey),
                          )
                        : Container(),
                    const SizedBox(height: 10),
                    if (type == "Request-Meeting")
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              _showAlertDialog(item.id.toString(), item);
                            },
                            child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                    color: AppColors.btngreyclr,
                                    border:
                                        Border.all(color: AppColors.borderclr),
                                    borderRadius: BorderRadius.circular(5)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 25),
                                child: Center(
                                    child: Text(
                                        Languages.of(context)!.accepttxt))),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              rejectMeetingRequestAPI(
                                item.id.toString(),
                              );
                            },
                            child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: AppColors.borderclr),
                                    borderRadius: BorderRadius.circular(5)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 25),
                                child: Center(
                                    child: Text(
                                        Languages.of(context)!.declinetxt))),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: () async {
                          await getCallIdAPI(item.id.toString(), item);
                        },
                        child: Container(
                            height: 40,
                            width: 100,
                            decoration: BoxDecoration(
                                color: AppColors.btngreyclr,
                                border: Border.all(color: AppColors.borderclr),
                                borderRadius: BorderRadius.circular(5)),
                            child: Center(
                                child: Text(Languages.of(context)!.starttxt))),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  getuserid() async {
    prefs = await SharedPreferences.getInstance();
    userid = prefs!.getString('userid') ?? "";
  }

  void _showAlertDialog(String reqId, Meeting item) {
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
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          item.images == null
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
                                            "${API.baseUrl}/upload/${item.images!}",
                                          )),
                                    ),
                                  ),
                                ),
                          const SizedBox(
                            height: 10,
                          ),
                          Center(
                            child: Text(
                              Languages.of(context)!
                                  .wouldyouliketoacceptthemeetingrequesttxt,
                              textAlign: TextAlign.center,
                              style: Appstyle.quicksand14w600
                                  .copyWith(color: AppColors.blackclr),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Text(
                            Languages.of(context)!.dateandtimetxt,
                            style: Appstyle.quicksand14w600
                                .copyWith(color: AppColors.textfieldclr),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          TextField(
                            controller: dateandtimecontroller,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 1),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.datetimetextfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.datetimetextfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.datetimetextfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Select date time',
                              hintStyle: Appstyle.quicksand15w600,
                              suffixIcon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                              ),
                            ),
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );

                              if (pickedDate != null) {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );

                                if (pickedTime != null) {
                                  DateTime finalDateTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );

                                  dateandtimecontroller.text =
                                      DateFormat('yyyy-MM-dd HH:mm')
                                          .format(finalDateTime);
                                }
                              }
                            },
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    if (!isReqLoading) {
                                      if (dateandtimecontroller.text.isEmpty) {
                                        showToast(Languages.of(context)!
                                            .selectdatetimetxt);
                                      } else {
                                        setAState(() {
                                          isReqLoading = true;
                                        });
                                        final callId = await _signalingService
                                            .createCall();
                                        await acceptMeetingRequestAPI(
                                            item.idFrom.toString(),
                                            item.idTo.toString(),
                                            reqId,
                                            "aceept-req",
                                            callId,
                                            item);
                                        // setAState(() {
                                        //   isReqLoading = false;
                                        // });

                                        Navigator.pop(context);
                                      }
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
                                          // AppColors.signinclr1,
                                          // AppColors.signinclr2
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
                                            .copyWith(
                                                color: AppColors.blackclr),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
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

  getMeetingRequestAPI() async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<MeetingViewModel>(context, listen: false)
            .getMeetingRequest(userid);
        if (Provider.of<MeetingViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<MeetingViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              meetingRequestResponseModel =
                  Provider.of<MeetingViewModel>(context, listen: false)
                      .meetingtrequestresponse
                      .response as MeetingRequestResponseModel;
              meetingcount = meetingRequestResponseModel.requestMeeting!.length;
              API.messageunreadcount = matchcount + meetingcount;
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

  getAllBlockedUsersAPI() async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<UserReportViewModel>(context, listen: false)
            .getAllBlockedUsersAPI(userid);
        if (Provider.of<UserReportViewModel>(context, listen: false)
                .isLoading ==
            false) {
          if (Provider.of<UserReportViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              allBlockedUserResponseModel =
                  Provider.of<UserReportViewModel>(context, listen: false)
                      .allblockedusersresponse
                      .response as AllBlockedUserResponseModel;
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

  getCallIdAPI(String meetingId, Meeting item) async {
    setState(() {
      isLoading = true;
    });
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<MeetingViewModel>(context, listen: false)
            .getMeetingCallId(meetingId);
        if (Provider.of<MeetingViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<MeetingViewModel>(context, listen: false).isSuccess ==
              true) {
            MeetingCallIdResponseModel meetingCallIdResponseModel =
                MeetingCallIdResponseModel();
            setState(() {
              isLoading = false;
              meetingCallIdResponseModel =
                  Provider.of<MeetingViewModel>(context, listen: false)
                      .meetingcallidresponse
                      .response as MeetingCallIdResponseModel;
            });

            if (meetingCallIdResponseModel.requestMeeting!.callId == null) {
              final callId = await _signalingService.createCall();
              acceptMeetingRequestAPI(
                  meetingCallIdResponseModel.requestMeeting!.idFrom.toString(),
                  meetingCallIdResponseModel.requestMeeting!.idTo.toString(),
                  meetingCallIdResponseModel.requestMeeting!.id.toString(),
                  "start-meeting",
                  callId,
                  item);
            } else {
              DateTime scheduleTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(
                  meetingCallIdResponseModel.requestMeeting!.scheduleAt!
                      .toLocal()
                      .toString());

              DateTime now = DateTime.now();
              Duration difference = scheduleTime.difference(now);
              // showToast(difference.inMinutes.toString());
              // return;

              if (difference.inMinutes > 5) {
                showToast(Languages.of(context)!.callcanstartbefore5mintxt);
                return;
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LiveStreamPage(
                            callId: meetingCallIdResponseModel
                                    .requestMeeting!.callId ??
                                "",
                            meetingModel: item,
                          )),
                ).then(
                  (value) async {
                    if (_tabController.index == 0) {
                      await initializeMessaging();
                      await getMeetingRequestAPI();
                    } else if (_tabController.index == 1) {
                      searchcontroller.clear();
                      await initializeMessaging();
                      await getMeetingRequestAPI();
                    }
                  },
                );
              }
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

  acceptMeetingRequestAPI(String idFrom, String idTo, String reqId, String type,
      String callId, Meeting item) async {
    setState(() {
      isReqLoading = true;
    });

    getuserid();
    if (dateandtimecontroller.text.isEmpty) {
      DateTime finalDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        DateTime.now().hour,
        DateTime.now().minute,
      );
      setState(() {
        dateandtimecontroller.text =
            DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
      });
    }
    String eventScheduleDate = DateFormat('yyyy-MM-dd HH:mm')
        .format(DateTime.parse(dateandtimecontroller.text).toUtc());

    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<MeetingViewModel>(context, listen: false)
            .acceptMeetingRequest(
                idFrom, idTo, reqId, callId, eventScheduleDate);
        if (Provider.of<MeetingViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<MeetingViewModel>(context, listen: false).isSuccess ==
              true) {
            ForgotPasswordResponseModel model = ForgotPasswordResponseModel();
            setState(() {
              isReqLoading = false;
              dateandtimecontroller.clear();
              model = Provider.of<MeetingViewModel>(context, listen: false)
                  .acceptmeetingtrequestresponse
                  .response as ForgotPasswordResponseModel;
            });
            await initializeMessaging();
            await getMeetingRequestAPI();
            if (type == "start-meeting") {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LiveStreamPage(
                          callId: callId,
                          meetingModel: item,
                        )),
              ).then(
                (value) async {
                  if (_tabController.index == 0) {
                    await initializeMessaging();
                    await getMeetingRequestAPI();
                  } else if (_tabController.index == 1) {
                    searchcontroller.clear();
                    await initializeMessaging();
                    await getMeetingRequestAPI();
                  }
                },
              );
            } else {
              showToast(model.message!);

              setState(() {
                isReqLoading = false;
              });
            }
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
              dateandtimecontroller.clear();
              ForgotPasswordResponseModel model =
                  Provider.of<MeetingViewModel>(context, listen: false)
                      .rejectmeetingtrequestresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
            await getMeetingRequestAPI();
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
