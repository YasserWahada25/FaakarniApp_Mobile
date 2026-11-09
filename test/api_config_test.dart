import 'dart:convert';

import 'package:fakarniapp/core/config/api_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bundle serving one in-memory `config/dev.json`.
class _ConfigBundle extends CachingAssetBundle {
  _ConfigBundle(this.json);

  final String? json;

  @override
  Future<ByteData> load(String key) async {
    if (json == null) throw StateError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(json!)));
  }
}

void main() {
  test('config/dev.json sets the gateway URL; placeholders and a missing file keep the defaults', () async {
    await ApiConfig.load(_ConfigBundle(null));
    expect(ApiConfig.baseUrl, 'http://10.0.2.2:8090');

    await ApiConfig.load(_ConfigBundle('{"API_BASE_URL": "<codespace>", "PATIENT_ID": "<id>"}'));
    expect(ApiConfig.baseUrl, 'http://10.0.2.2:8090');
    expect(ApiConfig.patientId, 'mobile-demo-patient');

    await ApiConfig.load(_ConfigBundle('{"API_BASE_URL": "https://demo-8090.app.github.dev", "PATIENT_ID": "p1"}'));
    expect(ApiConfig.baseUrl, 'https://demo-8090.app.github.dev');
    expect(ApiConfig.patientId, 'p1');
    expect(ApiConfig.uri('/api/events').toString(), 'https://demo-8090.app.github.dev/api/events');
  });
}
