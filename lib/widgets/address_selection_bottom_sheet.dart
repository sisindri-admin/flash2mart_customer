import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';

class AddressSelectionBottomSheet extends StatefulWidget {
  final String initialGpsAddress;
  final List<UserAddress> savedAddresses;
  final Function(String addressTitle, String fullAddress) onAddressSelected;
  final Function(UserAddress newAddress) onAddressSaved;

  const AddressSelectionBottomSheet({
    super.key,
    required this.initialGpsAddress,
    required this.savedAddresses,
    required this.onAddressSelected,
    required this.onAddressSaved,
  });

  @override
  State<AddressSelectionBottomSheet> createState() => _AddressSelectionBottomSheetState();
}

class _AddressSelectionBottomSheetState extends State<AddressSelectionBottomSheet> {
  late TextEditingController _liveLocationController;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _liveLocationController = TextEditingController(text: widget.initialGpsAddress);
  }

  @override
  void dispose() {
    _liveLocationController.dispose();
    super.dispose();
  }

  // Live Location రీ-డిటెక్ట్ చేసే ఫంక్షన్
  Future<void> _redetectLocation() async {
    setState(() => _isDetecting = true);
    final freshAddress = await LocationService.getCurrentAddress();
    if (mounted) {
      setState(() {
        _liveLocationController.text = freshAddress;
        _isDetecting = false;
      });
    }
  }

  // Home, Work, Other అడ్రస్ యాడ్ చేసే మోడల్ డైలాగ్
  void _showAddAddressDialog(String defaultTag) {
    final houseNoController = TextEditingController();
    final areaController = TextEditingController(text: _liveLocationController.text);
    final landmarkController = TextEditingController();
    String selectedTag = defaultTag;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save Address as $selectedTag',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: houseNoController,
                      decoration: const InputDecoration(
                        labelText: 'House / Flat / Floor / Building No. *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'Road / Area / Colony *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'Landmark (Optional e.g. Near Water Tank)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: ['Home', 'Work', 'Other'].map((tag) {
                        final isSelected = selectedTag == tag;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(tag),
                            selected: isSelected,
                            selectedColor: const Color(0xFF00875A),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                            onSelected: (val) => setModalState(() => selectedTag = tag),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00875A),
                        ),
                        onPressed: () {
                          if (houseNoController.text.trim().isEmpty || areaController.text.trim().isEmpty) {
                            return;
                          }

                          final newAddress = UserAddress(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: selectedTag,
                            houseNo: houseNoController.text.trim(),
                            area: areaController.text.trim(),
                            landmark: landmarkController.text.trim(),
                          );

                          widget.onAddressSaved(newAddress);
                          widget.onAddressSelected(newAddress.title, newAddress.fullAddress);

                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('SAVE & SELECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Choose Delivery Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),

            // 1. LIVE LOCATION EDITABLE FIELD & REDETECT BUTTON
            const Text('Live Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _liveLocationController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.my_location, color: Color(0xFF00875A)),
                      suffixIcon: _isDetecting
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00875A)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.autorenew, color: Color(0xFF00875A)),
                              tooltip: 'Re-detect Location',
                              onPressed: _redetectLocation,
                            ),
                      hintText: 'Edit or detect location...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onPressed: () {
                    widget.onAddressSelected('Current Location', _liveLocationController.text.trim());
                    Navigator.pop(context);
                  },
                  child: const Text('USE THIS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),

            // 2. SAVED ADDRESSES SECTION (HOME, WORK, OTHER)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton.icon(
                  onPressed: () => _showAddAddressDialog('Home'),
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF00875A)),
                  label: const Text('Add New', style: TextStyle(color: Color(0xFF00875A), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Add Chips
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.home, size: 16, color: Color(0xFF00875A)),
                  label: const Text('Add Home'),
                  onPressed: () => _showAddAddressDialog('Home'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.work, size: 16, color: Color(0xFF00875A)),
                  label: const Text('Add Work'),
                  onPressed: () => _showAddAddressDialog('Work'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.location_on, size: 16, color: Color(0xFF00875A)),
                  label: const Text('Add Other'),
                  onPressed: () => _showAddAddressDialog('Other'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (widget.savedAddresses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('No saved addresses yet. Click Add Home or Add Work above to save.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            else
              ...widget.savedAddresses.map((addr) {
                IconData icon = Icons.location_on;
                if (addr.title == 'Home') icon = Icons.home;
                if (addr.title == 'Work') icon = Icons.work;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00875A).withOpacity(0.1),
                      child: Icon(icon, color: const Color(0xFF00875A)),
                    ),
                    title: Text(addr.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(addr.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      widget.onAddressSelected(addr.title, addr.fullAddress);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}