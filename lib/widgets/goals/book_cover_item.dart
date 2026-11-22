import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:litly/core/app_colors.dart';

// Widget item sampul buku untuk daftar buku bulanan dan tahunan
class BookCoverItem extends StatelessWidget {
  final String title;
  final String? coverUrl;
  final int percent;
  final bool isCompleted;
  final bool showPercent;

  BookCoverItem({
    Key? key,
    required this.title,
    this.coverUrl,
    this.percent = 0,
    this.isCompleted = false,
    this.showPercent = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String initial = title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : 'B';

    // Placeholder kotak berwarna pastel jika gambar kosong atau error
    Widget fallbackCover = Container(
      width: 85,
      height: 115,
      decoration: BoxDecoration(
        color: AppColors.kLavender,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.kRedMaroon,
        ),
      ),
    );

    Widget imageWidget;
    if (coverUrl == null || coverUrl!.trim().isEmpty) {
      imageWidget = fallbackCover;
    } else if (coverUrl!.trim().startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: coverUrl!.trim(),
        width: 85,
        height: 115,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => fallbackCover,
        placeholder: (context, url) => Container(
          width: 85,
          height: 115,
          color: AppColors.kLavender,
          alignment: Alignment.center,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else {
      imageWidget = Image.file(
        File(coverUrl!.trim()),
        width: 85,
        height: 115,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallbackCover,
      );
    }

    return Container(
      width: 85,
      margin: EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kontainer sampul buku dengan rounded 12 dan badge status
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 85,
                  height: 115,
                  child: imageWidget,
                ),
              ),

              // Badge check jika buku selesai
              if (isCompleted)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.kNavyDark,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),

              // Pil persentase jika buku sedang dibaca
              if (!isCompleted && showPercent)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.kPinkLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kRedMaroon,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6),
          // Judul buku 1 baris ellipsis
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
