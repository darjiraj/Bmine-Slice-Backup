import 'dart:convert';
import 'dart:io';

import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/checkuserexistmodel.dart';
import 'package:bmine_slice/models/loginresponsemodel.dart';
import 'package:bmine_slice/models/profileresponsemodel.dart';
import 'package:bmine_slice/models/signupresponsemodel.dart';
import 'package:bmine_slice/screen/bottemnavbar.dart';
import 'package:bmine_slice/screen/editprofile.dart';
import 'package:bmine_slice/screen/termsandconditionscreen.dart';
import 'package:bmine_slice/viewmodels/loginviewmodel.dart';
import 'package:bmine_slice/viewmodels/profileviewmodel.dart';
import 'package:bmine_slice/viewmodels/signupviewmodel.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  String social_type = "";
  String email = "";
  String first_name = "";
  String last_name = "";
  String social_id = "";

  RegisterScreen({
    super.key,
    required this.social_type,
    required this.email,
    required this.first_name,
    required this.last_name,
    required this.social_id,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController emailaddresscontroller = TextEditingController();
  TextEditingController confirmemailaddresscontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController confirmpasswordcontroller = TextEditingController();
  TextEditingController fNamecontroller = TextEditingController();
  TextEditingController lNamecontroller = TextEditingController();
  TextEditingController dobcontroller = TextEditingController();
  TextEditingController mobileNocontroller = TextEditingController();
  TextEditingController hometownController = TextEditingController();
  List<Map<String, dynamic>> predictions = [];
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  String socialType = "";
  String socialId = "";
  String fcmToken = "";
  String selectedPlaceId = "";
  String hometownLat = "";
  String hometownLong = "";
  String country = "";

  bool isLoading = false;
  String selectedGender = "";
  List<String> genderOptions = [
    'Man - Straight',
    'Man - Gay',
    'Man - Bi',
    'Woman - Straight',
    'Woman - Lesbian',
    'Woman - Bi',
    'Trans-Man',
    'Trans-Woman'
  ];

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  bool isPassVisible = true;
  bool isCheckTerms = false;
  bool isUnderAge = false;
  bool isConfirmPassVisible = true;
  String userid = "";
  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid')!;

    print("USER IDDD +++++++ $userid");
  }

  Future<void> fetchPredictions(String input) async {
    const apiKey = "AIzaSyCRNjykxoRKwqenOpoqBdoYz1CTvPYI5So";
    const apiUrl =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    final response = await http
        .get(Uri.parse('$apiUrl?input=$input&types=geocode&key=$apiKey'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          predictions = List<Map<String, dynamic>>.from(data['predictions'].map(
              (prediction) => {
                    'description': prediction['description'],
                    'place_id': prediction['place_id']
                  }));
        });
      } else {
        setState(() {
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
      throw Exception('Failed to fetch place details: ${response.statusCode}');
    }
  }

  filledData() {
    setState(() {
      emailaddresscontroller.text = widget.email;
      confirmemailaddresscontroller.text = widget.email;
      fNamecontroller.text = widget.first_name;
      lNamecontroller.text = widget.last_name;
      socialId = widget.social_id;
      socialType = widget.social_type;
    });
  }

  gefcmToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    print("gefcmToken");
    fcmToken = await FirebaseMessaging.instance.getToken() ?? "no fcm";
    print("token ========= $fcmToken");

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcmtoken', fcmToken);
    setState(() {});
  }

  @override
  void initState() {
    filledData();
    gefcmToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size kSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  Center(
                    child: Text(
                      Languages.of(context)!.signuptxt,
                      style: Appstyle.marcellusSC25w600,
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${Languages.of(context)!.fistNametxt}:",
                            style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: fNamecontroller,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 10),
                              hintText: Languages.of(context)!.fistNametxt,
                              hintStyle:
                                  const TextStyle(color: AppColors.hinttextclr),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text("${Languages.of(context)!.lastNametxt}:",
                            style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: lNamecontroller,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 10),
                              hintText: Languages.of(context)!.lastNametxt,
                              hintStyle: const TextStyle(
                                color: AppColors.hinttextclr,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text("${Languages.of(context)!.gendertxt}:",
                            style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 10,
                        ),
                        InputDecorator(
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.textfieldclr),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.textfieldclr),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.textfieldclr),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedGender.isEmpty
                                  ? null
                                  : selectedGender,
                              hint: Text(Languages.of(context)!.gendertxt,
                                  style: const TextStyle(
                                      color: AppColors.hinttextclr,
                                      fontSize: 18)),
                              isExpanded: true,
                              isDense: true,
                              icon: Image.asset(
                                AppAssets.dropArrow,
                                width: 25,
                                height: 25,
                              ),
                              style: const TextStyle(color: Colors.black),
                              items: genderOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedGender = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text("${Languages.of(context)!.dobtxt}:",
                            style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: dobcontroller,
                          readOnly: true,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today,
                                  color: AppColors.blackclr),
                              onPressed: () => _selectDate(context),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 13, horizontal: 10),
                            hintText: Languages.of(context)!.dobtxt,
                            hintStyle:
                                const TextStyle(color: AppColors.hinttextclr),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.textfieldclr),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.textfieldclr),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.textfieldclr),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                            "${Languages.of(context)!.mobileNotxt} (${Languages.of(context)!.optionaltxt}):",
                            style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: mobileNocontroller,
                          keyboardType: TextInputType.phone,
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 10),
                              hintText: Languages.of(context)!.mobileNotxt,
                              hintStyle:
                                  const TextStyle(color: AppColors.hinttextclr),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text("HomeTown", style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: hometownController,
                          onSubmitted: (value) {
                            predictions.clear();
                            setState(() {});
                          },
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              fetchPredictions(value);
                            } else {
                              setState(() {
                                predictions.clear();
                              });
                            }
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'HomeTown',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 13, horizontal: 10),
                            hintStyle:
                                const TextStyle(color: AppColors.hinttextclr),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.textfieldclr),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.textfieldclr),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.textfieldclr),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Container(
                          child: predictions.isEmpty
                              ? const SizedBox.shrink()
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: predictions.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
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
                                            setState(() {
                                              hometownController.text =
                                                  predictions[index]
                                                      ['description'];
                                            });
                                            final String selectedPlaceId =
                                                predictions[index]['place_id'];
                                            final placeDetails =
                                                await fetchPlaceDetails(
                                                    selectedPlaceId);

                                            hometownLat =
                                                placeDetails['latitude']
                                                    .toString();

                                            country =
                                                placeDetails['city'].toString();
                                            hometownLong =
                                                placeDetails['longitude']
                                                    .toString();
                                            setState(() {
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
                        const SizedBox(
                          height: 10,
                        ),
                        Text(Languages.of(context)!.emailaddresstxt,
                            style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: emailaddresscontroller,
                          keyboardType: TextInputType.emailAddress,
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 10),
                              hintText: Languages.of(context)!.enteremailtxt,
                              hintStyle:
                                  const TextStyle(color: AppColors.hinttextclr),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                            "${Languages.of(context)!.confirmemailaddresstxt}:",
                            style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: confirmemailaddresscontroller,
                          keyboardType: TextInputType.emailAddress,
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 10),
                              hintText: Languages.of(context)!.enteremailtxt,
                              hintStyle:
                                  const TextStyle(color: AppColors.hinttextclr),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: AppColors.textfieldclr),
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 30, right: 30, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        socialType == "login"
                            ? Text("${Languages.of(context)!.passwordtxt}:",
                                style: Appstyle.quicksand18w600)
                            : Container(),
                        socialType == "login"
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: TextField(
                                  controller: passwordcontroller,
                                  obscureText: isPassVisible,
                                  onTapOutside: (event) {
                                    FocusScope.of(context).unfocus();
                                  },
                                  decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        icon: isPassVisible
                                            ? Image.asset(
                                                AppAssets.eyesicon,
                                                height: 25,
                                                width: 25,
                                              )
                                            : Image.asset(
                                                AppAssets.hideeyesicon,
                                                height: 25,
                                                width: 25,
                                              ),
                                        onPressed: () {
                                          setState(() {
                                            isPassVisible = !isPassVisible;
                                          });
                                        },
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 13, horizontal: 10),
                                      hintText:
                                          Languages.of(context)!.passwordtxt,
                                      hintStyle: const TextStyle(
                                          color: AppColors.hinttextclr),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: AppColors.textfieldclr),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: AppColors.textfieldclr),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: AppColors.textfieldclr),
                                        borderRadius: BorderRadius.circular(8),
                                      )),
                                ),
                              )
                            : Container(),
                        socialType == "login"
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                    "${Languages.of(context)!.confirmpasswordtxt}:",
                                    style: Appstyle.quicksand18w600),
                              )
                            : Container(),
                        socialType == "login"
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: TextField(
                                  controller: confirmpasswordcontroller,
                                  obscureText: isConfirmPassVisible,
                                  onTapOutside: (event) {
                                    FocusScope.of(context).unfocus();
                                  },
                                  decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        icon: isConfirmPassVisible
                                            ? Image.asset(
                                                AppAssets.eyesicon,
                                                height: 25,
                                                width: 25,
                                              )
                                            : Image.asset(
                                                AppAssets.hideeyesicon,
                                                height: 25,
                                                width: 25,
                                              ),
                                        onPressed: () {
                                          setState(() {
                                            isConfirmPassVisible =
                                                !isConfirmPassVisible;
                                          });
                                        },
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 13, horizontal: 10),
                                      hintText: Languages.of(context)!
                                          .confirmpasswordtxt,
                                      hintStyle: const TextStyle(
                                          color: AppColors.hinttextclr),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: AppColors.textfieldclr),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: AppColors.textfieldclr),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: AppColors.textfieldclr),
                                        borderRadius: BorderRadius.circular(8),
                                      )),
                                ),
                              )
                            : Container(),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isCheckTerms,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.comfortable,
                              activeColor: AppColors.signinclr1,
                              onChanged: (value) {
                                setState(() {
                                  isCheckTerms = value ?? false;
                                });
                              },
                            ),
                            RichText(
                              text: TextSpan(
                                text:
                                    "${Languages.of(context)!.iacceptthetxt} ",
                                style: Appstyle.quicksand15w600
                                    .copyWith(color: AppColors.blackclr),
                                children: [
                                  TextSpan(
                                    text: Languages.of(context)!
                                        .termandconditiontxt,
                                    style: Appstyle.quicksand15w600.copyWith(
                                        color: AppColors.signinclr1,
                                        decoration: TextDecoration.underline),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  TermsandConditionsScreen(),
                                            ));
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: isUnderAge,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.comfortable,
                              activeColor: AppColors.signinclr1,
                              onChanged: (value) {
                                setState(() {
                                  isUnderAge = value ?? false;
                                });
                              },
                            ),
                            Text(
                              Languages.of(context)!.isUnderAgetxt,
                              style: Appstyle.quicksand15w600
                                  .copyWith(color: AppColors.blackclr),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        InkWell(
                          onTap: () async {
                            if (fNamecontroller.text.isEmpty) {
                              showToast(
                                  Languages.of(context)!.enterfirstnametxt);
                            } else if (lNamecontroller.text.isEmpty) {
                              showToast(
                                  Languages.of(context)!.enterlastnametxt);
                            } else if (dobcontroller.text.isEmpty) {
                              showToast(Languages.of(context)!.selectdobtxt);
                            } else if (hometownController.text.isEmpty) {
                              showToast(
                                  Languages.of(context)!.enterhometowntxt);
                            } else if (emailaddresscontroller.text.isEmpty) {
                              showToast(Languages.of(context)!.enterEmailtxt);
                            } else if (isValidEmail(
                                    emailaddresscontroller.text) ==
                                false) {
                              showToast(
                                  Languages.of(context)!.enterValidEmailtxt);
                            } else if (confirmemailaddresscontroller
                                .text.isEmpty) {
                              showToast(
                                  Languages.of(context)!.enterconfirmemailtxt);
                            } else if (isValidEmail(
                                    confirmemailaddresscontroller.text) ==
                                false) {
                              showToast(Languages.of(context)!
                                  .enterValidConfirmEmailtxt);
                            } else if (emailaddresscontroller.text !=
                                confirmemailaddresscontroller.text) {
                              showToast(
                                  Languages.of(context)!.emailmismatchedtxt);
                            } else if (passwordcontroller.text.isEmpty &&
                                socialType == "login") {
                              showToast(
                                  Languages.of(context)!.enterpasswordtxt);
                            } else if (confirmpasswordcontroller.text.isEmpty &&
                                socialType == "login") {
                              showToast(Languages.of(context)!
                                  .enterconfirmpasswordtxt);
                            } else if (passwordcontroller.text !=
                                confirmpasswordcontroller.text) {
                              showToast(
                                  Languages.of(context)!.passwordmismatchtxt);
                            } else if (!isCheckTerms) {
                              showToast(Languages.of(context)!
                                  .pleasechecktermsandcondtiontxt);
                            } else if (!isUnderAge) {
                              showToast(Languages.of(context)!
                                  .pleasecheckunderagetxt);
                            } else {
                              await doSignup(
                                  fNamecontroller.text.trim(),
                                  lNamecontroller.text.trim(),
                                  emailaddresscontroller.text.trim(),
                                  passwordcontroller.text.trim(),
                                  mobileNocontroller.text.trim(),
                                  dobcontroller.text.trim(),
                                  selectedGender,
                                  socialId,
                                  socialType,
                                  hometownController.text,
                                  hometownLat,
                                  hometownLong);
                            }
                          },
                          child: Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  width: 1, color: AppColors.blackclr),
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
                                child: Text(Languages.of(context)!.registertxt,
                                    style: Appstyle.quicksand16w500
                                        .copyWith(color: AppColors.whiteclr))),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                Languages.of(context)!.alreadyhaveanaccounttxt,
                                style: Appstyle.quicksand15w600
                                    .copyWith(color: AppColors.blackclr),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.textfieldclr,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                Languages.of(context)!.ortxt,
                                style: Appstyle.quicksand16w600
                                    .copyWith(color: AppColors.blackclr),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.textfieldclr,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        InkWell(
                          onTap: () async {
                            await handleGoogleSignIn();
                          },
                          child: Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  width: 1, color: AppColors.blackclr),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AppAssets.googleicon,
                                  height: 22,
                                  width: 22,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  Languages.of(context)!.loginwithgoogletxt,
                                  style: Appstyle.quicksand18w500
                                      .copyWith(color: AppColors.blackclr),
                                )
                              ],
                            ),
                          ),
                        ),
                        !Platform.isIOS
                            ? Container()
                            : Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: InkWell(
                                  onTap: () async {
                                    await signInWithApple();
                                  },
                                  child: Container(
                                    height: 50,
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          width: 1, color: AppColors.blackclr),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          AppAssets.appleicon,
                                          height: 22,
                                          width: 22,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          Languages.of(context)!
                                              .loginwithappletxt,
                                          style: Appstyle.quicksand18w500
                                              .copyWith(
                                                  color: AppColors.blackclr),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(
                          height: 60,
                        ),
                        Center(
                          child: Text(Languages.of(context)!.copyrightstxt),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            isLoading
                ? Container(
                    height: kSize.height,
                    width: kSize.width,
                    color: Colors.transparent,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.bminetxtclr)),
                  )
                : Container()
          ],
        ),
      ),
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
        dobcontroller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  doSignup(
    String first_name,
    String last_name,
    String email,
    String password,
    String mobile_no,
    String dob,
    String gender,
    String social_id,
    String social_type,
    String hometown,
    String latitude,
    String longitude,
  ) async {
    setState(() {
      isLoading = true;
    });

    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<SignUpViewModel>(context, listen: false).doSignup(
          first_name,
          last_name,
          email,
          password,
          mobile_no,
          dob,
          gender,
          social_id,
          social_type,
          hometown,
          latitude,
          longitude,
        );
        if (Provider.of<SignUpViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<SignUpViewModel>(context, listen: false).isSuccess ==
              true) {
            isLoading = false;
            print("Success");
            SignUpResponseModel model =
                Provider.of<SignUpViewModel>(context, listen: false)
                    .signupresponse
                    .response as SignUpResponseModel;
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            if (model.success == true) {
              DatabaseReference userRef =
                  FirebaseDatabase.instance.ref().child('users');
              DatabaseReference databaseReference = userRef.push();
              // Replace the following values with actual user data
              prefs.setString("firebaseId", databaseReference.key.toString());
              await prefs.setString('userid', model.data!.id.toString());
              print("databaseReference.key == ${databaseReference.key}");

              await userRef.child(databaseReference.key.toString()).set(
                {
                  "id": databaseReference.key,
                  "loginuserid": model.data!.id.toString(),
                  "nickname":
                      "${model.data!.firstName!} ${model.data!.lastName!}",
                  "photoUrl": "",
                  "dob": DateFormat('yyyy-MM-dd')
                      .format(DateFormat('dd/MM/yyyy').parse(dob)),
                  "status": "online",
                  "fcmToken": fcmToken,
                },
              );
              await updateFirebaseId(
                  databaseReference.key.toString(), fcmToken);
              showToast(model.message!);
              prefs.setBool("isLogin", true);
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                            isScreen: "New-User",
                          )),
                  (Route<dynamic> route) => false);
            } else {
              showToast(model.message!);
            }
          } else {
            setState(() {
              isLoading = false;
              // print("Error");
              // kToast("user not found");
            });
            showToast(Provider.of<SignUpViewModel>(context, listen: false)
                .signupresponse
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

  String capitalize(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  signInWithApple() async {
    try {
      final result = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      var socialid = result.userIdentifier;

      await checkAccountExist(socialid!, appleAccount: result, "apple");

      // getCheckAccountExist(socialid!, appleAccount: result, "apple");
    } catch (error) {
      print('Error signing in with Apple: $error');
    }
  }

  handleGoogleSignIn() async {
    try {
      await _googleSignIn.signIn().then((GoogleSignInAccount? account) {
        if (account != null) {
          var email = account.email;
          var socialid = account.id;
          checkAccountExist(socialid, account: account, "google");

          // dologin(
          //   "google",
          //   email,
          //   "",
          //   first_name: fName,
          //   last_name: lName,
          //   social_id: socialid,
          // );
        }
      }).catchError((e) {
        print("e ===== $e");
      });
    } catch (e) {
      print("EEEEEEEEEEEEEE ======= $e");
    }
  }

  checkAccountExist(String social_id, String type,
      {AuthorizationCredentialAppleID? appleAccount,
      GoogleSignInAccount? account}) async {
    String fName = "";
    String lName = "";
    setState(() {});
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<LoginViewModel>(context, listen: false)
            .checkAccountExist(social_id);
        if (Provider.of<LoginViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<LoginViewModel>(context, listen: false).isSuccess ==
              true) {
            CheckUserExistModel model =
                Provider.of<LoginViewModel>(context, listen: false)
                    .accountexistsponse
                    .response as CheckUserExistModel;

            if (type != "apple") {
              var fullname = account!.displayName!.split(" ");

              if (fullname.length > 1) {
                fName = fullname[0];
                lName = fullname[1];
              } else {
                fName = fullname[0];
              }
            }
            if (model.success == false) {
              if (type == "apple") {
                var email = appleAccount!.email;
                var fullname = [
                  appleAccount.givenName ?? '',
                  appleAccount.familyName ?? ''
                ];
                String fName = "";
                String lName = "";

                if (fullname.length > 1) {
                  fName = fullname[0];
                  lName = fullname[1];
                } else {
                  fName = fullname[0];
                }

                setState(() {
                  emailaddresscontroller.text = email ?? "";
                  confirmemailaddresscontroller.text = email ?? "";
                  fNamecontroller.text = fName;
                  lNamecontroller.text = lName;

                  socialType = "apple";
                  socialId = social_id;
                });
              } else {
                var fullname = account!.displayName!.split(" ");
                String fName = "";
                String lName = "";

                if (fullname.length > 1) {
                  fName = fullname[0];
                  lName = fullname[1];
                } else {
                  fName = fullname[0];
                }

                setState(() {
                  emailaddresscontroller.text = account.email;
                  confirmemailaddresscontroller.text = account.email;
                  fNamecontroller.text = fName;
                  lNamecontroller.text = lName;
                  socialType = "google";
                  socialId = social_id;
                });
              }
            } else {
              if (type == "apple") {
                dologin(
                  "apple",
                  appleAccount!.email ?? "",
                  "",
                  first_name: appleAccount.familyName ?? "",
                  last_name: appleAccount.givenName ?? "",
                  social_id: appleAccount.userIdentifier!,
                );
              } else {
                dologin(
                  "google",
                  account!.email,
                  "",
                  first_name: fName,
                  last_name: lName,
                  social_id: account.id,
                );
              }
            }
          } else {
            setState(() {});
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

  dologin(String social_type, String email, String password,
      {first_name, last_name, social_id}) async {
    setState(() {
      isLoading = true;
    });

    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<LoginViewModel>(context, listen: false).doLogin(
          social_type,
          email,
          password,
          first_name: first_name,
          last_name: last_name,
          social_id: social_id,
        );
        if (Provider.of<LoginViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<LoginViewModel>(context, listen: false).isSuccess ==
              true) {
            LoginResponseModel model =
                Provider.of<LoginViewModel>(context, listen: false)
                    .loginresponse
                    .response as LoginResponseModel;
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            await prefs.setString('userid', model.data!.id.toString());
            await prefs.setString(
                'firebaseId', model.data!.firebaseId.toString());
            isLoading = false;
            showToast(model.message!);
            if (model.success == true) {
              await updateFirebaseId(model.data!.firebaseId ?? "", fcmToken);
              prefs.setBool("isLogin", true);
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => BottomNavBar()),
                  (Route<dynamic> route) => false);
            }
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<LoginViewModel>(context, listen: false)
                .loginresponse
                .msg
                .toString());
          }
        } else {
          setState(() {
            isLoading = false;
          });
          showToast(Languages.of(context)!.nointernettxt);
        }
      }
    });
  }

  updateFirebaseId(
    String firebaseId,
    String fcm_token,
  ) async {
    print("updateFirebaseId function call");
    setState(() {});
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<SignUpViewModel>(context, listen: false)
            .updateFirebaseId(userid, firebaseId, fcm_token);
        if (Provider.of<SignUpViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<SignUpViewModel>(context, listen: false).isSuccess ==
              true) {
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            setState(() {
              prefs.setString("firebaseId", firebaseId);
            });
          }
        } else {
          setState(() {});
          showToast(Languages.of(context)!.nointernettxt);
        }
      }
    });
  }

  getProfileDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ProfileViewModel>(context, listen: false)
            .getProfileAPI(userid, "0.0", "0.0", "");
        if (Provider.of<ProfileViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<ProfileViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              ProfileResponseModel profileResponseModel =
                  Provider.of<ProfileViewModel>(context, listen: false)
                      .profileresponse
                      .response as ProfileResponseModel;
              String userJson = jsonEncode(profileResponseModel.aboutMe!
                  .map((user) => user.toJson())
                  .toList());
              String userProfileJson =
                  jsonEncode(profileResponseModel.userProfile!.toJson());
              print("userJson ============= $userJson");
              prefs.setString('userProfileJson', userProfileJson);
              prefs.setString('user', userJson);
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
