// Import file for mobile platforms
import 'package:mobile_scanner/mobile_scanner.dart';

dynamic createMobileScannerController() {
  final controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back, // Použiť zadnú kameru
    returnImage: false,
  );
  // Scanner sa nespúšťa automaticky
  return controller;
}

dynamic createMobileScanner({required dynamic controller, required Function onDetect}) {
  return MobileScanner(
    controller: controller as MobileScannerController,
    onDetect: onDetect as void Function(BarcodeCapture),
  );
}

void disposeMobileScannerController(dynamic controller) {
  (controller as MobileScannerController).dispose();
}
