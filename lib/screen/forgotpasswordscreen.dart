import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/viewmodels/forgotpasswordviewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  TextEditingController emailController = TextEditingController();
  bool isLoading = false;


  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    Size kSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          Center(
                            child: Text(
                              Languages.of(context)!
                                  .forgotPasswordHeader, // Add a relevant header text
                              style: Appstyle.marcellusSC25w600,
                            ),
                          ),
                          const SizedBox(height: 70),
                          Text(
                            Languages.of(context)!
                                .emailaddresstxt, // "Email Address"
                            style: Appstyle.quicksand18w600,
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 10),
                              hintText: Languages.of(context)!
                                  .enteremailtxt, // "Enter your email"
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
                          const SizedBox(height: 30),
                          InkWell(
                            onTap: () async {
                              if (emailController.text.isEmpty) {
                                showToast(Languages.of(context)!.enterEmailtxt);
                              } else if (!isValidEmail(emailController.text)) {
                                showToast(
                                    Languages.of(context)!.enterValidEmailtxt);
                              } else {
                                await doForgotPassword(
                                  emailController.text.trim(),
                                );
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
                                child: Text(
                                  Languages.of(context)!
                                      .sendResetLinkTxt, // "Send Reset Link"
                                  style: Appstyle.quicksand16w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Spacer to push the footer to the bottom
                const SizedBox(height: 10),
                Center(
                  child: Text(Languages.of(context)!.copyrightstxt),
                ),
                const SizedBox(height: 10),
              ],
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

  doForgotPassword(String email) async {
    print("get callForgotPass function call");
    setState(() {
      isLoading = true;
    });
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<ForgotPassViewModel>(context, listen: false)
            .forgotPassword(email);
        if (Provider.of<ForgotPassViewModel>(context, listen: false)
                .isLoading ==
            false) {
          if (Provider.of<ForgotPassViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              print("Success");
              ForgotPasswordResponseModel model =
                  Provider.of<ForgotPassViewModel>(context, listen: false)
                      .forgotpasswordresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<ForgotPassViewModel>(context, listen: false)
                .forgotpasswordresponse
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
}
