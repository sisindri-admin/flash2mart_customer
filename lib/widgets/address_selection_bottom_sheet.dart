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
  State<AddressSelectionBottomSheet> createState() =>
      _AddressSelectionBottomSheetState();
}

class _AddressSelectionBottomSheetState
    extends State<AddressSelectionBottomSheet> {
  late TextEditingController _liveLocationController;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _liveLocationController = TextEditingController(
      text: widget.initialGpsAddress.isNotEmpty
          ? widget.initialGpsAddress
          : LocationService.defaultNelloreAddress,
    );
  }

  @override
  void dispose() {
    _liveLocationController.dispose();
    super.dispose();
  }

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

  void _showAddAddressDialog(String defaultTag) {
    final houseNoController = TextEditingController(text: '5/523');
    final areaController = TextEditingController(
      text: 'Podalakur Rd, Telugu Ganga Colony, Nellore - 524004',
    );
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
            final keyboardPadding = MediaQuery.of(ctx).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: keyboardPadding),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Save Address as $selectedTag',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: houseNoController,
                        decoration: const InputDecoration(
                          labelText: 'House / Flat / Door No. *',
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
                          labelText: 'Landmark (Optional)',
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
                              selectedColor: const Color(0xFFC81E45),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) =>
                                  setModalState(() => selectedTag = tag),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC81E45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (houseNoController.text.trim().isEmpty ||
                                areaController.text.trim().isEmpty) {
                              return;
                            }

                            final newAddress = UserAddress(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              title: selectedTag,
                              houseNo: houseNoController.text.trim(),
                              area: areaController.text.trim(),
                              landmark: landmarkController.text.trim(),
                            );

                            widget.onAddressSaved(newAddress);
                            widget.onAddressSelected(
                              newAddress.title,
                              newAddress.fullAddress,
                            );

                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'SAVE & DELIVER HERE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Delivery Location',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const Text(
                'Current / Live GPS Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _liveLocationController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFFC81E45),
                        ),
                        suffixIcon: _isDetecting
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFC81E45),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.autorenew_rounded,
                                  color: Color(0xFFC81E45),
                                ),
                                tooltip: 'Detect GPS Location',
                                onPressed: _redetectLocation,
                              ),
                        hintText: 'Enter area, street, pincode...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC81E45),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      widget.onAddressSelected(
                        'Podalakur Road',
                        _liveLocationController.text.trim(),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'CONFIRM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Popular Areas in Nellore (Quick Select)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAreaChip(
                    'Podalakur Road',
                    'Podalakur Road- 5/523, Podalakur Rd, Telugu Ganga Colony, Nellore - 524004',
                  ),
                  _buildQuickAreaChip(
                    'Vedayapalem',
                    'Vedayapalem, Main Road, Near Railway Gate, Nellore - 524004',
                  ),
                  _buildQuickAreaChip(
                    'Magunta Layout',
                    'Plot 402, Magunta Layout, Beside Children Park, Nellore - 524003',
                  ),
                  _buildQuickAreaChip(
                    'Trunk Road',
                    'Trunk Road, Gandhi Statue Center, Nellore - 524001',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saved Addresses',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddAddressDialog('Home'),
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      color: Color(0xFFC81E45),
                    ),
                    label: const Text(
                      'Add New',
                      style: TextStyle(
                        color: Color(0xFFC81E45),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(
                      Icons.home_rounded,
                      size: 16,
                      color: Color(0xFFC81E45),
                    ),
                    label: const Text('Add Home'),
                    onPressed: () => _showAddAddressDialog('Home'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(
                      Icons.work_rounded,
                      size: 16,
                      color: Color(0xFFC81E45),
                    ),
                    label: const Text('Add Work'),
                    onPressed: () => _showAddAddressDialog('Work'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Color(0xFFC81E45),
                    ),
                    label: const Text('Add Other'),
                    onPressed: () => _showAddAddressDialog('Other'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.savedAddresses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Tap any quick area above or click Add Home to save your address.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )
              else
                ...widget.savedAddresses.map((addr) {
                  IconData icon = Icons.location_on_rounded;
                  if (addr.title == 'Home') icon = Icons.home_rounded;
                  if (addr.title == 'Work') icon = Icons.work_rounded;

                  return Card(
                    elevation: 0.5,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0x1AC81E45),
                        child: Icon(icon, color: const Color(0xFFC81E45)),
                      ),
                      title: Text(
                        addr.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        addr.fullAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
      ),
    );
  }

  Widget _buildQuickAreaChip(String label, String fullAddress) {
    return InkWell(
      onTap: () {
        setState(() {
          _liveLocationController.text = fullAddress;
        });
        widget.onAddressSelected(label, fullAddress);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 13,
              color: Color(0xFFC81E45),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9F1239),
              ),
            ),
          ],
        ),
      ),
    );
  }
}