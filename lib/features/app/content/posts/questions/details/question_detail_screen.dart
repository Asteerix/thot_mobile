import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/widgets/post_actions.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/app/content/shared/widgets/post_header.dart';

class QuestionDetailScreen extends StatefulWidget {
  final String questionId;
  final bool isFromProfile;
  final String? userId;
  const QuestionDetailScreen({
    super.key,
    required this.questionId,
    this.isFromProfile = false,
    this.userId,
  });
  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen>
    with TickerProviderStateMixin {
  final _postRepository = ServiceLocator.instance.postRepository;
  Post? _questionPost;
  Map<String, dynamic>? _rawQuestionData;
  bool _isLoading = true;
  String? _error;
  final Set<String> _selectedOptions = {};
  bool _hasVoted = false;
  bool _isMultipleChoice = false;
  bool _isExpired = false;
  DateTime? _endDate;
  late AnimationController _animationController;
  late AnimationController _progressAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  double _animatedTotalVotes = 0;
  int _totalParticipants = 0;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _progressAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestion();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Future.delayed(Duration.zero);
      if (!mounted) return;
      final postsStateProvider = context.read<PostsStateProvider>();
      final post = await postsStateProvider.loadPost(widget.questionId);
      if (post == null) {
        throw Exception('Question introuvable');
      }
      final rawData = await _postRepository.getPost(widget.questionId);
      if (!mounted) return;
      setState(() {
        _questionPost = post;
        _rawQuestionData = rawData;
        final questionData = rawData['metadata']?['question'] ?? {};
        _isMultipleChoice = questionData['multipleChoice'] ?? false;
        _hasVoted = (questionData['votedBy'] as List?)?.isNotEmpty ?? false;
        if (questionData['endDate'] != null) {
          _endDate = DateTime.parse(questionData['endDate']);
          _isExpired = _endDate!.isBefore(DateTime.now());
        }
        final votedBy = questionData['votedBy'] as List? ?? [];
        _totalParticipants = votedBy.length;
        _isLoading = false;
      });
      _animationController.forward();
      _progressAnimationController.forward();
      final totalVotes =
          (_rawQuestionData!['metadata']?['question']?['totalVotes'] as int?) ??
              0;
      _animateTotalVotes(totalVotes);
    } catch (e) {
      LoggerService.instance.error('Error loading question', e);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _voteForOption(String optionId) {
    if (_hasVoted || _isExpired) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_isMultipleChoice) {
        if (_selectedOptions.contains(optionId)) {
          _selectedOptions.remove(optionId);
        } else {
          _selectedOptions.add(optionId);
        }
      } else {
        _selectedOptions.clear();
        _selectedOptions.add(optionId);
        _submitVotes();
      }
    });
  }

  Future<void> _submitVotes() async {
    if (_selectedOptions.isEmpty) {
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Veuillez sélectionner au moins une option'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }
    try {
      HapticFeedback.heavyImpact();
      if (_selectedOptions.isNotEmpty) {
        await _postRepository.voteOnQuestion(
            widget.questionId, _selectedOptions.first);
      }
      setState(() {
        _hasVoted = true;
      });
      _loadQuestion();
      if (mounted) {
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
              content: Text('Vote enregistré avec succès!'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showComments() {
    SafeNavigation.showSnackBar(
      context,
      SnackBar(
        content: Text('Ouvrir les commentaires...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleLike(Post post) async {
    final postsProvider = context.read<PostsStateProvider>();
    await postsProvider.toggleLike(post.id);
  }

  Future<void> _handleSave(Post post) async {
    final postsProvider = context.read<PostsStateProvider>();
    await postsProvider.toggleBookmark(post.id);
  }

  String _getTimeRemaining() {
    if (_endDate == null) return '';
    final now = DateTime.now();
    if (_endDate!.isBefore(now)) return 'Terminé';
    final difference = _endDate!.difference(now);
    if (difference.inDays > 0) {
      return '${difference.inDays}j restants';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h restantes';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min restantes';
    } else {
      return 'Bientôt terminé';
    }
  }

  void _animateTotalVotes(int target) {
    final animation = Tween<double>(
      begin: 0,
      end: target.toDouble(),
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutCubic,
    ));
    animation.addListener(() {
      setState(() {
        _animatedTotalVotes = animation.value;
      });
    });
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}k';
    }
    return number.toString();
  }

  Widget _buildQuestionHeader() {
    if (_questionPost == null) return SizedBox.shrink();
    return Container(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(
            post: _questionPost!,
            onBack: () => SafeNavigation.pop(context),
            isVideoPost: false,
          ),
          if (_questionPost!.imageUrl != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _questionPost!.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white.withOpacity(0.3),
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
          ],
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _questionPost!.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isExpired ? 1.0 : _pulseAnimation.value,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isExpired
                                    ? AppColors.red.withOpacity(0.2)
                                    : AppColors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isExpired
                                      ? AppColors.red.withOpacity(0.3)
                                      : AppColors.purple.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isExpired ? Icons.lock : Icons.timer,
                                    size: 14,
                                    color: _isExpired
                                        ? AppColors.red
                                        : AppColors.purple,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _getTimeRemaining(),
                                    style: TextStyle(
                                      color: _isExpired
                                          ? Colors.red
                                          : AppColors.purple,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (_isMultipleChoice)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.checklist,
                                size: 14,
                                color: AppColors.info,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Choix multiple',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_totalParticipants > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group,
                                size: 14,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${_formatNumber(_totalParticipants)} participants',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
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
        ],
      ),
    );
  }

  Widget _buildPollOptions() {
    if (_rawQuestionData == null) return SizedBox.shrink();
    final options =
        (_rawQuestionData!['metadata']?['question']?['options'] as List?) ?? [];
    final totalVotes =
        (_rawQuestionData!['metadata']?['question']?['totalVotes'] as int?) ??
            0;
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.5),
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple[400] ?? AppColors.purple,
                            Colors.blue[400] ?? AppColors.blue,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bar_chart,
                        color: Theme.of(context).colorScheme.surface,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasVoted || _isExpired
                              ? 'Résultats du sondage'
                              : 'Sondage en cours',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        if (totalVotes > 0)
                          AnimatedBuilder(
                            animation: _progressAnimationController,
                            builder: (context, child) {
                              return Text(
                                '${_animatedTotalVotes.toInt()} ${_animatedTotalVotes.toInt() == 1 ? 'vote' : 'votes'} au total',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                if (!_hasVoted && !_isExpired)
                  Icon(
                    Icons.touch_app,
                    color: Colors.purple[400] ?? AppColors.purple,
                    size: 24,
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final optionId = option['id'] ?? '';
            final text = option['text'] ?? '';
            final votes = option['votes'] ?? 0;
            final percentage =
                totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
            final isSelected = _selectedOptions.contains(optionId);
            final showResults = _hasVoted || _isExpired;
            final isWinning = showResults &&
                votes ==
                    options
                        .map((o) => (o['votes'] ?? 0) as int)
                        .reduce(math.max);
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: showResults ? null : () => _voteForOption(optionId),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: showResults
                        ? (isWinning
                            ? AppColors.purple.withOpacity(0.1)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest)
                        : (isSelected
                            ? AppColors.purple.withOpacity(0.2)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: showResults
                          ? (isWinning
                              ? AppColors.purple.withOpacity(0.5)
                              : Theme.of(context).colorScheme.outline)
                          : (isSelected
                              ? AppColors.purple
                              : Theme.of(context).colorScheme.outline),
                      width: (isSelected || isWinning) ? 2 : 1,
                    ),
                    boxShadow: isWinning
                        ? [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (showResults)
                        AnimatedBuilder(
                          animation: _progressAnimationController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: (_progressAnimationController.value *
                                      percentage /
                                      100)
                                  .clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.purple.withOpacity(0.3),
                                      AppColors.blue.withOpacity(0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: showResults
                                    ? (isWinning
                                        ? LinearGradient(
                                            colors: [
                                              Colors.purple[400] ??
                                                  AppColors.purple,
                                              Colors.blue[400] ??
                                                  AppColors.blue,
                                            ],
                                          )
                                        : null)
                                    : (isSelected
                                        ? LinearGradient(
                                            colors: [
                                              Colors.purple[400] ??
                                                  AppColors.purple,
                                              Colors.purple[600] ??
                                                  AppColors.purple,
                                            ],
                                          )
                                        : null),
                                color: (showResults && !isWinning)
                                    ? AppColors.purple.withOpacity(0.2)
                                    : (!showResults && !isSelected)
                                        ? Theme.of(context).colorScheme.outline
                                        : null,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: showResults
                                    ? Text(
                                        '${percentage.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          shadows: isWinning
                                              ? [
                                                  Shadow(
                                                    blurRadius: 3,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      )
                                    : Text(
                                        String.fromCharCode(65 + index),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: showResults || isSelected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  fontSize: 15,
                                  fontWeight: showResults || isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (showResults && isWinning)
                              Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.emoji_events,
                                  color: AppColors.warning,
                                  size: 18,
                                ),
                              ),
                            if (showResults) ...[
                              SizedBox(width: 8),
                              Text(
                                '$votes',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (!showResults && isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.purple,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_isMultipleChoice &&
              !_hasVoted &&
              !_isExpired &&
              _selectedOptions.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 16),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple[400] ?? AppColors.purple,
                    Colors.purple[600] ?? AppColors.purple,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _submitVotes,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.how_to_vote,
                          color: Theme.of(context).colorScheme.surface,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Voter (${_selectedOptions.length} ${_selectedOptions.length == 1 ? 'choix' : 'choix'})',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpenEndedQuestion() {
    final commentCount = 0;
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (Colors.purple[900] ?? AppColors.purple).withOpacity(0.2),
            (Colors.blue[900] ?? AppColors.blue).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (Colors.purple[700] ?? AppColors.purple).withOpacity(0.3),
                  (Colors.blue[700] ?? AppColors.blue).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple[400] ?? AppColors.purple,
                              Colors.blue[400] ?? AppColors.blue,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.forum,
                          size: 32,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Text(
                  'Débat Ouvert',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Partagez votre opinion et débattez avec la communauté',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      Icons.comment,
                      commentCount,
                      'Réponses',
                      AppColors.blue,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    _buildStatItem(Icons.group, _totalParticipants,
                        'Participants', AppColors.success),
                  ],
                ),
                SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple[400] ?? AppColors.purple,
                        Colors.blue[400] ?? AppColors.blue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showComments,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_comment,
                            color: Theme.of(context).colorScheme.surface,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Participer au débat',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int value, String label, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        SizedBox(height: 8),
        Text(
          _formatNumber(value),
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.purple,
              ),
              SizedBox(height: 16),
              Text(
                'Chargement de la question...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null || _questionPost == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () => SafeNavigation.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _error ?? 'Une erreur est survenue',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                ),
                icon: Icon(Icons.refresh),
                label: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    final questionType =
        _rawQuestionData?['metadata']?['question']?['type'] ?? 'poll';
    final isPoll = questionType == 'poll';
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildQuestionHeader(),
              ),
              SliverToBoxAdapter(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child:
                      isPoll ? _buildPollOptions() : _buildOpenEndedQuestion(),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                    Theme.of(context).colorScheme.onSurface,
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: PostActions(
                post: _questionPost!,
                onLike: () => _handleLike(_questionPost!),
                onComment: _showComments,
                onSave: () => _handleSave(_questionPost!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
