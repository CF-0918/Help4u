import 'package:flutter/material.dart';

class LocationProvider extends ChangeNotifier{
  String locationName;
  LocationProvider({this.locationName="Abu Workshop"});

  void updateLocation(String newLocation){
    locationName = newLocation;
    notifyListeners();
  }

}