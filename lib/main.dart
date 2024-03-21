import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

void main() {
  runApp(MaterialApp(
    home: GoogleMapSearchPlacesApi(),
  ));
}

class GoogleMapSearchPlacesApi extends StatefulWidget {
  const GoogleMapSearchPlacesApi({Key? key}) : super(key: key);

  @override
  _GoogleMapSearchPlacesApiState createState() =>
      _GoogleMapSearchPlacesApiState();
}

class _GoogleMapSearchPlacesApiState extends State<GoogleMapSearchPlacesApi> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  var uuid = const Uuid();
  String _sessionToken = '1234567890';
  List<dynamic> _sourcePlaceList = [];
  List<dynamic> _destinationPlaceList = [];
  final String PLACES_API_KEY = "AIzaSyCP3qu-d2OgoVc7rv8Lq9PVbL-aFICr-Qc";

  @override
  void initState() {
    super.initState();
    _sourceController.addListener(() {
      _onChanged(_sourceController.text, isSource: true);
    });
    _destinationController.addListener(() {
      _onChanged(_destinationController.text, isSource: false);
    });
  }

  _onChanged(String input, {required bool isSource}) {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(input, isSource: isSource);
  }

  void _onLocationSelected(String placeId, bool isSource) async {
    try {
      String placeDetailsUrl =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$PLACES_API_KEY';
      var response = await http.get(Uri.parse(placeDetailsUrl));
      if (response.statusCode == 200) {
        var placeDetails = json.decode(response.body)['result'];
        double lat = placeDetails['geometry']['location']['lat'];
        double lng = placeDetails['geometry']['location']['lng'];
        if (isSource) {
          setState(() {
            _sourceController.text = placeDetails['formatted_address'];
          });
        } else {
          print('Destination Latitude: $lat, Longitude: $lng');
        }
      } else {
        throw Exception('Failed to load place details');
      }
    } catch (e) {
      print(e);
    }
  }

  void getSuggestion(String input, {required bool isSource}) async {
    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=$input&key=$PLACES_API_KEY&sessiontoken=$_sessionToken';
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);
      if (kDebugMode) {
        print('mydata');
        print(data);
      }
      if (response.statusCode == 200) {
        setState(() {
          if (isSource) {
            _sourcePlaceList = json.decode(response.body)['predictions'];
          } else {
            _destinationPlaceList = json.decode(response.body)['predictions'];
          }
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Search places Api',
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _sourceController,
              decoration: InputDecoration(
                labelText: "Source Location",
                hintText: "Search your source location here",
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _sourcePlaceList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    String placeId = _sourcePlaceList[index]['place_id'];
                    _onLocationSelected(placeId, true);
                  },
                  child: ListTile(
                    title: Text(_sourcePlaceList[index]["description"]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: "Destination Location",
                hintText: "Search your destination location here",
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _destinationPlaceList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    String placeId = _destinationPlaceList[index]['place_id'];
                    _onLocationSelected(placeId, false);
                  },
                  child: ListTile(
                    title: Text(_destinationPlaceList[index]["description"]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
