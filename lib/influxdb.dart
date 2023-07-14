import 'dart:async';
import 'dart:collection';

import 'package:influxdb_client/api.dart';

class InfluxStream {
  StreamController fetchDoneController = StreamController.broadcast();

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

  final Map<String, String> sensors = HashMap();

  void get_records(Timer t) async {
    var stream = await queryService.query(fluxQuery);
    stream.listen((record) {
      String field = record['_field'].toString();
      String value = record['_value'].toString();
      sensors.addAll({field : value});
    }, onError: (e) {
      print('Error $e');
    }, onDone: () => {}, cancelOnError: false);
  }
  void timerInit(){
    Timer.periodic(const Duration(seconds: 30),get_records);
  }
}