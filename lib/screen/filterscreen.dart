import 'dart:math';

import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  LocationPermission? permission;
  final List<String> _checkboxLabels = [
    'A Long-Term Relationship',
    'Fun Casual Dates',
    'Humor',
    'Kindness',
    'Playfulness',
    'Marriage',
    'Intimacy Without Commitment',
    'A Life Partner',
    'Ethical Non-Monogamy',
  ];

  List<String> _selectedValues = [];
  String measurementtype = "";
  void _toggleSelection(String value) {
    setState(() {
      if (_selectedValues.contains(value)) {
        _selectedValues.remove(value);
      } else {
        if (value.isNotEmpty) {
          _selectedValues.add(value);
        }
      }
      _selectedValues.removeWhere((item) => item.isEmpty);
    });
  }

  double _ageStart = 18;
  double _ageEnd = 100;
  double? _distance;
  bool isChangeHeight = false;
  bool isChangeDistance = false;
  bool _includeSlightlyOlder = false;
  bool _verifiedProfilesOnly = false;
  bool _switchValue1 = false;
  bool _switchValue2 = false;
  bool serviceEnabled = false;
  String _selectedGender = "";
  String _selectedLang = "";
  RangeValues? _currentRangeValues;

  getValuefromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  getDatafromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    measurementtype = prefs.getString('Measurement') ?? "KM";
    _selectedGender = prefs.getString("finGender") ?? "";
    _switchValue1 = prefs.getBool("finisShowHeight") ?? false;
    print("_switchValue1 = $_switchValue1");
    _switchValue2 = prefs.getBool("finisShowLookingFor") ?? false;
    String finAge = prefs.getString("finAge") ?? "";
    if (finAge.contains('-')) {
      List<String> ageParts = finAge.split('-');
      _ageStart = ageParts[0].isEmpty ? 18 : double.parse(ageParts[0]);
      _ageEnd = ageParts.length > 1 && ageParts[1].isNotEmpty
          ? double.parse(ageParts[1])
          : 100;
    } else {
      _ageStart = 18;
      _ageEnd = 100;
    }
    bool finSideifRunOut = prefs.getBool("finSideifRunOut") ?? false;
    String finDistanceAway = prefs.getString("finDistanceAway") ?? "";
    String finisVerify = prefs.getString("finisVerify") ?? "0";
    _selectedLang = prefs.getString("finSelLanguage") ?? "";
    String finHeight = prefs.getString("finHeight") ?? "";
    String finLookingFor = prefs.getString("finLookingFor") ?? "";
    if (finSideifRunOut) {
      _ageStart = (_ageStart + 2).clamp(18, 100);
      _ageEnd = (_ageEnd - 2).clamp(18, 100);
    }
    _includeSlightlyOlder = finSideifRunOut;
    _distance = finDistanceAway == "0" || finDistanceAway.isEmpty
        ? 100
        : double.parse(finDistanceAway);
    _verifiedProfilesOnly = finisVerify == "0" ? false : true;
    if (finHeight.contains('-')) {
      List<String> heightParts = finHeight.split('-');
      _currentRangeValues = RangeValues(
          heightParts[0].isEmpty ? 48 : parseFormattedHeight(heightParts[0]),
          heightParts.length > 1 && heightParts[1].isNotEmpty
              ? parseFormattedHeight(heightParts[1])
              : 143);
    }

    _selectedValues = finLookingFor.split(", ");

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getDatafromPrefs();
    getValuefromPrefs();
    getLocation();
    _tabController = TabController(length: 2, vsync: this);
  }

  String _formatHeight(double value) {
    int feet = (value ~/ 12).toInt();
    int inches = (value % 12).round();
    return "$feet'$inches\"";
  }

  double parseFormattedHeight(String height) {
    final parts = height.replaceAll('"', '').split("'");
    if (parts.length != 2) {
      throw FormatException('Invalid height format. Expected format: X\'Y"');
    }
    final feet = int.parse(parts[0]);
    final inches = int.parse(parts[1]);
    return (feet * 12 + inches).toDouble();
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      await getLocation();
      Navigator.pop(context);
    }
  }

  getLocation() async {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLocation = prefs.getBool("IsLocationStart") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppColors.whiteclr,
        appBar: AppBar(
          backgroundColor: AppColors.whiteclr,
          surfaceTintColor: AppColors.whiteclr,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2.0),
            child: Container(
              color: AppColors.textfieldclr,
              height: 1.0,
            ),
          ),
          title: Row(
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
              Text(
                Languages.of(context)!.filterstxt,
                style: Appstyle.marcellusSC20w500
                    .copyWith(color: AppColors.blackclr),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.signinclr1,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle:
                  Appstyle.quicksand14w600.copyWith(color: AppColors.blackclr),
              unselectedLabelStyle:
                  Appstyle.quicksand14w600.copyWith(color: Colors.black54),
              tabs: [
                Tab(text: Languages.of(context)!.basicfilterstxt),
                Tab(text: Languages.of(context)!.advancefilterstxt),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  basicFilterWidget(context),
                  advanceFilterWidget(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  basicFilterWidget(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 25, right: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              Languages.of(context)!.whowouldyouliketodatetxt,
              style: Appstyle.quicksand16w500.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 15),
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.white,
              ),
              child: DropdownButtonFormField<String>(
                icon: const Icon(
                  Icons.abc,
                  color: Colors.transparent,
                ),
                value: _selectedGender.isEmpty ? null : _selectedGender,
                isDense: true,
                hint: Text(
                  Languages.of(context)!.selectGendertxt,
                  style: Appstyle.quicksand16w600
                      .copyWith(color: AppColors.blackclr),
                ),
                items: [
                  'Man - Straight',
                  'Man - Gay',
                  'Man - Bi',
                  'Woman - Straight',
                  'Woman - Lesbian',
                  'Woman - Bi',
                  'Trans-Man',
                  'Trans-Woman'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: Appstyle.quicksand16w600
                          .copyWith(color: AppColors.blackclr),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              Languages.of(context)!.howoldaretheytxt,
              style: Appstyle.quicksand16w500.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Text(
              '${Languages.of(context)!.betweentxt} ${_ageStart.round()} to ${_ageEnd.round()}',
              style:
                  Appstyle.quicksand16w600.copyWith(color: AppColors.blackclr),
            ),
            RangeSlider(
              values: RangeValues(_ageStart, _ageEnd),
              min: 18,
              max: 100,
              activeColor: AppColors.signinclr1,
              inactiveColor: Colors.black26,
              onChanged: (RangeValues values) {
                setState(() {
                  _ageStart = values.start;
                  _ageEnd = values.end;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    Languages.of(context)!.seepeople2yeartxt,
                    style: Appstyle.quicksand14w600
                        .copyWith(color: AppColors.blackclr),
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: _includeSlightlyOlder
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.gradientclr1,
                                  AppColors.gradientclr2
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Colors.white,
                                ],
                              ),
                      ),
                    ),
                    Switch(
                      value: _includeSlightlyOlder,
                      onChanged: (value) {
                        setState(() {
                          _includeSlightlyOlder = !_includeSlightlyOlder;
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            Text(
              Languages.of(context)!.howfarawayaretheytxt,
              style: Appstyle.quicksand16w500.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${Languages.of(context)!.uptotxt} ${_distance == null ? "" : _distance!.round()} ${measurementtype == "MI" ? Languages.of(context)!.milesawaytxt : Languages.of(context)!.kmawaytxt}',
                  style: Appstyle.quicksand16w600
                      .copyWith(color: AppColors.blackclr),
                ),
                SizedBox(
                  width: 10,
                ),
                if (!serviceEnabled)
                  InkWell(
                    onTap: () {
                      _showLocationServiceDialog();
                    },
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
              ],
            ),
            Slider(
              value: _distance == null ? 100 : _distance!,
              min: 1,
              activeColor: AppColors.signinclr1,
              max: 100,
              onChanged: (double value) {
                setState(() {
                  isChangeDistance = true;
                  _distance = value;
                });
              },
            ),
            Text(
              Languages.of(context)!.seepeopleslightlyfurtherawayifIouttxt,
              style:
                  Appstyle.quicksand14w600.copyWith(color: AppColors.blackclr),
            ),
            const SizedBox(height: 20),
            Text(
              Languages.of(context)!.haveheyverifiedtxt,
              style: Appstyle.quicksand16w500.copyWith(color: Colors.black54),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset(
                          AppAssets.verifiedicon,
                          height: 20,
                          width: 20,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            Languages.of(context)!.verifiedprofilesonlytxt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Appstyle.quicksand16w600
                                .copyWith(color: AppColors.blackclr),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          gradient: _verifiedProfilesOnly
                              ? const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.gradientclr1,
                                    AppColors.gradientclr2
                                  ],
                                )
                              : const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.white,
                                  ],
                                ),
                        ),
                      ),
                      Switch(
                        value: _verifiedProfilesOnly,
                        onChanged: (value) {
                          setState(() {
                            _verifiedProfilesOnly = !_verifiedProfilesOnly;
                          });
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              Languages.of(context)!.whichlanguagesdotheyknowtxt,
              style: Appstyle.quicksand16w500.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              icon: const Icon(
                Icons.abc,
                color: Colors.transparent,
              ),
              value: _selectedLang.isEmpty ? null : _selectedLang,
              hint: Text(
                Languages.of(context)!.selectlanguagetxt,
                style: Appstyle.quicksand16w600
                    .copyWith(color: AppColors.blackclr),
              ),
              items: [
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
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: Appstyle.quicksand16w600
                        .copyWith(color: AppColors.blackclr),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLang = newValue!;
                });
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 14.0),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      setState(() {
                        _selectedGender = "";
                        _ageStart = 18;
                        _ageEnd = 100;
                        _includeSlightlyOlder = false;
                        _distance = null;
                        _verifiedProfilesOnly = false;
                        _selectedLang = "";

                        prefs.remove("finGender");
                        prefs.remove("finAge");
                        prefs.remove("finHeight");
                        prefs.remove("finLookingFor");
                        prefs.remove("finSideifRunOut");
                        prefs.remove("finisShowHeight");
                        prefs.remove("finisShowLookingFor");
                        prefs.remove("finDistanceAway");
                        prefs.remove("finisVerify");
                        prefs.remove("finSelLanguage");
                        prefs.remove("last_feed_position");
                        prefs.remove("last_leave_page");
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.bminetxtclr),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          Languages.of(context)!.cleartxt,
                          style: Appstyle.quicksand16w600
                              .copyWith(color: AppColors.bminetxtclr),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await SharedPreferences.getInstance();
                      String lookingfor = _selectedValues
                          .where((value) => value.isNotEmpty)
                          .join(", ");
                      prefs.setString("finGender", _selectedGender);
                      double adjustedAgeStart =
                          _includeSlightlyOlder ? _ageStart - 2 : _ageStart;
                      double adjustedAgeEnd =
                          _includeSlightlyOlder ? _ageEnd + 2 : _ageEnd;
                      prefs.setString("finAge",
                          "${adjustedAgeStart.round()}-${adjustedAgeEnd.round()}");
                      prefs.setBool("finSideifRunOut", _includeSlightlyOlder);
                      if (isChangeDistance) {
                        prefs.setString(
                            "finDistanceAway", _distance!.round().toString());
                      }

                      prefs.setString(
                          "finisVerify", _verifiedProfilesOnly ? "1" : "0");
                      prefs.setString("finSelLanguage", _selectedLang);
                      if (isChangeHeight) {
                        prefs.setString("finHeight",
                            "${_formatHeight(_currentRangeValues!.start)}-${_formatHeight(_currentRangeValues!.end)}");
                      } else {
                        prefs.setString("finHeight", "");
                      }
                      prefs.setString("finLookingFor", lookingfor);
                      prefs.setBool("finisShowHeight", _switchValue1);
                      prefs.setBool("finisShowLookingFor", _switchValue2);

                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppColors.bminetxtclr,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          Languages.of(context)!.applytxt,
                          style: Appstyle.quicksand16w600
                              .copyWith(color: AppColors.whiteclr),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  advanceFilterWidget(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 25, right: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Text(
                  Languages.of(context)!.howtallaretheytxt,
                  style:
                      Appstyle.quicksand16w500.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 5),
                Text(
                  Languages.of(context)!.anyheightisjustfinetxt,
                  style: Appstyle.quicksand16w600
                      .copyWith(color: AppColors.blackclr),
                ),
              ],
            ),
            RangeSlider(
              values: _currentRangeValues == null
                  ? RangeValues(48, 143)
                  : _currentRangeValues!,
              min: 48,
              max: 143,
              divisions: 95,
              labels: _currentRangeValues != null
                  ? RangeLabels(
                      _formatHeight(_currentRangeValues!.start),
                      _formatHeight(_currentRangeValues!.end),
                    )
                  : const RangeLabels("4'0\"", "11'11\""),
              onChanged: (RangeValues values) {
                setState(() {
                  isChangeHeight = true;
                  _currentRangeValues = values;
                });
              },
              activeColor: AppColors.signinclr1,
              inactiveColor: Colors.black26,
            ),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Languages.of(context)!.howotherpeopletunouttxt,
                      style: Appstyle.quicksand14w600
                          .copyWith(color: AppColors.blackclr),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            gradient: _switchValue1
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.gradientclr1,
                                      AppColors.gradientclr2
                                    ],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white,
                                      Colors.white,
                                    ],
                                  ),
                          ),
                        ),
                        Switch(
                          value: _switchValue1,
                          onChanged: (value) {
                            setState(() {
                              _switchValue1 = !_switchValue1;
                            });
                          },
                          activeColor: Colors.white,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  Languages.of(context)!.whataretheylookingfortxt,
                  style:
                      Appstyle.quicksand16w500.copyWith(color: Colors.black54),
                ),
                ListView.builder(
                  itemCount: _checkboxLabels.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.comfortable,
                      title: Text(
                        _checkboxLabels[index],
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      value: _selectedValues.contains(_checkboxLabels[index]),
                      activeColor: AppColors.signinclr1,
                      onChanged: (value) {
                        _toggleSelection(_checkboxLabels[index]);
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Languages.of(context)!.howotherpeopletunouttxt,
                      style: Appstyle.quicksand14w600
                          .copyWith(color: AppColors.blackclr),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            gradient: _switchValue2
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.gradientclr1,
                                      AppColors.gradientclr2
                                    ],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white,
                                      Colors.white,
                                    ],
                                  ),
                          ),
                        ),
                        Switch(
                          value: _switchValue2,
                          onChanged: (value) {
                            setState(() {
                              _switchValue2 = !_switchValue2;
                            });
                          },
                          activeColor: Colors.white,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 50),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      setState(() {
                        _selectedGender = "";
                        _ageStart = 18;
                        _ageEnd = 100;
                        _selectedValues.clear();
                        _currentRangeValues = RangeValues(48, 143);
                        _includeSlightlyOlder = false;
                        _distance = null;
                        _verifiedProfilesOnly = false;
                        _selectedLang = "";
                        _switchValue1 = false;
                        _switchValue2 = false;
                      });
                      await prefs.remove("finGender");
                      await prefs.remove("finAge");
                      await prefs.remove("finHeight");
                      await prefs.remove("finLookingFor");
                      await prefs.remove("finSideifRunOut");
                      await prefs.remove("finisShowHeight");
                      await prefs.remove("finisShowLookingFor");
                      await prefs.remove("finDistanceAway");
                      await prefs.remove("finisVerify");
                      await prefs.remove("finSelLanguage");
                      await prefs.remove("last_feed_position");
                      await prefs.remove("last_leave_page");

                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.bminetxtclr),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          Languages.of(context)!.cleartxt,
                          style: Appstyle.quicksand16w600
                              .copyWith(color: AppColors.bminetxtclr),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      String lookingfor = _selectedValues
                          .where((value) => value.isNotEmpty)
                          .join(", ");

                      double adjustedAgeStart =
                          _includeSlightlyOlder ? _ageStart - 2 : _ageStart;
                      double adjustedAgeEnd =
                          _includeSlightlyOlder ? _ageEnd + 2 : _ageEnd;
                      prefs.setString("finGender", _selectedGender);
                      prefs.setString("finAge",
                          "${adjustedAgeStart.round()}-${adjustedAgeEnd.round()}");

                      if (isChangeHeight) {
                        prefs.setString("finHeight",
                            "${_formatHeight(_currentRangeValues!.start)}-${_formatHeight(_currentRangeValues!.end)}");
                      } else {
                        prefs.setString("finHeight", "");
                      }
                      prefs.setString("finLookingFor", lookingfor);
                      prefs.setBool("finSideifRunOut", _includeSlightlyOlder);
                      prefs.setBool("finisShowHeight", _switchValue1);
                      prefs.setBool("finisShowLookingFor", _switchValue2);

                      if (isChangeDistance) {
                        prefs.setString(
                            "finDistanceAway", _distance!.round().toString());
                      }
                      prefs.setString(
                          "finisVerify", _verifiedProfilesOnly ? "1" : "0");
                      prefs.setString("finSelLanguage", _selectedLang);
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppColors.bminetxtclr,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          Languages.of(context)!.applytxt,
                          style: Appstyle.quicksand16w600
                              .copyWith(color: AppColors.whiteclr),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _recheckLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      await getLocation();
    } else {
      _showLocationServiceDialog();
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.whiteclr,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Languages.of(context)!.enableLocationServicestxt,
              style: Appstyle.quicksand18w600,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              Languages.of(context)!.locationservicesaredisabledproceedtxt,
              style: Appstyle.quicksand14w400,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            isSemanticButton: true,
            child: Text(
              Languages.of(context)!.canceltxt,
              style: Appstyle.quicksand16w500
                  .copyWith(color: AppColors.bminetxtclr),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openLocationSettings();
              await _recheckLocationServices();
            },
            isSemanticButton: true,
            child: Text(
              Languages.of(context)!.enabletxt,
              style: Appstyle.quicksand16w500
                  .copyWith(color: AppColors.bminetxtclr),
            ),
          ),
        ],
      ),
    );
  }
}
