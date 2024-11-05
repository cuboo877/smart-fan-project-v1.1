import 'package:fanishion_project_v1/service/ble_controller.dart';
import 'package:fanishion_project_v1/widget/mapPageAppBar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, controller, child) {
        return SafeArea(
            child: Scaffold(
          appBar: MapPageAppBar(),
        ));
      },
    );
  }
}
