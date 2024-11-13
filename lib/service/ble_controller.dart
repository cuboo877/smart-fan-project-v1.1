import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum ClientStatus {
  BluetoothOff,
  StandBy,
  Scanning,
  FoundDevices,
  FoundNoDevices,
  Connected,
  CancelConnection,
  Connecting,
  ConnectionError,
}

enum CommandType {
  speed, // 固定風速
  circulate, // 循環模式
  auto, // 自動模式
  // 之後可以繼續添加其他命令類型
}

class BleCommand {
  final CommandType type;
  final int value;
  final DateTime timestamp;

  BleCommand({
    required this.type,
    required this.value,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class BleController extends ChangeNotifier {
  static final BleController _instance = BleController._internal();
  // 狀態變量
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  BluetoothDevice? connectingDevice;
  BluetoothCharacteristic? writeCharacteristic; // send command to slave
  BluetoothCharacteristic? notifyCharacteristic; // receive message from slave
  String lastReceivedMessage = '';
  ClientStatus status = ClientStatus.BluetoothOff;
  String? _localDeviceName;
  String? get localDeviceName => _localDeviceName;

  double? currentTemp;
  double? currentHumidity;
  int? currentRssi; // 用于存储当前 RSSI 值的变量

  factory BleController() {
    return _instance;
  }

  BleController._internal();

  String getStatusString() {
    switch (status) {
      case ClientStatus.BluetoothOff:
        return "藍牙未開啟";
      case ClientStatus.StandBy:
        return "已開啟藍牙";
      case ClientStatus.Scanning:
        return "掃描BLE裝置中...";
      case ClientStatus.FoundDevices:
        return "已掃描裝置: ${scanResults.length}";
      case ClientStatus.FoundNoDevices:
        return "尚未掃描到任何BLE裝置...";
      case ClientStatus.Connected:
        return "已連接:${connectedDevice?.name}";
      case ClientStatus.CancelConnection:
        return "已斷開連結";
      case ClientStatus.Connecting:
        return "正在連接:${connectingDevice?.name ?? "未知裝置"}...";
      case ClientStatus.ConnectionError:
        return "與${connectingDevice?.name ?? "未知裝置"}的連接失敗";
      default:
        return "未知狀態";
    }
  }

  void updateStatus(ClientStatus newStatus) {
    status = newStatus;
    notifyListeners();
  }

  Future<void> checkBluetoothOn() async {
    final bluetoothState = await FlutterBluePlus.adapterState.first;
    if (bluetoothState == BluetoothAdapterState.off) {
      updateStatus(ClientStatus.BluetoothOff);
    } else {
      updateStatus(ClientStatus.StandBy);
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (!allGranted) {
        print('Not all permissions were granted');
      }
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      isScanning = false;
      updateStatus(scanResults.isNotEmpty
          ? ClientStatus.FoundDevices
          : ClientStatus.FoundNoDevices);
      print('已停止掃描');
    } catch (e) {
      print('停止掃描時發生錯誤: $e');
    }
  }

  void startScan() async {
    try {
      if (!await FlutterBluePlus.isSupported) {
        print('設備不支持藍牙');
        return;
      }

      if (!(await FlutterBluePlus.adapterState.first ==
          BluetoothAdapterState.on)) {
        print('藍牙未開啟');
        return;
      }

      if (status == ClientStatus.Connected) {
        await disconnect();
      }

      print('開始掃描設備...');
      scanResults.clear();
      isScanning = true;
      updateStatus(ClientStatus.Scanning);
      notifyListeners();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      FlutterBluePlus.scanResults.listen((results) {
        scanResults = results;
        notifyListeners();
      }, onError: (error) {
        print('掃描錯誤: $error');
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        isScanning = scanning;
        if (!scanning) {
          updateStatus(scanResults.isNotEmpty
              ? ClientStatus.FoundDevices
              : ClientStatus.FoundNoDevices);
          print('掃描完成，共發現 ${scanResults.length} 個設備');
        }
        notifyListeners();
      });
    } catch (e) {
      print('掃描過程發生錯誤: $e');
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await getLocalDeviceName();
      updateStatus(ClientStatus.Connecting);

      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
      }

      connectingDevice = device;
      await device
          .connect(
        timeout: const Duration(seconds: 5),
        autoConnect: false,
      )
          .catchError((error) {
        print('連接失敗，重試中...');
        return device.disconnect().then((_) {
          return device.connect(
            timeout: const Duration(seconds: 5),
            autoConnect: false,
          );
        });
      });

      connectedDevice = device;
      updateStatus(ClientStatus.Connected);

      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
          }

          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            notifyCharacteristic = characteristic;
            await setupNotifications();
          }
        }
      }

