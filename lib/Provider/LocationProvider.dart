import 'package:flutter/material.dart';

class LocationProvider extends ChangeNotifier{
  String? locationId;
  LocationProvider({this.locationId});

  void updateLocation(String newLocation){
    locationId = newLocation;
    notifyListeners();
  }

}