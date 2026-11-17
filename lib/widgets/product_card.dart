import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final double marketPrice;
  final String unit;
  final String imageUrl;
  final int stock;
  final int quantityInCart;
  final String merchantId;
  final String category;
  final String description;
  final bool isCombo;
  final String comboItems;
  final List<String> comboImages;
  final List<Map<String, dynamic>> comboProductsList;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  static final Map<String, MemoryImage> _sharedMemoryImageCache = {};
  static final Set<String> _invalidBase64Keys = {};

  const ProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.marketPrice,
    required this.unit,
    required this.imageUrl,
    required this.stock,
    required this.quantityInCart,
    this.merchantId = '',
    this.category = 'General',
    this.description = '',
    this.isCombo = false,
    this.comboItems = '',
    this.comboImages = const [],
    this.comboProductsList = const [],
    required this.onAdd,
    required this.onRemove,
  });

  Widget _buildProductImage(String imageStr) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty || _invalidBase64Keys.contains(trimmed)) {
      return Container(
        color: const Color(0xFFF8FAFC),
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 38,
          color: Colors.green.shade200,
        ),
      );
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      MemoryImage? memImg = _sharedMemoryImageCache[trimmed];
      if (memImg == null) {
        try {
          final String cleanBase64 =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          final Uint8List bytes = base64Decode(cleanBase64.trim());
          memImg = MemoryImage(bytes);
          _sharedMemoryImageCache[trimmed] = memImg;
        } catch (_) {
          _invalidBase64Keys.add(trimmed);
          return Container(
            color: const Color(0xFFF8FAFC),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 38,
              color: Colors.green.shade200,
            ),
          );
        }
      }
      return Image(
        image: memImg,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF8FAFC),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 38,
            color: Colors.green.shade200,
          ),
        ),
      );
    }

    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFF8FAFC),
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 38,
          color: Colors.green.shade200,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = stock <= 0;

    final double effectiveMarketPrice = (marketPrice > price && price > 0)
        ? marketPrice
        : (price > 0 ? (price * 1.18).ceilToDouble() : price);

    int discountPercent = 0;
    if (effectiveMarketPrice > price && effectiveMarketPrice > 0) {
      discountPercent =
          (((effectiveMarketPrice - price) / effectiveMarketPrice) * 100)
              .round()
              .clamp(5, 85);
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: id,
                productData: {
                  'name': name,
                  'price': price,
                  'marketPrice': effectiveMarketPrice,
                  'unit': unit,
                  'imageUrl': imageUrl,
                  'stock': stock,
                  'merchantId': merchantId,
                  'category': category,
                  'description': description,
                  'isCombo': isCombo,
                  'comboItems': comboItems,
                  'images': comboImages,
                  'comboProductsList': comboProductsList,
                },
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. IMAGE + GRAY UNIT STRIP + OVERLAPPING ADD / "- 1 +" BUTTON
              SizedBox(
                height: 110,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 105,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(11),
                              ),
                              child: Opacity(
                                opacity: isOutOfStock ? 0.45 : 1.0,
                                child: (isCombo && _resolvedComboImages().length > 1)
                                    ? _ComboSwipeImageSlider(
                                        images: _resolvedComboImages(),
                                        imageBuilder: _buildProductImage,
                                      )
                                    : _buildProductImage(imageUrl),
                              ),
                            ),
                          ),
                          // Light Gray Unit Strip ("410 g", "849 g", "500 g")
                          Container(
                            height: 24,
                            width: double.infinity,
                            color: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.only(left: 7, right: 60),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              unit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Unique Combo Deal Badge on Top-Left
                    if (isCombo)
                      Positioned(
                        top: 5,
                        left: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Color(0x337C3AED), blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: const Text(
                            '✨ COMBO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                    // Overlapping ADD / "- 1 +" Button on Bottom-Right
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: isOutOfStock
                          ? Container(
                              height: 28,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Center(
                                child: Text(
                                  'OUT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            )
                          : quantityInCart == 0
                              ? InkWell(
                                  onTap: onAdd,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 30,
                                    width: 58,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF007AA6),
                                        width: 1.3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x12000000),
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'ADD',
                                        style: TextStyle(
                                          color: Color(0xFF007AA6),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 30,
                                  width: 66,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF38BDF8),
                                        Color(0xFF0284C7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x220284C7),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: onRemove,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 3,
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$quantityInCart',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: onAdd,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 3,
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // 2. BOLD PRICE + STRUCK-THROUGH MRP + GREEN "% OFF" (FittedBox prevents any overflow)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      '₹${price.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color:
                            isOutOfStock ? Colors.grey : const Color(0xFF09090B),
                      ),
                    ),
                    if (effectiveMarketPrice > price) ...[
                      const SizedBox(width: 4),
                      Text(
                        '₹${effectiveMarketPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF334155),
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$discountPercent% off',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 2),

              // 3. PRODUCT NAME (Exact typography from Image 1)
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  height: 1.18,
                  color:
                      isOutOfStock ? Colors.grey : const Color(0xFF09090B),
                ),
              ),
              const SizedBox(height: 3),

              // 4. DELIVERY TIME ("⚡ 15 mins") + COMPACT "4 Items >" ON COMBO CARDS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 12,
                        color: Color(0xFF16A34A),
                      ),
                      SizedBox(width: 2),
                      Text(
                        '15 mins',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  if (isCombo)
                    GestureDetector(
                      onTap: () => _showComboBreakdownSheet(context, effectiveMarketPrice),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            comboProductsList.isNotEmpty
                                ? "${comboProductsList.length} Items"
                                : "Items",
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 13,
                            color: Color(0xFF6D28D9),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _resolvedComboImages() {
    final List<String> list = [];
    for (final img in comboImages) {
      if (img.trim().isNotEmpty && !list.contains(img.trim())) {
        list.add(img.trim());
      }
    }
    for (final item in comboProductsList) {
      final s = (item['imageUrl'] ?? item['imageBase64'] ?? '').toString().trim();
      if (s.isNotEmpty && !list.contains(s)) {
        list.add(s);
      }
    }
    if (imageUrl.trim().isNotEmpty && !list.contains(imageUrl.trim())) {
      list.insert(0, imageUrl.trim());
    }
    return list;
  }


  void _showComboBreakdownSheet(BuildContext context, double totalMrp) {
    final List<String> allImgs = _resolvedComboImages();
    int highlightIdx = -1;
    double highestVal = -1;
    for (int i = 0; i < comboProductsList.length; i++) {
      final item = comboProductsList[i];
      final double act = ((item['actualPrice'] ?? 0) as num).toDouble();
      final double off = ((item['offerPrice'] ?? 0) as num).toDouble();
      if (off == 0 && act > 0) {
        highlightIdx = i;
        break;
      }
      if (act > highestVal) {
        highestVal = act;
        highlightIdx = i;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "✨ COMBO OFFER BREAKDOWN",
                              style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              if (allImgs.isNotEmpty)
                SizedBox(
                  height: 155,
                  child: _ComboSwipeImageSlider(
                    images: allImgs,
                    imageBuilder: _buildProductImage,
                  ),
                ),
              const Divider(height: 14),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (comboProductsList.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Included Combo Products (${comboProductsList.length})",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF4C1D95)),
                          ),
                          if (totalMrp > price)
                            Text(
                              "Save ₹${(totalMrp - price).toInt()}",
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF16A34A)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...comboProductsList.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final iName = (item['name'] ?? 'Item').toString();
                        final iQty = (item['quantity'] ?? item['qty'] ?? '1 pack').toString();
                        final double iActual = ((item['actualPrice'] ?? 0) as num).toDouble();
                        final double iOffer = ((item['offerPrice'] ?? 0) as num).toDouble();
                        final String iImg = (item['imageUrl'] ?? item['imageBase64'] ?? '').toString();
                        final bool isHighlighted = idx == highlightIdx;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isHighlighted ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHighlighted ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                              width: isHighlighted ? 1.3 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: _buildProductImage(iImg),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "$iQty $iName",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                          ),
                                        ),
                                        if (isHighlighted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF7C3AED),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              iOffer == 0 ? "FREE BONUS" : "TOP VALUE",
                                              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        if (iActual > iOffer) ...[
                                          Text(
                                            "Actual: ₹${iActual.toInt()}",
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF94A3B8),
                                              decoration: TextDecoration.lineThrough,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          iOffer == 0 ? "₹0 (FREE)" : "₹${iOffer.toInt()}",
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            color: iOffer == 0 ? const Color(0xFF16A34A) : const Color(0xFF4C1D95),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else if (comboItems.isNotEmpty) ...[
                      const Text(
                        "Included Combo Items:",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF4C1D95)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF7C3AED).withAlpha(60)),
                        ),
                        child: Text(comboItems, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4)),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("₹${price.toInt()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            if (totalMrp > price) ...[
                              const SizedBox(width: 6),
                              Text("₹${totalMrp.toInt()}", style: const TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: Color(0xFF94A3B8))),
                            ],
                          ],
                        ),
                        const Text("Total Combo Price", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        onAdd();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text("ADD COMBO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComboSwipeImageSlider extends StatefulWidget {
  final List<String> images;
  final Widget Function(String) imageBuilder;
  const _ComboSwipeImageSlider({
    required this.images,
    required this.imageBuilder,
  });

  @override
  State<_ComboSwipeImageSlider> createState() => _ComboSwipeImageSliderState();

}

class _ComboSwipeImageSliderState extends State<_ComboSwipeImageSlider> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (idx) => setState(() => _activeIndex = idx),
          itemBuilder: (context, idx) => widget.imageBuilder(widget.images[idx]),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (idx) {
                final bool active = idx == _activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: active ? 5.0 * 2.2 : 5.0,
                  height: 5.0,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF7C3AED) : Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
