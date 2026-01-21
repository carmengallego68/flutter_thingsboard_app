import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_gen/gen_l10n/messages.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:thingsboard_app/core/context/tb_context.dart';
import 'package:thingsboard_app/core/context/tb_context_widget.dart';
//import 'package:thingsboard_app/modules/profile/change_password_page.dart';
//import 'package:thingsboard_app/thingsboard_client.dart';
import 'package:thingsboard_app/widgets/tb_app_bar.dart';
import 'package:thingsboard_app/utils/ui/tb_text_styles.dart';
//import 'package:thingsboard_app/widgets/tb_progress_indicator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class WiFiWsPage extends TbPageWidget {
  final bool _fullscreen;
  final String _ssid;

  WiFiWsPage(
    TbContext tbContext, {
    bool fullscreen = false,
    String ssid = '',
    super.key,
  })  : _fullscreen = fullscreen,
        _ssid = ssid,
        super(tbContext);

  @override
  State<StatefulWidget> createState() => _WiFiWsPageState();
}

class _WiFiWsPageState extends TbPageState<WiFiWsPage> {

  final _bridgeWsFormKey = GlobalKey<FormBuilderState>();
 
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.1');
  final TextEditingController _portController = TextEditingController(text: '80');

  final TextEditingController _wifiSsidController = TextEditingController(text: '');
  final TextEditingController _wifiPassController = TextEditingController(text: '');
  final TextEditingController _apSsidController = TextEditingController(text: '');
  final TextEditingController _apPassController = TextEditingController(text: '');

  final TextEditingController _systemUserController = TextEditingController(text: '');
  final TextEditingController _systemPassController = TextEditingController(text: '');
  final TextEditingController _deviceIdController = TextEditingController(text: '');
  final TextEditingController _accessTokenController = TextEditingController(text: '');
  final TextEditingController _customerIdController = TextEditingController(text: '');
  final TextEditingController _loraIdController = TextEditingController(text: '1');

  final TextEditingController _gatewayController = TextEditingController(text: '');
  final TextEditingController _maskController = TextEditingController(text: '');
  final TextEditingController _dns1Controller = TextEditingController(text: '');
  final TextEditingController _dns2Controller = TextEditingController(text: '');

  final TextEditingController _pinController = TextEditingController(text: '');
  final TextEditingController _apnController = TextEditingController(text: '');
  final TextEditingController _apnUserController = TextEditingController(text: '');
  final TextEditingController _apnPassController = TextEditingController(text: '');

  final TextEditingController _devIdCntController = TextEditingController(text: '');
  final TextEditingController _loraIdCntController = TextEditingController(text: '');
  final TextEditingController _bridgeIdCntController = TextEditingController(text: '');

  final TextEditingController _ipCntController = TextEditingController(text: '192.168.1.1');

  //final TextEditingController _wifiSsidCntController = TextEditingController(text: '');
  //final TextEditingController _wifiPassCntController = TextEditingController(text: '');
  final TextEditingController _apSsidCntController = TextEditingController(text: '');
  final TextEditingController _apPassCntController = TextEditingController(text: '');
  //final TextEditingController _gatewayCntController = TextEditingController(text: '');
  //final TextEditingController _maskCntController = TextEditingController(text: '');
  //final TextEditingController _dns1CntController = TextEditingController(text: '');
  //final TextEditingController _dns2CntController = TextEditingController(text: '');

  final TextEditingController _offsetTaraController = TextEditingController(text: '');
  final TextEditingController _valorRefTaraController = TextEditingController(text: '');

  final TextEditingController _sensorTypeController = TextEditingController(text: '');
  final TextEditingController _sensorLoraAddrController = TextEditingController(text: '');
  final TextEditingController _sensorRdModeController = TextEditingController(text: '');


  final _showPasswordNotifier = ValueNotifier<bool>(false);
  final _showUserPassNotifier = ValueNotifier<bool>(false);
  final _showApPassNotifier = ValueNotifier<bool>(false);
  final _showPinNotifier = ValueNotifier<bool>(false);
  final _showApnPassNotifier = ValueNotifier<bool>(false);
  final _showApPassCntNotifier = ValueNotifier<bool>(false);

  final TextEditingController _tsMonitorController = TextEditingController(text: '');
  final _telemetryChange = ValueNotifier<bool>(false);
  
  static const LECTURA_PULSE = 1;      // Pulsos en un pin
  static const LECTURA_ADC = 2;        // Valor ADC (0-5V)
  static const LECTURA_MODBUS = 3;     // MODBUS
  static const LECTURA_HX711 = 4;    
  

  WebSocketChannel? _channel;

  Map<dynamic, dynamic> _nodoContent = {};
  Map<dynamic, dynamic> _nodoVersion = {};
  Map<dynamic, dynamic> _pollsContent = {};
  Map<dynamic, dynamic> _pollsConcentradores = {};
  Map<dynamic, dynamic> _pollsPolls = {};

  dynamic _concentrador = {};
  dynamic _sensoresInfo = {};
  dynamic _sensor = {};

  dynamic _telemetryData = {};

  bool _esBridge = false;
  bool _esConcentrador = false;

  String _tsTelemetry = '';
  String _valueTelemetry = '';

