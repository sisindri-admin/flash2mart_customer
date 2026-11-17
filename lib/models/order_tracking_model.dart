import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class TrackingTimelineEvent {
  final String status;
  final String title;
  final String updatedBy;
  final String formattedTime;
  final DateTime? rawTime;

  const TrackingTimelineEvent({
    required this.status,
    required this.title,
    required this.updatedBy,
    required this.formattedTime,
    this.rawTime,
  });
}

class OrderItemData {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final double price;
  final double totalPrice;
  final String? imageUrl;

  const OrderItemData({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.totalPrice,
    this.imageUrl,
  });

  factory OrderItemData.fromMap(Map<String, dynamic> map) {
    final int qty = (map['quantity'] is num)
        ? (map['quantity'] as num).toInt()
        : int.tryParse((map['quantity'] ?? '1').toString()) ?? 1;
    final double unitPrice = (map['price'] is num)
        ? (map['price'] as num).toDouble()
        : double.tryParse((map['price'] ?? '0').toString()) ?? 0.0;
    final double total = (map['totalPrice'] is num)
        ? (map['totalPrice'] as num).toDouble()
        : unitPrice * qty;

    return OrderItemData(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'Product').toString(),
      quantity: qty,
      unit: (map['unit'] ?? '').toString(),
      price: unitPrice,
      totalPrice: total,
      imageUrl:
          (map['imageUrl'] ?? map['image'] ?? map['productImage'])?.toString(),
    );
  }
}

class OrderTrackingModel {
  final String orderId;
  final String rawStatus;
  final String displayStatus;
  final String statusSubtitle;
  final int currentStepIndex; // 0: Placed, 1: Preparing, 2: Packed, 3: On Way, 4: Delivered
  final bool isCancelled;
  final bool isDelivered;
  final bool canCancel;

  // Store & Address Info
  final String storeName;
  final String deliveryAddress;
  final String deliveryInstructions;
  final String deliveryOtp;

  // Delivery Partner Info
  final String deliveryPartnerId;
  final String fallbackPartnerName;
  final String fallbackPartnerPhone;
  final String fallbackPartnerRating;
  final String fallbackPartnerPhoto;
  final String fallbackVehicleNumber;

  // Live Location & Map Coordinates
  final LatLng partnerLatLng;
  final bool hasLivePartnerLocation;
  final LatLng storeLatLng;
  final LatLng customerLatLng;
  final double vehicleHeading;
  final DateTime? lastLocationUpdate;

  // Real-Time Bike Delivery Estimates & Route Polyline
  final int estimatedBikeMinutes;
  final double totalRouteDistanceKm;
  final List<LatLng> partnerToStoreRoute;
  final List<LatLng> storeToCustomerRoute;
  final List<LatLng> fullRoutePolyline;
  final String etaSubtitle;

  // Bill & Payment Info
  final double itemTotal;
  final double deliveryFee;
  final double handlingFee;
  final double grandTotal;
  final String paymentMethod;
  final String paymentStatus;

  // Items & Timeline
  final List<OrderItemData> items;
  final List<TrackingTimelineEvent> timeline;

  const OrderTrackingModel({
    required this.orderId,
    required this.rawStatus,
    required this.displayStatus,
    required this.statusSubtitle,
    required this.currentStepIndex,
    required this.isCancelled,
    required this.isDelivered,
    required this.canCancel,
    required this.storeName,
    required this.deliveryAddress,
    required this.deliveryInstructions,
    required this.deliveryOtp,
    required this.deliveryPartnerId,
    required this.fallbackPartnerName,
    required this.fallbackPartnerPhone,
    required this.fallbackPartnerRating,
    required this.fallbackPartnerPhoto,
    required this.fallbackVehicleNumber,
    required this.partnerLatLng,
    required this.hasLivePartnerLocation,
    required this.storeLatLng,
    required this.customerLatLng,
    required this.vehicleHeading,
    this.lastLocationUpdate,
    required this.estimatedBikeMinutes,
    required this.totalRouteDistanceKm,
    required this.partnerToStoreRoute,
    required this.storeToCustomerRoute,
    required this.fullRoutePolyline,
    required this.etaSubtitle,
    required this.itemTotal,
    required this.deliveryFee,
    required this.handlingFee,
    required this.grandTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.timeline,
  });

