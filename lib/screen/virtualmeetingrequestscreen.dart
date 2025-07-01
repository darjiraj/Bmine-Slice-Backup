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
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VirtualMeetingRequestsScreen extends StatefulWidget {
  const VirtualMeetingRequestsScreen({super.key});

  @override
  State<VirtualMeetingRequestsScreen> createState() =>
      _VirtualMeetingRequestsScreenState();
}

class _VirtualMeetingRequestsScreenState
    extends State<VirtualMeetingRequestsScreen> {
  int selectedPlan = 0;
  String userid = "";
  bool isLoading = false;
  bool isProductLoading = false;

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
      'com.buy.3virtualmeetings',
      'com.buy.15virtualmeetings',
      'com.buy.30virtualmeetings',
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
          buyVirtualMeetingRequestApi(
            purchase.productID == "com.buy.3virtualmeetings"
                ? "3"
                : purchase.productID == "com.buy.15virtualmeetings"
                    ? "15"
                    : purchase.productID == "com.buy.30virtualmeetings"
                        ? "30"
                        : "",
            purchase.productID == "com.buy.3virtualmeetings"
                ? "13.99"
                : purchase.productID == "com.buy.15virtualmeetings"
                    ? "54.00"
                    : purchase.productID == "com.buy.30virtualmeetings"
                        ? "84.90"
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
                              AppColors.signinclr1,
                              AppColors.signinclr2
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
    print("package == ${package.title}");

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
                if (package.title != "Buy 3 Virtual Meetings" &&
                    package.title !=
                        "Buy 3 Virtual Meetings (com.app.bmine (unreviewed))")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        package.title.isEmpty
                            ? Container()
                            : Text(
                                package.title == "Buy 15 Virtual Meetings" ||
                                        package.title ==
                                            "Buy 15 Virtual Meetings (com.app.bmine (unreviewed))"
                                    ? "Popular"
                                    : package.title ==
                                                "Buy 30 Virtual Meetings" ||
                                            package.title ==
                                                "Buy 30 Virtual Meetings (com.app.bmine (unreviewed))"
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
                                '${Languages.of(context)!.savetxt} ${package.title == "Buy 15 Virtual Meetings" || package.title == "Buy 15 Virtual Meetings (com.app.bmine (unreviewed))" ? "23" : package.title == "Buy 30 Virtual Meetings" || package.title == "Buy 30 Virtual Meetings (com.app.bmine (unreviewed))" ? "39" : ""}%',
                                style: Appstyle.quicksand13w600
                                    .copyWith(color: AppColors.whiteclr)),
                          ),
                        ),
                      ],
                    ),
                  ),
                package.title != "Buy 3 Virtual Meetings" &&
                        package.title !=
                            "Buy 3 Virtual Meetings (com.app.bmine (unreviewed))"
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
                              '${package.title == "Buy 3 Virtual Meetings" || package.title == "Buy 3 Virtual Meetings (com.app.bmine (unreviewed))" ? "3" : package.title == "Buy 15 Virtual Meetings" || package.title == "Buy 15 Virtual Meetings (com.app.bmine (unreviewed))" ? "15" : package.title == "Buy 30 Virtual Meetings" || package.title == "Buy 30 Virtual Meetings (com.app.bmine (unreviewed))" ? "30" : ""} ${Languages.of(context)!.virtulemeetingstxt}',
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

  buyVirtualMeetingRequestApi(
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
            .buyVirtualMeetingRequestApi(
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
                      .buyvirtualmeetingrequestresponse
                      .response as ForgotPasswordResponseModel;
              showToast(model.message!);
            });
            Navigator.pop(context);
          } else {
            setState(() {
              isLoading = false;
            });
            showToast(Provider.of<PurchaseViewModel>(context, listen: false)
                .buyvirtualmeetingrequestresponse
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
