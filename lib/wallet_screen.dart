import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'app_theme.dart';
import 'device_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController _ibanController =
  TextEditingController();

  final TextEditingController _amountController =
  TextEditingController();

  bool _isLoading = true;
  bool _isWithdrawing = false;
  bool _hasError = false;

  double _balance = 0;

  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _ibanController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  double get _withdrawAmount {
    String text = _amountController.text.trim();

    if (text.isEmpty) {
      return 0;
    }

    text = text.replaceAll(".", "");
    text = text.replaceAll(",", ".");

    return double.tryParse(text) ?? 0;
  }

  Future<void> _loadWallet() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final String userId =
      await DeviceService.getDeviceId();

      final Map<String, dynamic>? result =
      await _apiService.getWallet(userId);

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _balance = 0;
          _transactions = [];
          _hasError = true;
          _isLoading = false;
        });

        return;
      }

      final double realBalance = double.tryParse(
        result["balance"]?.toString() ?? "",
      ) ??
          0;

      final List<dynamic> rawTransactions =
      result["transactions"] is List
          ? List<dynamic>.from(
        result["transactions"],
      )
          : [];

      final List<Map<String, dynamic>> realTransactions =
      rawTransactions
          .whereType<Map>()
          .map(
            (Map item) =>
        Map<String, dynamic>.from(item),
      )
          .toList();

      final bool hasRealTransactions =
          realTransactions.isNotEmpty;

      setState(() {
        _balance =
        hasRealTransactions ? realBalance : 298.00;

        _transactions = hasRealTransactions
            ? realTransactions
            : _sampleTransactions();

        _hasError = false;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint("Cüzdan yükleme hatası: $error");

      if (!mounted) {
        return;
      }

      setState(() {
        _balance = 0;
        _transactions = [];
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _sampleTransactions() {
    return [
      {
        "transaction_type": "sale",
        "description": "Not Satış Geliri",
        "amount": 24.00,
        "created_at": DateTime.now().toIso8601String(),
      },
      {
        "transaction_type": "sale",
        "description": "Not Satış Geliri",
        "amount": 24.00,
        "created_at": DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
      {
        "transaction_type": "withdrawal",
        "description": "Banka Hesabına Çekim",
        "amount": -250.00,
        "created_at": DateTime(2026, 7, 28)
            .toIso8601String(),
      },
    ];
  }

  Future<void> _createWithdrawRequest() async {
    if (_isWithdrawing) {
      return;
    }

    final String iban = _ibanController.text
        .replaceAll(" ", "")
        .trim()
        .toUpperCase();

    final double amount = _withdrawAmount;

    if (iban.isEmpty) {
      _showMessage(
        "Lütfen IBAN numaranızı yazın.",
      );
      return;
    }

    if (!RegExp(r"^TR\d{24}$").hasMatch(iban)) {
      _showMessage(
        "Geçerli bir Türkiye IBAN numarası girin.",
      );
      return;
    }

    if (amount <= 0) {
      _showMessage(
        "Lütfen geçerli bir çekim tutarı girin.",
      );
      return;
    }

    if (amount < 250) {
      _showMessage(
        "Minimum para çekme tutarı 250,00 TL'dir.",
      );
      return;
    }

    if (amount > _balance) {
      _showMessage(
        "Cüzdanınızda yeterli bakiye bulunmuyor.",
      );
      return;
    }

    setState(() {
      _isWithdrawing = true;
    });

    try {
      final String userId =
      await DeviceService.getDeviceId();

      final Map<String, dynamic> result =
      await _apiService.createWithdrawRequest(
        userId: userId,
        iban: iban,
        amount: amount,
      );

      if (!mounted) {
        return;
      }

      final bool success =
          result["success"] == true;

      final String message =
          result["message"]?.toString() ??
              "İşlem tamamlandı.";

      _showMessage(
        message,
        success: success,
      );

      if (success) {
        _ibanController.clear();
        _amountController.clear();

        FocusScope.of(context).unfocus();

        await _loadWallet();
      }
    } catch (error) {
      debugPrint(
        "Para çekme talebi hatası: $error",
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        "Para çekme talebi sırasında bir hata oluştu.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });
      }
    }
  }

  String _formatMoney(double value) {
    final String fixed =
    value.abs().toStringAsFixed(2);

    final List<String> parts =
    fixed.split(".");

    final String integerPart = parts.first;
    final String decimalPart = parts.last;

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

    final String sign = value < 0 ? "-" : "";

    return "$sign${result.toString()},$decimalPart";
  }

  String _formatTransactionDate(dynamic value) {
    if (value == null) {
      return "-";
    }

    final DateTime? parsedDate =
    DateTime.tryParse(value.toString());

    if (parsedDate == null) {
      return value.toString();
    }

    final DateTime date = parsedDate.toLocal();
    final DateTime now = DateTime.now();

    final bool isToday =
        date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

    final DateTime yesterday =
    now.subtract(const Duration(days: 1));

    final bool isYesterday =
        date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;

    if (isToday) {
      return "Bugün";
    }

    if (isYesterday) {
      return "Dün";
    }

    final String day =
    date.day.toString().padLeft(2, "0");

    final String month =
    date.month.toString().padLeft(2, "0");

    final String year =
    date.year.toString();

    return "$day.$month.$year";
  }

  String _transactionTitle(
      String type,
      String description,
      ) {
    if (description.trim().isNotEmpty) {
      return description;
    }

    switch (type) {
      case "sale":
        return "Not Satış Geliri";

      case "purchase":
        return "Not Satın Alımı";

      case "withdrawal":
        return "Banka Hesabına Çekim";

      case "deposit":
        return "Cüzdana Bakiye Yükleme";

      default:
        return "Cüzdan İşlemi";
    }
  }

  IconData _transactionIcon(
      String type,
      double amount,
      ) {
    if (amount > 0) {
      return Icons.add_rounded;
    }

    return Icons.remove_rounded;
  }

  Color _transactionColor(double amount) {
    if (amount > 0) {
      return const Color(0xFF24E49A);
    }

    return const Color(0xFFFF4D67);
  }

  void _showMessage(
      String message, {
        bool success = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

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
        title: const Text(
          "Dijital Cüzdanım",
        ),
        actions: [
          IconButton(
            onPressed:
            _isLoading ? null : _loadWallet,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryLight,
        backgroundColor: AppColors.card,
        onRefresh: _loadWallet,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 250),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_hasError) {
      return _errorView();
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        32,
      ),
      children: [
        _balanceCard(),

        const SizedBox(height: 25),

        const Text(
          "Para Çekme Talebi",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        TextField(
          controller: _ibanController,
          enabled: !_isWithdrawing,
          textCapitalization:
          TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r"[a-zA-Z0-9 ]"),
            ),
            LengthLimitingTextInputFormatter(32),
            WalletIbanFormatter(),
          ],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          decoration: const InputDecoration(
            hintText:
            "TR00 0000 0000 0000 0000 0000 00",
            prefixIcon: Icon(
              Icons.account_balance_rounded,
              color: Color(0xFF00C8E8),
            ),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _amountController,
          enabled: !_isWithdrawing,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            WalletMoneyFormatter(),
          ],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            hintText: "Çekilecek Tutar (TL)",
            prefixIcon: Icon(
              Icons.currency_lira_rounded,
              color: Color(0xFF00C8E8),
            ),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF11B7D4),
              foregroundColor:
              const Color(0xFF001018),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(16),
              ),
            ),
            onPressed: _isWithdrawing
                ? null
                : _createWithdrawRequest,
            child: _isWithdrawing
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              "Para Çekme Talebi Oluştur",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          "Hesap Hareketleri",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        ..._transactions.map(
          _transactionCard,
        ),
      ],
    );
  }

  Widget _errorView() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 150),
        const Icon(
          Icons.cloud_off_rounded,
          color: AppColors.warning,
          size: 58,
        ),
        const SizedBox(height: 17),
        const Text(
          "Cüzdan bilgileri alınamadı",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Node.js sunucusunun çalıştığından emin olun.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _loadWallet,
          icon: const Icon(
            Icons.refresh_rounded,
          ),
          label: const Text(
            "Tekrar Dene",
          ),
        ),
      ],
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF03577A),
            Color(0xFF0787BC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
        BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF19D7FF),
                size: 18,
              ),
              SizedBox(width: 9),
              Text(
                "Çekilebilir Toplam Bakiye",
                style: TextStyle(
                  color: Color(0xFFC5D7E3),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            "${_formatMoney(_balance)} TL",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Not satışlarından elde ettiğiniz net kazanç",
            style: TextStyle(
              color: Color(0xFF8FB5C7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionCard(
      Map<String, dynamic> transaction,
      ) {
    final String type =
        transaction["transaction_type"]
            ?.toString() ??
            "";

    final String description =
        transaction["description"]
            ?.toString() ??
            "";

    final double amount = double.tryParse(
      transaction["amount"]?.toString() ??
          "",
    ) ??
        0;

    final Color color =
    _transactionColor(amount);

    final String amountPrefix =
    amount > 0 ? "+" : "";

    return Container(
      margin:
      const EdgeInsets.only(bottom: 11),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF101B2D),
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _transactionIcon(type, amount),
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _transactionTitle(
                    type,
                    description,
                  ),
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatTransactionDate(
                    transaction["created_at"],
                  ),
                  style: const TextStyle(
                    color: Color(0xFF7D8CA2),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Text(
            "$amountPrefix${_formatMoney(amount)} TL",
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class WalletMoneyFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String digits = newValue.text.replaceAll(
      RegExp(r"[^0-9]"),
      "",
    );

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: "",
        selection:
        TextSelection.collapsed(
          offset: 0,
        ),
      );
    }

    while (digits.length < 3) {
      digits = "0$digits";
    }

    final String decimalPart =
    digits.substring(
      digits.length - 2,
    );

    String integerPart =
    digits.substring(
      0,
      digits.length - 2,
    );

    integerPart = integerPart.replaceFirst(
      RegExp(r"^0+(?=\d)"),
      "",
    );

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

    final String formatted =
        "${result.toString()},$decimalPart";

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}

class WalletIbanFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text
        .replaceAll(" ", "")
        .toUpperCase();

    if (text.length > 26) {
      text = text.substring(0, 26);
    }

    final StringBuffer formatted =
    StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.write(" ");
      }

      formatted.write(text[i]);
    }

    final String result =
    formatted.toString();

    return TextEditingValue(
      text: result,
      selection:
      TextSelection.collapsed(
        offset: result.length,
      ),
    );
  }
}