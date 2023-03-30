import 'dart:io';
import 'package:bbback/app_service.dart';
import 'package:conduit/conduit.dart';

void main() async {
  //порт, на котором будет запущена апишка
  final port = int.parse(Platform.environment["PORT"] ?? '8888');

  final service = Application<AppService>()
    ..options.port = port
    ..options.configurationFilePath = 'config.yaml';
  await service.start(numberOfInstances: 3, consoleLogging: true);
}
