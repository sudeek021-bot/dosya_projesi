import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.noteId,
    required this.noteTitle,
    required this.userId,
  });

  final int noteId;
  final String noteTitle;
  final String userId;

  @override
  State<ReportScreen> createState() =>
      _ReportScreenState();
}

class _ReportScreenState
    extends State<ReportScreen> {
  final ReportService _reportService =
  ReportService();

  final TextEditingController
  _descriptionController =
  TextEditingController();

  static const Map<String, String>
  _reasonLabels = <String, String>{
    'incorrect_content':
    'Yanlış veya hatalı içerik',
    'incomplete_content':
    'Eksik içerik',
    'copyright':
    'Telif hakkı ihlali',
    'inappropriate_content':
    'Uygunsuz içerik',
    'spam':
    'Spam veya yanıltıcı içerik',
    'other':
    'Diğer',
  };

  String _selectedReason =
      'incorrect_content';

  bool _isSubmitting = false;
  bool _isCompleted = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_isSubmitting ||
        _isCompleted) {
      return;
    }

    if (widget.userId.trim().isEmpty) {
      _showMessage(
        'Kullanıcı bilgisi alınamadı.',
        success: false,
      );
      return;
    }

    final String description =
    _descriptionController.text.trim();

    if (_selectedReason == 'other' &&
        description.isEmpty) {
      _showMessage(
        'Diğer seçeneği için açıklama yazın.',
        success: false,
      );
      return;
    }

    if (description.length > 2000) {
      _showMessage(
        'Açıklama en fazla 2000 karakter olabilir.',
        success: false,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final Map<String, dynamic> result =
    await _reportService.reportNote(
      noteId: widget.noteId,
      userId: widget.userId,
      reason: _selectedReason,
      description: description,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] != true) {
      _showMessage(
        result['error']?.toString() ??
            'Şikâyet gönderilemedi.',
        success: false,
      );
      return;
    }

    setState(() {
      _isCompleted = true;
    });

    _showMessage(
      result['message']?.toString() ??
          'Şikâyetiniz incelemeye alındı.',
      success: true,
    );
  }

  void _showMessage(
      String message, {
        required bool success,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons
                  .check_circle_rounded
                  : Icons
                  .error_outline_rounded,
              color: success
                  ? AppColors.success
                  : AppColors.error,
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
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notu Şikâyet Et',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          children: [
            _buildNoteCard(),

            const SizedBox(height: 16),

            if (_isCompleted)
              _buildSuccessCard()
            else ...[
              _buildInformationCard(),

              const SizedBox(height: 18),

              const Text(
                'Şikâyet Nedeni',
                style: TextStyle(
                  color:
                  AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              _buildReasonSelector(),

              const SizedBox(height: 18),

              TextField(
                controller:
                _descriptionController,
                enabled:
                !_isSubmitting,
                maxLines: 6,
                maxLength: 2000,
                decoration:
                const InputDecoration(
                  labelText:
                  'Açıklama',
                  hintText:
                  'Sorunu ayrıntılı şekilde açıklayın.',
                  alignLabelWithHint:
                  true,
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child:
                ElevatedButton.icon(
                  onPressed:
                  _isSubmitting
                      ? null
                      : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons
                        .flag_rounded,
                  ),
                  label: Text(
                    _isSubmitting
                        ? 'Gönderiliyor...'
                        : 'Şikâyeti Gönder',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(17),
      decoration:
      BoxDecoration(
        color: AppColors.card,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color:
          AppColors.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
            BoxDecoration(
              color: AppColors.error
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              Icons
                  .picture_as_pdf_rounded,
              color: AppColors.error,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Text(
                  'Şikâyet edilen not',
                  style: TextStyle(
                    color:
                    AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.noteTitle,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color:
                    AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: AppColors.primary
            .withValues(
          alpha: 0.09,
        ),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary
              .withValues(
            alpha: 0.24,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons
                .info_outline_rounded,
            color:
            AppColors.primaryLight,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Şikâyetiniz admin tarafından incelenecektir. Aynı not için aktif bir şikâyetiniz varsa tekrar gönderemezsiniz.',
              style: TextStyle(
                color:
                AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSelector() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration:
      BoxDecoration(
        color: AppColors.card,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          AppColors.borderSoft,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReason,
          isExpanded: true,
          dropdownColor:
          AppColors.card,
          icon: const Icon(
            Icons
                .keyboard_arrow_down_rounded,
          ),
          items: _reasonLabels.entries
              .map(
                (
                MapEntry<String, String>
                entry,
                ) {
              return DropdownMenuItem<
                  String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style:
                  const TextStyle(
                    color: AppColors
                        .textPrimary,
                    fontSize: 13,
                  ),
                ),
              );
            },
          )
              .toList(),
          onChanged: _isSubmitting
              ? null
              : (String? value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedReason =
                  value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
      decoration:
      BoxDecoration(
        color: AppColors.success
            .withValues(
          alpha: 0.10,
        ),
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.success
              .withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons
                .check_circle_rounded,
            color: AppColors.success,
            size: 58,
          ),
          const SizedBox(height: 14),
          const Text(
            'Şikâyetiniz Alındı',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              AppColors.textPrimary,
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bildiriminiz admin incelemesine gönderildi.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              AppColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child:
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context)
                    .pop();
              },
              icon: const Icon(
                Icons
                    .arrow_back_rounded,
              ),
              label: const Text(
                'Not Detayına Dön',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