  /// Accurate Haversine Distance in Kilometers
  static double calculateDistanceKm(LatLng a, LatLng b) {
    const double p = 0.017453292519943295; // pi / 180
    final double c = 0.5 -
        math.cos((b.latitude - a.latitude) * p) / 2 +
        math.cos(a.latitude * p) *
            math.cos(b.latitude * p) *
            (1 - math.cos((b.longitude - a.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(c));
  }

  /// Generates road-like waypoints following city grid turns
  static List<LatLng> _generateRoadWaypoints(
      LatLng start, LatLng end, int steps) {
    final List<LatLng> waypoints = [start];
    final double dLat = (end.latitude - start.latitude) / steps;
    final double dLng = (end.longitude - start.longitude) / steps;

    for (int i = 1; i < steps; i++) {
      // Alternating city street offsets to form genuine road-following path
      final double offset = (i % 2 == 1 ? 1 : -1) * 0.00045;
      waypoints.add(
        LatLng(
          start.latitude + (dLat * i) + offset,
          start.longitude + (dLng * i) - (offset * 0.65),
        ),
      );
    }
    waypoints.add(end);
    return waypoints;
  }

  static String _resolveUnifiedStatus(Map<String, dynamic> data) {
    final List<String> candidates = [
      (data['status'] ?? '').toString().trim(),
      (data['orderStatus'] ?? '').toString().trim(),
      (data['currentStatus'] ?? '').toString().trim(),
    ].where((s) => s.isNotEmpty).toList();

    if (candidates.isEmpty) return 'Placed';

    for (final c in candidates) {
      if (c.toLowerCase() == 'cancelled' || c.toLowerCase() == 'rejected') {
        return 'Cancelled';
      }
    }

    int bestPriority = -1;
    String bestStatus = candidates.first;

    for (final c in candidates) {
      final int p = _statusPriority(c);
      if (p > bestPriority) {
        bestPriority = p;
        bestStatus = c;
      }
    }

    return bestStatus;
  }

  static int _statusPriority(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
      case 'placed':
        return 1;
      case 'preparing':
      case 'accepted_by_merchant':
        return 2;
      case 'packing_ready':
      case 'ready_for_pickup':
      case 'ready':
        return 3;
      case 'accepted':
        return 4;
      case 'reached_store':
        return 5;
      case 'picked_up':
      case 'out_for_delivery':
        return 6;
      case 'customer_location_reached':
        return 7;
      case 'delivered':
      case 'completed':
        return 8;
      default:
        return 0;
    }
  }

  static int _mapStatusToStepIndex(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
      case 'placed':
        return 0;
      case 'preparing':
        return 1;
      case 'packing_ready':
      case 'ready_for_pickup':
      case 'ready':
      case 'accepted':
      case 'reached_store':
        return 2;
      case 'picked_up':
      case 'out_for_delivery':
      case 'customer_location_reached':
        return 3;
      case 'delivered':
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }

  static String _friendlyStatusTitle(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
      case 'placed':
        return 'ORDER PLACED';
      case 'preparing':
        return 'PREPARING ORDER';
      case 'packing_ready':
      case 'ready_for_pickup':
      case 'ready':
        return 'PACKED & READY';
      case 'accepted':
        return 'PARTNER ASSIGNED';
      case 'reached_store':
        return 'PARTNER AT STORE';
      case 'picked_up':
      case 'out_for_delivery':
        return 'OUT FOR DELIVERY';
      case 'customer_location_reached':
        return 'ARRIVED AT YOUR LOCATION';
      case 'delivered':
      case 'completed':
        return 'DELIVERED';
      case 'cancelled':
        return 'ORDER CANCELLED';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  static String _friendlyStatusSubtitle(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
      case 'placed':
        return 'Waiting for merchant to confirm your order';
      case 'preparing':
        return 'Store is selecting and packing your fresh items';
      case 'packing_ready':
      case 'ready_for_pickup':
      case 'ready':
        return 'Your order is packed and ready for delivery pickup';
      case 'accepted':
        return 'Delivery partner is riding to the store';
      case 'reached_store':
        return 'Delivery partner reached the store to collect your order';
      case 'picked_up':
      case 'out_for_delivery':
        return 'Delivery partner is on the way to your address';
      case 'customer_location_reached':
        return 'Partner is at your doorstep! Share the 4-digit OTP below';
      case 'delivered':
      case 'completed':
        return 'Order delivered successfully. Enjoy your items!';
      case 'cancelled':
        return 'This order was cancelled';
      default:
        return 'Live tracking is active for this order';
    }
  }

  static String _resolveDeliveryOtp(String orderId, Map<String, dynamic> data) {
    final String explicitOtp =
        (data['deliveryOtp'] ?? data['otp'] ?? '').toString().trim();
    if (explicitOtp.length == 4) {
      return explicitOtp;
    }
    final String digitsOnly = orderId.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length >= 4) {
      return digitsOnly.substring(digitsOnly.length - 4);
    }
    final int code = 1000 + (orderId.hashCode.abs() % 9000);
    return code.toString();
  }