  /// Show snackbar.
  void kShowSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAlert(BuildContext context, String title, String message) async {
    showDialog<void>(
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


  Future<bool?> _confirmDialog(BuildContext context, String title, String message) async {
    bool? val = await showDialog<bool>(
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
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            const SizedBox(width: 12),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                  Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
    return val;
  }

  String _formatTs(int ts) {
      final DateTime timeStamp = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      String formattedDate = DateFormat('dd/NN/yyyy hh:mm:ss').format(timeStamp);
      return formattedDate;
  }

  String _formatTsNow() {
      final DateTime now = DateTime.now();
      String formattedDate = DateFormat('dd/MM/yyyy hh:mm:ss').format(now);
      return formattedDate;
  }

  bool _sendGetPollsMessage() {
      Map<dynamic, dynamic> mensaje = {
        'type': 'REQUEST',
        'action': 'get',
        'clase': 'polls',
      };
      return sendMessage(mensaje);
  }

  bool _sendPutConfigMessage(Map<dynamic, dynamic> config) {
      Map<dynamic, dynamic> mensaje = {
        'type': 'REQUEST',
        'action': 'put',
        'clase': 'configuracion',
        'data': config
      };
      return sendMessage(mensaje);
  }

  bool _onSetConfigModemBridge(BuildContext context) {
      _nodoContent['configModem']['sim_pin'] = int.parse(_pinController.text);
      _nodoContent['configModem']['apn'] = _apnController.text;
      _nodoContent['configModem']['apn_user'] = _apnUserController.text;
      _nodoContent['configModem']['apn_pass'] = _apnPassController.text;
      Map<dynamic, dynamic> configModem = { 'configModem': _nodoContent['configModem'] };
      return _sendPutConfigMessage(configModem);
  }

  void _onConfigModemBridge(BuildContext context) {
      final modem = _nodoContent['configModem'];
      _pinController.text = modem['sim_pin'].toString();
      _apnController.text = modem['apn'];
      _apnUserController.text = modem['apn_user'];
      _apnPassController.text = modem['apn_pass'];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Módem 4G'),
          content: 
            SingleChildScrollView(child:
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    FormBuilder(
                        key: _bridgeWsFormKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                //Text('Configuración 4G', style: TbTextStyles.bodyMedium),
                                ValueListenableBuilder(
                                    valueListenable: _showPinNotifier,
                                    builder: (
                                      BuildContext context,
                                      bool showPassword,
                                      child,
                                    ) {
                                      return FormBuilderTextField(
                                        name: 'pin',
                                        controller: _pinController,
                                        //initialValue: _password,
                                        obscureText: !showPassword,
                                        style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                        //style: const TextStyle(color: Colors.black),
                                        validator: FormBuilderValidators.compose(
                                          [
                                            FormBuilderValidators.required(
                                              errorText: 'Campo Obligatorio: PIN'
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
                                              _showPinNotifier.value =
                                                  !_showPinNotifier.value;
                                            },
                                          ),
                                          border: const OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  Colors.black.withOpacity(.12),
                                            ),
                                          ),
                                          labelText: 'PIN',
                                          labelStyle:
                                              TbTextStyles.bodySmall.copyWith(
                                            color: Colors.black.withOpacity(.54),
                                          ),
                                        ),
                                      );
                                    },
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'APN',
                                    controller: _apnController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo obligatorio: APN'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'APN',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'apn_user',
                                    controller: _apnUserController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Usuario APN'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Usuario APN',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                ValueListenableBuilder(
                                    valueListenable: _showApnPassNotifier,
                                    builder: (
                                      BuildContext context,
                                      bool showPassword,
                                      child,
                                    ) {
                                      return FormBuilderTextField(
                                        name: 'apn_pass',
                                        controller: _apnPassController,
                                        //initialValue: _password,
                                        obscureText: !showPassword,
                                        style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                        //style: const TextStyle(color: Colors.black),
                                        validator: FormBuilderValidators.compose(
                                          [
                                            FormBuilderValidators.required(
                                              errorText: 'Campo Obligatorio: Contraseña APN'
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
                                              _showApnPassNotifier.value =
                                                  !_showApnPassNotifier.value;
                                            },
                                          ),
                                          border: const OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  Colors.black.withOpacity(.12),
                                            ),
                                          ),
                                          labelText: 'Contraseña APN',
                                          labelStyle:
                                              TbTextStyles.bodySmall.copyWith(
                                            color: Colors.black.withOpacity(.54),
                                          ),
                                        ),
                                      );
                                    },
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(child: 
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                backgroundColor: Colors.blueGrey,
                                textStyle: const TextStyle(color: Colors.blue)
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
                              backgroundColor: Colors.blueGrey,
                            ),
                            onPressed: () async {
                                bool enviado = _onSetConfigModemBridge(context);
                                if (enviado) await _showAlert(context, 'Configuración 4G', 'La configuración se ha enviado al Bridge');
                                if (context.mounted) {
                                    Navigator.of(context).pop();
                                }
                            },
                            child: const Center(
                              child: Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ),
                      ]
                    ),

                ],
              ),
            ),
        ),
      );
  }


  bool _onSetConfigWiFiBridge(BuildContext context) {
      _nodoContent['configRed']['ip'] = _ipController.text;
      _nodoContent['configRed']['gateway'] = _gatewayController.text;
      _nodoContent['configRed']['subnet_mask'] = _maskController.text;
      _nodoContent['configRed']['dns1'] = _dns1Controller.text;
      _nodoContent['configRed']['dns2'] = _dns2Controller.text;
      _nodoContent['configRed']['ap_ssid'] = _apSsidController.text;
      _nodoContent['configRed']['ap_pass'] = _apPassController.text;
      _nodoContent['configRed']['wifi_ssid'] = _wifiSsidController.text;
      _nodoContent['configRed']['wifi_pass'] = _wifiPassController.text;
      Map<dynamic, dynamic> configRed = { 'configRed': _nodoContent['configRed'] };
      return _sendPutConfigMessage(configRed);
  }
  
  void _onConfigWiFiBridge(BuildContext context) {
      final wifi = _nodoContent['configRed'];
      _ipController.text = wifi['ip'];
      _gatewayController.text = wifi['gateway'];
      _maskController.text = wifi['subnet_mask'];
      _dns1Controller.text = wifi['dns1'];
      _dns2Controller.text = wifi['dns2'];
      _apSsidController.text = wifi['ap_ssid'];
      _apPassController.text = wifi['ap_pass'];
      _wifiSsidController.text = wifi['wifi_ssid'];
      _wifiPassController.text = wifi['wifi_pass'];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('WiFi'),
          content: 
            SingleChildScrollView(child:
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    FormBuilder(
                        key: _bridgeWsFormKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                Text('STA (Estación)', style: TbTextStyles.bodyMedium),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'wifi_ssid',
                                    controller: _wifiSsidController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo obligatorio: SSID Red WiFi'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'SSID Red WiFi',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                ValueListenableBuilder(
                                    valueListenable: _showPasswordNotifier,
                                    builder: (
                                      BuildContext context,
                                      bool showPassword,
                                      child,
                                    ) {
                                      return FormBuilderTextField(
                                        name: 'wifi_pass',
                                        controller: _wifiPassController,
                                        //initialValue: _password,
                                        obscureText: !showPassword,
                                        style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                        //style: const TextStyle(color: Colors.black),
                                        validator: FormBuilderValidators.compose(
                                          [
                                            FormBuilderValidators.required(
                                              errorText: 'Campo Obligatorio: Contraseña Red WiFi'
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
                                          labelText: 'Contraseña Red WiFi',
                                          labelStyle:
                                              TbTextStyles.bodySmall.copyWith(
                                            color: Colors.black.withOpacity(.54),
                                          ),
                                        ),
                                      );
                                    },
                                ),
                                //const SizedBox(height: 12),
                                const Divider(),
                                Text('AP (Punto Acceso)', style: TbTextStyles.bodyMedium),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'ap_ssid',
                                    controller: _apSsidController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: SSID'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'SSID',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                ValueListenableBuilder(
                                    valueListenable: _showApPassNotifier,
                                    builder: (
                                      BuildContext context,
                                      bool showPassword,
                                      child,
                                    ) {
                                      return FormBuilderTextField(
                                        name: 'ap_pass',
                                        controller: _apPassController,
                                        //initialValue: _password,
                                        obscureText: !showPassword,
                                        style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                        //style: const TextStyle(color: Colors.black),
                                        validator: FormBuilderValidators.compose(
                                          [
                                            FormBuilderValidators.required(
                                              errorText: 'Campo Obligatorio: Contraseña SSID'
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
                                              _showApPassNotifier.value =
                                                  !_showApPassNotifier.value;
                                            },
                                          ),
                                          border: const OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  Colors.black.withOpacity(.12),
                                            ),
                                          ),
                                          labelText: 'Contraseña SSID',
                                          labelStyle:
                                              TbTextStyles.bodySmall.copyWith(
                                            color: Colors.black.withOpacity(.54),
                                          ),
                                        ),
                                      );
                                    },
                                ),

                                //const SizedBox(height: 12),
                                const Divider(),
                                Text('IP Estática', style: TbTextStyles.bodyMedium),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'ip',
                                    controller: _ipController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: IP'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Dirección IP',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'gateway',
                                    controller: _gatewayController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Gateway'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Dirección Gateway',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'subnet_mask',
                                    controller: _maskController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Máscara Subred'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Máscara Subred',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'dns1',
                                    controller: _dns1Controller,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: DNS1'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'DNS1',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'dns2',
                                    controller: _dns2Controller,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: DNS2'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'DNS2',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(child: 
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                backgroundColor: Colors.blueGrey,
                                textStyle: const TextStyle(color: Colors.blue)
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
                              backgroundColor: Colors.blueGrey,
                            ),
                            onPressed: () async {
                                bool enviado =_onSetConfigWiFiBridge(context);
                                if (enviado) await _showAlert(context, 'Configuración WiFi', 'La configuración se ha enviado al Bridge');
                                if (context.mounted) {
                                    Navigator.of(context).pop();
                                }
                            },
                            child: const Center(
                              child: Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ),
                      ]
                    ),

                ],
              ),
            ),
        ),
      );
  }

  bool _onSetConfigIdentBridge(BuildContext context) {
      _nodoContent['identificacion']['device_id'] = _deviceIdController.text;
      _nodoContent['identificacion']['customer_id'] = _customerIdController.text;
      _nodoContent['identificacion']['system_user'] = _systemUserController.text;
      _nodoContent['identificacion']['system_pass'] = _systemPassController.text;
      _nodoContent['identificacion']['loraId'] = int.parse(_loraIdController.text);
      _nodoContent['identificacion']['access_token'] = _accessTokenController.text;
      Map<dynamic, dynamic> ident = { 'identificacion': _nodoContent['identificacion'] };
      return _sendPutConfigMessage(ident);
  }

  void _onConfigIdentBridge(BuildContext context) {
      final ident = _nodoContent['identificacion'];
      _deviceIdController.text = ident['device_id'];
      _customerIdController.text = ident['customer_id'];
      _systemUserController.text = ident['system_user'];
      _systemPassController.text = ident['system_pass'];
      _loraIdController.text = ident['loraId'].toString();
      _accessTokenController.text = ident['access_token'];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Identificación'),
          content: 
            SingleChildScrollView(child:
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    FormBuilder(
                        key: _bridgeWsFormKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                //Text('Identificacion', style: TbTextStyles.titleMedium),
                                FormBuilderTextField(
                                    name: 'device_id',
                                    controller: _deviceIdController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black,),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo obligatorio: Identificador Dispositivo'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Identificador Dispositivo',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'access_token',
                                    controller: _accessTokenController,
                                    //nitialValue: _username,
                                    //style: const TextStyle(color: Colors.black),
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo obligatorio: Token de Acceso'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Token de Acceso',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'access_token',
                                    controller: _loraIdController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.number,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo obligatorio: Identificador LoRa (loraId)'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Identificador LoRa',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'customer_id',
                                    controller: _customerIdController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo obligatorio: Identificador Cliente'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Identificador Cliente',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'system_user',
                                    controller: _systemUserController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo obligatorio: Identificador Usuario'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Identificador Usuario',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                ValueListenableBuilder(
                                    valueListenable: _showUserPassNotifier,
                                    builder: (
                                      BuildContext context,
                                      bool showPassword,
                                      child,
                                    ) {
                                      return FormBuilderTextField(
                                        name: 'system_pass',
                                        controller: _systemPassController,
                                        //initialValue: _password,
                                        obscureText: !showPassword,
                                        style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                        //style: const TextStyle(color: Colors.black),
                                        validator: FormBuilderValidators.compose(
                                          [
                                            FormBuilderValidators.required(
                                              errorText: 'Campo Obligatorio: Contraseña Usuario'
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
                                              _showUserPassNotifier.value =
                                                  !_showUserPassNotifier.value;
                                            },
                                          ),
                                          border: const OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  Colors.black.withOpacity(.12),
                                            ),
                                          ),
                                          labelText: 'Contraseña Usuario',
                                          labelStyle:
                                              TbTextStyles.bodySmall.copyWith(
                                            color: Colors.black.withOpacity(.54),
                                          ),
                                        ),
                                      );
                                    },
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(child: 
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                backgroundColor: Colors.blueGrey,
                                textStyle: const TextStyle(color: Colors.blue)
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
                              backgroundColor: Colors.blueGrey,
                            ),
                            onPressed: () async {
                                bool enviado = _onSetConfigIdentBridge(context);
                                if (enviado) await _showAlert(context, 'Identificación', 'La Identificación se ha enviado al Bridge');
                                if (context.mounted) {
                                    Navigator.of(context).pop();
                                }
                            },
                            child: const Center(
                              child: Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ),
                      ]
                    ),
                ],
              ),
            ),
        ),
      );
  }

  void _onConectar(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conectar con Nodo'),
          content: 
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                  Row(
                    children: [
                      Expanded(child:
                        Text('Dirección IP: ', style: TbTextStyles.bodySmall.copyWith(color: Colors.black)),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(child:
                        TextField(
                            decoration: const InputDecoration(hintText: '192.168.1.1', hintStyle: TextStyle(fontSize: 10)),
                            controller: _ipController,
                            style:  TbTextStyles.bodySmall.copyWith(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child:
                        Text('Puerto: ', style: TbTextStyles.bodySmall.copyWith(color: Colors.black)),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(child:
                        TextField(
                            decoration: const InputDecoration(hintText: '80', hintStyle: TextStyle(fontSize: 10)),
                            controller: _portController,
                            keyboardType: TextInputType.number,
                            style:  TbTextStyles.bodySmall.copyWith(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  Row(children: [
                      Expanded(child: 
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.centerLeft,
                              //backgroundColor: Colors.blueGrey,
                              backgroundColor: Colors.black45,
                              textStyle: const TextStyle(color: Colors.white)
                            ),
                            onPressed: () async => Navigator.pop(context),
                            child: const Center(
                              child: Text('Cancelar', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                        ),
                      ),
/*
                    ElevatedButton.icon(
                        icon: const Icon(Icons.wifi),
                        label: const Text('Cancelar'),
                        color: Colors.black45,
                        onPressed: () async => Navigator.pop(context),
                    ),
*/
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
                              bool conectadoWs = await _onWsConnect(context);
print('Ws:_onConectar> conectadoWs=$conectadoWs');
                              if (context.mounted) {
print('Ws:_onConectar> CERRANDO');
                                  if (conectadoWs) {
                                      Navigator.of(context).pop();
                                  } else {
                                      _showAlert(context, 'ERROR', 'No se ha podido establecer comunicación. Comprueba si la IP y el Puerto son correctos.');
                                  }
                              }
                          },
                          child: const Center(
                            child: Text('Conectar', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                      ),

/*
                      ElevatedButton.icon(
                        icon: const Icon(Icons.wifi),
                        label: const Text('Conectar'),
                        onPressed: () async => _onWsConnect(context),
                    ),
*/
                  ],),
              ],
            ),
        ),
      );
  }

  void _onWsMessage(message) async {
print('_onWsMessage> message=$message');
      final msgData = jsonDecode(message) as Map<String, dynamic>;
      if (msgData['type'] == 'RESPONSE') {
          if (msgData['action'] == 'get') {
              if (msgData['clase'] == 'configuracion') {
print('_onWsMessage> Recibida Configuración');
                  _nodoContent = msgData['content'];
                  _nodoVersion = _nodoContent['version'];
                  if (_nodoVersion['class'].startsWith('Bridge')) {
                      if (msgData.containsKey('concentradores')) {
                          _pollsConcentradores = msgData['concentradores'];
                      }
                      setState(() {
                          _esBridge = true;
                          _esConcentrador = false;
                      });
                  } else {
                      if (_nodoVersion['class'].startsWith('Concentrador')) {
                          if (_nodoContent.containsKey('sensoresInfo')) {
                              _sensoresInfo = _nodoContent['sensoresInfo'];
                          }
                          setState(() {
                              _esBridge = false;
                              _esConcentrador = true;
                          });
                      } else {
                          setState(() {
                              _esBridge = false;
                              _esConcentrador = false;
                          });
                      }
                  }
print('_onWsMessage> EsBridge=$_esBridge : Conc=$_esConcentrador');
              } else if (msgData['clase'] == 'polls') {
                  _pollsContent = msgData['content'];
                  _pollsConcentradores = _pollsContent['concentradores'];
                  _pollsPolls = _pollsContent['polls'];
              }
          }
      } else if (msgData['type'] == 'monitor') {
          setState(() {
              _telemetryData = msgData['value'];
              _tsMonitorController.text = _formatTsNow();
              _telemetryChange.value = !_telemetryChange.value;
          });
      }
  }

  bool sendTextMessage(String mensaje) {
      try {
print('sendTextMessage=$mensaje');
          _channel?.sink.add(mensaje);
          return true;
      } on WebSocketChannelException catch (e) {
          _showAlert(context, 'ERROR', 'No se ha podido enviar el mensaje: ${e.toString()}');
          return false;
      }
  }

  bool sendMessage(Map<dynamic, dynamic> mensaje) {
      final data = jsonEncode(mensaje);
      return sendTextMessage(data);
  }

  bool _sendGetConfigRequest() {
      Map<dynamic, dynamic> mensaje = {
        'type': 'REQUEST',
        'action': 'get',
        'clase': 'configuracion',
        'incluir_concentradores': 'true',
      };
      return sendMessage(mensaje);
  }

  void _onWsClose(BuildContext context) async {
      _channel?.sink.close(status.goingAway);
  }

  Future<bool> _onWsConnect(BuildContext context) async {
      String? ip = _ipController?.text;
      String? port = _portController?.text;
      String url = 'ws://$ip:$port/ws';
      //String url = 'wss://$ip:$port';
print('_onWsConnect> URL=$url');
      try {
          _channel = WebSocketChannel.connect(
              Uri.parse(url),
          );
          await _channel?.ready;

          _channel?.stream.listen((message) {
              _onWsMessage(message);
          });
          _sendGetConfigRequest();
          return true;
      } on WebSocketChannelException catch (e) {
print('_onWsConnect ERROR  : ${e.toString()}');
          return false;
      }
    }

  /*
  void _onIdent(BuildContext context) async {
  }
  */


  Future<bool> _onActivarConcentrador(BuildContext context, dynamic concentrador) async {
      // ignore: prefer_interpolation_to_compose_strings
      bool? ok = await _confirmDialog(context, 'AVISO', 'Se va a enviar una solicitud al dispositivo "'+concentrador['deviceName']+'", con Identificador Lora '+concentrador['loraId'].toString()+' (loraId), para que active su Punto de Acceso');
      if (ok!) {
          Map<dynamic, dynamic> mensaje = {
              'type': 'wifi',
              'action': 'start',
              'toLoraId': concentrador['loraId'],
          };
          return sendMessage(mensaje);
      } else {
        return false;
      }
  }

  Widget _buildConcentradoresList() {
      List<dynamic> concentradores = _pollsConcentradores['concentradores'];
    return Container(
      //height: 300.0, // Change as per your requirement
      //width: 300.0, // Change as per your requirement
      child: concentradores.isEmpty
          ? const Text("No hay resultados", style: TextStyle(color: Colors.orange))
          : ListView.builder(
        shrinkWrap: true,
        itemCount: concentradores.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title:  
                InkWell(
                    child: Text(
                        concentradores[index]['deviceName'], 
                        style: TbTextStyles.bodySmall.copyWith(color: Colors.blue.shade900),
                      ),
                    onTap: () async  {
                        await _onActivarConcentrador(context, concentradores[index]);
                        await _showAlert(context, 'Concentrador', 'Se ha enviado la petición');
                    }
                ),
          );
        },
      ),
    );
  }

  void _onConcentradores(BuildContext context) async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Concentradores'),
            content: 
                SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            _buildConcentradoresList(),
                            const SizedBox(
                              height: 20,
                            ),
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
                                  child: Text('Cerrar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                            ),
                        ]
                    ),
                ),
          );
        });
  }


  void _onReset(BuildContext context) async {
      bool? ok = await _confirmDialog(context, 'Reiniciar', 'Se va a reiniciar el Nodo');
      if (ok!) {
          Map<dynamic, dynamic> mensaje = {
              'type' : 'reset',
          };
          sendMessage(mensaje);
          if (context.mounted) {
              _showAlert(context, 'Reiniciar', 'Se ha enviado la petición al nodo');
          }
      }
  }

