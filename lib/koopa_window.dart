import 'dart:collection';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:influxdb_client/api.dart';
import 'grafana_webview.dart';
import 'package:url_launcher/url_launcher.dart';

void koopa(String title, BuildContext context){
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => KoopaWindow(title: title,)),
  );
}

class KoopaWindow extends StatefulWidget {
  const KoopaWindow({
    super.key,
    required this.title
  });

  final String title;

  @override
  State<KoopaWindow> createState() => _KoopaWindowState();
}

class _KoopaWindowState extends State<KoopaWindow> {
  late Timer queryTimer;
  String temp0 = "";
  String humidity0 = "";
  String temp1 = "";
  String humidity1 = "";
  bool lights = false;
  bool heater = false;

  var queryService = InfluxDBClient(
    url: 'https://eu-central-1-1.aws.cloud2.influxdata.com',
    token: 'uMA54OIJ6S4KYGf15s9pCMMbdYtZ760XrMvVG5LwbKyQChoOk0aodvzVEdfGZ8vobsJfWLibqpA_WRyN6iI3Kw==',
    org: 'Koopa',
    bucket: 'Koopa Data',
  ).getQueryService();
  var fluxQuery = '''
  from(bucket: "Koopa Data")
  |> range(start: 0)
  |> last()
  ''';

  //TODO use attribute setter to abstract this into a loop
  void _handleDataReceived(Map<String,String> data) {
    setState(() {
      temp0 = data['temp0']!;
      humidity0 = data['humidity0']!;
      temp1 = data['temp1']!;
      humidity1 = data['humidity1']!;
      lights = data['lights'] == '1.0' ? true : false;
      heater = data['heater'] == '1.0' ? true : false;
    });
  }

  final Map<String, String> sensors = HashMap();

  void getRecords(Timer? t) async {
    var stream = await queryService.query(fluxQuery);
    stream.listen((record) {
      String field = record['_field'].toString();
      String value = record['_value'].toString();
      sensors.addAll({field : value});
    }, onError: (e) {
      print('Error $e');
    }, onDone: () => _handleDataReceived(sensors), cancelOnError: false);
  }

  void grafanaWebview(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WebViewApp()),
    );
  }

  Future<void> _launchUrl() async {
    Uri _url = Uri.parse('https://koopa.grafana.net/d/JoROtTf4z/koopa-s-vivarium?orgId=1&from=now-24h&to=now');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  void initState() {
    super.initState();
    getRecords(null);
    queryTimer = Timer.periodic(const Duration(seconds: 30),getRecords);
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.amber,
          centerTitle: true,
        ),
        body: Center(
            child: GridView.count(
              primary: false,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 2,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        const Icon(
                          Icons.thermostat_rounded, size: 80, color: Colors.deepOrangeAccent,
                        ),
                        Text(temp0 == "" ? "":"$temp0 °C", style: const TextStyle(fontSize: 30))
                      ],
                    )
                  )
                ),
                Container(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                        child: Column(
                          children: <Widget>[
                            const Icon(
                              Icons.water_drop, size: 80, color: Colors.indigoAccent,
                            ),
                            Text(humidity0 == "" ? "":"$humidity0 %RH", style: const TextStyle(fontSize: 30))
                          ],
                        )
                    )
                ),
                Container(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                        child:
                        lights?
                            const Icon(
                                Icons.lightbulb_sharp, size: 100, color: Colors.yellow):
                            const Icon(
                                Icons.lightbulb_outline_sharp, size: 100, color: Colors.grey)
                        )
                    ),
                Container(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                        child:
                        heater?
                        const Icon(
                            Icons.waves_sharp, size: 100, color: Colors.redAccent):
                        const Icon(
                            Icons.waves_sharp, size: 100, color: Colors.grey)
                    )
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: InkWell(
                      onTap: _launchUrl,
                      child: const Text(
                        'Analytics',
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        )
                      )
                    )
                  )
                )
              ],
            )
        )
    );
  }

  @override
  void dispose() {
    super.dispose();
    queryTimer.cancel();
  }
}



