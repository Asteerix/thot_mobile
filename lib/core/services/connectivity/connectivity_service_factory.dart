import 'package:thot/core/services/connectivity/connectivity_service.dart';
import 'package:thot/core/services/connectivity/connectivity_service.dart'
    if (dart.library.io) 'package:thot/core/services/connectivity/connectivity_service_io.dart'
    if (dart.library.js_interop) 'package:thot/core/services/connectivity/connectivity_service_web.dart'
    as impl;
export 'connectivity_service.dart' show ConnectivityService;
ConnectivityService createConnectivityService() {
  return impl.createConnectivityService();
}