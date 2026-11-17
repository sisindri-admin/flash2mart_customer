import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<String> getCurrentAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Location Service చెక్ చేయడం
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'GPS / Location Disabled';
    }

    // 2. Permission చెక్ చేయడం
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location Permission Denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location Permission Denied';
    }

    try {
      // 3. Current Latitude & Longitude తీసుకోవడం
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      // 4. Flutter WEB (Chrome) ఐతే OpenStreetMap API వాడుతుంది
      if (kIsWeb) {
        return await _getAddressFromWebAPI(position.latitude, position.longitude);
      }

      // 5. ANDROID / IOS ఐతే Native Geocoding వాడుతుంది
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String street = place.street ?? '';
        String subLocality = place.subLocality ?? '';
        String locality = place.locality ?? '';
        String postalCode = place.postalCode ?? '';

        List<String> parts = [];
        if (street.isNotEmpty) parts.add(street);
        if (subLocality.isNotEmpty && !street.contains(subLocality)) parts.add(subLocality);
        if (locality.isNotEmpty) parts.add(locality);
        if (postalCode.isNotEmpty) parts.add(postalCode);

        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (e) {
      debugPrint('Location Fetch Error: $e');
      return 'Nellore, Andhra Pradesh'; // Fallback Address
    }

    return 'Netaji Nagar, Nellore';
  }

  // Web Browser లో Geocoding సపోర్ట్ చేయడానికి వెబ్ హెల్పర్ మెథడ్
  static Future<String> _getAddressFromWebAPI(double lat, double lng) async {
    try {
      // 'zoom=18' ఇస్తే బిల్డింగ్ లేదా రోడ్ లెవెల్ కచ్చితత్వం వస్తుంది
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'Flash2MartCustomerApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          String houseNumber = address['house_number'] ?? '';
          String road = address['road'] ?? address['pedestrian'] ?? address['suburb'] ?? '';
          String neighbourhood = address['neighbourhood'] ?? address['residential'] ?? '';
          String city = address['city'] ?? address['town'] ?? address['village'] ?? '';
          String postcode = address['postcode'] ?? '';

          List<String> parts = [];
          if (houseNumber.isNotEmpty) parts.add('D.No: $houseNumber');
          if (road.isNotEmpty) parts.add(road);
          if (neighbourhood.isNotEmpty && neighbourhood != road) parts.add(neighbourhood);
          if (city.isNotEmpty) parts.add(city);
          if (postcode.isNotEmpty) parts.add(postcode);

          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('Web Geocoding API Error: $e');
    }
    return 'Vedayapalem, Nellore';
  }
}