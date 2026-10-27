import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/order_tracking_model.dart';

class LiveTrackingMapCard extends StatefulWidget {
  final OrderTrackingModel model;
  final Future<void> Function(String phoneNumber) onCallPartner;

  const LiveTrackingMapCard({
    super.key,
    required this.model,
    required this.onCallPartner,
  });

  @override
  State<LiveTrackingMapCard> createState() => _LiveTrackingMapCardState();
}

class _LiveTrackingMapCardState extends State<LiveTrackingMapCard> {
  final MapController _mapController = MapController();
  bool _autoFollow = true;
  double _currentZoom = 14.2;

  @override
  void initState() {
    super.initState();
    // After first frame, fit all 3 route points so user immediately sees Partner, Mart, and Customer Pin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitAllRouteBounds();
    });
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLat = oldWidget.model.partnerLatLng.latitude;
    final oldLng = oldWidget.model.partnerLatLng.longitude;
    final newLat = widget.model.partnerLatLng.latitude;
    final newLng = widget.model.partnerLatLng.longitude;

    if ((oldLat != newLat || oldLng != newLng) && _autoFollow) {
      try {
        _mapController.move(widget.model.partnerLatLng, _currentZoom);
      } catch (_) {}
    }
  }

  void _recenterPartner() {
    setState(() => _autoFollow = true);
    try {
      _mapController.move(widget.model.partnerLatLng, 15.0);
    } catch (_) {}
  }

  void _fitAllRouteBounds() {
    setState(() => _autoFollow = false);
    try {
      final model = widget.model;
      final List<LatLng> points = [
        model.partnerLatLng,
        model.storeLatLng,
        model.customerLatLng,
      ];
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 35),
        ),
      );
    } catch (_) {}
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1.0).clamp(3.0, 19.0);
    });
    try {
      _mapController.move(_mapController.camera.center, _currentZoom);
    } catch (_) {}
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1.0).clamp(3.0, 19.0);
    });
    try {
      _mapController.move(_mapController.camera.center, _currentZoom);
    } catch (_) {}
  }

  String _formatLastUpdateLabel(DateTime? lastUpdate, bool hasLive) {
    if (!hasLive) return 'Live Bike Route Active';
    if (lastUpdate == null) return 'Live GPS Active';
    final int seconds = DateTime.now().difference(lastUpdate).inSeconds.abs();
    if (seconds < 20) return 'Live GPS • Updated just now';
    if (seconds < 60) return 'Live GPS • ${seconds}s ago';
    final int mins = seconds ~/ 60;
    if (mins < 60) return 'Live GPS • ${mins}m ago';
    return 'Live GPS Active';
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final List<Marker> markers = [];

    // 1. MART / STORE PIN
    markers.add(
      Marker(
        point: model.storeLatLng,
        width: 80,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00875A),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3),
                ],
              ),
              child: const Text(
                'MART',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00875A), width: 2.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF00875A),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );

    // 2. CUSTOMER LOCATION PIN ("YOUR LOCATION" pin chey)
    markers.add(
      Marker(
        point: model.customerLatLng,
        width: 85,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3),
                ],
              ),
              child: const Text(
                'YOUR LOCATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2563EB), width: 2.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: const Icon(
                Icons.person_pin_circle_rounded,
                color: Color(0xFF2563EB),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );

    // 3. DELIVERY PARTNER BIKE PIN (With heading rotation & pulsing halo)
    markers.add(
      Marker(
        point: model.partnerLatLng,
        width: 54,
        height: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: (model.vehicleHeading * math.pi) / 180.0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4016A34A),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Dynamic Real-Time Bike Delivery Estimate Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: model.isDelivered
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFEFF6FF),
              border: Border(
                bottom: BorderSide(
                  color: model.isDelivered
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFBFDBFE),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: model.isDelivered
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    model.isDelivered
                        ? Icons.check_circle_rounded
                        : Icons.two_wheeler_rounded,
                    color: model.isDelivered
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              model.isDelivered
                                  ? 'Order Delivered'
                                  : 'Arriving in ~${model.estimatedBikeMinutes} Mins by Bike',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: model.isDelivered
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (!model.isDelivered)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${model.totalRouteDistanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        model.etaSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: model.isDelivered
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Interactive Map: height 250 with CORS-free Web Tile Provider & Blue Route Line
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Container(
              color: const Color(0xFFE2E8F0), // Clean placeholder background
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: model.partnerLatLng,
                      initialZoom: _currentZoom,
                      minZoom: 3.0,
                      maxZoom: 19.0,
                      onPositionChanged: (pos, hasGesture) {
                        if (hasGesture && _autoFollow) {
                          setState(() => _autoFollow = false);
                        }
                      },
                    ),
                    children: [
                      // Reliable, CORS-enabled TileLayer with native image loading
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        fallbackUrl:
                            'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.flash2mart.customer',
                        maxZoom: 19,
                      ),

                      // Blue Color Road Route Line
                      PolylineLayer(
                        polylines: [
                          // Outer glow / casing
                          Polyline(
                            points: model.fullRoutePolyline,
                            color: const Color(0x332563EB),
                            strokeWidth: 8.5,
                          ),
                          // Main Blue Route Line
                          Polyline(
                            points: model.fullRoutePolyline,
                            color: const Color(0xFF2563EB),
                            strokeWidth: 4.5,
                          ),
                        ],
                      ),

                      // 3 Pins (Partner Bike + Mart + Customer Location Pin)
                      MarkerLayer(markers: markers),
                    ],
                  ),

                  // Top-Left Live Status Badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xF0FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: model.hasLivePartnerLocation
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatLastUpdateLabel(
                              model.lastLocationUpdate,
                              model.hasLivePartnerLocation,
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top-Right Zoom Controls (+ / -)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            onTap: _zoomIn,
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(Icons.add_rounded,
                                  size: 18, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            onTap: _zoomOut,
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(Icons.remove_rounded,
                                  size: 18, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom-Right Controls: "Fit Route" + "Re-center"
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          elevation: 2,
                          child: InkWell(
                            onTap: _fitAllRouteBounds,
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.route_rounded,
                                    size: 15,
                                    color: Color(0xFF2563EB),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Fit Route',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          elevation: 2,
                          child: InkWell(
                            onTap: _recenterPartner,
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.my_location_rounded,
                                    size: 16,
                                    color: _autoFollow
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _autoFollow ? 'Tracking' : 'Center',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _autoFollow
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Delivery Partner Details Bar
          _DeliveryPartnerBar(
            model: model,
            onCallPartner: widget.onCallPartner,
          ),
        ],
      ),
    );
  }
}

