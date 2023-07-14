import 'dart:collection';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:influxdb_client/api.dart';
import 'grafana_webview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';
import 'dart:async';

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
enum MQTT_event {CONNECTED, GOOD_DISCONNECT, BAD_DISCONNECT, NO_DATA, SUBSCRIBED, NO_EVENT}
const MAX_MQTT_CONNECT_RETRY = 5;
const _topic = '/koopa_home';

class _KoopaWindowState extends State<KoopaWindow> {
  String temp0 = "";
  String humidity0 = "";
  String temp1 = "";
  String humidity1 = "";
  bool lights = false;
  bool heater = false;
  final client = MqttServerClient('ec2-35-176-90-64.eu-west-2.compute.amazonaws.com', '');
  MQTT_event event = MQTT_event.GOOD_DISCONNECT;
  late String mqtt_status;
  int retry_count = MAX_MQTT_CONNECT_RETRY;

  Future<void> mqtt() async {
    client.logging(on: false);
    client.setProtocolV311();
    client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 2000;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('oppo')
        .startClean();
    print('MQTT client connecting...');

    try {
      retry_count--;
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }

    /// Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
    }
  }

  void subscribeHandler(){
    /// Ok, lets try a subscription
    print('Subscribing to $_topic');
    client.subscribe(_topic, MqttQos.atMostOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final data = pt.split(' ');
      if (data[0].contains('get_temp0')) {
        temp0 = data[1].substring(0, data[1].length - 1);
      }
      if (data[0].contains('get_humidity0')) {
        humidity0 = data[1].substring(0, data[1].length - 1);
      }
      if (data[0].contains('get_lights')) {
        lights = data[1] == '0.00' ? false : true;
      }
      if (data[0].contains('get_heater')) {
        heater = data[1] == '0.00' ? false : true;
      }
      setState(() {

      });
    });
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
    event = MQTT_event.SUBSCRIBED;
    setState(() {});
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
      event = MQTT_event.GOOD_DISCONNECT;
      setState(() {});
    } else {
      print(
          'EXAMPLE::OnDisconnected callback is unsolicited or none, this is incorrect - exiting');
      event = MQTT_event.BAD_DISCONNECT;
      setState(() {});
    }
  }

  /// The successful connect callback
  void onConnected() {
    print(
        'EXAMPLE::OnConnected client callback - Client connection was successful');
    event = MQTT_event.CONNECTED;
    setState(() {});
  }

  /// Publisher
  void publishMQTT(String msg) {
    if (client.connectionStatus!.state == MqttConnectionState.connected){
      final builder = MqttClientPayloadBuilder();
      builder.addString(msg);
      client.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload!);
      print('published $msg');
    }
  }

  Future<void> _launchGrafana() async {
    Uri _url = Uri.parse('https://koopa.grafana.net/d/JoROtTf4z/koopa-s-vivarium?orgId=1&from=now-24h&to=now');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  void initState() {
    super.initState();
    mqtt();
    // getRecords(null);
    // queryTimer = Timer.periodic(const Duration(seconds: 30),getRecords);
    // setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    switch(event){
      case MQTT_event.CONNECTED:
        mqtt_status = 'Connected';
        retry_count = MAX_MQTT_CONNECT_RETRY;
        subscribeHandler();
        event = MQTT_event.NO_EVENT;
        break;
      case MQTT_event.BAD_DISCONNECT:
        mqtt_status = 'Connection lost (bad)';
        if (retry_count > 0){
          mqtt();
          event = MQTT_event.NO_EVENT;
          break;
        }
        mqtt_status = 'Too many attempts';
        break;
      case MQTT_event.GOOD_DISCONNECT:
        mqtt_status = 'Connection lost (good)';
        event = MQTT_event.NO_EVENT;
        break;
      case MQTT_event.NO_DATA:
        mqtt_status = 'No Data';
        event = MQTT_event.NO_EVENT;
        break;
      case MQTT_event.SUBSCRIBED:
        mqtt_status = 'Connected to stream';
        publishMQTT('set_refresh 0');
        event = MQTT_event.NO_EVENT;
        break;
      default:
        event = MQTT_event.NO_EVENT;
    }
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.amber,
          title: const Text('Koopa'),
          centerTitle: true
      ),
      body: GridView.count(
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
                        Icons.thermostat_rounded, size: 80, color: Colors.deepOrangeAccent),
                    Text(temp0!=''?"$temp0 °C":'', style: const TextStyle(fontSize: 30))
                  ],
                )
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Center(
                child: Column(
                  children: <Widget>[
                    const Icon(
                      Icons.water_drop, size: 80, color: Colors.indigoAccent,),
                    Text(humidity0!=''?"$humidity0 %RH":'', style: const TextStyle(fontSize: 30))
                  ],
                )
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Center(
                child: IconButton(
                  iconSize: 100,
                  color: lights?Colors.yellow:Colors.grey,
                  icon: const Icon(Icons.lightbulb_sharp),
                  onPressed: (){publishMQTT(lights?'set_lights 0':'set_lights 1');},
                )
            ),
          ),
          Container(
              padding: const EdgeInsets.all(8),
              child: Center(
                  child: IconButton(
                    iconSize: 100,
                    color: heater?Colors.redAccent:Colors.grey,
                    icon: const Icon(Icons.waves),
                    onPressed: (){publishMQTT(heater?'set_heater 0':'set_heater 1');},
                  )
              )
          ),
          Center(
            child: InkWell(
              onTap: _launchGrafana,
              child: const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
                mqtt_status,
                style: const TextStyle(
                    fontSize: 16
                )
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    client.unsubscribe(_topic);
    client.disconnect();
    super.dispose();
  }
}



