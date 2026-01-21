import 'dart:async';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
//import 'package:flutter_gen/gen_l10n/messages.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:thingsboard_app/core/context/tb_context.dart';
import 'package:thingsboard_app/core/context/tb_context_widget.dart';
//import 'package:thingsboard_app/modules/profile/change_password_page.dart';
//import 'package:thingsboard_app/thingsboard_client.dart';
import 'package:thingsboard_app/widgets/tb_app_bar.dart';
import 'package:thingsboard_app/utils/ui/tb_text_styles.dart';
//import 'package:thingsboard_app/widgets/tb_progress_indicator.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';
//import 'package:plugin_wifi_connect/plugin_wifi_connect.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class WiFiPage extends TbPageWidget {
  final bool _fullscreen;

  WiFiPage(
    TbContext tbContext, {
    bool fullscreen = false,
    super.key,
  })  : _fullscreen = fullscreen,
        super(tbContext);

  @override
  State<StatefulWidget> createState() => _WiFiPageState();
}

class _WiFiPageState extends TbPageState<WiFiPage> {
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  bool shouldCheckCan = true;
  bool get isStreaming => subscription != null;

  //final _isLoadingNotifier = ValueNotifier<bool>(true);

  final _bridgeFormKey = GlobalKey<FormBuilderState>();

  //User? _currentUser;


  /// Show snackbar.
  void kShowSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

 Future<void> _startScan(BuildContext context) async {
    // check if "can" startScan
    if (shouldCheckCan) {
      // check if can-startScan
      final can = await WiFiScan.instance.canStartScan();
      // if can-not, then show error
      if (can != CanStartScan.yes) {
        if (context.mounted) kShowSnackBar(context, "No se puede iniciar el escaneo: $can");
        return;
      }
    }

    // call startScan API
    final result = await WiFiScan.instance.startScan();
    if (context.mounted) kShowSnackBar(context, "Escaneando: $result");
    // reset access points.
    setState(() => accessPoints = <WiFiAccessPoint>[]);
  }

  Future<bool> _canGetScannedResults(BuildContext context) async {
    if (shouldCheckCan) {
      // check if can-getScannedResults
      final can = await WiFiScan.instance.canGetScannedResults();
      // if can-not, then show error
      if (can != CanGetScannedResults.yes) {
        if (context.mounted) {
          kShowSnackBar(context, "No se han podido obtener resultados: $can");
        }
        accessPoints = <WiFiAccessPoint>[];
        return false;
      }
    }
    return true;
  }


  Future<void> _getScannedResults(BuildContext context) async {
    if (await _canGetScannedResults(context)) {
      // get scanned results
      final results = await WiFiScan.instance.getScannedResults();
      setState(() => accessPoints = results);
    }
  }

  Future<void> _startListeningToScanResults(BuildContext context) async {
    if (await _canGetScannedResults(context)) {
      subscription = WiFiScan.instance.onScannedResultsAvailable
          .listen((result) => setState(() => accessPoints = result));
    }
  }


  void _stopListeningToScanResults() {
    subscription?.cancel();
    setState(() => subscription = null);
  }


  @override
  void initState() {
    super.initState();
    //_loadUser();
  }

  @override
  void dispose() async {
    super.dispose();
    // stop subscription for scanned results
    _stopListeningToScanResults();

      bool isConnected = await WiFiForIoTPlugin.isConnected();
      if (isConnected) {
          WiFiForIoTPlugin.disconnect();
      }
  }


