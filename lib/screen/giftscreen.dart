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
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GiftScreen extends StatefulWidget {
  String frd_id;
  bool isSettingScreen;
  GiftScreen({super.key, required this.frd_id, required this.isSettingScreen});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  int selectedPlan = 0;
  String? selectedGiftType;

  String userid = "";
  bool isLoading = false;
  bool isReqLoading = false;
  bool isProductLoading = false;

  PurchaseDetailsResponseModel purchaseDetailsResponseModel =
      PurchaseDetailsResponseModel();

  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];

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

  void initStore() async {
    final bool available = await _iap.isAvailable();
    if (!available) return;
    setState(() {
      isProductLoading = true;
    });
    const Set<String> kIds = {
      'com.buy.3gifts',
      'com.buy.15gifts',
      'com.buy.30gifts'
    };
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(kIds);
    if (response.notFoundIDs.isNotEmpty) {
      print("Products not found: ${response.notFoundIDs}");
    }
    setState(() {
      _products = response.productDetails;
      _products.sort((a, b) =>
          double.parse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')).compareTo(
              double.parse(b.price.replaceAll(RegExp(r'[^0-9.]'), ''))));
      isProductLoading = false;
    });
  }

  void listenToPurchaseUpdates() {
    _iap.purchaseStream.listen((List<PurchaseDetails> purchases) {
      for (PurchaseDetails purchase in purchases) {
        if (purchase.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(purchase);
        }
        if (purchase.status == PurchaseStatus.purchased) {
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          buyGiftsApi(
            purchase.productID == "com.buy.30gifts"
                ? "30"
                : purchase.productID == "com.buy.15gifts"
                    ? "15"
                    : purchase.productID == "com.buy.3gifts"
                        ? "3"
                        : "",
            purchase.productID == "com.buy.30gifts"
                ? "84.90"
                : purchase.productID == "com.buy.15gifts"
                    ? "54.00"
                    : purchase.productID == "com.buy.3gifts"
                        ? "13.99"
                        : "",
            purchase.verificationData.serverVerificationData,
            purchase.purchaseID ?? "",
          );
        } else if (purchase.status == PurchaseStatus.error) {}
      }
    });
  }

  void buyProduct(ProductDetails product) async {
    clearDuplicateTransaction();
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isSettingScreen) {
      getPurchaseDetailsAPI();
    }
    initStore();
    listenToPurchaseUpdates();
  }

  @override
  Widget build(BuildContext context) {
    var kSize = MediaQuery.of(context).size;
    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppColors.whiteclr,
        body: isReqLoading
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
            : SafeArea(
                child: Stack(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    purchaseDetailsResponseModel.userGift !=
                                            null
                                        ? Languages.of(context)!.selectgiftstxt
                                        : Languages.of(context)!
                                            .sendgiftstoyourloveonestxt,
                                    textAlign: TextAlign.center,
                                    style: purchaseDetailsResponseModel
                                                .userGift !=
                                            null
                                        ? Appstyle.quicksand20w600
                                            .copyWith(color: AppColors.blackclr)
                                        : Appstyle.quicksand16w500.copyWith(
                                            color: AppColors.blackclr),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Image.asset(
                                    AppAssets.cancel,
                                    width: 27,
                                    height: 27,
                                  ),
                                ),
                              ],
                            ),
                            purchaseDetailsResponseModel.userGift != null &&
                                    purchaseDetailsResponseModel
                                            .userGift!.totalCount! >
                                        0
                                ? _buildSelectGiftCard(
                                    purchaseDetailsResponseModel.userGift!)
                                : isProductLoading
                                    ? Container(
                                        height: kSize.height / 2,
                                        width: kSize.width,
                                        color: Colors.transparent,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.bminetxtclr,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: _products.length,
                                        itemBuilder: (context, index) {
                                          return _buildPackageCard(
                                              _products[index], index);
                                        },
                                      ),
                            SizedBox(height: 16),
                            Center(
                              child: InkWell(
                                onTap: () async {
                                  if (purchaseDetailsResponseModel.userGift !=
                                          null &&
                                      purchaseDetailsResponseModel
                                              .userGift!.totalCount! >
                                          0) {
                                    await sendGifttoFriendApi(widget.frd_id,
                                        "1", selectedGiftType ?? "");
                                  } else {
                                    buyProduct(_products[selectedPlan]);
                                  }
                                },
                                child: Container(
                                  height: 45,
                                  width: 150,
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
                                          purchaseDetailsResponseModel
                                                      .userGift !=
                                                  null
                                              ? Languages.of(context)!.submittxt
                                              : Languages.of(context)!
                                                  .continuetxt,
                                          style: Appstyle.quicksand16w500)),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
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
      ),
    );
  }

  Widget _buildPackageCard(ProductDetails package, int index) {
    print("package = ${package.title}");
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPlan = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.whiteclr,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: selectedPlan == index
                      ? AppColors.blueclr
                      : AppColors.indexclrgreyclr,
                  width: selectedPlan == index ? 1.8 : 1)),
          margin: EdgeInsets.symmetric(vertical: 1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
            child: Column(
              children: [
                if (package.title != "Buy 3 Gifts" &&
                    package.title != "Buy 3 Gifts (com.app.bmine (unreviewed))")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        package.title.isEmpty
                            ? Container()
                            : Text(
                                package.title == "Buy 15 Gifts" ||
                                        package.title ==
                                            "Buy 15 Gifts (com.app.bmine (unreviewed))"
                                    ? "Popular"
                                    : package.title == "Buy 30 Gifts" ||
                                            package.title ==
                                                "Buy 30 Gifts (com.app.bmine (unreviewed))"
                                        ? "Best Value"
                                        : "",
                                style: Appstyle.quicksand15w600
                                    .copyWith(color: AppColors.blackclr)),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.blueclr,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 4),
                            child: Text(
                                '${Languages.of(context)!.savetxt} ${package.title == "Buy 15 Gifts" || package.title == "Buy 15 Gifts (com.app.bmine (unreviewed))" ? "23" : package.title == "Buy 30 Gifts" || package.title == "Buy 30 Gifts (com.app.bmine (unreviewed))" ? "39" : ""}%',
                                style: Appstyle.quicksand13w600
                                    .copyWith(color: AppColors.whiteclr)),
                          ),
                        ),
                      ],
                    ),
                  ),
                package.title != "Buy 3 Gifts" &&
                        package.title !=
                            "Buy 3 Gifts (com.app.bmine (unreviewed))"
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        child: Divider(
                          height: 1.5,
                        ),
                      )
                    : SizedBox(
                        height: 50,
                      ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 10,
                        ),
                        _buildGiftIcon(AppAssets.bouquet),
                        Spacer(),
                        _buildGiftIcon(AppAssets.chocolateBox),
                        Spacer(),
                        _buildGiftIcon(AppAssets.candy),
                        Spacer(),
                        _buildGiftIcon(AppAssets.teddyBear),
                        Spacer(),
                        _buildGiftIcon(AppAssets.redWineGlass),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${package.title == "Buy 3 Gifts" || package.title == "Buy 3 Gifts (com.app.bmine (unreviewed))" ? "3" : package.title == "Buy 15 Gifts" || package.title == "Buy 15 Gifts (com.app.bmine (unreviewed))" ? "15" : package.title == "Buy 30 Gifts" || package.title == "Buy 30 Gifts (com.app.bmine (unreviewed))" ? "30" : ""} ${Languages.of(context)!.gifttxt}',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Text(
                              //     '${package.currencySymbol}${(int.parse(package.price) / 3).toStringAsFixed(2)}/ea'),
                              Text(
                                '${(package.price)} ${Languages.of(context)!.totaltxt}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildSelectGiftCard(UserGift giftModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedGiftType = null;
          });
        },
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.whiteclr,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.indexclrgreyclr, width: 1)),
          margin: EdgeInsets.symmetric(vertical: 1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
            child: Column(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 10),
                        _buildSelectGiftIcon(AppAssets.bouquet, 'bouquet',
                            giftModel.totalCount.toString()),
                        Spacer(),
                        _buildSelectGiftIcon(AppAssets.chocolateBox,
                            'chocolateBox', giftModel.totalCount.toString()),
                        Spacer(),
                        _buildSelectGiftIcon(AppAssets.candy, 'candy',
                            giftModel.totalCount.toString()),
                        Spacer(),
                        _buildSelectGiftIcon(AppAssets.teddyBear, 'teddyBear',
                            giftModel.totalCount.toString()),
                        Spacer(),
                        _buildSelectGiftIcon(AppAssets.redWineGlass,
                            'redWineGlass', giftModel.totalCount.toString()),
                        SizedBox(width: 10),
                      ],
                    ),
                    SizedBox(height: 35),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              '${giftModel.totalCount} ${Languages.of(context)!.giftsavailabletxt}',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
    // ListView.builder(
    //   shrinkWrap: true,
    //   physics: NeverScrollableScrollPhysics(),
    //   itemCount: filteredGifts.length,
    //   itemBuilder: (context, index) {
    //     return Padding(
    //       padding: const EdgeInsets.only(top: 10),
    //       child: InkWell(
    //         onTap: () {
    //           setState(() {
    //             selectedPlan = index;
    //             selectedGiftType = null;
    //           });
    //         },
    //         child: Container(
    //           decoration: BoxDecoration(
    //               color: AppColors.whiteclr,
    //               borderRadius: BorderRadius.circular(15),
    //               border: Border.all(
    //                   color: selectedPlan == index
    //                       ? AppColors.blueclr
    //                       : AppColors.indexclrgreyclr,
    //                   width: selectedPlan == index ? 1.8 : 1)),
    //           margin: EdgeInsets.symmetric(vertical: 1),
    //           child: Padding(
    //             padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
    //             child: Column(
    //               children: [
    //                 Column(
    //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                   children: [
    //                     Row(
    //                       mainAxisAlignment: MainAxisAlignment.center,
    //                       children: [
    //                         SizedBox(width: 10),
    //                         _buildSelectGiftIcon(AppAssets.bouquet, 'bouquet',
    //                             index, filteredGifts[index].count),
    //                         Spacer(),
    //                         _buildSelectGiftIcon(
    //                             AppAssets.chocolateBox,
    //                             'chocolateBox',
    //                             index,
    //                             filteredGifts[index].count),
    //                         Spacer(),
    //                         _buildSelectGiftIcon(AppAssets.candy, 'candy',
    //                             index, filteredGifts[index].count),
    //                         Spacer(),
    //                         _buildSelectGiftIcon(AppAssets.teddyBear,
    //                             'teddyBear', index, filteredGifts[index].count),
    //                         Spacer(),
    //                         _buildSelectGiftIcon(
    //                             AppAssets.redWineGlass,
    //                             'redWineGlass',
    //                             index,
    //                             filteredGifts[index].count),
    //                         SizedBox(width: 10),
    //                       ],
    //                     ),
    //                     SizedBox(height: 35),
    //                     Padding(
    //                       padding: const EdgeInsets.symmetric(horizontal: 10),
    //                       child: Row(
    //                         crossAxisAlignment: CrossAxisAlignment.start,
    //                         mainAxisAlignment: MainAxisAlignment.center,
    //                         children: [
    //                           Text(
    //                               '${filteredGifts[index].count} ${Languages.of(context)!.giftsavailabletxt}',
    //                               style: TextStyle(
    //                                   fontSize: 18,
    //                                   fontWeight: FontWeight.bold)),
    //                         ],
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //                 SizedBox(height: 8),
    //               ],
    //             ),
    //           ),
    //         ),
    //       ),
    //     );
    //   },
    // );
  }

  Widget _buildGiftIcon(String icon) {
    return Image.asset(
      icon,
      width: 45,
      height: 45,
    );
  }

  Widget _buildSelectGiftIcon(
      String iconPath, String giftKey, String? availableCount) {
    bool isSelected = selectedGiftType == giftKey;

    return InkWell(
      onTap: () {
        setState(() {
          selectedGiftType = isSelected ? null : giftKey;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.blueclr, width: 2)
                  : null,
            ),
            child: Image.asset(
              iconPath,
              width: 40,
              height: 40,
            ),
          ),
        ],
      ),
    );
  }

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
  }

  buyGiftsApi(
    String count,
    String total,
    String verificationToken,
    String payment_id,
  ) async {
    setState(() {
      isLoading = true;
    });
    getuserid();
    isInternetAvailable().then((isConnected) async {
      if (isConnected) {
        await Provider.of<PurchaseViewModel>(context, listen: false)
            .buyGiftsApi(userid, count, total, verificationToken, payment_id);
        if (Provider.of<PurchaseViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<PurchaseViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              ForgotPasswordResponseModel model =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .buygiftsresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
            Navigator.pop(context);
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .buygiftsresponse
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

  sendGifttoFriendApi(String to_id, String quantity, String gift_type) async {
    setState(() {
      isLoading = true;
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
              isLoading = false;
              ForgotPasswordResponseModel model =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .sendgiftsresponse
                      .response as ForgotPasswordResponseModel;
              // showToast(model.message!);
            });
            Navigator.pop(context, "send-gift");
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .sendgiftsresponse
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

  getPurchaseDetailsAPI() async {
    setState(() {
      isReqLoading = true;
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
              isReqLoading = false;
              purchaseDetailsResponseModel =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .purchasedetailsresponse
                      .response as PurchaseDetailsResponseModel;
            });
          } else {
            setState(() {
              isReqLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .purchasedetailsresponse
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
}
