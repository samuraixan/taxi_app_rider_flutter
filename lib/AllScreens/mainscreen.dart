import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/AllWidgets/noDriverAvailableDialog.dart';
import 'package:uber_clone/AllWidgets/progressDialog.dart';
import 'package:uber_clone/Assistants/geoFireAssistant.dart';
import 'package:uber_clone/Models/directDetails.dart';
import 'package:uber_clone/Models/nearbyAvailableDrivers.dart';
import 'package:uber_clone/configMaps.dart';
import 'package:uber_clone/main.dart';


import '../AllWidgets/Divider.dart';
import '../Assistants/assistantMethods.dart';
import '../DataHandler/appData.dart';
import 'loginScreen.dart';
import 'searchScreen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String idScreen = 'mainScreen';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controllerGoogleMap =
  Completer<GoogleMapController>();
  GoogleMapController? newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DirectionDetails? tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  late Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;
  LocationPermission? permission;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoad = false;

  DatabaseReference? rideRequestRef;

  BitmapDescriptor? nearByIcon;

  List<NearbyAvailableDrivers>? availableDrivers;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef = FirebaseDatabase.instance.ref().child('Ride Requests').push();

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      'latitude': pickUp?.latitude.toString(),
      'longitude': pickUp?.longitude.toString()
    };

    Map dropOffLocMap = {
      'latitude': dropOff?.latitude.toString(),
      'longitude': dropOff?.longitude.toString()
    };

    Map rideInfoMap = {
      'driver_id': 'waiting',
      'payment_method': 'cash',
      'pickup': pickUpLocMap,
      'dropoff': dropOffLocMap,
      'cretaed_at': DateTime.now().toString(),
      'rider_name': userCurrentInfo?.name,
      'rider_phone': userCurrentInfo?.phone,
      'pickup_address': pickUp?.placeName,
      'dropoff_address': dropOff?.placeName
    };

    rideRequestRef?.set(rideInfoMap);
  }

  void cancelRideRequest() {
    rideRequestRef?.remove();
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 350;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230;
      drawerOpen = true;
    });
    saveRideRequest();
  }


  restApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });
    locatePosition();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirection();
    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 240;
      bottomPaddingOfMap = 230;
      drawerOpen = false;
    });
  }

  void locatePosition() async {
    permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLatPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = CameraPosition(target: latLatPosition, zoom: 15);
    newGoogleMapController?.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    if (mounted) {
      String address =
      await AssistantMethods.searchCoordinateAddress(position, context);
      print('Это ваш адрес: $address');
      initGeoFireListener();
    }
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    final colorizeColors = [
      Colors.green,
      Colors.purple,
      Colors.pink,
      Colors.blue,
      Colors.yellow,
      Colors.red,
    ];

    TextStyle colorizeTextStyle = const TextStyle(
      fontSize: 35,
      fontFamily: 'Pacifico',
    );
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Main Screen'),
      ),
      drawer: Container(
        color: Colors.white,
        width: 255,
        child: Drawer(
          child: ListView(
            children: [
              SizedBox(
                height: 165,
                child: DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/user_icon.jpg',
                        height: 65,
                        width: 65,
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Имя профиля',
                              style: TextStyle(
                                  fontSize: 16, fontFamily: 'Rowdies')),
                          SizedBox(height: 6),
                          Text('Посетите профиль')
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const DividerWidget(),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  'История',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  'Посетите профиль',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.info),
                title: Text(
                  'О нас',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                },
                child: const ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    'Выход',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              setState(() {
                bottomPaddingOfMap = 300;
              });
              locatePosition();
            },
          ),
          // HamburgerButton for Drawer
          Positioned(
            top: 38,
            left: 22,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen) {
                  scaffoldKey.currentState?.openDrawer();
                } else {
                  restApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon((drawerOpen) ? Icons.menu : Icons.close,
                      color: Colors.black),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              curve: Curves.bounceIn,
              duration: const Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(19),
                        topRight: Radius.circular(19)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ]),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'Привет,',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        'Куда направляться?',
                        style: TextStyle(fontSize: 20, fontFamily: 'Rowdies'),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SearchScreen()));
                          if (res == 'obtainDirection') {
                            // await getPlaceDirection();
                            displayRideDetailsContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7, 0.7),
                                ),
                              ]),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(width: 10),
                                Text('Поиск')
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.home, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(Provider.of<AppData>(context).pickUpLocation?.placeName ?? 'Добавить домашний адрес'),
                                // Provider.of<AppData>(context).pickUpLocation != null
                                // ?Provider.of<AppData>(context).pickUpLocation?.placeName
                                // :'Добавить домашний адрес'),
                                const SizedBox(height: 4),
                                const Text('Ваш домашний адрес проживания', style: TextStyle(color: Colors.black54, fontSize: 12),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      const DividerWidget(),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Icon(
                            Icons.work,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Добавить адрес работы'),
                              SizedBox(height: 4),
                              Text(
                                'Адрес вашего офиса',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12),
                              )
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSize(
              curve: Curves.bounceIn,
              duration: const Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Image.asset('assets/images/taxi.png',
                                  height: 70, width: 80),
                              const SizedBox(width: 16),
                              Column(
                                children: [
                                  const Text(
                                    'Машина',
                                    style: TextStyle(
                                        fontSize: 19, fontFamily: 'Rowdies'),
                                  ),
                                  Text(
                                    tripDirectionDetails?.distanceText ?? '',
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Expanded(child: Container()),
                              Text(
                                (tripDirectionDetails != null)
                                    ? '\$${AssistantMethods.calculateFares(tripDirectionDetails!)}'
                                    : '',
                                style: const TextStyle(fontFamily: 'Rowdies'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.moneyCheckDollar,
                                size: 19, color: Colors.black54),
                            SizedBox(width: 16),
                            Text('Наличные'),
                            SizedBox(width: 6),
                            Icon(Icons.keyboard_arrow_down,
                                color: Colors.black54, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                          onPressed: () {
                            displayRequestRideContainer();
                            availableDrivers = GeoFireAssistant.nearbyAvailableDriversList;
                            searchNearestDriver();
                          },
                          child: const Padding(
                              padding: EdgeInsets.all(17),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Запрос',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),),
                                  Icon(FontAwesomeIcons.taxi, color: Colors.white, size: 26),
                                ],
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 0.5,
                      blurRadius: 16,
                      color: Colors.black54,
                      offset: Offset(0.7, 0.7),
                    )
                  ]),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText('Прошу подвезти...', textStyle: colorizeTextStyle, colors: colorizeColors, textAlign: TextAlign.center),
                          ColorizeAnimatedText('Пожалуйста подождите...', textStyle: colorizeTextStyle, colors: colorizeColors, textAlign: TextAlign.center),
                          ColorizeAnimatedText('Поиск водителя...', textStyle: colorizeTextStyle, colors: colorizeColors, textAlign: TextAlign.center),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {
                          print('Главное событие');
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        restApp();
                      },
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(width: 2, color: Colors.grey[300]!),
                        ),
                        child: const Icon(Icons.close, size: 26),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      child: const Text('Отменить поездку', textAlign: TextAlign.center, style: TextStyle(fontSize: 12),),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng =
    LatLng(initialPos!.latitude ?? 0.0, initialPos.longitude ?? 0.0);
    var dropOffLatLng =
    LatLng(finalPos!.latitude ?? 0.0, finalPos.longitude ?? 0.0);

    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: 'Пожалуйста подождите...'));

    var details = await AssistantMethods.obtainDirectionDetails(
        pickUpLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);

    print('Это точки кодирования :: ${details!.encodePoints}');

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolyLinePointResult =
    polylinePoints.decodePolyline(details.encodePoints ?? '');
    pLineCoordinates.clear();
    if (decodePolyLinePointResult.isNotEmpty) {
      decodePolyLinePointResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: const PolylineId('PolylineId'),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        ?.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pichkUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(
          title: initialPos.placeName, snippet: 'Мое местоположение'),
      position: pickUpLatLng,
      markerId: const MarkerId('pickUpId'),
    );
    Marker dropOffLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
      InfoWindow(title: finalPos.placeName, snippet: 'Место высадки'),
      position: dropOffLatLng,
      markerId: const MarkerId('dropOffId'),
    );
    setState(() {
      markersSet.add(pichkUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: const CircleId('pickUpId'),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.deepPurple,
      circleId: const CircleId('dropOffId'),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  void initGeoFireListener() {
    Geofire.initialize('availableDrivers');
    // comment
    Geofire.queryAtLocation(currentPosition.latitude, currentPosition.longitude, 15)?.listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //широта будет получена из map['latitude']
        //долгота будет получена из map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers = NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.nearbyAvailableDriversList.add(nearbyAvailableDrivers);
            if(nearbyAvailableDriverKeysLoad == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers = NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            // Загружены все исходные данные
            print(map['result']);

            break;
        }
      }

      setState(() {});
    }
    );
    // comment
  }

  void updateAvailableDriversOnMap() {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMakers = Set<Marker>();
    for (NearbyAvailableDrivers driver in GeoFireAssistant.nearbyAvailableDriversList) {
      LatLng driverAvailablePosition = LatLng(driver.latitude!, driver.longitude!);

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvailablePosition,
        icon: nearByIcon!,
        rotation: AssistantMethods.createRandomNumber(360),
      );
      tMakers.add(marker);
    }

    setState(() {
      markersSet = tMakers;
    });
  }

  void createIconMarker() {
    if (nearByIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, 'assets/images/car_android.png').then((value) => {
        nearByIcon = value,
      }
      );
    }
  }

  void noDriverFound() {
    showDialog(context: context,barrierDismissible: false, builder: (BuildContext context) => const NoDriverAvailableDialog()
    );
  }

  void searchNearestDriver() {

    if (availableDrivers!.isEmpty) {
      cancelRideRequest();
      restApp();
      noDriverFound();
      return;
    }
    var driver = availableDrivers![0];
    notifyDriver(driver);
    availableDrivers!.removeAt(0);
  }

  void notifyDriver(NearbyAvailableDrivers driver) {
    driversRef.child(driver.key!).child('newRide').set(rideRequestRef!.key);

    driversRef.child(driver.key!).child('token').once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        String token = event.snapshot.value.toString();
        AssistantMethods.sendNotificationToDriver(token, context, rideRequestRef!.key!);
      }
    }
    );
  }
}
