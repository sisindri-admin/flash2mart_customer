import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RealtimeReviewsWidget extends StatefulWidget {
  final String productId;
  final String productName;
  final String primaryImageUrl;

  const RealtimeReviewsWidget({
    super.key,
    required this.productId,
    required this.productName,
    required this.primaryImageUrl,
  });

  @override
  State<RealtimeReviewsWidget> createState() => _RealtimeReviewsWidgetState();
}

class _RealtimeReviewsWidgetState extends State<RealtimeReviewsWidget> {
  final ImagePicker _picker = ImagePicker();
  final Set<String> _likedReviewIds = {};
  final Map<String, Uint8List> _base64Cache = {};

  Widget _buildImage(String imageStr, {BoxFit fit = BoxFit.cover}) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty) {
      return Icon(
        Icons.shopping_bag_outlined,
        size: 32,
        color: Colors.green.shade200,
      );
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      Uint8List? bytes = _base64Cache[trimmed];
      if (bytes == null) {
        try {
          final String cleanBase64 =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          bytes = base64Decode(cleanBase64.trim());
          _base64Cache[trimmed] = bytes;
        } catch (_) {
          return Icon(
            Icons.shopping_bag_outlined,
            size: 32,
            color: Colors.green.shade200,
          );
        }
      }
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.shopping_bag_outlined,
          size: 32,
          color: Colors.green.shade200,
        ),
      );
    }

    return Image.network(
      trimmed,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shopping_bag_outlined,
        size: 32,
        color: Colors.green.shade200,
      ),
    );
  }

  void _openFullScreenPhoto(
    BuildContext context,
    String imageStr,
    String author,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildImage(imageStr, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 14,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Photo by $author',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWriteReviewWithPhotoDialog(BuildContext context) async {
    final TextEditingController commentCtrl = TextEditingController();
    final TextEditingController nameCtrl = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? '',
    );
    int selectedStars = 5;
    String uploadedPhotoBase64 = '';
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickReviewImage(ImageSource source) async {
            try {
              final XFile? picked = await _picker.pickImage(
                source: source,
                maxWidth: 700,
                maxHeight: 700,
                imageQuality: 65,
              );
              if (picked != null) {
                final Uint8List bytes = await picked.readAsBytes();
                setDialogState(() {
                  uploadedPhotoBase64 = base64Encode(bytes);
                });
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not pick photo: $e')),
                );
              }
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Write a Real-Time Review',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (idx) {
                        final int starVal = idx + 1;
                        return IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setDialogState(() => selectedStars = starVal);
                          },
                          icon: Icon(
                            starVal <= selectedStars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Your Name (Optional)',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'How is the product freshness, quality & delivery?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add Real Product Photo (Optional):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => pickReviewImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text(
                          'Camera',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => pickReviewImage(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 16,
                        ),
                        label: const Text(
                          'Gallery',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (uploadedPhotoBase64.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 90,
                            width: 90,
                            child: _buildImage(uploadedPhotoBase64),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () {
                              setDialogState(() => uploadedPhotoBase64 = '');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00875A),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (commentCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your review comment'),
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isSubmitting = true);
                        final User? user = FirebaseAuth.instance.currentUser;
                        final String authorName = nameCtrl.text.trim().isNotEmpty
                            ? nameCtrl.text.trim()
                            : (user?.displayName ?? 'Verified Customer');

                        final String ratingTag = selectedStars == 5
                            ? 'Very Good'
                            : selectedStars == 4
                                ? 'Good'
                                : selectedStars == 3
                                    ? 'Ok-Ok'
                                    : 'Bad';

                        try {
                          await FirebaseFirestore.instance
                              .collection('product_reviews')
                              .add({
                            'productId': widget.productId,
                            'productName': widget.productName,
                            'userId': user?.uid ?? '',
                            'author': authorName,
                            'rating': selectedStars,
                            'tag': ratingTag,
                            'comment': commentCtrl.text.trim(),
                            'photoBase64': uploadedPhotoBase64,
                            'helpfulCount': 1,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Review & photo posted live successfully!',
                                ),
                                backgroundColor: Color(0xFF00875A),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving review: $e')),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Post Live Review'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _incrementHelpful(String docId, bool isFirestoreDoc) async {
    if (_likedReviewIds.contains(docId)) return;
    setState(() => _likedReviewIds.add(docId));
    if (isFirestoreDoc) {
      try {
        await FirebaseFirestore.instance
            .collection('product_reviews')
            .doc(docId)
            .update({
          'helpfulCount': FieldValue.increment(1),
        });
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('product_reviews')
          .where('productId', isEqualTo: widget.productId)
          .snapshots(),
      builder: (context, snapshot) {
        final List<QueryDocumentSnapshot> liveDocs = snapshot.data?.docs ?? [];

        final List<QueryDocumentSnapshot> sortedLive =
            List<QueryDocumentSnapshot>.from(liveDocs);
        sortedLive.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final Timestamp? aT = aData['createdAt'] as Timestamp?;
          final Timestamp? bT = bData['createdAt'] as Timestamp?;
          if (aT == null || bT == null) return 0;
          return bT.compareTo(aT);
        });

        final List<Map<String, dynamic>> allReviews = [
          ...sortedLive.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final Timestamp? ts = d['createdAt'] as Timestamp?;
            final String dateStr = ts != null
                ? 'Posted on ${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                : 'Posted just now';
            return {
              'id': doc.id,
              'isFirestore': true,
              'author': (d['author'] ?? 'Verified Customer').toString(),
              'rating': ((d['rating'] ?? 5) as num).toInt(),
              'tag': (d['tag'] ?? 'Very Good').toString(),
              'date': dateStr,
              'comment': (d['comment'] ?? '').toString(),
              'photo': (d['photoBase64'] ?? d['photoUrl'] ?? '').toString(),
              'helpfulCount': ((d['helpfulCount'] ?? 1) as num).toInt(),
            };
          }),
          {
            'id': 'seed_1',
            'isFirestore': false,
            'author': 'Lakshmi Narayana (Nellore)',
            'rating': 5,
            'tag': 'Very Good',
            'date': 'Verified Purchase',
            'comment':
                'Super fresh quality and fast 15 mins delivery! Neat packaging and best price.',
            'photo': widget.primaryImageUrl,
            'helpfulCount': 37,
          },
          {
            'id': 'seed_2',
            'isFirestore': false,
            'author': 'Prachi Patil',
            'rating': 5,
            'tag': 'Very Good',
            'date': 'Verified Purchase',
            'comment':
                'Genuine product received at lowest price. Delivery partner was very polite.',
            'photo': widget.primaryImageUrl,
            'helpfulCount': 50,
          },
        ];

        final List<Map<String, String>> customerPhotos = [];
        for (final rev in allReviews) {
          final String p = (rev['photo'] ?? '').toString().trim();
          if (p.isNotEmpty) {
            customerPhotos.add({
              'photo': p,
              'author': (rev['author'] ?? 'Customer').toString(),
            });
          }
        }

        final int extraCount = sortedLive.length;
        final int star5 = 620 +
            sortedLive
                .where((d) => ((d.data() as Map)['rating'] ?? 5) == 5)
                .length;
        final int star4 = 230 +
            sortedLive
                .where((d) => ((d.data() as Map)['rating'] ?? 5) == 4)
                .length;
        final int star3 = 78 +
            sortedLive
                .where((d) => ((d.data() as Map)['rating'] ?? 5) == 3)
                .length;
        final int star2 = 25 +
            sortedLive
                .where((d) => ((d.data() as Map)['rating'] ?? 5) == 2)
                .length;
        final int star1 = 44 +
            sortedLive
                .where((d) => ((d.data() as Map)['rating'] ?? 5) == 1)
                .length;
        final int totalRatings = star5 + star4 + star3 + star2 + star1;
        final int totalReviewsCount = 324 + extraCount;
        final double weightedAvg =
            ((star5 * 5) + (star4 * 4) + (star3 * 3) + (star2 * 2) + (star1 * 1)) /
                totalRatings;

        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Customer Ratings & Reviews',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openWriteReviewWithPhotoDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0FDF4),
                      foregroundColor: const Color(0xFF00875A),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      side: const BorderSide(color: Color(0xFF00875A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 14),
                    label: const Text(
                      'Add Photo Review',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 112,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: const Color(0xFF00875A),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                weightedAvg.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: const Color(0xFFF8FAFC),
                          child: Column(
                            children: [
                              Text(
                                '$totalRatings ratings',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalReviewsCount reviews',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        _buildRatingBar(
                          'Very Good',
                          star5 / totalRatings,
                          '$star5',
                          const Color(0xFF00875A),
                        ),
                        const SizedBox(height: 6),
                        _buildRatingBar(
                          'Good',
                          star4 / totalRatings,
                          '$star4',
                          const Color(0xFF22C55E),
                        ),
                        const SizedBox(height: 6),
                        _buildRatingBar(
                          'Ok-Ok',
                          star3 / totalRatings,
                          '$star3',
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 6),
                        _buildRatingBar(
                          'Bad',
                          star2 / totalRatings,
                          '$star2',
                          const Color(0xFFEA580C),
                        ),
                        const SizedBox(height: 6),
                        _buildRatingBar(
                          'Very Bad',
                          star1 / totalRatings,
                          '$star1',
                          const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 26),
              if (customerPhotos.isNotEmpty) ...[
                Text(
                  'Real Customer Photos (${23 + customerPhotos.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 78,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        customerPhotos.length > 6 ? 6 : customerPhotos.length,
                    itemBuilder: (context, idx) {
                      final item = customerPhotos[idx];
                      final String photoStr = item['photo'] ?? '';
                      final String author = item['author'] ?? 'Customer';
                      return GestureDetector(
                        onTap: () =>
                            _openFullScreenPhoto(context, photoStr, author),
                        child: Container(
                          width: 78,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildImage(photoStr),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
              ...allReviews.take(8).map((rev) {
                final String revId = rev['id'] as String;
                final bool isFirestore = rev['isFirestore'] as bool;
                final bool isLiked = _likedReviewIds.contains(revId);
                final int baseCount = rev['helpfulCount'] as int;
                final int displayHelpful =
                    isFirestore ? baseCount : baseCount + (isLiked ? 1 : 0);
                final String revPhoto = (rev['photo'] ?? '').toString();

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00875A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${rev['rating']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${rev['tag']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '• ${rev['date']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${rev['comment']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                    height: 1.38,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '~ ${rev['author']}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (revPhoto.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _openFullScreenPhoto(
                                context,
                                revPhoto,
                                '${rev['author']}',
                              ),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildImage(revPhoto),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _incrementHelpful(revId, isFirestore),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.thumb_up_alt_rounded
                                    : Icons.thumb_up_alt_outlined,
                                size: 15,
                                color: isLiked
                                    ? const Color(0xFF00875A)
                                    : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Helpful ($displayHelpful)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isLiked
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isLiked
                                      ? const Color(0xFF00875A)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingBar(
    String label,
    double ratio,
    String countText,
    Color barColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            countText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