/*
double bigendian2float(final valor) {
  final bytes = Uint8List(4); // start with the 4 bytes = 32 bits

  var byteData = bytes.buffer.asByteData(); // ByteData lets you choose the endianness
  byteData.setInt16(0, 0, Endian.big); // Note big is the default here, but shown for completeness
  byteData.setInt16(2, valor, Endian.big);
  print(bytes); // just for debugging - does my byte order look right?
//  print(hex.encode(bytes)); // ditto

  final f32 = byteData.getFloat32(0, Endian.big);  
  return f32;
}
*/

  Widget _buildMonitorValuesList() {
    /*
    dynamic values = _telemetryData['value'];
    values ??= { 'valor': '-' };
    final valueKeys = values.keys.toList();
    */
    List valueKeys = [];
    final vKeys = _telemetryData.keys.toList();
    if (vKeys.length > 6) { valueKeys = vKeys.take(6).toList(); }
    else { valueKeys = vKeys.take(vKeys.length).toList(); }
    return Container(
      child: valueKeys.isEmpty
          ? const Text('No hay resultados', style: TextStyle(color: Colors.orange))
          : ListView.builder(
        shrinkWrap: true,
        itemCount: valueKeys.length,
        itemBuilder: (BuildContext context, int index) {
          String k = valueKeys[index];
print('_buildMonitorValuesList> key=$k');
          dynamic valor = _telemetryData[k];
print('_buildMonitorValuesList> valor=$valor');
          String texto = k + '=' + valor.toString();
          return ListTile(
            dense: true,
            title:  
                InkWell(
                    child: Text(
                        texto, 
                        style: TbTextStyles.bodySmall.copyWith(color: Colors.blue.shade900),
                      ),
                    onTap: () {
                    }
                ),
          );
        },
      ),
    );
  }

  Future<void> _onMonitorDialog(BuildContext context, dynamic sensor) async {
      String titulo = _getTipoSensor(sensor['sensorType']) + ' (loraAddr:' + sensor['loraAddr'].toString() + ')';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(titulo),
            content: 
                SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            ValueListenableBuilder(
                                valueListenable: _telemetryChange,
                                builder: (
                                  BuildContext context,
                                  bool showPassword,
                                  child,
                                ) {
                                  return FormBuilderTextField(
                                    name: 'monitor_ts',
                                    controller: _tsMonitorController,
                                    readOnly: true,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    /*
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Contraseña SSID'
                                        ),
                                      ],
                                    ),
                                    */
                                    decoration: InputDecoration(
                                      /*
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          showPassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        color: Colors.black,
                                        onPressed: () {
                                          _showApPassCntNotifier.value =
                                              !_showApPassCntNotifier.value;
                                        },
                                      ),
                                      */
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Timestamp',
                                      labelStyle:
                                          TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                  );
                                },
                          ),

                          const SizedBox(height: 12),
                          ValueListenableBuilder(
                                valueListenable: _telemetryChange,
                                builder: (
                                  BuildContext context,
                                  bool showPassword,
                                  child,
                                ) {
                                  return _buildMonitorValuesList();
                          }),
                          const SizedBox(height: 10),
                          Row(children: [
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
                                        _onStopMonitor(context, sensor);
                                        Navigator.pop(context);
                                    },
                                    child: const Center(
                                      child: Text('Detener', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                              ),
                            ],)
                        ]
                    ),
                ),
          );
        });
  }

  Future<void> _onStopMonitor(BuildContext context, dynamic sensor) async {
      //bool? ok = await _confirmDialog(context, 'Monitorizar', 'Se va a detener la monitorización del sensor');
      //if (ok!) {
          Map<dynamic, dynamic> mensaje = {
              'type' : 'monitor',
              'action' : 'stop',
              'loraAddr': sensor['loraAddr']
          };
          sendMessage(mensaje);
          if (context.mounted) {
              Navigator.of(context).pop();
          }
      ////}
  }

  Future<void> _onStartMonitor(BuildContext context, dynamic sensor) async {
      bool? ok = await _confirmDialog(context, 'Monitorizar', 'Se va a solicitar la monitorización del sensor');
      if (ok!) {
          Map<dynamic, dynamic> mensaje = {
              'type' : 'monitor',
              'action' : 'start',
              'loraAddr': sensor['loraAddr']
          };
          sendMessage(mensaje);
          if (context.mounted) {
              await _onMonitorDialog(context, sensor);
          }
          /*
          if (context.mounted) {
              _showAlert(context, 'Reiniciar', 'Se ha enviado la petición');
          }
          */
      }
  }

  Future<bool> _onSendCalibrarFactor(BuildContext context) async {
      String valorRef = _valorRefTaraController.text;
      Map<dynamic, dynamic> mensaje = {
          'type': 'REQUEST',
          'action': 'post',
          'clase': 'calibrar_factor',
          'data': {
              'loraAddr': _sensor['loraAddr'],
              'valorRef': double.parse(valorRef)
          }
      };
      return sendMessage(mensaje);
  }

  Future<void> _onCalibrarFactor(BuildContext context) async {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Calibrar Escala'),
          content: 
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                    FormBuilder(
                        key: _bridgeWsFormKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FormBuilderTextField(
                                  name: 'valorRef',
                                  controller: _valorRefTaraController,
                                  style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                  keyboardType: TextInputType.number,
                                  validator: FormBuilderValidators.compose(
                                    [
                                        FormBuilderValidators.required(
                                            errorText: 'Campo Obligatorio: Valor de Referencia'
                                        ),
                                    ],
                                  ),
                                  decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                      ),
                                    ),
                                    labelText: 'Valor de Referencia',
                                    labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                    ),
                                  ),
                              ),
                              const SizedBox(
                                  height: 24,
                              ),
                              Row(children: [
                                  Expanded(child: 
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.all(16),
                                          alignment: Alignment.centerLeft,
                                          //backgroundColor: Colors.blueGrey,
                                          backgroundColor: Colors.black45,
                                          textStyle: const TextStyle(color: Colors.white)
                                        ),
                                        onPressed: () async => Navigator.pop(context),
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
                                          _onSendCalibrarFactor(context);
                                          if (context.mounted) {
                                              Navigator.of(context).pop();
                                          }
                                      },
                                      child: const Center(
                                        child: Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                        ),
                  ),
                ],
            ),
        ),
      );
  }

  Future<bool> _onSendCalibrarTara(BuildContext context) async {
      String offset = _offsetTaraController.text;
      Map<dynamic, dynamic> mensaje = {
          'type': 'REQUEST',
          'action': 'post',
          'clase': 'calibrar_tara',
          'data': {
              'loraAddr': _sensor['loraAddr'],
              'offset': double.parse(offset)
          }
      };
      return sendMessage(mensaje);
  }

  Future<void> _onCalibrarTara(BuildContext context) async {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Calibrar Tara'),
          content: 
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                    FormBuilder(
                        key: _bridgeWsFormKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FormBuilderTextField(
                                  name: 'offset',
                                  controller: _offsetTaraController,
                                  style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                  keyboardType: TextInputType.number,
                                  validator: FormBuilderValidators.compose(
                                    [
                                        FormBuilderValidators.required(
                                            errorText: 'Campo Obligatorio: Offset'
                                        ),
                                    ],
                                  ),
                                  decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                      ),
                                    ),
                                    labelText: 'Offset (valor actual)',
                                    labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                    ),
                                  ),
                              ),
                              const SizedBox(
                                  height: 24,
                              ),
                              Row(children: [
                                  Expanded(child: 
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.all(16),
                                          alignment: Alignment.centerLeft,
                                          //backgroundColor: Colors.blueGrey,
                                          backgroundColor: Colors.black45,
                                          textStyle: const TextStyle(color: Colors.white)
                                        ),
                                        onPressed: () async => Navigator.pop(context),
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
                                          await _onSendCalibrarTara(context);
                                          if (context.mounted) {
                                              Navigator.of(context).pop();
                                          }
                                      },
                                      child: const Center(
                                        child: Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                        ),
                  ),
                ],
            ),
        ),
      );
  }

  
  String _getModoLectura(int rdMode) {
      Map<int, String> modosLectura = {
          1: 'Pulsos',
          2: 'Conversión ADC',
          3: 'MODBUS',
          4: 'HX711',
      };
      return modosLectura.containsKey(rdMode) ? modosLectura[rdMode]! : '';
  }

  String _getTipoSensor(int sensorType) {
      Map<int, String> tiposSensor = {
          1: 'Caudalímetro',
          2: 'Sensor de Peso',
          3: 'Sensor de Temperatura',
          4: 'Sensor de Nivel',
          5: 'Sensor de Amoniaco (HH3)',
          6: 'Sensor de CO2',
          7: 'Sensor de Humedad',
          8: 'Meter Trifásico DTSU666',
          9: 'Meter Monofásico DSSU666',
      };
      return tiposSensor.containsKey(sensorType) ? tiposSensor[sensorType]! : '';
  }

  bool _esSensorCalibrable(dynamic sensor) {
      if (sensor['rd_mode'] == LECTURA_ADC) return true;
      return false;
  }

  void _onSensor(BuildContext context, int index) async {
      _sensor = _sensoresInfo['sensores'][index];
      _sensorTypeController.text = _getTipoSensor(_sensor['sensorType']);
      _sensorLoraAddrController.text = _sensor['loraAddr'].toString();
      _sensorRdModeController.text = _getModoLectura(_sensor['rd_mode']);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sensor'),
            content: 
                SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FormBuilder(
                              key: _bridgeWsFormKey,
                              autovalidateMode: AutovalidateMode.disabled,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FormBuilderTextField(
                                    name: 'sensor_type',
                                    controller: _sensorTypeController,
                                    readOnly: true,
                                        //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                        //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Tipo de Sensor'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Tipo de Sensor',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FormBuilderTextField(
                                    name: 'loraAddr',
                                    controller: _sensorLoraAddrController,
                                    readOnly: true,
                                        //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                        //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Dirección LoRa'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Dirección LoRa (loraAddr)',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FormBuilderTextField(
                                    name: 'rd_mode',
                                    controller: _sensorRdModeController,
                                    readOnly: true,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Modo de Lectura'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Modo de Lectura',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                              Expanded(child:
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(8),
                                      alignment: Alignment.centerLeft,
                                      //backgroundColor: Colors.blueGrey,
                                      backgroundColor: Colors.black45,
                                      textStyle: const TextStyle(color: Colors.white)
                                    ),
                                    onPressed: () {
                                        Navigator.pop(context);
                                    },
                                    child: const Center(
                                      child: Text('Cerrar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Expanded(child:
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(8),
                                      alignment: Alignment.centerLeft,
                                      backgroundColor: Colors.blue,
                                    ),
                                    onPressed: () async {
                                        await _onStartMonitor(context, _sensor);
                                    },
                                    child: const Center(
                                      child: Text('Monitor', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                              ),
                              const SizedBox(
                                  width: 6,
                              ),
                              Container(
                                child:
                                  _esSensorCalibrable(_sensor) ?
                                    Column(children: [
                                      Expanded(child:
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.all(8),
                                            alignment: Alignment.centerLeft,
                                            backgroundColor: Colors.blue,
                                          ),
                                          onPressed: () async {
                                              await _onCalibrarTara(context);
                                              await _onCalibrarFactor(context);
                                          },
                                          child: const Center(
                                            child: Text('Calibrar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ) : null,
                                ),
                            ],)
                        ]
                    ),
                ),
          );
        });
  }

  Widget _buildSensoresList() {
    List<dynamic> sensores = _sensoresInfo['sensores'];
//sensores.add({'sensorType': 3, 'loraAddr': 5, 'rd_mode': 2, 'param': { 'wire_num': 0, 'i2c_address': 72, 'channel': 0, 'tara': 0.1, 'factor': 100.0, 'offset': 10.0 } });
//print('sensores=$sensores');
    return Container(
      //height: 300.0, // Change as per your requirement
      //width: 300.0, // Change as per your requirement
      child: sensores.isEmpty
          ? const Text('No hay resultados', style: TextStyle(color: Colors.orange))
          : ListView.builder(
        shrinkWrap: true,
        itemCount: sensores.length,
        itemBuilder: (BuildContext context, int index) {
          String tipo = _getTipoSensor(sensores[index]['sensorType']);
          String nombre = tipo + ' (loraAddr: ' + sensores[index]['loraAddr'].toString() + ')';
print('Sensor> Nombre=$nombre');
          return ListTile(
            title:  
                InkWell(
                    child: Text(
                        nombre, 
                        style: TbTextStyles.bodySmall.copyWith(color: Colors.blue.shade900),
                      ),
                    onTap: () {
                        _onSensor(context, index);
                    }
                ),
          );
        },
      ),
    );
  }

  void _onSensores(BuildContext context) async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sensores'),
            content: 
                SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            _buildSensoresList(),
                            const SizedBox(
                              height: 20,
                            ),
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
                                  child: Text('Cerrar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                            ),
                        ]
                    ),
                ),
          );
        });
  }


  Widget _bodyBridge(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onConfigIdentBridge(context);
                  //_onIdent(context);
              },
              child: const Center(
                  child: Text('Identificación', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),
          const SizedBox(
              height: 24,
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onConfigWiFiBridge(context);
              },
              child: const Center(
                  child: Text('Configuración WiFi', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),
          const SizedBox(
              height: 24,
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onConfigModemBridge(context);
              },
              child: const Center(
                  child: Text('Configuración 4G', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),
          const SizedBox(
              height: 24,
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onReset(context);
              },
              child: const Center(
                  child: Text('Reiniciar Bridge', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),
          const SizedBox(
              height: 24,
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onConcentradores(context);
              },
              child: const Center(
                  child: Text('Concentradores', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),
      ],);
  }




  bool _onSetConfigWiFiConcentrador(BuildContext context) {
      _nodoContent['configRed']['ip'] = _ipCntController.text;
      //_nodoContent['configRed']['gateway'] = _gatewayCntController.text;
      //_nodoContent['configRed']['subnet_mask'] = _maskCntController.text;
      //_nodoContent['configRed']['dns1'] = _dns1CntController.text;
      //_nodoContent['configRed']['dns2'] = _dns2CntController.text;
      _nodoContent['configRed']['ap_ssid'] = _apSsidCntController.text;
      _nodoContent['configRed']['ap_pass'] = _apPassCntController.text;
      //_nodoContent['configRed']['wifi_ssid'] = _wifiSsidCntController.text;
      //_nodoContent['configRed']['wifi_pass'] = _wifiPassCntController.text;
      Map<dynamic, dynamic> configRed = { 'configRed': _nodoContent['configRed'] };
      return _sendPutConfigMessage(configRed);
  }
  
  void _onConfigWiFiConcentrador(BuildContext context) {
      final wifi = _nodoContent['configRed'];
      _ipCntController.text = wifi['ip'];
      //_gatewayCntController.text = wifi['gateway'];
      //_maskCntController.text = wifi['subnet_mask'];
      //_dns1CntController.text = wifi['dns1'];
      //_dns2CntController.text = wifi['dns2'];
      _apSsidCntController.text = wifi['ap_ssid'];
      _apPassCntController.text = wifi['ap_pass'];
      //_wifiSsidCntController.text = wifi['wifi_ssid'];
      //_wifiPassCntController.text = wifi['wifi_pass'];
      _showApPassCntNotifier.value = false;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('WiFi'),
          content: 
            SingleChildScrollView(child:
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    FormBuilder(
                        key: _bridgeWsFormKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                /*
                                Text('STA (Estación)', style: TbTextStyles.bodyMedium),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'wifi_ssid',
                                    controller: _wifiSsidCntController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo obligatorio: SSID Red WiFi'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'SSID Red WiFi',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                ValueListenableBuilder(
                                    valueListenable: _showPasswordNotifier,
                                    builder: (
                                      BuildContext context,
                                      bool showPassword,
                                      child,
                                    ) {
                                      return FormBuilderTextField(
                                        name: 'wifi_pass',
                                        controller: _wifiPassCntController,
                                        //initialValue: _password,
                                        obscureText: !showPassword,
                                        style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                        //style: const TextStyle(color: Colors.black),
                                        validator: FormBuilderValidators.compose(
                                          [
                                            FormBuilderValidators.required(
                                              errorText: 'Campo Obligatorio: Contraseña Red WiFi'
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
                                          labelText: 'Contraseña Red WiFi',
                                          labelStyle:
                                              TbTextStyles.bodySmall.copyWith(
                                            color: Colors.black.withOpacity(.54),
                                          ),
                                        ),
                                      );
                                    },
                                ),
                                //const SizedBox(height: 12),
                                const Divider(),
                                */
                                Text('AP (Punto Acceso)', style: TbTextStyles.bodyMedium),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'ap_ssid',
                                    controller: _apSsidCntController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: SSID'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'SSID',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                ValueListenableBuilder(
                                    valueListenable: _showApPassCntNotifier,
                                    builder: (
                                      BuildContext context,
                                      bool showPassword,
                                      child,
                                    ) {
                                      return FormBuilderTextField(
                                        name: 'ap_pass',
                                        controller: _apPassCntController,
                                        //initialValue: _password,
                                        obscureText: !showPassword,
                                        style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                        //style: const TextStyle(color: Colors.black),
                                        validator: FormBuilderValidators.compose(
                                          [
                                            FormBuilderValidators.required(
                                              errorText: 'Campo Obligatorio: Contraseña SSID'
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
                                              _showApPassCntNotifier.value =
                                                  !_showApPassCntNotifier.value;
                                            },
                                          ),
                                          border: const OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  Colors.black.withOpacity(.12),
                                            ),
                                          ),
                                          labelText: 'Contraseña SSID',
                                          labelStyle:
                                              TbTextStyles.bodySmall.copyWith(
                                            color: Colors.black.withOpacity(.54),
                                          ),
                                        ),
                                      );
                                    },
                                ),

                                //const SizedBox(height: 12),
                                const Divider(),
                                Text('IP Estática', style: TbTextStyles.bodyMedium),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'ip',
                                    controller: _ipCntController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: IP'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Dirección IP',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                /*
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'gateway',
                                    controller: _gatewayController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Gateway'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Dirección Gateway',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'subnet_mask',
                                    controller: _maskController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Máscara Subred'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Máscara Subred',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'dns1',
                                    controller: _dns1Controller,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: DNS1'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'DNS1',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'dns2',
                                    controller: _dns2Controller,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: DNS2'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'DNS2',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                */
                            ],
                        ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(child: 
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                backgroundColor: Colors.blueGrey,
                                textStyle: const TextStyle(color: Colors.blue)
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
                              backgroundColor: Colors.blueGrey,
                            ),
                            onPressed: () async {
                                bool enviado =_onSetConfigWiFiConcentrador(context);
                                if (enviado) await _showAlert(context, 'Configuración WiFi', 'La configuración se ha enviado al Concentrador');
                                if (context.mounted) {
                                    Navigator.of(context).pop();
                                }
                            },
                            child: const Center(
                              child: Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ),
                      ]
                    ),

                ],
              ),
            ),
        ),
      );
  }

  bool _onSetIdentConcentrador(BuildContext context) {
      _nodoContent['ident']['deviceId'] = _devIdCntController.text;
      _nodoContent['ident']['loraId'] = _loraIdCntController.text;
      _nodoContent['ident']['bridgeId'] = _bridgeIdCntController.text;
      Map<dynamic, dynamic> ident = { 'ident': _nodoContent['ident'] };
      return _sendPutConfigMessage(ident);
  }


  void _onIdentConcentrador(BuildContext context) {
      final ident = _nodoContent['ident'];
      _devIdCntController.text = ident['deviceId'];
      _loraIdCntController.text = ident['loraId'].toString();
      _bridgeIdCntController.text = ident['bridgeId'].toString();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Identificación Concentrador'),
          content: 
            SingleChildScrollView(child:
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    FormBuilder(
                        key: _bridgeWsFormKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                FormBuilderTextField(
                                    name: 'cnt_deviceId',
                                    controller: _devIdCntController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Identificador Dispositivo'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Identificador Dispositivo',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'cnt_lora_id',
                                    controller: _loraIdCntController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Identificador LoRa (loraId)'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Identificador LoRa (loraId)',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'cnt_bridge_id',
                                    controller: _bridgeIdCntController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Identificador LoRa del Bridge'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Identificador LoRa del Bridge',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(child: 
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                backgroundColor: Colors.blueGrey,
                                textStyle: const TextStyle(color: Colors.blue)
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
                              backgroundColor: Colors.blueGrey,
                            ),
                            onPressed: () async {
                                bool enviado = _onSetIdentConcentrador(context);
                                if (enviado) await _showAlert(context, 'Identificación Concentrador', 'La configuración se ha enviado al Concentrador');
                                if (context.mounted) {
                                    Navigator.of(context).pop();
                                }
                            },
                            child: const Center(
                              child: Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ),
                      ]
                    ),

                ],
              ),
            ),
        ),
      );
  }

