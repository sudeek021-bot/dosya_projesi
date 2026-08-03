import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'app_theme.dart';
import 'device_service.dart';

class PurchaseScreen extends StatefulWidget {
  final Map<String, dynamic> note;

  const PurchaseScreen({
    super.key,
    required this.note,
  });

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _purchaseCompleted = false;

  String? _fileUrl;
  String? _resultMessage;
  String? _purchaseDate;

  int? get _noteId {
    return int.tryParse(
      widget.note["id"]?.toString() ?? "",
    );
  }

  double get _price {
    return double.tryParse(
      widget.note["price"]?.toString() ?? "",
    ) ??
        0;
  }

  String get _title {
    return widget.note["title"]?.toString() ??
        "Başlıksız Not";
  }

  String get _university {
    return widget.note["university_name"]?.toString() ??
        "Üniversite belirtilmemiş";
  }

  String get _category {
    return widget.note["category_name"]?.toString() ??
        "Kategori belirtilmemiş";
  }

  String get _educationType {
    return widget.note["education_type"]?.toString() ?? "";
  }

  String get _gradeLevel {
    return widget.note["grade_level"]?.toString() ??
        "Seviye belirtilmemiş";
  }

  String get _pdfName {
    final String? filePath =
    widget.note["file_path"]?.toString();

    if (filePath != null && filePath.trim().isNotEmpty) {
      final String cleanPath = filePath.replaceAll("\\", "/");
      final String name = cleanPath.split("/").last;

      if (name.isNotEmpty) {
        return name;
      }
    }

    final String safeTitle = _title
        .replaceAll(RegExp(r'[^\wçÇğĞıİöÖşŞüÜ\s-]'), "")
        .replaceAll(" ", "_");

    return "$safeTitle.pdf";
  }

  String _formatMoney(double value) {
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split(".");

    final String integerPart = parts[0];
    final String decimalPart = parts[1];

    final StringBuffer result = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      final int remaining = integerPart.length - i;

      result.write(integerPart[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        result.write(".");
      }
    }

    return "${result.toString()},$decimalPart";
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, "0");
    final String month = date.month.toString().padLeft(2, "0");
    final String year = date.year.toString();

    final String hour = date.hour.toString().padLeft(2, "0");
    final String minute = date.minute.toString().padLeft(2, "0");

