import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';
import 'package:thingsboard_app/config/routes/router.dart';
import 'package:thingsboard_app/core/context/tb_context.dart';

import 'wifiWs_page.dart';

class WiFiWsRoutes extends TbRoutes {
  late final wifiWsHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
      var fullscreen = params['fullscreen']?.first == 'true';
      return WiFiWsPage(tbContext, fullscreen: fullscreen);
    },
  );

  WiFiWsRoutes(TbContext tbContext) : super(tbContext);

  @override
  void doRegisterRoutes(router) {
    router.define('/wifiWs', handler: wifiWsHandler);
  }
}
