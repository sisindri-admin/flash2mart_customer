import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
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
  static const double _defaultZoom = 15.0;

  @override
  void didUpdateWidget(covariant LiveTrackingMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLat = oldWidget.model.partnerLatLng.latitude;
    final oldLng = oldWidget.model.partnerLatLng.longitude;
    final newLat = widget.model.partnerLatLng.latitude;
    final newLng = widget.model.partnerLatLng.longitude;

    if ((oldLat != newLat || oldLng != newLng) && _autoFollow) {
      try {
        _mapController.move(widget.model.partnerLatLng, _defaultZoom);
      } catch (_) {
        // Ignore if MapController is not yet attached on first frame
      }
    }
  }

  void _recenterMap() {
    setState(() => _autoFollow = true);
    try {
      _mapController.move(widget.model.partnerLatLng, 15.5);
    } catch (_) {}
  }

  String _formatLastUpdateLabel(DateTime? lastUpdate, bool hasLive) {
    if (!hasLive) return 'Store / Area Map View';
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

    // 1. Store Marker (if available)
    if (model.storeLatLng != null) {
      markers.add(
        Marker(
          point: model.storeLatLng!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00875A), width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF00875A), size: 22),
          ),
        ),
      );
    }

    // 2. Customer Home Marker (if available)
    if (model.customerLatLng != null) {
      markers.add(
        Marker(
          point: model.customerLatLng!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2563EB), width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: const Icon(Icons.home_rounded, color: Color(0xFF2563EB), size: 22),
          ),
        ),
      );
    }

    // 3. Delivery Partner Live Marker with Heading Rotation
    markers.add(
      Marker(
        point: model.partnerLatLng,
        width: 46,
        height: 46,
        child: Transform.rotate(
          angle: (model.vehicleHeading * math.pi) / 180.0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
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
          // Interactive OpenStreetMap with Live Tracking Controls
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: model.partnerLatLng,
                    initialZoom: _defaultZoom,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && _autoFollow) {
                        setState(() => _autoFollow = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.flash2mart.customer',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),

                // Top-Left Live Status Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                : const Color(0xFFF59E0B),
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

                // Bottom-Right Re-Center Map Button
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    elevation: 2,
                    child: InkWell(
                      onTap: _recenterMap,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              size: 16,
                              color: _autoFollow
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _autoFollow ? 'Following' : 'Re-center',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _autoFollow
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Delivery Partner Details Bar (Dynamic Lookup via delivery_partners collection)
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
            : 'Partner will be assigned once order is ready',
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

        final String resolvedPhoto =
            (pData['photoUrl'] ?? pData['profileImage'] ?? model.fallbackPartnerPhoto)
                .toString()
                .trim();

        final String vehicleType = (pData['vehicleType'] ?? 'Bike').toString().trim();
        final String vehicleNo =
            (pData['vehicleNumber'] ?? model.fallbackVehicleNumber).toString().trim();
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
    final bool hasValidPhone = phone.replaceAll(RegExp(r'[^\d+]'), '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0x1A00875A),
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? const Icon(Icons.delivery_dining_rounded, color: Color(0xFF00875A), size: 24)
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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