  // build toggle with label
  Widget _buildToggle({
    String? label,
    bool value = false,
    ValueChanged<bool>? onChanged,
    Color? activeColor,
  }) =>
      Row(
        children: [
          if (label != null) Text(label),
          Switch(value: value, onChanged: onChanged, activeColor: activeColor),
        ],
      );

      
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF091D30),
      //backgroundColor: Colors.white,
      appBar: TbAppBar(
        tbContext,
        title: const Text('Configuración'),
        actions: [
          _buildToggle(
                label: "Realizar escaneo ?",
                value: shouldCheckCan,
                onChanged: (v) => setState(() => shouldCheckCan = v),
                activeColor: Colors.purple)
        ],
      ),
      body: Builder(
        builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.perm_scan_wifi),
                      label: const Text('Escanear'),
                      onPressed: () async => _startScan(context),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Resultados'),
                      onPressed: () async => _getScannedResults(context),
                    ),
                    _buildToggle(
                      label: "STREAM",
                      value: isStreaming,
                      onChanged: (shouldStream) async => shouldStream
                          ? await _startListeningToScanResults(context)
                          : _stopListeningToScanResults(),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: Center(
                    child: accessPoints.isEmpty
                        ? const Text("No hay resultados", style: TextStyle(color: Colors.orange))
                        : ListView.builder(
                            itemCount: accessPoints.length,
                            itemBuilder: (context, i) =>
                                _AccessPointTile(accessPoint: accessPoints[i])),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}



/// Show tile for AccessPoint.
///
/// Can see details when tapped.
class _AccessPointTile extends StatelessWidget {
  final WiFiAccessPoint accessPoint;

  _AccessPointTile({Key? key, required this.accessPoint})
      : super(key: key);

  final _accessPointFormKey = GlobalKey<FormBuilderState>();

  final _showPasswordNotifier = ValueNotifier<bool>(false);

  final TextEditingController _pwdController = TextEditingController();

  final _storage = const FlutterSecureStorage();

  String _pwd = '';

  Future<void> _readFromStorage(ssid) async {
    _pwdController.text = await _storage.read(key: ssid) ?? '';
    _pwd = _pwdController.text;
print('_readFromStorage> PASSWORD: $_pwd::');
  }


  Future<void> _showAlert(BuildContext context, String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<bool> _onConectar(BuildContext context, String ssid) async {
      String pwd = _pwdController.text;
      if (pwd != _pwd) {
        //_usernameController.text = username;
        await _storage.write(key: ssid, value: pwd);
print('_onConectar> GRABANDO PWD: $pwd');
      }
// NO VALE
//pwd = "3KMYUUYJS6JRXRAJ";
      bool isConnected = await WiFiForIoTPlugin.connect(
          ssid,
          password: pwd,
          security: NetworkSecurity.WPA,
      );
      return isConnected;
  }


  Future<bool> _conectadoCon(String ssid) async {
      bool conectado = await WiFiForIoTPlugin.isConnected();
print('_conectadoCon> conectado=$conectado');
      if (conectado) {
          String? wifiSSID = await WiFiForIoTPlugin.getSSID();
print('_conectadoCon> wifiSSID=$wifiSSID');
          if (wifiSSID == ssid) {
              return true;
          }
          /*
          bool isConnected = await WiFiForIoTPlugin.isRegisteredWifiNetwork(
              ssid,
          );
print('_conectadoCon> isConnected=$isConnected');
          return isConnected;
          */
      } 
      return false;
  }


  /*
  Future<void> _onConectar(BuildContext context, String ssid) async {
      String pwd = _pwdController!.text;
  print('_onConectar> ssid=$ssid : pwd=$pwd');
      if (Platform.isAndroid) {
          await PluginWifiConnect.activateWifi();
      }
      bool? connected = await PluginWifiConnect.connectToSecureNetwork(ssid, pwd);
      if (connected!) {
  print('_onConectar> CONECTADO');
          if (context.mounted) {
              Navigator.popAndPushNamed(context, '/bridgeWs');
          }
      } else {
  print('_onConectar> ERROR EN CONEXION');
          if (context.mounted) {
              _showAlert(context, 'ERROR', 'Ha fallado la conexión con la Red WiFi');
              Navigator.pop(context);
          }
      }
  }
  */

  // build row that can display info, based on label: value pair.
  /*
  Widget _buildInfo(String label, dynamic value) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey)),
        ),
        child: Row(
          children: [
            Text(
              "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(child: Text(value.toString()))
          ],
        ),
      );
      */

  @override
  Widget build(BuildContext context) {
    final title = accessPoint.ssid.isNotEmpty ? accessPoint.ssid : "**EMPTY**";
    final signalIcon = accessPoint.level >= -80
        ? Icons.signal_wifi_4_bar
        : Icons.signal_wifi_0_bar;
    _readFromStorage(accessPoint.ssid);
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(signalIcon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(accessPoint.capabilities, style: TextStyle(color: Colors.white)),
      onTap: () async {
        bool conectadoCon = await _conectadoCon(accessPoint.ssid);
        if (conectadoCon) {
            if (context.mounted) {
                Navigator.popAndPushNamed(context, '/wifiWs');
            }
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: 
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[

                      ValueListenableBuilder(
                          valueListenable: _showPasswordNotifier,
                          builder: (
                            BuildContext context,
                            bool showPassword,
                            child,
                          ) {
                            return FormBuilderTextField(
                                name: 'password',
                                controller: _pwdController,
                                //initialValue: _password,
                                obscureText: !showPassword,
                                style: const TextStyle(color: Colors.black),
                                validator: FormBuilderValidators.compose(
                                    [
                                        FormBuilderValidators.required(
                                            errorText: 'Campo Obligatorio: Contraseña',
                                        ),
                                    ],
                                ),
                                decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        showPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                    ),
                                    color: Colors.black,
                                    onPressed: () {
                                        _showPasswordNotifier.value =
                                            !_showPasswordNotifier.value;
                                    },
                                  ),
                                  border: const OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Colors.black.withOpacity(.12),
                                      ),
                                  ),
                                  labelText: 'Contraseña',
                                  labelStyle: 
                                      TbTextStyles.bodyLarge.copyWith(
                                          color: Colors.black.withOpacity(.54),
                                      ),
                                ),
                            );
                        },
                      ),


                      /*
                      TextField(
                          decoration: InputDecoration(hintText: "Introduce Contraseña", hintStyle: TextStyle(fontSize: 12)),
                          controller: _c,
                      ),
                      */
                      const SizedBox(height: 24),
                      Row(
                        spacing: 10,
                        children: [
                          Expanded(child: 
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.centerLeft,
                                  //backgroundColor: Colors.blueGrey,
                                  backgroundColor: Colors.black45,
                                  textStyle: const TextStyle(color: Colors.white)
                                ),
                                onPressed: () {
                                    Navigator.pop(context);
                                },
                                child: const Center(
                                  child: Text('Cancelar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(child: 
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () async {
                                bool isConnected = await _onConectar(context, accessPoint.ssid);
      print('_onConectar> isConnected=$isConnected');
                                if (context.mounted) {
                                    if (isConnected) {
                                        Navigator.popAndPushNamed(context, '/wifiWs');
                                    } else {
                                        Navigator.pop(context);
                                        _showAlert(context, 'ERROR', 'Ha fallado la conexión con la Red WiFi');
                                    }
                                }
                              },
                              child: const Center(
                                child: Text('Conectar', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ),
                          ),
                        ]
                      ),
                  ],
                ),
            ),
          );
        }
      },
    );
  }
}


/** 
class WiFiConnectDialog extends StatefulWidget {

  @override
  _WiFiConnectDialogState createState() => new _WiFiConnectDialogState();
}

class _WiFiConnectDialogState extends State<WiFiConnectDialog> {
  String _text = "initial";
  TextEditingController? _c;
  @override
  initState(){
    _c = new TextEditingController();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(_text),
            new RaisedButton(
              onPressed: () {
              showDialog(
                child: Dialog(
                child: Column(
                  children: <Widget>[
                    TextField(
                        decoration: new InputDecoration(hintText: "Contraseña"),
                        controller: _c,

                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                          backgroundColor: Colors.blueGrey,
                        ),
                        onPressed: () {
                            Navigator.pop(context);
                        },
                        child: Center(
                          child: Text('Cancelar', style: TextStyle(color: Colors.white)),
                        ),
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                          backgroundColor: Colors.blueGrey,
                        ),
                        onPressed: () {
                            Navigator.pop(context);
                        },
                        child: Center(
                          child: Text('Conectar', style: TextStyle(color: Colors.white)),
                        ),
                    ),
                  ],
                ),

              ), context: context);
            },
            child: new Text("Show Dialog"),)
          ],
        )
      ),
    );
  }
}
*/
