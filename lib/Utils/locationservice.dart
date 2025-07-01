import 'package:bmine_slice/Utils/apis.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<void> getCurrentLocation() async {
    print('getCurrentLocation called');
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // Request permissions if they are not already granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message
        print('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, handle accordingly
      print('Location permissions are permanently denied.');
      return;
    }

    // If permissions are granted, get the current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Send the latitude and longitude to the API
    await sendLocationToApi(position);
  }

  // Method to send location data to the API
  static Future<void> sendLocationToApi(Position position) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String userId = prefs.getString("userid") ?? "";

    try {
      var url = Uri.parse(
        API.addLocation,
      );
      Map<String, dynamic> Jsonbody = {
        'user_id': userId,
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      };
      var response = await http.post(
        url,
        body: Jsonbody,
      );

      print('Jsonbody: $Jsonbody');
      if (response.statusCode == 200) {
        prefs.setBool("IsLocationStart", true);
        print("IS LOCATION == ${prefs.getBool("IsLocationStart")}");

        print('Location sent successfully: ${response.body}');
      } else {
        print('Failed to send location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }
}
