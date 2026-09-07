import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../screens/profile_screen.dart';
import 'address_selection_bottom_sheet.dart';

class HomeHeaderWidget extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const HomeHeaderWidget({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  State<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends State<HomeHeaderWidget> {
  String _displayTitle = '⚡ 15 MINS DELIVERY';
  String _displayAddress = 'Fetching location...';
  String _rawGpsAddress = '';

  // Saved Addresses List
  final List<UserAddress> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final address = await LocationService.getCurrentAddress();
    if (mounted) {
      setState(() {
        _rawGpsAddress = address;
        _displayAddress = address;
      });
    }
  }

  void _openAddressSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddressSelectionBottomSheet(
          initialGpsAddress: _rawGpsAddress,
          savedAddresses: _savedAddresses,
          onAddressSelected: (String title, String fullAddress) {
            setState(() {
              _displayTitle = title.toUpperCase();
              _displayAddress = fullAddress;
            });
          },
          onAddressSaved: (UserAddress newAddress) {
            setState(() {
              _savedAddresses.removeWhere((a) => a.title == newAddress.title && newAddress.title != 'Other');
              _savedAddresses.add(newAddress);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF00875A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayTitle,
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: _openAddressSelection,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _displayAddress,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: widget.onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search milk, rice, brinjal...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}