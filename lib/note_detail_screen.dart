import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'device_service.dart';
import 'purchase_screen.dart';
import 'report_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  final Map<String, dynamic> note;

  const NoteDetailScreen({
    super.key,
    required this.note,
  });

  double _parseDouble(dynamic value) {
    return double.tryParse(
      value?.toString() ?? "",
    ) ??
        0;
  }

  String _fiyatFormatla(dynamic value) {
    final double price =
    _parseDouble(value);

    final String fixed =
    price.toStringAsFixed(2);

    final List<String> parts =
    fixed.split(".");

    final String integerPart =
        parts.first;

    final String decimalPart =
        parts.last;

    final StringBuffer result =
    StringBuffer();

    for (int i = 0;
    i < integerPart.length;
    i++) {
      final int remaining =
          integerPart.length - i;

      result.write(integerPart[i]);

      if (remaining > 1 &&
          remaining % 3 == 1) {
        result.write(".");
      }
    }

    return "${result.toString()},$decimalPart";
  }

  String _puanFormatla(dynamic value) {
    return _parseDouble(value)
        .toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        note["title"]?.toString() ??
            "Başlıksız Not";

    final String description =
        note["description"]?.toString() ??
            "Bu not için açıklama eklenmemiş.";

    final String university =
        note["university_name"]?.toString() ??
            "Üniversite belirtilmemiş";

    final String category =
        note["category_name"]?.toString() ??
            "Kategori belirtilmemiş";

    final String educationType =
        note["education_type"]?.toString() ??
            "";

    final String gradeLevel =
        note["grade_level"]?.toString() ??
            "Seviye belirtilmemiş";

    final String rating =
    _puanFormatla(
      note["average_rating"],
    );

    final String price =
    _fiyatFormatla(
      note["price"],
    );

    final String downloadCount =
        note["download_count"]?.toString() ??
            "0";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Not Detayı"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          30,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _pdfOnizleme(),

            const SizedBox(height: 23),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color:
                      AppColors.textPrimary,
                      fontSize: 22,
                      height: 1.25,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success
                        .withValues(
                      alpha: 0.14,
                    ),
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                  child: Text(
                    "$price TL",
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _bilgiSatiri(
              Icons.school_rounded,
              university,
            ),

            const SizedBox(height: 9),

            _bilgiSatiri(
              Icons.category_rounded,
              category,
            ),

            if (educationType.isNotEmpty) ...[
              const SizedBox(height: 9),
              _bilgiSatiri(
                Icons.account_balance_rounded,
                educationType,
              ),
            ],

            const SizedBox(height: 9),

            _bilgiSatiri(
              Icons.workspace_premium_rounded,
              gradeLevel,
            ),

            const SizedBox(height: 23),

            Row(
              children: [
                Expanded(
                  child: _istatistikKarti(
                    icon: Icons.star_rounded,
                    iconColor:
                    AppColors.warning,
                    value: rating,
                    title: "Puan",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _istatistikKarti(
                    icon:
                    Icons.download_rounded,
                    iconColor:
                    AppColors.primaryLight,
                    value: downloadCount,
                    title: "İndirme",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 27),

            const Text(
              "Not Açıklaması",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 11),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius:
                BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.borderSoft,
                ),
              ),
              child: Text(
                description,
                style: const TextStyle(
                  color:
                  AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 20),

            _ucretsizBilgi(),

            const SizedBox(height: 27),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (
                          BuildContext context,
                          ) {
                        return PurchaseScreen(
                          note: note,
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(
                  Icons
                      .shopping_cart_checkout_rounded,
                ),
                label: Text(
                  "Satın Al • $price TL",
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final int? noteId =
                  int.tryParse(
                    note["id"]?.toString() ??
                        "",
                  );

                  if (noteId == null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Not kimliği alınamadı.",
                        ),
                      ),
                    );
                    return;
                  }

                  final String userId =
                  await DeviceService
                      .getDeviceId();

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (
                          BuildContext context,
                          ) {
                        return ReportScreen(
                          noteId: noteId,
                          noteTitle: title,
                          userId: userId,
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.error,
                ),
                label: const Text(
                  "Notu Şikâyet Et",
                  style: TextStyle(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfOnizleme() {
    return Container(
      width: double.infinity,
      height: 215,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.card,
            AppColors.blueSoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
        BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryLight
              .withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: const Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.primaryLight,
            size: 67,
          ),
          SizedBox(height: 12),
          Text(
            "PDF Ders Notu",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Satın almadan önce dosya bilgilerini inceleyin",
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
              AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bilgiSatiri(
      IconData icon,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryLight,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color:
              AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _istatistikKarti({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color:
                  AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ucretsizBilgi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.primaryLight
            .withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryLight
              .withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryLight,
            size: 23,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "İlk not indirme hakkınız ücretsizdir. Sonraki satın alımlar cüzdan bakiyenizden gerçekleştirilir.",
              style: TextStyle(
                color:
                AppColors.textSecondary,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}