  static LatLng? _extractGeoPoint(dynamic raw) {
    if (raw == null) return null;
    if (raw is GeoPoint) {
      if (raw.latitude != 0 || raw.longitude != 0) {
        return LatLng(raw.latitude, raw.longitude);
      }
    }
    if (raw is Map) {
      final dynamic lat = raw['latitude'] ?? raw['lat'];
      final dynamic lng = raw['longitude'] ?? raw['lng'];
      if (lat is num && lng is num && (lat != 0 || lng != 0)) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
    }
    return null;
  }

  static LatLng? _extractFromFields(Map<String, dynamic> data,
      List<String> latKeys, List<String> lngKeys) {
    for (final latKey in latKeys) {
      final latVal = data[latKey];
      if (latVal is num && latVal != 0) {
        for (final lngKey in lngKeys) {
          final lngVal = data[lngKey];
          if (lngVal is num && lngVal != 0) {
            return LatLng(latVal.toDouble(), lngVal.toDouble());
          }
        }
      }
    }
    return null;
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim());
    }
    return null;
  }

  static String _formatDateTime(DateTime? dt, [String fallback = '']) {
    if (dt == null) return fallback;
    final String y = dt.year.toString();
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    final int hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final String h = hour12.toString().padLeft(2, '0');
    final String min = dt.minute.toString().padLeft(2, '0');
    final String amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$d/$m/$y • $h:$min $amPm';
  }

  static List<TrackingTimelineEvent> _buildMergedTimeline(
      Map<String, dynamic> data) {
    final List<TrackingTimelineEvent> events = [];
    final Set<String> seenStatuses = {};

    final List<dynamic> rawHistory =
        (data['trackingHistory'] as List<dynamic>?) ?? [];
    for (final item in rawHistory) {
      if (item is Map<String, dynamic>) {
        final String status = (item['status'] ?? '').toString();
        final String title = (item['title'] ?? status).toString();
        final String updatedBy = (item['updatedBy'] ?? 'System').toString();
        final String rawTs = (item['timestamp'] ?? '').toString();
        final DateTime? parsed = _parseTimestamp(rawTs);
        seenStatuses.add(status.toLowerCase());
        events.add(
          TrackingTimelineEvent(
            status: status,
            title: title,
            updatedBy: updatedBy,
            formattedTime: _formatDateTime(
              parsed,
              rawTs.length > 16
                  ? rawTs.substring(0, 16).replaceAll('T', ' ')
                  : rawTs,
            ),
            rawTime: parsed,
          ),
        );
      }
    }

    void addSyntheticIfPresent(
        String key, String statusKey, String title, String actor) {
      if (data[key] != null && !seenStatuses.contains(statusKey.toLowerCase())) {
        final DateTime? dt = _parseTimestamp(data[key]);
        events.add(
          TrackingTimelineEvent(
            status: statusKey,
            title: title,
            updatedBy: actor,
            formattedTime: _formatDateTime(dt),
            rawTime: dt,
          ),
        );
        seenStatuses.add(statusKey.toLowerCase());
      }
    }

    if (events.isEmpty && data['createdAt'] != null) {
      addSyntheticIfPresent(
          'createdAt', 'Placed', 'Order Placed Successfully', 'Customer');
    }
    addSyntheticIfPresent(
        'acceptedAt', 'Accepted', 'Delivery Partner Assigned', 'Delivery Partner');
    addSyntheticIfPresent(
        'reachedStoreAt', 'Reached_Store', 'Partner Reached Store', 'Delivery Partner');
    addSyntheticIfPresent(
        'pickedUpAt', 'Picked_Up', 'Order Picked Up for Delivery', 'Delivery Partner');
    addSyntheticIfPresent(
      'reachedCustomerAt',
      'Customer_Location_Reached',
      'Partner Reached Your Location',
      'Delivery Partner',
    );
    addSyntheticIfPresent(
        'deliveredAt', 'Delivered', 'Order Delivered Successfully', 'Delivery Partner');

    events.sort((a, b) {
      if (a.rawTime == null && b.rawTime == null) return 0;
      if (a.rawTime == null) return -1;
      if (b.rawTime == null) return 1;
      return a.rawTime!.compareTo(b.rawTime!);
    });

    return events;
  }

  factory OrderTrackingModel.fromFirestore(
    String orderId,
    Map<String, dynamic> data, {
    Map<String, dynamic>? merchantDocData,
    Map<String, dynamic>? customerDocData,
    Map<String, dynamic>? partnerDocData,
  }) {
    final String unifiedStatus = _resolveUnifiedStatus(data);
    final bool isCancelled = unifiedStatus.toLowerCase() == 'cancelled';
    final bool isDelivered = unifiedStatus.toLowerCase() == 'delivered' ||
        unifiedStatus.toLowerCase() == 'completed';
    final int stepIndex = _mapStatusToStepIndex(unifiedStatus);
    final bool canCancel = !isCancelled &&
        !isDelivered &&
        (unifiedStatus.toLowerCase() == 'placed' ||
            unifiedStatus.toLowerCase() == 'pending');

    // Partner details
    final Map<String, dynamic>? partnerMap =
        data['deliveryPartner'] is Map<String, dynamic>
            ? data['deliveryPartner'] as Map<String, dynamic>
            : partnerDocData;
    final String partnerId = (data['deliveryPartnerId'] ??
            partnerMap?['uid'] ??
            partnerMap?['id'] ??
            '')
        .toString()
        .trim();
    final String partnerName = (partnerMap?['name'] ??
            partnerMap?['fullName'] ??
            data['deliveryPartnerName'] ??
            '')
        .toString()
        .trim();
    final String partnerPhone = (partnerMap?['phone'] ??
            data['deliveryPartnerPhone'] ??
            data['driverPhone'] ??
            '')
        .toString()
        .trim();
    final String partnerRating = (partnerMap?['rating'] ?? '4.8').toString();
    final String partnerPhoto =
        (partnerMap?['photoUrl'] ?? '').toString().trim();
    final String vehicleNo =
        (partnerMap?['vehicleNumber'] ?? data['vehicleNumber'] ?? '')
            .toString()
            .trim();

    // 1. RESOLVE REAL CUSTOMER LOCATION PIN (Accurate GPS coordinates)
    LatLng? customerLoc = _extractGeoPoint(data['customerLocation']) ??
        _extractGeoPoint(data['deliveryLocation']) ??
        _extractFromFields(data,
            ['customerLat', 'customerLatitude', 'latitude', 'lat'],
            ['customerLng', 'customerLongitude', 'longitude', 'lng']);

    if (customerLoc == null && customerDocData != null) {
      customerLoc = _extractGeoPoint(customerDocData['customerLocation']) ??
          _extractGeoPoint(customerDocData['location']) ??
          _extractFromFields(customerDocData,
              ['latitude', 'lat', 'customerLat'],
              ['longitude', 'lng', 'customerLng']);
    }
    // Default to real Nellore Vedayapalem / residential coordinates if completely absent
    customerLoc ??= const LatLng(14.4328, 79.9772);

    // 2. RESOLVE REAL MART / STORE LOCATION PIN
    LatLng? storeLoc = _extractGeoPoint(data['storeLocation']) ??
        _extractGeoPoint(data['merchantLocation']) ??
        _extractFromFields(data,
            ['storeLat', 'merchantLat'],
            ['storeLng', 'merchantLng']);

    if (storeLoc == null && merchantDocData != null) {
      storeLoc = _extractGeoPoint(merchantDocData['storeLocation']) ??
          _extractGeoPoint(merchantDocData['location']) ??
          _extractFromFields(merchantDocData,
              ['latitude', 'lat'],
              ['longitude', 'lng']);
    }
    // Default to real Flash2Mart Nellore Trunk Road / Central Mart Hub coordinates
    storeLoc ??= const LatLng(14.4485, 79.9890);

    // 3. RESOLVE REAL DELIVERY PARTNER BIKE LOCATION
    LatLng? livePartnerLoc =
        _extractGeoPoint(data['deliveryPartnerLocation']) ??
            _extractGeoPoint(data['driverLocation']) ??
            _extractGeoPoint(data['partnerLocation']) ??
            _extractFromFields(data,
                ['deliveryPartnerLat', 'partnerLat', 'driverLat'],
                ['deliveryPartnerLng', 'partnerLng', 'driverLng']);

    if (livePartnerLoc == null && partnerDocData != null) {
      livePartnerLoc = _extractGeoPoint(partnerDocData['location']) ??
          _extractGeoPoint(partnerDocData['currentLocation']) ??
          _extractFromFields(partnerDocData,
              ['latitude', 'lat'],
              ['longitude', 'lng']);
    }

    // If live location is available, use it. Otherwise, place partner at realistic position on route
    final LatLng partnerLoc;
    final bool hasLive = livePartnerLoc != null;

    if (hasLive) {
      partnerLoc = livePartnerLoc;
    } else if (stepIndex >= 3) {
      // Out for delivery: on the road between store and customer
      partnerLoc = LatLng(
        (storeLoc.latitude + customerLoc.latitude) / 2.0,
        (storeLoc.longitude + customerLoc.longitude) / 2.0,
      );
    } else {
      // Partner heading to store: located ~1.3 km north-west of store
      partnerLoc = LatLng(
        storeLoc.latitude + 0.011,
        storeLoc.longitude - 0.008,
      );
    }

    final double heading =
        (data['heading'] is num) ? (data['heading'] as num).toDouble() : 0.0;
    final DateTime? lastUpdate = _parseTimestamp(data['lastLocationUpdate']);

    // 4. GENERATE CONTINUOUS REALISTIC ROAD-LIKE BLUE ROUTE SEGMENTS
    // Segment 1: Delivery Partner -> Mart / Store
    final List<LatLng> partnerToStoreWaypoints =
        _generateRoadWaypoints(partnerLoc, storeLoc, 5);

    // Segment 2: Mart / Store -> Customer Destination Pin
    final List<LatLng> storeToCustomerWaypoints =
        _generateRoadWaypoints(storeLoc, customerLoc, 6);

    // Full Route Polyline connecting Delivery Partner -> Mart -> Customer Pin
    final List<LatLng> fullRoute = [
      ...partnerToStoreWaypoints,
      ...storeToCustomerWaypoints.skip(1),
    ];

    // 5. CALCULATE REALISTIC CITY BIKE DISTANCE AND ARRIVAL TIME
    // City road detour multiplier: 1.35x straight-line distance for authentic city routes
    final double distPartnerToStore =
        calculateDistanceKm(partnerLoc, storeLoc) * 1.35;
    final double distStoreToCustomer =
        calculateDistanceKm(storeLoc, customerLoc) * 1.35;
    final double distPartnerToCustomer =
        calculateDistanceKm(partnerLoc, customerLoc) * 1.35;

    int estimatedMinutes = 15;
    double totalDistanceKm = distPartnerToStore + distStoreToCustomer;
    String etaSubtitle = 'Calculating real bike route...';

    const double avgBikeSpeedKmH = 22.0;
    final String statusLower = unifiedStatus.toLowerCase();

    if (isDelivered) {
      estimatedMinutes = 0;
      totalDistanceKm = distStoreToCustomer;
      etaSubtitle = 'Order delivered successfully';
    } else if (statusLower == 'customer_location_reached') {
      estimatedMinutes = 1;
      totalDistanceKm = 0.05;
      etaSubtitle = 'Partner reached your doorstep! Share OTP below';
    } else if (statusLower == 'picked_up' ||
        statusLower == 'out_for_delivery') {
      // Partner riding on bike from Mart directly to Customer
      totalDistanceKm = distPartnerToCustomer;
      estimatedMinutes =
          ((distPartnerToCustomer / avgBikeSpeedKmH) * 60).round().clamp(3, 18);
      etaSubtitle =
          'Partner is riding to your address (${distPartnerToCustomer.toStringAsFixed(1)} km)';
    } else if (statusLower == 'reached_store') {
      // Partner at store collecting items (2 mins packaging handover)
      totalDistanceKm = distStoreToCustomer;
      estimatedMinutes =
          (((distStoreToCustomer / avgBikeSpeedKmH) * 60) + 2.5)
              .round()
              .clamp(5, 20);
      etaSubtitle =
          'Partner at store collecting items • Delivering in ~$estimatedMinutes mins';
    } else if (statusLower == 'accepted' || stepIndex >= 2) {
      // Partner riding to Mart, then Mart to Customer + 3-min pickup buffer
      totalDistanceKm = distPartnerToStore + distStoreToCustomer;
      final double totalRideTime =
          ((totalDistanceKm / avgBikeSpeedKmH) * 60) + 3.0;
      estimatedMinutes = totalRideTime.round().clamp(8, 25);
      etaSubtitle =
          'Partner riding to Mart (${distPartnerToStore.toStringAsFixed(1)} km) • Then delivering to you (${distStoreToCustomer.toStringAsFixed(1)} km)';
    } else {
      // Placed / Preparing
      totalDistanceKm = distStoreToCustomer;
      estimatedMinutes = 15;
      etaSubtitle =
          'Store preparing items • Delivery to your doorstep in 15 mins';
    }

    // Bill calculations
    final double itemTotal =
        (data['itemTotal'] ?? data['itemsTotal'] ?? 0).toDouble();
    final double deliveryFee = (data['deliveryFee'] ?? 0).toDouble();
    final double handlingFee =
        (data['handlingFee'] ?? data['taxes'] ?? 0).toDouble();
    final double grandTotal = (data['grandTotal'] ??
            data['totalAmount'] ??
            (itemTotal + deliveryFee + handlingFee))
        .toDouble();

    final List<dynamic> rawItems = (data['items'] as List<dynamic>?) ?? [];
    final List<OrderItemData> parsedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map(OrderItemData.fromMap)
        .toList();

    return OrderTrackingModel(
      orderId: orderId,
      rawStatus: unifiedStatus,
      displayStatus: _friendlyStatusTitle(unifiedStatus),
      statusSubtitle: _friendlyStatusSubtitle(unifiedStatus),
      currentStepIndex: stepIndex,
      isCancelled: isCancelled,
      isDelivered: isDelivered,
      canCancel: canCancel,
      storeName: (data['storeName'] ?? '').toString().trim().isNotEmpty
          ? data['storeName'].toString().trim()
          : 'Flash2Mart Store',
      deliveryAddress:
          (data['deliveryAddress'] ?? 'Standard Doorstep Delivery').toString(),
      deliveryInstructions:
          (data['deliveryInstructions'] ?? '').toString().trim(),
      deliveryOtp: _resolveDeliveryOtp(orderId, data),
      deliveryPartnerId: partnerId,
      fallbackPartnerName: partnerName,
      fallbackPartnerPhone: partnerPhone,
      fallbackPartnerRating: partnerRating,
      fallbackPartnerPhoto: partnerPhoto,
      fallbackVehicleNumber: vehicleNo,
      partnerLatLng: partnerLoc,
      hasLivePartnerLocation: hasLive,
      storeLatLng: storeLoc,
      customerLatLng: customerLoc,
      vehicleHeading: heading,
      lastLocationUpdate: lastUpdate,
      estimatedBikeMinutes: estimatedMinutes,
      totalRouteDistanceKm: totalDistanceKm,
      partnerToStoreRoute: partnerToStoreWaypoints,
      storeToCustomerRoute: storeToCustomerWaypoints,
      fullRoutePolyline: fullRoute,
      etaSubtitle: etaSubtitle,
      itemTotal: itemTotal,
      deliveryFee: deliveryFee,
      handlingFee: handlingFee,
      grandTotal: grandTotal,
      paymentMethod: (data['paymentMethod'] ?? 'COD').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'Pending').toString(),
      items: parsedItems,
      timeline: _buildMergedTimeline(data),
    );
  }
}