    return "$day.$month.$year • $hour:$minute";
  }

  Future<void> _purchaseNote() async {
    if (_isLoading) {
      return;
    }

    final int? noteId = _noteId;

    if (noteId == null) {
      _showMessage("Not kimliği alınamadı.");
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      final String userId =
      await DeviceService.getDeviceId();

      final Map<String, dynamic> result =
      await _apiService.purchaseNote(
        noteId: noteId,
        userId: userId,
      );

      if (!mounted) {
        return;
      }

      final bool success = result["success"] == true;

      final String message =
          result["message"]?.toString() ??
              "Satın alma işlemi tamamlanamadı.";

      if (!success) {
        setState(() {
          _resultMessage = message;
        });

        _showMessage(message);
        return;
      }

      final String? filePath =
      result["filePath"]?.toString();

      final String fileUrl =
      _apiService.buildFileUrl(filePath);

      setState(() {
        _purchaseCompleted = true;
        _fileUrl = fileUrl;
        _resultMessage = message;
        _purchaseDate = _formatDate(DateTime.now());
      });

      _showMessage(
        message,
        success: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        "Satın alma sırasında beklenmeyen bir hata oluştu.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openPdf() async {
    final String? fileUrl = _fileUrl;

    if (fileUrl == null || fileUrl.isEmpty) {
      _showMessage("PDF bağlantısı bulunamadı.");
      return;
    }

    try {
      final Uri uri = Uri.parse(fileUrl);

      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage("PDF açılamadı.");
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        "PDF açılırken bir hata oluştu.",
      );
    }
  }

  void _goHome() {
    Navigator.of(context).popUntil(
          (route) => route.isFirst,
    );
  }

  void _showMessage(
      String message, {
        bool success = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              color: success
                  ? AppColors.success
                  : AppColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _purchaseCompleted
              ? "Satın Alma Başarılı"
              : "Satın Alma",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32,
        ),
        child: _purchaseCompleted
            ? _successContent()
            : _purchaseContent(),
      ),
    );
  }

  Widget _purchaseContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _noteCard(),

        const SizedBox(height: 20),

        _freeDownloadCard(),

        const SizedBox(height: 18),

        _paymentSummary(),

        const SizedBox(height: 18),

        _securityCard(),

        if (_resultMessage != null) ...[
          const SizedBox(height: 16),
          _errorCard(_resultMessage!),
        ],

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : _purchaseNote,
            icon: _isLoading
                ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(
              Icons.shopping_cart_checkout_rounded,
            ),
            label: Text(
              _isLoading
                  ? "İşlem Yapılıyor..."
                  : "Satın Al • ${_formatMoney(_price)} TL",
            ),
          ),
        ),
      ],
    );
  }

  Widget _successContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            20,
            28,
            20,
            24,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.success.withValues(
                alpha: 0.45,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(
                    alpha: 0.13,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 45,
                ),
              ),

              const SizedBox(height: 17),

              const Text(
                "Satın Alma Başarılı",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _resultMessage ??
                    "PDF erişiminiz başarıyla oluşturuldu.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              _purchasedFileCard(),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openPdf,
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
            ),
            label: const Text(
              "PDF'yi Aç",
            ),
          ),
        ),

        const SizedBox(height: 11),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _goHome,
            icon: const Icon(
              Icons.home_rounded,
            ),
            label: const Text(
              "Ana Sayfaya Dön",
            ),
          ),
        ),
      ],
    );
  }

  Widget _purchasedFileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 55,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.primaryLight,
                  size: 29,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _pdfName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 28),

          _fileInformationRow(
            icon: Icons.school_rounded,
            title: "Üniversite",
            value: _university,
          ),

          const SizedBox(height: 13),

          _fileInformationRow(
            icon: Icons.category_rounded,
            title: "Kategori",
            value: _category,
          ),

          const SizedBox(height: 13),

          _fileInformationRow(
            icon: Icons.workspace_premium_rounded,
            title: "Eğitim seviyesi",
            value: [
              if (_educationType.isNotEmpty)
                _educationType,
              _gradeLevel,
            ].join(" • "),
          ),

          const SizedBox(height: 13),

          _fileInformationRow(
            icon: Icons.calendar_today_rounded,
            title: "Satın alma tarihi",
            value: _purchaseDate ?? "-",
          ),
        ],
      ),
    );
  }

  Widget _fileInformationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primaryLight,
          size: 18,
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _noteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AppColors.borderSoft,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 65,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  _university,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  [
                    _category,
                    if (_educationType.isNotEmpty)
                      _educationType,
                    _gradeLevel,
                  ].join(" • "),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(
                alpha: 0.13,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${_formatMoney(_price)} TL",
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _freeDownloadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(
          alpha: 0.09,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryLight.withValues(
            alpha: 0.27,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            color: AppColors.primaryLight,
            size: 25,
          ),

          SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "İlk indirme ücretsiz",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Ücretsiz hakkınızı daha önce kullanmadıysanız bu işlemde cüzdanınızdan ücret alınmaz.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentSummary() {
    final double commission = _price * 0.20;
    final double sellerEarning = _price - commission;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.borderSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ödeme Özeti",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          _summaryRow(
            title: "Not fiyatı",
            value: "${_formatMoney(_price)} TL",
            color: AppColors.textPrimary,
          ),

          const SizedBox(height: 12),

          _summaryRow(
            title: "Platform komisyonu (%20)",
            value: "${_formatMoney(commission)} TL",
            color: AppColors.warning,
          ),

          const SizedBox(height: 12),

          _summaryRow(
            title: "Satıcı kazancı",
            value: "${_formatMoney(sellerEarning)} TL",
            color: AppColors.success,
          ),

          const Divider(height: 29),

          _summaryRow(
            title: "Ödenecek toplam",
            value: "${_formatMoney(_price)} TL",
            color: AppColors.primaryLight,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String title,
    required String value,
    required Color color,
    bool bold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: bold ? 16 : 14,
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _securityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: AppColors.success,
            size: 24,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              "İşlem başarılı olduğunda PDF erişimi hesabınıza tanımlanır. Daha önce satın aldığınız not için tekrar ücret ödemezsiniz.",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}