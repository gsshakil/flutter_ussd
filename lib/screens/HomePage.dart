import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ussd_service/ussd_service.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String ussdResponse;
  String _mobileNumber = '';
  String balance;
  List<SimCard> _simCard = <SimCard>[];
  makeMyRequest() async {
    int subscriptionId = 1; // sim card subscription ID
    String code = "*152#"; // ussd code payload
    if (await Permission.phone.request().isGranted) {
      try {
        String ussdResponseMessage = await UssdService.makeRequest(
          subscriptionId,
          code,
          Duration(seconds: 10), // timeout (optional) - default is 10 seconds
        );
        print("succes! message: $ussdResponseMessage");
        setState(() {
          ussdResponse = ussdResponseMessage.toString();
        });
      } catch (e) {
        debugPrint("error! code: ${e.code} - message: ${e.message}");
      }
    }
  }

  Future<void> initMobileNumberState() async {
    if (!await MobileNumber.hasPhonePermission) {
      await MobileNumber.requestPhonePermission;
      return;
    }
    String mobileNumber = '+880152358388';
    try {
      mobileNumber = (await MobileNumber.mobileNumber);
      print('Mobile Number: $mobileNumber');
      _simCard = (await MobileNumber.getSimCards);
       final List<SimCard> simCards = await MobileNumber.getSimCards;
    return simCards;
    } on PlatformException catch (e) {
      debugPrint("Failed to get mobile number because of '${e.message}'");
    }

    if (!mounted) return;

    setState(() {
      _mobileNumber = mobileNumber;
    });
  }

  @override
  void initState() {
    super.initState();
    MobileNumber.listenPhonePermission((isPermissionGranted) {
      if (isPermissionGranted) {
        initMobileNumberState();
      } else {}
    });

    initMobileNumberState();
    makeMyRequest();
  }

  Widget fillCards() {
    List<Widget> widgets = _simCard
        .map((SimCard sim) => Text(
            'Sim Card Number: (${sim.countryPhonePrefix}) - ${sim.number}\nCarrier Name: ${sim.carrierName}\nCountry Iso: ${sim.countryIso}\nDisplay Name: ${sim.displayName}\nSim Slot Index: ${sim.slotIndex}\n\n'))
        .toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: widgets,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ussdResponse != null) {
      List<String> res = ussdResponse.split(' ');
      setState(() {
        balance = res[3];
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('My Phone'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 40,
                child: Center(
                  child: Text(
                    'Balance',
                    style: Theme.of(context).textTheme.bodyText1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Divider(),
              Container(
                padding: EdgeInsets.all(20),
                child: ussdResponse != null
                    ? Text(
                        ussdResponse,
                        style: Theme.of(context).textTheme.headline5,
                      )
                    : Text('No data found'),
              ),
              Divider(),
              SizedBox(
                height: 10,
              ),
              Text(
                'My Phone Number',
                style: Theme.of(context).textTheme.bodyText1,
              ),
              SizedBox(
                height: 10,
              ),
              (_mobileNumber != null || _mobileNumber.isNotEmpty)
                  ? Text(
                      '+880167712749',
                      style: Theme.of(context).textTheme.headline5,
                    )
                  : Text('No number found'),
              Divider(),
              SizedBox(
                height: 10,
              ),
              fillCards(),
            ],
          ),
        ),
      ),
    );
  }
}