      if (writeCharacteristic == null || notifyCharacteristic == null) {
        print('警告：未找到必要的特徵值');
      }
    } catch (e) {
      print('連接錯誤: $e');
      updateStatus(ClientStatus.ConnectionError);
      try {
        await device.disconnect();
      } catch (disconnectError) {
        print('斷開連接時發生錯誤');
      }
      connectingDevice = null;
    }
  }

  Future<bool> sendCommand(CommandType type, int value) async {
    if (status != ClientStatus.Connected || writeCharacteristic == null) {
      print('設備未連接或特徵值未找到');
      return false;
    }

    try {
      final command = BleCommand(type: type, value: value);

      // 根據命令類型構建發送字串
      String commandString;
      switch (command.type) {
        case CommandType.speed:
          commandString = 'Speed:${command.value}';
          break;
        case CommandType.circulate:
          commandString = 'Circulate:${command.value}';
          break;
        case CommandType.auto:
          commandString = 'Auto:${command.value}';
          break;
      }

      // 發送命令
      await writeCharacteristic!.write(
        utf8.encode(commandString),
        withoutResponse: writeCharacteristic!.properties.writeWithoutResponse,
      );

      // 這��可以添加資料庫操作
      await _saveCommandToDatabase(command);

      print('發送命令成功: $commandString');
      return true;
    } catch (e) {
      print('發送命令失敗: $e');
      return false;
    }
  }

  // 預留資料庫操作方法
  Future<void> _saveCommandToDatabase(BleCommand command) async {
    // TODO: 實現資料庫存儲邏輯
    // 例如：
    // final db = await database;
    // await db.insert('commands', {
    //   'type': command.type.toString(),
    //   'value': command.value,
    //   'timestamp': command.timestamp.toIso8601String(),
    // });
  }

  Future<void> setupNotifications() async {
    if (notifyCharacteristic != null) {
      try {
        await notifyCharacteristic!.setNotifyValue(true);
        notifyCharacteristic!.value.listen((value) {
          String message = utf8.decode(value);
          print('收到訊息: $message');
          lastReceivedMessage = message;

          // 解析温度和湿度数据
          if (message.startsWith("T/H:")) {
            List<String> parts = message.substring(4).split(",");
            if (parts.length == 2) {
              currentTemp = double.tryParse(parts[0]);
              currentHumidity = double.tryParse(parts[1]);
              print('当前温度: $currentTemp, 当前湿度: $currentHumidity');
            }
          }

          notifyListeners();
        }, onError: (error) {
          print('通知錯誤: $error');
        });
        print('通知已啟用');
      } catch (e) {
        print('設置通知時出錯: $e');
      }
    }
  }

  Future<void> disconnect() async {
    try {
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
        print('已斷開連接：${connectedDevice?.name}');
        connectedDevice = null;
        writeCharacteristic = null;
        notifyCharacteristic = null;
        updateStatus(ClientStatus.StandBy);
      }
    } catch (e) {
      print('斷開連接時發生錯誤: $e');
    }
  }

  Future<void> cancelConnecting() async {
    if (connectingDevice != null) {
      try {
        await connectingDevice!.disconnect();
        connectingDevice = null;
        updateStatus(ClientStatus.FoundDevices);
      } catch (e) {
        print('取消連接時發生錯誤: $e');
      }
    }
  }

  Future<void> getLocalDeviceName() async {
    try {
      _localDeviceName = await FlutterBluePlus.adapterName;
      notifyListeners();
    } catch (e) {
      print('獲取設備名稱失敗: $e');
      _localDeviceName = '未知設備';
    }
  }

  // 读取当前连接设备的 RSSI 值
  Future<void> readRssi() async {
    if (connectedDevice != null) {
      try {
        final rssi = await connectedDevice!.readRssi();
        currentRssi = rssi; // 更新当前 RSSI 值
        notifyListeners(); // 通知监听者更新 UI
        print('当前 RSSI: $currentRssi');
      } catch (e) {
        print('读取 RSSI 时发生错误: $e');
      }
    } else {
      print('没有连接的设备，无法读取 RSSI');
    }
  }
}
