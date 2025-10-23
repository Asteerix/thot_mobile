import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/features/posts/application/providers/posts_state_provider.dart';
import 'package:thot/shared/widgets/common/cached_network_image_widget.dart';
class QuestionCardWithVoting extends StatefulWidget {
  final Post questionPost;
  final Map<String, dynamic> rawQuestionData;
  final bool isFromProfile;
  final Function()? onVoteCompleted;
  const QuestionCardWithVoting({
    super.key,
    required this.questionPost,
    required this.rawQuestionData,
    this.isFromProfile = false,
    this.onVoteCompleted,
  });
  @override
  State<QuestionCardWithVoting> createState() => _QuestionCardWithVotingState();
}
class _QuestionCardWithVotingState extends State<QuestionCardWithVoting> {
  final _postService = ServiceLocator.instance.postRepository;
  List<String> _selectedOptions = [];
  bool _hasVoted = false;
  bool _isVoting = false;
  Map<String, dynamic>? _currentQuestionData;
  @override
  void initState() {
    super.initState();
    _currentQuestionData = widget.rawQuestionData;
    _checkIfUserHasVoted();
  }
  void _checkIfUserHasVoted() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userProfile?.id;
    if (userId != null) {
      final metadata =
          _currentQuestionData!['metadata'] as Map<String, dynamic>?;
      final questionData = metadata?['question'] as Map<String, dynamic>?;
      if (questionData != null && questionData['voters'] != null) {
        final voters = questionData['voters'] as List<dynamic>;
        dynamic userVote;
        try {
          userVote = voters.firstWhere(
            (voter) {
              if (voter is Map<String, dynamic>) {
                final voterId = voter['userId'];
                if (voterId is String) {
                  return voterId == userId;
                } else if (voterId is Map && voterId['_id'] != null) {
                  return voterId['_id'] == userId;
                }
              }
              return false;
            },
            orElse: () => null,
          );
        } catch (e) {
          userVote = null;
        }
        if (userVote != null) {
          setState(() {
            _hasVoted = true;
            if (userVote['optionIds'] is List) {
              _selectedOptions = List<String>.from(userVote['optionIds']);
            }
          });
        }
      }
    }
  }
  bool get _isMultipleChoice {
    final metadata = _currentQuestionData!['metadata'] as Map<String, dynamic>?;
    final questionData = metadata?['question'] as Map<String, dynamic>?;
    return questionData?['isMultipleChoice'] == true;
  }
  bool get _hasOptions {
    final metadata = _currentQuestionData!['metadata'] as Map<String, dynamic>?;
    final questionData = metadata?['question'] as Map<String, dynamic>?;
    final options = questionData?['options'] as List<dynamic>?;
    return options != null && options.isNotEmpty;
  }
  String get _questionType {
    final metadata = _currentQuestionData!['metadata'] as Map<String, dynamic>?;
    final questionData = metadata?['question'] as Map<String, dynamic>?;
    return questionData?['questionType'] ?? questionData?['type'] ?? 'open';
  }
  bool get _isPollType {
    return _questionType == 'poll' && _hasOptions;
  }
  Future<void> _voteForOption(String optionId) async {
    if (_isVoting || !_isPollType) return;
    setState(() {
      _isVoting = true;
    });
    try {
      if (_isMultipleChoice) {
        List<String> newOptions = List<String>.from(_selectedOptions);
        if (newOptions.contains(optionId)) {
          newOptions.remove(optionId);
        } else {
          newOptions.add(optionId);
        }
        setState(() {
          _selectedOptions = newOptions;
          _isVoting = false;
        });
      } else {
        final isRemovingVote = _hasVoted && _selectedOptions.contains(optionId);
        if (isRemovingVote) {
          setState(() {
            _hasVoted = false;
            _selectedOptions = [];
            _isVoting = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Vote retiré (cliquez sur une autre option pour voter)'),
                backgroundColor: AppColors.orange,
              ),
            );
          }
          widget.onVoteCompleted?.call();
          return;
        }
        final response =
            await _postService.voteOnQuestion(widget.questionPost.id, optionId);
        setState(() {
          _hasVoted = true;
          _selectedOptions = [optionId];
          _currentQuestionData = response;
          _isVoting = false;
        });
        if (mounted) {
          final postsStateProvider = context.read<PostsStateProvider>();
          await postsStateProvider.loadPost(widget.questionPost.id);
        }
        widget.onVoteCompleted?.call();
      }
    } catch (e) {
      LoggerService.instance.error('Error voting: $e');
      setState(() {
        _isVoting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors du vote'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
  Future<void> _submitMultipleVotes() async {
    if (_isVoting || _selectedOptions.isEmpty || !_isPollType) return;
    setState(() {
      _isVoting = true;
    });
    try {
      if (_selectedOptions.isNotEmpty) {
        final response = await _postService.voteOnQuestion(
          widget.questionPost.id,
          _selectedOptions.first,
        );
        setState(() {
          _hasVoted = true;
          _currentQuestionData = response;
          _isVoting = false;
        });
      } else {
        setState(() {
          _isVoting = false;
        });
      }
      if (mounted) {
        final postsStateProvider = context.read<PostsStateProvider>();
        await postsStateProvider.loadPost(widget.questionPost.id);
      }
      widget.onVoteCompleted?.call();
    } catch (e) {
      LoggerService.instance.error('Error submitting votes: $e');
      setState(() {
        _isVoting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors du vote'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
  Widget _buildVoteResults() {
    final metadata = _currentQuestionData!['metadata'] as Map<String, dynamic>?;
    final questionData = metadata?['question'] as Map<String, dynamic>?;
    if (questionData == null || questionData['options'] == null) {
      return const SizedBox();
    }
    final options = questionData['options'] as List<dynamic>;
    final totalVotes = questionData['totalVotes'] ?? 0;
    int maxVotes = 0;
    for (var option in options) {
      final votes = (option['votes'] ?? 0) as int;
      if (votes > maxVotes) maxVotes = votes;
    }
    return Column(
      children: options.map((option) {
        final votes = (option['votes'] ?? 0) as int;
        final percentage = totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
        final optionId = option['_id'] ?? '';
        final isSelected = _selectedOptions.contains(optionId);
        final isWinning = votes == maxVotes && votes > 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option['text'] ?? '',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: isWinning
                          ? AppColors.blue
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight:
                          isWinning ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    width: (MediaQuery.of(context).size.width - 80) *
                        percentage /
                        100,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isWinning
                          ? AppColors.blue
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  Widget _buildVoteOptions() {
    final metadata = _currentQuestionData!['metadata'] as Map<String, dynamic>?;
    final questionData = metadata?['question'] as Map<String, dynamic>?;
    if (questionData == null || questionData['options'] == null) {
      return const SizedBox();
    }
    final options = questionData['options'] as List<dynamic>;
    final isMultiple = _isMultipleChoice;
    return Column(
      children: [
        ...options.map((option) {
          final optionId = option['_id'] ?? '';
          final isSelected = _selectedOptions.contains(optionId);
          return GestureDetector(
            onTap: _isVoting ? null : () => _voteForOption(optionId),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.blue.withOpacity(0.08)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.blue.withOpacity(0.5)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isMultiple
                        ? (isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank)
                        : (isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                    color: isSelected
                        ? AppColors.blue
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option['text'] ?? '',
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_isVoting && isSelected)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.blue),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        if (isMultiple) ...[
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_selectedOptions.isNotEmpty && !_isVoting)
                ? _submitMultipleVotes
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              disabledBackgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              disabledForegroundColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isVoting
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary),
                    ),
                  )
                : const Text(
                    'VOTER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ],
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final metadata = _currentQuestionData!['metadata'] as Map<String, dynamic>?;
    final questionData = metadata?['question'] as Map<String, dynamic>?;
    final totalVotes = questionData?['totalVotes'] ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.questionPost.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImageWidget(
                imageUrl: widget.questionPost.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.questionPost.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                if (_isPollType)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCard
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.poll,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _hasVoted
                                        ? 'Résultats du sondage'
                                        : 'Participez au sondage',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (totalVotes > 0)
                                    Text(
                                      '$totalVotes participant${totalVotes > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_isPollType && _isMultipleChoice)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MULTIPLE',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _hasVoted ? _buildVoteResults() : _buildVoteOptions(),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCard
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.comment,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Question ouverte',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Partagez votre opinion dans les commentaires',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}