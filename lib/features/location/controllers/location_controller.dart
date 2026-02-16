// ignore_for_file: deprecated_member_use

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationController extends GetxController {
  var isLoading = false.obs;
  var selectedLocation = 'Selected Location'.obs;
  var address = 'Add your location'.obs;

  Future<void> requestLocation() async {
    isLoading.value = true;
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address.value =
              '${place.street}, ${place.locality}, ${place.country}';
        }

        if (Get.currentRoute != '/home') {
          Get.offNamed('/home');
        }
      } else {
        Get.snackbar(
            'Permission Denied', 'Please enable location permissions.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to get location: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void goToHome() {
    Get.toNamed('/home');
  }
}
