import 'dart:convert';
import 'dart:math';

import 'package:location/location.dart';

import './local.properties';
import './serviceLocator.dart';
import './services/LocalStorageService.dart';

import 'services/google_maps.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator().then((val) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "What's in my Masjid",
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MasjidMaps(),
    );
  }
}

class MasjidMaps extends StatefulWidget {
  MasjidMaps({Key? key}) : super(key: key);

  @override
  _MasjidMapsState createState() => _MasjidMapsState();
}

class _MasjidMapsState extends State<MasjidMaps> {
  List<Marker> markers = [];
  LatLng _lastMapPosition = LatLng(locator<LocalStorageService>().latitude,
      locator<LocalStorageService>().longitude);
  late GoogleMapController googleMapsController;
  // LatLng _lastMapPosition;
  Location location = new Location();
  LocationData? locationData;

  @override
  void initState() {
    super.initState();
  }

  void getCurrentPosition() async {
    MapPreferences preferences = await initialiseMapSettings();
    print(preferences.notificationString);
    if (preferences.locationFlag) {
      if (locationData == null) {
        locationData = await location.getLocation();
      }
      googleMapsController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(locationData!.latitude!, locationData!.longitude!),
            zoom: 16,
          ),
        ),
      );
      setState(() {
        _lastMapPosition =
            LatLng(locationData!.latitude!, locationData!.longitude!);
        // markers.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildMap(_lastMapPosition, markers),
    );
  }

  Widget buildMap(LatLng latLng, Iterable masajids) {
    Future<LatLngBounds> screenLatLng;
    return Stack(
      children: [
        GoogleMap(
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          markers: Set.from(
            masajids,
          ),
          initialCameraPosition: CameraPosition(target: latLng, zoom: 15.0),
          onCameraMove: (position) {
            _lastMapPosition = position.target;
            locator<LocalStorageService>().latitude = _lastMapPosition.latitude;
            locator<LocalStorageService>().longitude =
                _lastMapPosition.longitude;
          },
          mapType: MapType.normal,
          onMapCreated: (controller) {
            googleMapsController = controller;
            screenLatLng = googleMapsController.getVisibleRegion();
            getCurrentPosition();
          },
        ),
        Builder(builder: (context) {
          return Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
              child: Column(
                verticalDirection: VerticalDirection.up,
                children: [
                  // bottom,
                  Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 3.0,
                          ),
                        ]),
                    padding: EdgeInsets.all(8),
                    child: IconButton(
                      icon: Icon(
                        Icons.my_location,
                        color: Colors.black,
                      ),
                      onPressed: () async {
                        getCurrentPosition();
                      },
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(8)),
                  Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 3.0,
                          ),
                        ]),
                    padding: EdgeInsets.all(8),
                    child: IconButton(
                      icon: Icon(
                        Icons.search,
                        color: Colors.black,
                      ),
                      onPressed: () async {
                        // getCurrentPosition();
                        screenLatLng = googleMapsController.getVisibleRegion();
                        LatLngBounds screenEdges = await screenLatLng;
                        getPlaces(_lastMapPosition, context, screenEdges);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  getPlaces(
      LatLng latLng, BuildContext context, LatLngBounds screenEdges) async {
    try {
      var url = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/nearbysearch/json',
        {
          'location': '${latLng.latitude},${latLng.longitude}',
          'radius': '${getRadius(screenEdges)}',
          'type': 'mosque',
          'fields': 'name',
          'key': '$MAPS_API_KEY',
          'locationbias':
              'rectangle:${screenEdges.southwest.latitude},${screenEdges.southwest.longitude}|${screenEdges.northeast.latitude},${screenEdges.northeast.longitude}',
        },
      );
      print(url.query);
      final response = await http.get(url);
      final int statusCode = response.statusCode;
      String snackBarText = 'No Masjid Found';
      if (statusCode == 201 || statusCode == 200) {
        Map responseBody = json.decode(response.body);
        List results = responseBody["results"];

        List<Marker> _markers = List.generate(results.length, (index) {
          Map result = results[index];
          Map location = result["geometry"]["location"];
          LatLng latLngMarker = LatLng(location["lat"], location["lng"]);

          return Marker(
            markerId: MarkerId("marker$index"),
            position: latLngMarker,
            icon: BitmapDescriptor.defaultMarker,
            onTap: () => Scaffold.of(context).showBottomSheet((context) =>
                placeDetails(
                    result["name"],
                    result["vicinity"],
                    (result["rating"] ?? "No Ratings").toString(),
                    latLngMarker)),
            infoWindow: InfoWindow(
              title: result["name"],
              onTap: () {},
            ),
          );
        });
        if (_markers.length != 0) {
          snackBarText = _markers.length.toString() + ' Masajid Found';
          // googleMapsController.animateCamera(CameraUpdate.zoomBy(-0.1));
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(snackBarText),
        ));

        setState(() {
          markers = _markers;
        });
      } else {
        throw Exception('Error');
      }
    } catch (e) {
      print('ERROR______________________' + e.toString());
    }
  }

  double getRadius(LatLngBounds screenEdges) {
    double x = (screenEdges.northeast.longitude -
            screenEdges.southwest.longitude) *
        cos((screenEdges.northeast.latitude + screenEdges.southwest.latitude) /
            2);
    double y = screenEdges.northeast.latitude - screenEdges.southwest.latitude;
    double z = sqrt(x * x + y * y) * 31855;
    return z;
  }

  Widget placeDetails(
      String name, String address, String rating, LatLng latLngMarker) {
    return Container(
      // color: Colors.amber,
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(blurRadius: 3)],
        // borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * .4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.home),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      name,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize:
                            Theme.of(context).textTheme.subtitle1!.fontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {},
                child: Row(
                  children: [
                    Text(
                      rating,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize:
                            Theme.of(context).textTheme.subtitle2!.fontSize,
                      ),
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow[700],
                      size: 16,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomSheet extends StatelessWidget {
  const BottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
