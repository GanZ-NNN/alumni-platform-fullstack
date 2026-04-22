import 'package:flutter/material.dart';

class ImageHelper {
  // ✅ ຕົວຊ່ວຍຈັດການຮູບພາບ ເພື່ອບໍ່ໃຫ້ມັນ Error ຖ້າ Server ຕາຍ ຫຼື ຫາບໍ່ເຫັນ
  static Widget networkImage(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (url == null || url.isEmpty) {
      return _buildPlaceholder(width, height);
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      // ✅ ຖ້າໂຫລດບໍ່ໄດ້ (ເຊັ່ນ Connection Refused) ໃຫ້ໂຊ Placeholder ແທນ
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(width, height);
      },
      // ✅ ສະແດງ Loading ລະຫວ່າງຖ້າ
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  static Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
