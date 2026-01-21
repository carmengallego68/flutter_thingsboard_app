import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';
import 'package:thingsboard_app/config/routes/router.dart';
import 'package:thingsboard_app/core/context/tb_context.dart';

import 'wifi_page.dart';

class WiFiRoutes extends TbRoutes {
  late final wifiHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
      var fullscreen = params['fullscreen']?.first == 'true';
      return WiFiPage(tbContext, fullscreen: fullscreen);
    },
  );

  WiFiRoutes(TbContext tbContext) : super(tbContext);

  @override
  void doRegisterRoutes(router) {
    router.define('/wifi', handler: wifiHandler);
  }
}
