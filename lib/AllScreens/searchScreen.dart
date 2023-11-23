import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/AllWidgets/progressDialog.dart';

import '../AllWidgets/Divider.dart';
import '../Assistants/requestAssistant.dart';
import '../DataHandler/appData.dart';
import '../Models/address.dart';
import '../Models/placePredictions.dart';
import '../configMaps.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController pickupController = TextEditingController();
  TextEditingController dropOffTextController = TextEditingController();
  List<PlacePredictions> placePredictionList = [];

  @override
  Widget build(BuildContext context) {
    String placeAddress =
        Provider.of<AppData>(context).pickUpLocation?.placeName ?? '';
    pickupController.text = placeAddress;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 215,
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 6,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7),
                )
              ]),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 25, top: 30, right: 25, bottom: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    Stack(
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(Icons.arrow_back)),
                        const Center(
                          child: Text(
                            'Установить отбытие',
                            style:
                            TextStyle(fontSize: 18, fontFamily: 'Rowdies'),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Image.asset('assets/images/pickicon.png',
                            height: 16, width: 16),
                        const SizedBox(height: 17),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: TextField(
                                controller: pickupController,
                                decoration: InputDecoration(
                                  hintText: 'Место получения',
                                  fillColor: Colors.grey[400],
                                  filled: true,
                                  contentPadding: const EdgeInsets.only(
                                      left: 11, top: 8, bottom: 8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Image.asset('assets/images/desticon.png',
                            height: 16, width: 16),
                        const SizedBox(height: 17),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: TextField(
                                onChanged: (val) {
                                  findPlace(val);
                                },
                                controller: dropOffTextController,
                                decoration: InputDecoration(
                                  hintText: 'Куда направляться?',
                                  fillColor: Colors.grey[400],
                                  filled: true,
                                  contentPadding: const EdgeInsets.only(
                                      left: 11, top: 8, bottom: 8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            // плитка для предсказаний
            const SizedBox(height: 10),
            (placePredictionList.isNotEmpty)
                ? Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListView.separated(
                padding: const EdgeInsets.all(0),
                itemBuilder: (context, index) {
                  return PredictionTile(
                      placePredictions: placePredictionList[index]);
                },
                separatorBuilder: (BuildContext context, int index) =>
                const DividerWidget(),
                itemCount: placePredictionList.length,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
              ),
            )
                : Container()
          ],
        ),
      ),
    );
  }

  void findPlace(String placeName) async {
    if (placeName.isNotEmpty) {
      String autoCompleteUrl =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:uz';
      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if (res == 'Провал') {
        return;
      }
      if (res['status'] == 'OK') {
        var predictions = res['predictions'];
        var placeList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();
        setState(() {
          placePredictionList = placeList;
        });
      }
    }
  }
}

class PredictionTile extends StatelessWidget {
  const PredictionTile({super.key, required this.placePredictions});

  final PlacePredictions placePredictions;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        getPlaceAddressDetails(placePredictions.place_id!, context);
      },
      child: Container(
        child: Column(
          children: [
            const SizedBox(width: 10),
            Row(
              children: [
                const Icon(Icons.add_location_alt_outlined),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                          placePredictions.main_text ?? 'Значение по умолчанию',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                          placePredictions.secondary_text ??
                              'Значение по умолчанию',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
            message: 'Пожалуйста ждите, идёт загрузка...'));

    String placeDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";
    var res = await RequestAssistant.getRequest(placeDetailsUrl);

    Navigator.pop(context);

    if (res == 'failed') {
      return;
    }
    if (res['status'] == 'OK') {
      Address address = Address();
      address.placeName = res['result']['name'];
      address.placeId = placeId;
      address.latitude = res['result']['geometry']['location']['lat'];
      address.longitude = res['result']['geometry']['location']['lng'];

      Provider.of<AppData>(context, listen: false)
          .updateDropeOffLocationAddress(address);
      print('Это место высадки :: ${address.placeName}');
      print(address.placeName);

      Navigator.pop(context, 'obtainDirection');
    }
  }
}
