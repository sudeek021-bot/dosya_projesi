import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.noteId,
    required this.noteTitle,
    required this.userId,
  });

  final int noteId;
  final String noteTitle;
  final String userId;

  @override
  State<ReviewsScreen> createState() =>
      _ReviewsScreenState();
}

class _ReviewsScreenState
    extends State<ReviewsScreen> {
  final ApiService _apiService =
  ApiService();

  final TextEditingController
  _commentController =
  TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isMutatingReview = false;
  bool _canReview = false;

  String? _errorMessage;
  String? _permissionMessage;

  int _selectedRating = 5;

  double _averageRating = 0;
  int _reviewCount = 0;

  List<Map<String, dynamic>>
  _reviews =
  <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();

    _loadPage();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  Future<void> _loadPage() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final List<dynamic> results =
    await Future.wait(
      <Future<dynamic>>[
        _apiService.getReviews(
          noteId: widget.noteId,
          page: 1,
          limit: 50,
        ),
        _apiService.reviewPermission(
          noteId: widget.noteId,
          userId: widget.userId,
        ),
      ],
    );

    if (!mounted) {
      return;
    }

    final Map<String, dynamic> reviewsResult =
    Map<String, dynamic>.from(
      results[0] as Map,
    );

    final Map<String, dynamic> permissionResult =
    Map<String, dynamic>.from(
      results[1] as Map,
    );

    if (reviewsResult['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            reviewsResult['error']?.toString() ??
                'Yorumlar yüklenemedi.';
      });

      return;
    }

    final List<Map<String, dynamic>> parsedReviews =
    <Map<String, dynamic>>[];

    final dynamic reviewsValue =
    reviewsResult['reviews'];

    if (reviewsValue is List) {
      for (final dynamic item in reviewsValue) {
        if (item is Map) {
          parsedReviews.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }
    }

    final Map<String, dynamic> summary =
    reviewsResult['summary'] is Map
        ? Map<String, dynamic>.from(
      reviewsResult['summary'] as Map,
    )
        : <String, dynamic>{};

    setState(() {
      _isLoading = false;
      _reviews = parsedReviews;

      _averageRating =
          double.tryParse(
            summary['average_rating']
                ?.toString() ??
                '0',
          ) ??
              0;

      _reviewCount =
          int.tryParse(
            summary['review_count']
                ?.toString() ??
                '0',
          ) ??
              0;

      _canReview =
          permissionResult['can_review'] ==
              true;

      _permissionMessage =
          permissionResult['message']
              ?.toString();
    });
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) {
      return;
    }

    final String comment =
    _commentController.text.trim();

    if (comment.isEmpty) {
      _showMessage(
        'Lütfen yorumunuzu yazın.',
        success: false,
      );

      return;
    }

    if (comment.length > 1500) {
      _showMessage(
        'Yorum en fazla 1500 karakter olabilir.',
        success: false,
      );

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final Map<String, dynamic> result =
    await _apiService.addReview(
      noteId: widget.noteId,
      userId: widget.userId,
      rating: _selectedRating,
      comment: comment,
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
            'Yorum eklenemedi.',
        success: false,
      );

      return;
    }

    _commentController.clear();

    _showMessage(
      result['message']?.toString() ??
          'Yorumunuz eklendi.',
      success: true,
    );

    await _loadPage();
  }


  Future<void> _showReviewActions(
      Map<String, dynamic> review,
      ) async {
    if (_isMutatingReview) {
      return;
    }

    final String? selectedAction =
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primaryLight,
                  ),
                  title: const Text(
                    'Yorumu Düzenle',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop('edit');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Yorumu Sil',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop('delete');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedAction == null) {
      return;
    }

    if (selectedAction == 'edit') {
      await _editReview(review);
    } else if (selectedAction == 'delete') {
      await _deleteReview(review);
    }
  }

  Future<void> _editReview(
      Map<String, dynamic> review,
      ) async {
    final int? reviewId = int.tryParse(
      review['id']?.toString() ?? '',
    );

    if (reviewId == null) {
      _showMessage(
        'Yorum kimliği alınamadı.',
        success: false,
      );
      return;
    }

    int editedRating = int.tryParse(
      review['rating']?.toString() ?? '5',
    ) ??
        5;

    final TextEditingController editController =
    TextEditingController(
      text: review['comment']?.toString() ?? '',
    );

    final Map<String, dynamic>? editedData =
    await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
              BuildContext context,
              StateSetter dialogSetState,
              ) {
            return AlertDialog(
              title: const Text(
                'Yorumu Düzenle',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(
                        5,
                            (int index) {
                          final int starValue = index + 1;

                          return IconButton(
                            onPressed: () {
                              dialogSetState(() {
                                editedRating = starValue;
                              });
                            },
                            icon: Icon(
                              starValue <= editedRating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editController,
                      maxLines: 5,
                      maxLength: 1500,
                      decoration: const InputDecoration(
                        labelText: 'Yorumunuz',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final String editedComment =
                    editController.text.trim();

                    if (editedComment.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      <String, dynamic>{
                        'rating': editedRating,
                        'comment': editedComment,
                      },
                    );
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    editController.dispose();

    if (!mounted || editedData == null) {
      return;
    }

    setState(() {
      _isMutatingReview = true;
    });

    final Map<String, dynamic> result =
    await _apiService.updateReview(
      noteId: widget.noteId,
      reviewId: reviewId,
      userId: widget.userId,
      rating: editedData['rating'] as int,
      comment: editedData['comment'] as String,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isMutatingReview = false;
    });

    if (result['success'] != true) {
      _showMessage(
        result['error']?.toString() ??
            'Yorum güncellenemedi.',
        success: false,
      );
      return;
    }

    _showMessage(
      result['message']?.toString() ??
          'Yorum güncellendi.',
      success: true,
    );

    await _loadPage();
  }

  Future<void> _deleteReview(
      Map<String, dynamic> review,
      ) async {
    final int? reviewId = int.tryParse(
      review['id']?.toString() ?? '',
    );

    if (reviewId == null) {
      _showMessage(
        'Yorum kimliği alınamadı.',
        success: false,
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Yorumu Sil',
          ),
          content: const Text(
            'Bu yorumu kalıcı olarak silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Sil',
                style: TextStyle(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isMutatingReview = true;
    });

    final Map<String, dynamic> result =
    await _apiService.deleteReview(
      noteId: widget.noteId,
      reviewId: reviewId,
      userId: widget.userId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isMutatingReview = false;
    });

    if (result['success'] != true) {
      _showMessage(
        result['error']?.toString() ??
            'Yorum silinemedi.',
        success: false,
      );
      return;
    }

    _showMessage(
      result['message']?.toString() ??
          'Yorum silindi.',
      success: true,
    );

    await _loadPage();
  }

  void _showMessage(
      String message, {
        required bool success,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
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
          'Yorumlar',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPage,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 260,
          ),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(
          24,
        ),
        children: [
          const SizedBox(
            height: 130,
          ),
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.error,
            size: 64,
          ),
          const SizedBox(
            height: 18,
          ),
          const Text(
            'Yorumlar yüklenemedi',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              AppColors.textPrimary,
              fontSize: 18,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            _errorMessage!,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(
            height: 22,
          ),
          ElevatedButton.icon(
            onPressed:
            _loadPage,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Tekrar Dene',
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        30,
      ),
      children: [
        _buildNoteHeader(),

        const SizedBox(
          height: 16,
        ),

        _buildRatingSummary(),

        const SizedBox(
          height: 16,
        ),

        if (_canReview)
          _buildReviewForm()
        else
          _buildPermissionCard(),

        const SizedBox(
          height: 20,
        ),

        const Text(
          'Kullanıcı Yorumları',
          style: TextStyle(
            color:
            AppColors.textPrimary,
            fontSize: 17,
            fontWeight:
            FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        if (_reviews.isEmpty)
          _buildEmptyReviews()
        else
          ..._reviews.map(
            _buildReviewCard,
          ),
      ],
    );
  }

  Widget _buildNoteHeader() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        17,
      ),
      decoration:
      BoxDecoration(
        color: AppColors.card,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
          AppColors.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration:
            BoxDecoration(
              color: AppColors.primary
                  .withValues(
                alpha: 0.13,
              ),
              borderRadius:
              BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons
                  .picture_as_pdf_rounded,
              color:
              AppColors.primaryLight,
              size: 28,
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child: Text(
              widget.noteTitle,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                color:
                AppColors.textPrimary,
                fontSize: 15,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        18,
      ),
      decoration:
      BoxDecoration(
        color:
        AppColors.cardSecondary,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _averageRating
                    .toStringAsFixed(
                  1,
                ),
                style:
                const TextStyle(
                  color:
                  AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              _buildStars(
                _averageRating.round(),
                interactive: false,
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                '$_reviewCount değerlendirme',
                style:
                const TextStyle(
                  color:
                  AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 20,
          ),
          const Expanded(
            child: Text(
              'Bu notu satın alan kullanıcıların puan ve yorumları burada görüntülenir.',
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

  Widget _buildReviewForm() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        18,
      ),
      decoration:
      BoxDecoration(
        color: AppColors.card,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
          AppColors.borderSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Değerlendirme Yap',
            style: TextStyle(
              color:
              AppColors.textPrimary,
              fontSize: 16,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Center(
            child: _buildStars(
              _selectedRating,
              interactive: true,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          TextField(
            controller:
            _commentController,
            enabled:
            !_isSubmitting,
            maxLines: 5,
            maxLength: 1500,
            decoration:
            const InputDecoration(
              labelText: 'Yorumunuz',
              hintText:
              'Not hakkındaki düşüncelerinizi yazın.',
              alignLabelWithHint:
              true,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          SizedBox(
            width: double.infinity,
            child:
            ElevatedButton.icon(
              onPressed:
              _isSubmitting
                  ? null
                  : _submitReview,
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
                    .rate_review_rounded,
              ),
              label: Text(
                _isSubmitting
                    ? 'Gönderiliyor...'
                    : 'Yorumu Gönder',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color: AppColors.warning
            .withValues(
          alpha: 0.09,
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: AppColors.warning
              .withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color:
            AppColors.warning,
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Text(
              _permissionMessage ??
                  'Bu nota yorum yapamazsınız.',
              style:
              const TextStyle(
                color:
                AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyReviews() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        28,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color:
            AppColors.textMuted,
            size: 45,
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            'Henüz yorum yapılmamış',
            style: TextStyle(
              color:
              AppColors.textPrimary,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          SizedBox(
            height: 6,
          ),
          Text(
            'Bu not için ilk değerlendirmeyi siz yapabilirsiniz.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      Map<String, dynamic> review,
      ) {
    final int rating =
        int.tryParse(
          review['rating']
              ?.toString() ??
              '0',
        ) ??
            0;

    final String userId =
        review['user_id']
            ?.toString() ??
            'Kullanıcı';

    final String comment =
        review['comment']
            ?.toString() ??
            '';

    final String createdAt =
        review['created_at']
            ?.toString() ??
            '';

    final bool isCurrentUser =
        userId == widget.userId;

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 11,
      ),
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color: AppColors.card,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          AppColors.borderSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                AppColors.primary
                    .withValues(
                  alpha: 0.15,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color:
                  AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        userId,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          color:
                          AppColors
                              .textPrimary,
                          fontSize: 13,
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(
                        width: 7,
                      ),
                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          AppColors
                              .primary
                              .withValues(
                            alpha:
                            0.13,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            8,
                          ),
                        ),
                        child:
                        const Text(
                          'Siz',
                          style:
                          TextStyle(
                            color:
                            AppColors
                                .primaryLight,
                            fontSize:
                            9,
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              if (isCurrentUser)
                IconButton(
                  onPressed: _isMutatingReview
                      ? null
                      : () {
                    _showReviewActions(
                      review,
                    );
                  },
                  tooltip: 'Yorum seçenekleri',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              _buildStars(
                rating,
                interactive: false,
                iconSize: 17,
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            comment,
            style:
            const TextStyle(
              color:
              AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color:
                AppColors.textMuted,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                _formatDate(
                  createdAt,
                ),
                style:
                const TextStyle(
                  color:
                  AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStars(
      int rating, {
        required bool interactive,
        double iconSize = 30,
      }) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children:
      List<Widget>.generate(
        5,
            (int index) {
          final int starValue =
              index + 1;

          final Widget starIcon =
          Icon(
            starValue <= rating
                ? Icons.star_rounded
                : Icons
                .star_border_rounded,
            color: Colors.amber,
            size: iconSize,
          );

          if (!interactive) {
            return Padding(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 1,
              ),
              child: starIcon,
            );
          }

          return IconButton(
            onPressed: () {
              setState(() {
                _selectedRating =
                    starValue;
              });
            },
            tooltip:
            '$starValue yıldız',
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 2,
            ),
            constraints:
            const BoxConstraints(),
            icon: starIcon,
          );
        },
      ),
    );
  }

  String _formatDate(
      String value,
      ) {
    if (value.trim().isEmpty) {
      return 'Tarih bilgisi yok';
    }

    final DateTime? date =
    DateTime.tryParse(
      value,
    );

    if (date == null) {
      return value;
    }

    final DateTime localDate =
    date.toLocal();

    final DateTime now =
    DateTime.now();

    final Duration difference =
    now.difference(
      localDate,
    );

    if (difference.isNegative ||
        difference.inMinutes < 1) {
      return 'Az önce';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    }

    if (difference.inDays == 1) {
      return 'Dün';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    }

    final String day =
    localDate.day
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String month =
    localDate.month
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '$day.$month.${localDate.year}';
  }
}