/*
  void _onIdentConcentrador(BuildContext context) {
      final ident = _nodoContent['ident'];
      _devIdCntController.text = ident['deviceId'];
      _loraIdCntController.text = ident['loraId'];
      _bridgeIdCntController.text = ident['bridgeId'];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Identificación Concentrador'),
          content: 
            SingleChildScrollView(child:
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    FormBuilder(
                        key: _bridgeWsFormKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                FormBuilderTextField(
                                    name: 'deviceId',
                                    controller: _devIdCntController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo obligatorio: Id. Dispositivo'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Id. Dispositivo',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'lora_id',
                                    controller: _loraIdCntController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Identificador LoRa (loraId)'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Identificador LoRa (loraId)',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                FormBuilderTextField(
                                    name: 'bridge_id',
                                    controller: _bridgeIdCntController,
                                    //nitialValue: _username,
                                    style: TbTextStyles.bodySmall.copyWith(color: Colors.black),
                                    //style: const TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.text,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: 'Campo Obligatorio: Identificador LoRa del Bridge'
                                        ),
                                      ],
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black.withOpacity(.12),
                                        ),
                                      ),
                                      labelText: 'Identificador LoRa del Bridge',
                                      labelStyle: TbTextStyles.bodySmall.copyWith(
                                        color: Colors.black.withOpacity(.54),
                                      ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(child: 
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                backgroundColor: Colors.blueGrey,
                                textStyle: const TextStyle(color: Colors.blue)
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
                              backgroundColor: Colors.blueGrey,
                            ),
                            onPressed: () async {
                                bool enviado = _onSetIdentConcentrador(context);
                                if (enviado) await _showAlert(context, 'Identificación Concentrador', 'La configuración se ha enviado al Concentrador');
                                if (context.mounted) {
                                    Navigator.of(context).pop();
                                }
                            },
                            child: const Center(
                              child: Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ),
                      ]
                    ),

                ],
              ),
            ),
        ),
      );
  }
*/


  Widget _bodyConcentrador(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onIdentConcentrador(context);
              },
              child: const Center(
                  child: Text('Identificación', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),
          const SizedBox(
              height: 24,
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onConfigWiFiConcentrador(context);
              },
              child: const Center(
                  child: Text('Configuración WiFi', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),
          const SizedBox(
              height: 24,
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onSensores(context);
              },
              child: const Center(
                  child: Text('Sensores', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),
          const SizedBox(
              height: 24,
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onReset(context);
              },
              child: const Center(
                  child: Text('Reiniciar Concentrador', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),

      ],);
  }

  Widget _bodyConectar(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.blue)
              ),
              onPressed: () {
                  _onConectar(context);
              },
              child: const Center(
                  child: Text('Conectar con nodo', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ),

      ],);
  }

  @override
  void initState() {
    super.initState();
    //_loadUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

      
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF091D30),
      //backgroundColor: Colors.white,
      appBar: TbAppBar(
        tbContext,
        title: const Text('Configuración'),
      ),
      body: Builder(
        builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                    child: Text(widget._ssid, style: TbTextStyles.titleMedium),
                ),
                const SizedBox(
                    height: 24,
                ),
                Center(
                    child: _esBridge ? _bodyBridge(context): 
                        _esConcentrador ? _bodyConcentrador(context) : _bodyConectar(context),
                ),
                /*
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.wifi),
                      label: const Text('Conectar con Bridge'),
                      onPressed: () async => _onConectar(context),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Configurar '),
                      //onPressed: () => {}
                      onPressed: () async => _onConfigBridge(context),
                    ),
                  ],
                ),
                const Divider(),
                */
              ],
            ),
          ),
        ),
      );
  }
}


