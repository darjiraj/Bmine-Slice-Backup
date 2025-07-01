import 'dart:io';

import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/checkuserexistmodel.dart';
import 'package:bmine_slice/models/loginresponsemodel.dart';
import 'package:bmine_slice/screen/bottemnavbar.dart';
import 'package:bmine_slice/screen/forgotpasswordscreen.dart';
import 'package:bmine_slice/screen/register.dart';
import 'package:bmine_slice/viewmodels/loginviewmodel.dart';
import 'package:bmine_slice/viewmodels/signupviewmodel.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailaddresscontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  bool isLoading = false;
  bool isRemember = false;
  bool isPassVisible = true;
  String fcmToken = "";
  String userid = "";
  String email = "";
  String password = "";
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  gefcmToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    print("gefcmToken");
    fcmToken = await FirebaseMessaging.instance.getToken() ?? "no fcm";
    print("token ========= $fcmToken");

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcmtoken', fcmToken);
  }

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
    print("prefs.getString('Email') === ${prefs.getString('Email')}");
    emailaddresscontroller.text = prefs.getString('Email') ?? "";
    passwordcontroller.text = prefs.getString('Password') ?? "";
    isRemember = prefs.getBool('isRemember') ?? false;

    print("USER IDDD +++++++ $userid");
  }

  @override
  void initState() {
    getuserid();
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
                      Languages.of(context)!.logintxt,
                      style: Appstyle.marcellusSC25w600,
                    ),
                  ),
                  const SizedBox(
                    height: 70,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Languages.of(context)!.emailaddresstxt,
                            style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 15,
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
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${Languages.of(context)!.passwordtxt}:",
                            style: Appstyle.quicksand18w600),
                        const SizedBox(
                          height: 15,
                        ),
                        TextField(
                          controller: passwordcontroller,
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                          obscureText: isPassVisible,
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
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 10),
                              hintText: Languages.of(context)!.passwordtxt,
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
                          height: 15,
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(Languages.of(context)!.forgotPasswordtxt,
                              style: Appstyle.quicksand15w600),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isRemember
                                        ? Colors.transparent
                                        : AppColors.textfieldclr,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(2)),
                              height: 18, // Adjust to your preferred size
                              width: 18,
                              child: Checkbox(
                                value: isRemember,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                                activeColor: AppColors.blueclr,
                                onChanged: (value) async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();

                                  setState(() {
                                    isRemember = value ?? false;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 7,
                            ),
                            Text(Languages.of(context)!.rememberlogintxt,
                                style: Appstyle.quicksand15w600)
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () async {
                            if (emailaddresscontroller.text.isEmpty) {
                              showToast(Languages.of(context)!.enterEmailtxt);
                            } else if (!isValidEmail(
                                emailaddresscontroller.text)) {
                              showToast(
                                  Languages.of(context)!.enterValidEmailtxt);
                            } else if (passwordcontroller.text.isEmpty) {
                              showToast(
                                  Languages.of(context)!.enterpasswordtxt);
                            } else {
                              await dologin(
                                  "login",
                                  emailaddresscontroller.text.trim(),
                                  passwordcontroller.text.trim());
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
                                  AppColors.signinclr1,
                                  AppColors.signinclr2
                                ],
                              ),
                            ),
                            child: Center(
                                child: Text(Languages.of(context)!.singintxt,
                                    style: Appstyle.quicksand16w500)),
                          ),
                        ),
                        const SizedBox(
                          height: 40,
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
                                  width: 5,
                                ),
                                Text(
                                  Languages.of(context)!.loginwithgoogletxt,
                                  style: Appstyle.quicksand17w500
                                      .copyWith(color: AppColors.blackclr),
                                )
                              ],
                            ),
                          ),
                        ),
                        Platform.isIOS
                            ? Padding(
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
                                          width: 5,
                                        ),
                                        Text(
                                          Languages.of(context)!
                                              .loginwithappletxt,
                                          style: Appstyle.quicksand17w500
                                              .copyWith(
                                                  color: AppColors.blackclr),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        const SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(
                                  email: "",
                                  social_type: "login",
                                  first_name: "",
                                  last_name: "",
                                  social_id: "",
                                ),
                              ),
                            );
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
                                Text(
                                  Languages.of(context)!.signupwithemailtxt,
                                  style: Appstyle.quicksand17w500
                                      .copyWith(color: AppColors.blackclr),
                                )
                              ],
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
                  )
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
                        color: AppColors.bminetxtclr,
                      ),
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  signInWithApple() async {
    try {
      final result = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      var email = result.email;
      var socialid = result.userIdentifier;
      var fullname = [result.givenName ?? '', result.familyName ?? ''];

      print("email =$email");
      print("socialid =$socialid");

      String fName = "";
      String lName = "";

      if (fullname.length > 1) {
        fName = fullname[0];
        lName = fullname[1];
      } else {
        fName = fullname[0];
      }
      await checkAccountExist(socialid!, appleAccount: result, "apple");
    } catch (error) {
      print('Error signing in with Apple: $error');
    }
  }

  handleGoogleSignIn() async {
    try {
      await _googleSignIn.signIn().then((GoogleSignInAccount? account) {
        if (account != null) {
          var socialid = account.id;
          checkAccountExist(socialid, account: account, "google");
        }
      }).catchError((e) {
        print("e ===== $e");
      });
    } catch (e) {
      print("EEEEEEEEEEEEEE ======= $e");
    }
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
              if (isRemember == true) {
                await prefs.setString(
                    "Email", emailaddresscontroller.text.trim());
                await prefs.setString(
                    "Password", passwordcontroller.text.trim());
                await prefs.setBool("isRemember", isRemember);
              } else {
                prefs.remove("Email");
                prefs.remove("Password");
                prefs.remove("isRemember");
              }
              await updateFirebaseId(model.data!.firebaseId ?? "", fcmToken);
              print("prefs.getString('Email') === ${prefs.getString('Email')}");
              print(
                  "prefs.getString('Password') === ${prefs.getString('Password')}");
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
    String firebase_id,
    String fcm_token,
  ) async {
    setState(() {});
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<SignUpViewModel>(context, listen: false)
            .updateFirebaseId(userid, firebase_id, fcm_token);
        if (Provider.of<SignUpViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<SignUpViewModel>(context, listen: false).isSuccess ==
              true) {
            setState(() {
              // kToast(model.message!);
            });
          }
        } else {
          setState(() {});
          showToast(Languages.of(context)!.nointernettxt);
        }
      }
    });
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterScreen(
                      email: appleAccount!.email ?? "",
                      social_type: "apple",
                      first_name: appleAccount.givenName ?? "",
                      last_name: appleAccount.familyName ?? "",
                      social_id: appleAccount.userIdentifier ?? "",
                    ),
                  ),
                );
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterScreen(
                          first_name: fName,
                          last_name: lName,
                          email: account!.email,
                          social_id: account.id,
                          social_type: "google"),
                    ));
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
}