class _DeliveryPartnerBar extends StatelessWidget {
  final OrderTrackingModel model;
  final Future<void> Function(String phoneNumber) onCallPartner;

  const _DeliveryPartnerBar({
    required this.model,
    required this.onCallPartner,
  });

  @override
  Widget build(BuildContext context) {
    if (model.deliveryPartnerId.isEmpty) {
      return _buildPartnerRow(
        name: model.fallbackPartnerName.isNotEmpty
            ? model.fallbackPartnerName
            : 'Assigning Delivery Partner...',
        subtitle: model.fallbackPartnerPhone.isNotEmpty
            ? '${model.fallbackPartnerRating} ★ • Verified Partner'
            : 'Partner will collect items from Mart then deliver to you',
        phone: model.fallbackPartnerPhone,
        photoUrl: model.fallbackPartnerPhoto,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('delivery_partners')
          .doc(model.deliveryPartnerId)
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> pData =
            (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

        final String resolvedName = (pData['fullName'] ??
                pData['name'] ??
                (model.fallbackPartnerName.isNotEmpty
                    ? model.fallbackPartnerName
                    : 'Delivery Partner'))
            .toString()
            .trim();

        final String resolvedPhone = (pData['phone'] ??
                pData['phoneNumber'] ??
                model.fallbackPartnerPhone)
            .toString()
            .trim();

        final String resolvedPhoto = (pData['photoUrl'] ??
                pData['profileImage'] ??
                model.fallbackPartnerPhoto)
            .toString()
            .trim();

        final String vehicleType =
            (pData['vehicleType'] ?? 'Bike').toString().trim();
        final String vehicleNo =
            (pData['vehicleNumber'] ?? model.fallbackVehicleNumber)
                .toString()
                .trim();
        final String vehicleBadge =
            vehicleNo.isNotEmpty ? '$vehicleType • $vehicleNo' : vehicleType;

        return _buildPartnerRow(
          name: resolvedName,
          subtitle: '${model.fallbackPartnerRating} ★ • $vehicleBadge',
          phone: resolvedPhone,
          photoUrl: resolvedPhoto,
        );
      },
    );
  }

  Widget _buildPartnerRow({
    required String name,
    required String subtitle,
    required String phone,
    required String photoUrl,
  }) {
    final bool hasValidPhone =
        phone.replaceAll(RegExp(r'[^\d+]'), '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0x1A00875A),
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? const Icon(
                    Icons.delivery_dining_rounded,
                    color: Color(0xFF00875A),
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (hasValidPhone)
            InkWell(
              onTap: () => onCallPartner(phone),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Assigning...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
        ],
      ),
    );
  }
}