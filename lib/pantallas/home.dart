import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:after_layout/after_layout.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _bluetooth = FlutterBluetoothSerial.instance;
  bool BTstate = false;
  bool BTconnected = false;
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? device;
  String contenido = "";

  @override
  void initState() {
    super.initState();
    permisos();
    estadoBT();
  }

  void permisos() async {
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetooth.request();
    await Permission.location.request();
  }

  void estadoBT() {
    _bluetooth.state.then(
          (value) {
        setState(() {
          BTstate = value.isEnabled;
        });
      },
    );

    _bluetooth.onStateChanged().listen(
          (event) {
        switch (event) {
          case BluetoothState.STATE_ON:
            BTstate = true;
            break;
          case BluetoothState.STATE_OFF:
            BTstate = false;
            break;
          case BluetoothState.STATE_TURNING_ON:
            break;
          case BluetoothState.STATE_TURNING_OFF:
            apagando();
            break;
        }
        setState(() {});
      },
    );
  }

  void encenderBT() async {
    await _bluetooth.requestEnable();
  }

  void apagarBT() async {
    await _bluetooth.requestDisable();
  }

  Widget switchBT() {
    return SwitchListTile(
      title: BTstate
          ? const Text('Bluetooth Encendido', style: TextStyle(fontWeight: FontWeight.bold))
          : const Text('Bluetooth Apagado', style: TextStyle(fontWeight: FontWeight.bold)),
      activeColor: BTstate ? Colors.blue : Colors.grey,
      tileColor: BTstate ? Colors.blue[100] : Colors.grey[300],
      value: BTstate,
      onChanged: (bool value) {
        if (value) {
          encenderBT();
        } else {
          apagarBT();
        }
      },
      secondary: BTstate
          ? const Icon(Icons.bluetooth, color: Colors.blue)
          : const Icon(Icons.bluetooth_disabled, color: Colors.grey),
    );
  }

  Widget infoDisp() {
    return ListTile(
      title: device == null
          ? const Text("Sin Dispositivo", style: TextStyle(fontStyle: FontStyle.italic))
          : Text("${device?.name}"),
      subtitle: device == null
          ? const Text("Sin Dispositivo", style: TextStyle(fontStyle: FontStyle.italic))
          : Text("${device?.address}"),
      trailing: BTconnected
          ? IconButton(
          onPressed: () async {
            await connection?.finish();
            BTconnected = false;
            devices = [];
            device = null;
            setState(() {});
          },
          icon: const Icon(Icons.delete, color: Colors.red))
          : IconButton(
          onPressed: () {
            listarDispositivos();
          },
          icon: const Icon(Icons.search, color: Colors.blue)),
    );
  }

  void listarDispositivos() async {
    devices = await _bluetooth.getBondedDevices();
    debugPrint(devices[0].name);
    setState(() {});
  }

  Widget lista() {
    if (BTconnected) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Text(
          contenido,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            letterSpacing: 1.2,
            wordSpacing: 1.2,
          ),
        ),
      );
    } else {
      return devices.isEmpty
          ? const Text("No hay dispositivos", style: TextStyle(color: Colors.redAccent))
          : ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${devices[index].name}", style: const TextStyle(fontSize: 16.0)),
            subtitle: Text(devices[index].address),
            trailing: IconButton(
              icon: const Icon(Icons.bluetooth_connected, color: Colors.green),
              onPressed: () async {
                connection = await BluetoothConnection.toAddress(
                    devices[index].address);
                device = devices[index];
                BTconnected = true;
                recibirDatos();
                setState(() {});
              },
            ),
          );
        },
      );
    }
  }

  void recibirDatos() {
    connection?.input?.listen(
          (event) {
        contenido += String.fromCharCodes(event);
        debugPrint(event.toString());
        setState(() {});
      },
    );
  }

  void enviarDatos(String msg) {
    if (connection!.isConnected) {
      connection?.output.add(ascii.encode('$msg\n'));
    }
  }

  Widget botonera() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        CupertinoButton(
          child: const Icon(Icons.flash_on, color: Colors.blue),
          onPressed: () {
            enviarDatos("light_on");
          },
        ),
        CupertinoButton(
          child: const Icon(Icons.flash_off, color: Colors.blueGrey),
          onPressed: () {
            enviarDatos("light_off");
          },
        ),
        CupertinoButton(
          child: const Icon(Icons.message, color: Colors.pink),
          onPressed: () {
            enviarDatos("random_message");
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Serial Bluetooth"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: <Widget>[
          switchBT(),
          const Divider(height: 10),
          infoDisp(),
          const Divider(height: 10),
          Expanded(child: lista()),
          const Divider(height: 10),
          botonera()
        ],
      ),
    );
  }

  void apagando() async {
    await connection?.finish();
    BTconnected = false;
    devices = [];
    device = null;
    setState(() {});
  }
}
