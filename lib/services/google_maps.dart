import 'package:location/location.dart';
import 'package:whats_in_my_masjid/serviceLocator.dart';
import 'package:whats_in_my_masjid/services/LocalStorageService.dart';

class MapPreferences {
  static bool isLocationAvailable = true;
  static String notification = '';

  bool get locationFlag => isLocationAvailable;
  String get notificationString => notification;
}

//First Step
Future<MapPreferences> initialiseMapSettings() async {
  Location location = new Location();
  PermissionStatus permission;

  //Check if user wants to share location
  if (locator<LocalStorageService>().useLocation) {
    permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
    }
    if (permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited) {
      if (await location.serviceEnabled()) {
        MapPreferences.isLocationAvailable = true;
        MapPreferences.notification = "Fetching Location";
        print(MapPreferences.notification);
        return Future<MapPreferences>.value(MapPreferences());
      } else {
        //Create map with last searched position and a "Notification Service Disabled" notification
        MapPreferences.isLocationAvailable = true;
        MapPreferences.notification =
            "Device Location is not enabled. Running in No Location mode";
        print(MapPreferences.notification);
        return Future<MapPreferences>.value(MapPreferences());
      }
    } else {
      //Create map with last searched position and a "Location Access Denied" notification
      MapPreferences.isLocationAvailable = false;
      MapPreferences.notification =
          "Location access denied at system level. Running in No Location mode";
      print(MapPreferences.notification);
      return Future<MapPreferences>.value(MapPreferences());
    }
  } else {
    MapPreferences.isLocationAvailable = false;
    MapPreferences.notification =
        "Location access denied at application level. Running in No Location mode";
    print(MapPreferences.notification);
    return Future<MapPreferences>.value(MapPreferences());
  }
}
