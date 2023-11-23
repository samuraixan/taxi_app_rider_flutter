import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/configMaps.dart';
import '../DataHandler/appData.dart';
import '../Models/address.dart';
import '../Models/allUsers.dart';
import '../Models/directDetails.dart';
import 'requestAssistant.dart';
import 'package:http/http.dart' as http;


class AssistantMethods {
  static Future<String> searchCoordinateAddress(Position position, context) async {
    String placeAddress = '';
    String st1, st2, st3;
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    var response = await RequestAssistant.getRequest(url);

    if (response != 'Провал') {
      if (response['results'].isNotEmpty) {
        st1 = response['results'][0]['address_components'][1]['long_name'];
        st2 = response['results'][0]['address_components'][2]['long_name'];
        st3 = response['results'][0]['address_components'][3]['long_name'];
        // st4 = response['results'][0]['address_components'][4]['long_name'];

        placeAddress = '$st1, $st2, $st3';
      }

      Address userPickUpAddress = Address();
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
    } else {
      return 'Местоположение';
    }
    return placeAddress;
  }

  static Future<DirectionDetails?> obtainDirectionDetails(LatLng initialPosition, LatLng finalPosition) async {
    String directionUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude}, ${initialPosition.longitude}&destination=${finalPosition.latitude}, ${finalPosition.longitude}&key=$mapKey";
    var res = await RequestAssistant.getRequest(directionUrl);
    if(res == 'Провал') {
      return null;
    }

    if(res['routes'].isEmpty) {
      return null;
    } else {
      DirectionDetails directionDetails = DirectionDetails();
      directionDetails.encodePoints = res['routes'][0]['overview_polyline']['points'];
      directionDetails.distanceText = res['routes'][0]['legs'][0]['distance']['text'];
      directionDetails.distanceValue = res['routes'][0]['legs'][0]['distance']['value'];
      directionDetails.durationText = res['routes'][0]['legs'][0]['duration']['text'];
      directionDetails.durationValue = res['routes'][0]['legs'][0]['duration']['value'];

      return directionDetails;
    }
  }

  static int calculateFares(DirectionDetails directionDetails)  {
    // in terms USD
    double timeTraveledFare = (directionDetails.durationValue! / 60) * 0.20;
    double distanceTraveledFare = (directionDetails.distanceValue! / 1000) * 0.20;
    double totalFareAmount = timeTraveledFare + distanceTraveledFare;
    //   Местная валюта
    // 1$ = 10120 so`m
    // double totalLocalAmount = totalFareAmount * 10120

    return totalFareAmount.truncate();
  }

  static void getCurrentOnlineUserInfo() async {
    firebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = firebaseUser?.uid ?? '';
    DatabaseReference reference = FirebaseDatabase.instance.ref().child('users').child(userId);

    reference.once().then((event) {
      final dataSnapshot = event.snapshot;
      if(dataSnapshot.value != null) {
        userCurrentInfo = Users.fromSnapshot(dataSnapshot);
      }
    });
  }

  static double createRandomNumber(int num) {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }

  static sendNotificationToDriver(String token, context, String ride_request_id) async {
    var destination = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map<String, String> headerMap = {
      'Content-Type': 'application/json',
      'Authorization': serverToken,
    };
    Map notificationMap = {
      'body': 'DropOff Address, ${destination?.placeName}',
      'title': 'Новый запрос на поездку'
    };
    Map dataMap = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'ride_request_id': ride_request_id
    };
    Map sendNotificationMap = {
      'notification': notificationMap,
      'data': dataMap,
      'to': token
    };

    var res = await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: headerMap,
        body: jsonEncode(sendNotificationMap)
    );
  }
}
