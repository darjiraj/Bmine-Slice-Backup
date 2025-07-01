import 'dart:async';
import 'dart:io';

import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/models/purchasedetailsresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPlusSubscriptionId = 'bmine.plus_plan';
const String _kProSubscriptionId = 'bmine.pro_plan';
const String _kEliteSubscriptionId = 'bmine.elite_plan';
const String _kAndroidPlusSubscriptionId = 'com.bmine_plus';
const String _kAndroidProSubscriptionId = 'com.bmine_pro';
const String _kAndroidEliteSubscriptionId = 'com.bmine_elite';
List<String> _kProductIds = <String>[
  _kProSubscriptionId,
  _kPlusSubscriptionId,
  _kEliteSubscriptionId
];
List<String> _kAndroidProductIds = <String>[
  _kAndroidPlusSubscriptionId,
  _kAndroidProSubscriptionId,
  _kAndroidEliteSubscriptionId,
];

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  int _currentIntroPage = 0;
  final PageController _pageController = PageController(initialPage: 0);
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool isLoading = false;
  bool isPurchase = false;
  bool isPlanActive = false;
  late AnimationController _controller;
  String userid = "";
  List<String> planArray = ["Free", "Pro", "Plus", "Elite"];

  DateTime? expiryDate;
  DateTime? purchaseDate;
  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
  }

  getPurchaseDetailsAPI() async {
    setState(() {
      isLoading = true;
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
              purchaseDetailsResponseModel =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .purchasedetailsresponse
                      .response as PurchaseDetailsResponseModel;
              isLoading = false;
              if (purchaseDetailsResponseModel.userMembership!.planName !=
                  null) {
                isPlanActive = true;
              } else {
                isPlanActive = false;
              }
            });
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .purchasedetailsresponse
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    Future.delayed(
      Duration.zero,
      () async {
        await getPurchaseDetailsAPI();
        await _initializePurchase();
      },
    );
  }

  Future<void> _initializePurchase() async {
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {});
      return;
    }
    if (isPlanActive) {
      setState(() {});
      return;
    }
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Purchase error: $error'),
    );

    Set<String> kIds = {};

    if (Platform.isAndroid) {
      kIds = {
        _kAndroidPlusSubscriptionId,
        _kAndroidProSubscriptionId,
        _kAndroidEliteSubscriptionId,
      };
    } else {
      kIds = {
        _kPlusSubscriptionId,
        _kProSubscriptionId,
        _kEliteSubscriptionId,
      };
    }
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(kIds);
    setState(() {
      _products = response.productDetails;
    });
    await _restorePurchases();
  }

  void clearDuplicateTransaction() async {
    final paymentQueue = SKPaymentQueueWrapper();

    // Get all pending transactions
    final transactions = await paymentQueue.transactions();

    for (var transaction in transactions) {
      // Finish any pending transactions for the specific product
      // if (transaction.payment.productIdentifier == 'plan_elite') {
      paymentQueue.finishTransaction(transaction);
      // }
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }

      if (purchase.status == PurchaseStatus.purchased) {
        if (Platform.isIOS && isPurchase) {
          setState(() {
            isPurchase = false;
          });
          purchaseDate = DateTime.fromMillisecondsSinceEpoch(
              int.parse(purchase.transactionDate.toString()));
          await buyMembershipApi(
            purchase.purchaseID ?? "",
            purchase.productID == "bmine.plus_plan"
                ? "Plus"
                : purchase.productID == "bmine.pro_plan"
                    ? "Pro"
                    : purchase.productID == "bmine.elite_plan"
                        ? "Elite"
                        : "",
            purchase.productID == "bmine.plus_plan"
                ? "89.99"
                : purchase.productID == "bmine.pro_plan"
                    ? "34.99"
                    : purchase.productID == "bmine.elite_plan"
                        ? "199.99"
                        : "",
            purchase.verificationData.serverVerificationData,
          );
        }
        //  else {
        //   Map<String, dynamic> jsonObject =
        //       jsonDecode(purchase.verificationData.localVerificationData);
        //   purchaseDate =
        //       DateTime.fromMillisecondsSinceEpoch(jsonObject['purchaseTime']);
        // }
        setState(() {});
      } else if (purchase.status == PurchaseStatus.restored) {
      } else if (purchase.status == PurchaseStatus.canceled) {
      } else {}
    }
  }

  Future<void> _restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  Future<void> _buySubscription(String productId) async {
    clearDuplicateTransaction();
    final product = _products.firstWhere((p) => p.id == productId);
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  void dispose() {
    _controller.dispose();
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size ksize = MediaQuery.of(context).size;
    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppColors.whiteclr,
        body: purchaseDetailsResponseModel.userMembership == null
            ? Container(
                height: ksize.height,
                width: ksize.width,
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.bminetxtclr,
                  ),
                ),
              )
            : SafeArea(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Image.asset(
                                AppAssets.cancel,
                                width: 30,
                                height: 30,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                SizedBox(
                                    height: 150,
                                    child: PageView.builder(
                                      itemCount: planArray.length,
                                      controller: _pageController,
                                      onPageChanged: (pageIndex) {
                                        print(pageIndex);
                                        setState(() {
                                          _currentIntroPage = pageIndex;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        return getintropages(
                                          ksize,
                                          index == 1
                                              ? Languages.of(context)!.protxt
                                              : index == 2
                                                  ? Languages.of(context)!
                                                      .plustxt
                                                  : index == 3
                                                      ? Languages.of(context)!
                                                          .elitetxt
                                                      : Languages.of(context)!
                                                          .freetxt,
                                        );
                                      },
                                    )),
                                Positioned(
                                  top: 70,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(4, (index) {
                                              return Container(
                                                alignment: Alignment.topCenter,
                                                decoration: BoxDecoration(
                                                    color: _currentIntroPage ==
                                                            index
                                                        ? Colors.blue
                                                        : Colors.black
                                                            .withAlpha(50),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 40),
                                                height: 10,
                                                width: 10,
                                              );
                                            }),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 45),
                                  child: _currentIntroPage == 0
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            featureItem(
                                                "35 ${Languages.of(context)!.swipeperdaytxt}",
                                                true),
                                            featureItem(
                                                Languages.of(context)!
                                                    .matchandchattxt,
                                                true),
                                            featureItem(
                                                Languages.of(context)!
                                                    .virtualevent39eventtxt,
                                                true),
                                            featureItem(
                                                Languages.of(context)!
                                                    .seewholikestxt,
                                                false),
                                            featureItem(
                                                Languages.of(context)!
                                                    .freegiftstxt,
                                                false),
                                            featureItem(
                                                Languages.of(context)!
                                                    .freevirtualinvitestxt,
                                                false),
                                            featureItem(
                                                Languages.of(context)!
                                                    .kingqueenswipestxt,
                                                false),
                                            SizedBox(
                                              height: 30,
                                            ),
                                          ],
                                        )
                                      : _currentIntroPage == 1
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                featureItem(
                                                    "40 ${Languages.of(context)!.swipeperdaytxt}",
                                                    true),
                                                featureItem(
                                                    Languages.of(context)!
                                                        .matchandchattxt,
                                                    true),
                                                featureItem(
                                                    Languages.of(context)!
                                                        .seewholikestxt,
                                                    true),
                                                featureItem(
                                                    Languages.of(context)!
                                                        .virtualevent34eventtxt,
                                                    true),
                                                featureItem(
                                                    Languages.of(context)!
                                                        .freegiftstxt,
                                                    false),
                                                featureItem(
                                                    Languages.of(context)!
                                                        .freevirtualinvitestxt,
                                                    false),
                                                featureItem(
                                                    Languages.of(context)!
                                                        .kingqueenswipestxt,
                                                    false),
                                                SizedBox(
                                                  height: 30,
                                                ),
                                              ],
                                            )
                                          : _currentIntroPage == 2
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    featureItem(
                                                        "45 ${Languages.of(context)!.swipeperdaytxt}",
                                                        true),
                                                    featureItem(
                                                        Languages.of(context)!
                                                            .matchandchattxt,
                                                        true),
                                                    featureItem(
                                                        Languages.of(context)!
                                                            .seewholikestxt,
                                                        true),
                                                    featureItem(
                                                        "1 ${Languages.of(context)!.freegiftperweektxt}",
                                                        true),
                                                    featureItem(
                                                        "1 ${Languages.of(context)!.freevirtualinviteperweektxt}",
                                                        true),
                                                    featureItem(
                                                        Languages.of(context)!
                                                            .virtualevent29eventtxt,
                                                        true),
                                                    featureItem(
                                                        Languages.of(context)!
                                                            .kingqueenswipestxt,
                                                        false),
                                                    SizedBox(
                                                      height: 30,
                                                    ),
                                                  ],
                                                )
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    featureItem(
                                                        "55 ${Languages.of(context)!.swipeperdaytxt}",
                                                        true),
                                                    featureItem(
                                                        Languages.of(context)!
                                                            .matchandchattxt,
                                                        true),
                                                    featureItem(
                                                        Languages.of(context)!
                                                            .seewholikestxt,
                                                        true),
                                                    featureItem(
                                                        "2 ${Languages.of(context)!.freegiftperweektxt}",
                                                        true),
                                                    featureItem(
                                                        "2 ${Languages.of(context)!.freevirtualinviteperweektxt}",
                                                        true),
                                                    featureItem(
                                                        Languages.of(context)!
                                                            .virtualevent29eventtxt,
                                                        true),
                                                    featureItem(
                                                        Languages.of(context)!
                                                            .kingqueenswipestxt,
                                                        true),
                                                    SizedBox(
                                                      height: 30,
                                                    ),
                                                  ],
                                                ),
                                ),
                                Positioned(
                                  top: -10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        Languages.of(context)!
                                            .enhanceyourexperiencetxt,
                                        style: Appstyle.quicksand13w400
                                            .copyWith(
                                                color: AppColors.blackclr),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              child: (_currentIntroPage == 0)
                                  ? (purchaseDetailsResponseModel
                                                  .userMembership ==
                                              null ||
                                          purchaseDetailsResponseModel
                                                  .userMembership!.planName ==
                                              null
                                      ? Center(
                                          child: Text(
                                            "Current Plan",
                                            style: Appstyle.quicksand18w600
                                                .copyWith(
                                              color: AppColors.timetxtgrey,
                                            ),
                                          ),
                                        )
                                      : Container())
                                  : ((purchaseDetailsResponseModel
                                                      .userMembership
                                                      ?.planName ==
                                                  "Pro" &&
                                              _currentIntroPage == 1) ||
                                          (purchaseDetailsResponseModel
                                                      .userMembership
                                                      ?.planName ==
                                                  "Plus" &&
                                              _currentIntroPage == 2) ||
                                          (purchaseDetailsResponseModel
                                                      .userMembership
                                                      ?.planName ==
                                                  "Elite" &&
                                              _currentIntroPage == 3))
                                      ? Center(
                                          child: Text(
                                            Languages.of(context)!
                                                .currentplantxt,
                                            style: Appstyle.quicksand18w600
                                                .copyWith(
                                              color: AppColors.timetxtgrey,
                                            ),
                                          ),
                                        )
                                      : InkWell(
                                          onTap: () async {
                                            print("ontap");
                                            setState(() {
                                              isPurchase = true;
                                            });

                                            if (_currentIntroPage == 1) {
                                              if (Platform.isAndroid) {
                                                _buySubscription(
                                                    _kAndroidProductIds[0]);
                                              } else {
                                                _buySubscription(
                                                    _kProductIds[0]);
                                              }
                                            } else if (_currentIntroPage == 2) {
                                              if (Platform.isAndroid) {
                                                _buySubscription(
                                                    _kAndroidProductIds[1]);
                                              } else {
                                                _buySubscription(
                                                    _kProductIds[1]);
                                              }
                                            } else if (_currentIntroPage == 3) {
                                              if (Platform.isAndroid) {
                                                _buySubscription(
                                                    _kAndroidProductIds[2]);
                                              } else {
                                                _buySubscription(
                                                    _kProductIds[2]);
                                              }
                                            }
                                          },
                                          child: Container(
                                            height: 50,
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                _currentIntroPage == 1
                                                    ? Languages.of(context)!
                                                        .monthbymonth3499mtxt
                                                    : _currentIntroPage == 2
                                                        ? Languages.of(context)!
                                                            .for90days2499mtxt
                                                        : Languages.of(context)!
                                                            .year19999txt,
                                                style: Appstyle.quicksand16w600,
                                              ),
                                            ),
                                          ),
                                        ),
                            )
                          ],
                        ),
                      ),
                    ),
                    isLoading
                        ? Container(
                            height: ksize.height,
                            width: ksize.width,
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
      ),
    );
  }

  Widget featureItem(String text, bool isEnabled) {
    return Column(
      children: [
        SizedBox(
          height: 15,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(
                isEnabled ? Icons.check : Icons.lock,
                color: isEnabled ? Colors.blue : Colors.grey,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: Appstyle.quicksand16w500
                        .copyWith(color: AppColors.blackclr)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  getintropages(Size ksize, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xffD875CB)),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xffFBFDFC),
                    Color(0xffF7D9FF),
                    Color(0xffF2ADFC),
                  ]),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  Text(Languages.of(context)!.bminetxt,
                      style: Appstyle.marcellusSC24w500
                          .copyWith(color: AppColors.bminetxtclr)),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color(0xffE789FE),
                            Color(0xffD757F8),
                          ]),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 5),
                      child: Text(title,
                          style: Appstyle.quicksand14w600
                              .copyWith(color: AppColors.whiteclr)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  buyMembershipApi(
    String purchaseId,
    String planName,
    String price,
    String verificationToken,
  ) async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<PurchaseViewModel>(context, listen: false)
            .buyMembershipApi(
                userid, purchaseId, planName, price, verificationToken);
        if (Provider.of<PurchaseViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<PurchaseViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              ForgotPasswordResponseModel model =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .buymembershipresponse
                      .response as ForgotPasswordResponseModel;

              showToast(model.message!);
            });
            await getPurchaseDetailsAPI();
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .buymembershipresponse
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

class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
