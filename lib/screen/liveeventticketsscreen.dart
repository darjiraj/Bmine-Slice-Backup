import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/commonfunctions.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/models/forgotpasswordresponsemodel.dart';
import 'package:bmine_slice/screen/base_screen.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveEventTicketsScreen extends StatefulWidget {
  const LiveEventTicketsScreen({super.key});

  @override
  State<LiveEventTicketsScreen> createState() => _LiveEventTicketsScreenState();
}

class _LiveEventTicketsScreenState extends State<LiveEventTicketsScreen> {
  int selectedPlan = 0;
  String userid = "";
  bool isLoading = false;
  bool isProductLoading = false;

  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];

  void initStore() async {
    final bool available = await _iap.isAvailable();
    if (!available) return;
    setState(() {
      isProductLoading = true;
    });
    const Set<String> kIds = {
      'com.buy.1liveeventticket',
      'com.buy.3liveeventticket',
      'com.buy.5liveeventticket',
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

          buyLiveEventTicketsApi(
            purchase.productID == "com.buy.1liveeventticket"
                ? "1"
                : purchase.productID == "com.buy.3liveeventticket"
                    ? "3"
                    : purchase.productID == "com.buy.5liveeventticket"
                        ? "5"
                        : "",
            purchase.productID == "com.buy.1liveeventticket"
                ? "39.99"
                : purchase.productID == "com.buy.3liveeventticket"
                    ? "99.99"
                    : purchase.productID == "com.buy.5liveeventticket"
                        ? "129.99"
                        : "",
            purchase.verificationData.serverVerificationData,
            purchase.purchaseID ?? "",
          );
        } else if (purchase.status == PurchaseStatus.error) {}
      }
    });
  }

  void buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  @override
  void initState() {
    super.initState();
    initStore();
    listenToPurchaseUpdates();
  }

  @override
  Widget build(BuildContext context) {
    var kSize = MediaQuery.of(context).size;
    return BaseScreen(
      child: Scaffold(
        backgroundColor: AppColors.whiteclr,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                  isProductLoading
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
                            return _buildPackageCard(_products[index], index);
                          },
                        ),
                  SizedBox(height: 16),
                  Center(
                    child: InkWell(
                      onTap: () async {
                        buyProduct(_products[selectedPlan]);
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
                              // AppColors.signinclr1,
                              // AppColors.signinclr2
                              AppColors.gradientclr1,
                              AppColors.gradientclr2
                            ],
                          ),
                        ),
                        child: Center(
                            child: Text(Languages.of(context)!.continuetxt,
                                style: Appstyle.quicksand16w500)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(ProductDetails package, int index) {
    print(
        "package ===  ${package.rawPrice} ${package.title} ${package.price} ${package.currencyCode}");
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
                if (package.title != "Buy 1 Live Event Tickets" &&
                    package.title !=
                        "Buy 1 Live Event Tickets (com.app.bmine (unreviewed))" &&
                    package.title !=
                        "Buy 1 Live Event Tickets (Bmine Dating app-Chat&Invites)")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        package.title.isEmpty
                            ? Container()
                            : Text(
                                // package.title.contains(
                                //             "Buy 3 Live Event Tickets") ||
                                //         package.title ==
                                //             "Buy 3 Live Event Tickets" ||
                                //         package.title ==
                                //             "Buy 3 Live Event Tickets (com.app.bmine (unreviewed))"
                                //     ? "Popular"
                                //     : package.title.contains(
                                //                 "Buy 5 Live Event Tickets") ||
                                //             package.title ==
                                //                 "Buy 5 Live Event Tickets" ||
                                //             package.title ==
                                //                 "Buy 5 Live Event Tickets (com.app.bmine (unreviewed))"
                                //         ? "Best Value"
                                //         : "",
                                package.title
                                        .contains("Buy 3 Live Event Tickets")
                                    ? "Popular"
                                    : package.title.contains(
                                            "Buy 5 Live Event Tickets")
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
                                // '${Languages.of(context)!.savetxt} ${package.title.contains("Buy 3 Live Event Tickets") || package.title == "Buy 3 Live Event Tickets" || package.title == "Buy 3 Live Event Tickets (com.app.bmine (unreviewed))" ? "23" : package.title.contains("Buy 5 Live Event Tickets") || package.title == "Buy 5 Live Event Tickets" || package.title == "Buy 5 Live Event Tickets (com.app.bmine (unreviewed))" ? "39" : ""}%',
                                '${Languages.of(context)!.savetxt} ${package.title.contains("Buy 3 Live Event Tickets") ? "23" : package.title.contains("Buy 5 Live Event Tickets") ? "39" : ""}%',
                                style: Appstyle.quicksand13w600
                                    .copyWith(color: AppColors.whiteclr)),
                          ),
                        ),
                      ],
                    ),
                  ),
                (package.title != "Buy 1 Live Event Tickets" &&
                        package.title !=
                            "Buy 1 Live Event Tickets (com.app.bmine (unreviewed))" &&
                        package.title !=
                            "Buy 1 Live Event Tickets (Bmine Dating app-Chat&Invites)")
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              // '${package.title.contains("Buy 1 Live Event Tickets") || package.title == "Buy 1 Live Event Tickets" || package.title == "Buy 1 Live Event Tickets (com.app.bmine (unreviewed))" ? "1" : package.title.contains("Buy 3 Live Event Tickets") || package.title == "Buy 3 Live Event Tickets" || package.title == "Buy 3 Live Event Tickets (com.app.bmine (unreviewed))" ? "3" : package.title.contains("Buy 5 Live Event Tickets") || package.title == "Buy 5 Live Event Tickets" || package.title == "Buy 5 Live Event Tickets (com.app.bmine (unreviewed))" ? "5" : ""} ${Languages.of(context)!.liveeventticketstxt}',
                              '${package.title.contains("Buy 1 Live Event Tickets") ? "1" : package.title.contains("Buy 3 Live Event Tickets") ? "3" : package.title.contains("Buy 5 Live Event Tickets") ? "5" : ""} ${Languages.of(context)!.liveeventticketstxt}',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Text('\$${package.pricePerItem}/ea'),
                              Text(
                                '${package.price} ${Languages.of(context)!.totaltxt}',
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

  getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getString('userid') ?? "";
  }

  buyLiveEventTicketsApi(
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
            .buyLiveEventTicketsApi(
                userid, count, total, verificationToken, payment_id);
        if (Provider.of<PurchaseViewModel>(context, listen: false).isLoading ==
            false) {
          if (Provider.of<PurchaseViewModel>(context, listen: false)
                  .isSuccess ==
              true) {
            setState(() {
              isLoading = false;
              print("Success");
              ForgotPasswordResponseModel model =
                  Provider.of<PurchaseViewModel>(context, listen: false)
                      .buyliveeventticketresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
            Navigator.pop(context);
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .buyliveeventticketresponse
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