/**
/// Show tile for AccessPoint.
///
/// Can see details when tapped.
class _ConcentradorTile extends StatelessWidget {
  final Map<dynamic, dynamic> concentrador;
  final WebSocketChannel channel;

  _ConcentradorTile({Key? key, required this.concentrador, required this.channel})
      : super(key: key);

  final _concentradorFormKey = GlobalKey<FormBuilderState>();

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

  bool sendTextMessage(BuildContext context, String mensaje) {
      try {
          channel?.sink.add(mensaje);
          return true;
      } on WebSocketChannelException catch (e) {
          _showAlert(context, 'ERROR', 'No se ha podido enviar el mensaje: ${e.toString()}');
          return false;
      }
  }

  bool sendMessage(BuildContext context, Map<dynamic, dynamic> mensaje) {
      final data = jsonEncode(mensaje);
      return sendTextMessage(context, data);
  }

  Future<bool> _onActivarConcentrador(BuildContext context) async {
      Map<dynamic, dynamic> mensaje = {
          'type': 'wifi',
          'action': 'start',
          'toLoraId': concentrador['loraId'],
      };
      return sendMessage(context, mensaje);
  }


  @override
  Widget build(BuildContext context) {
    final title = concentrador['deviceName'].isNotEmpty ? concentrador['deviceName'] : "**EMPTY**";
print('TITLE=$title');
    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(title, style: const TextStyle(color: Colors.black)),
      /*
      onTap: () async => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Se va a enviar una orden al Concentrador para que active su red WiFi'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            const SizedBox(width: 12),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                  Navigator.pop(context, true);
                  _onActivarConcentrador(context);
              },
            ),
          ],
        ),
      ),
      */
    );
  }
}
*/