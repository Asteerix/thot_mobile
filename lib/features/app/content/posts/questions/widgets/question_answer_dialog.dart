import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/models/question.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:thot/core/di/service_locator.dart';

/// Modale pour répondre à une question/sondage
class QuestionAnswerDialog extends StatefulWidget {
  final Post post;
  final Question question;

  const QuestionAnswerDialog({
    super.key,
    required this.post,
    required this.question,
  });

  @override
  State<QuestionAnswerDialog> createState() => _QuestionAnswerDialogState();
}

class _QuestionAnswerDialogState extends State<QuestionAnswerDialog> {
  Set<String> _selectedOptionIds = {};
  bool _isVoting = false;
  bool _hasVoted = false;
  Map<String, int> _voteCounts = {};
  int _totalVotes = 0;
  late bool _isMultipleChoice;

  @override
  void initState() {
    super.initState();
    _initializeVotes();
  }

  void _initializeVotes() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎯 QUESTION_ANSWER_DIALOG - INIT');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📋 Question: ${widget.question.title}');
    print('📋 Total votes from question: ${widget.question.totalVotes}');
    print('📋 Options count: ${widget.question.options.length}');

    _totalVotes = widget.question.totalVotes;
    _isMultipleChoice = widget.question.isMultipleChoice;

    // Vérifier si l'utilisateur a déjà voté
    final userVotedOptions = widget.question.getUserVotedOptions();
    if (userVotedOptions.isNotEmpty) {
      _hasVoted = true;
      _selectedOptionIds = userVotedOptions.toSet();
      print('✅ User has already voted: $_selectedOptionIds');
    }

    for (final option in widget.question.options) {
      final optionId = option.id ?? '';
      _voteCounts[optionId] = option.votes;
      print('   Option: ${option.text} (id: $optionId, votes: ${option.votes})');
    }
    print('📋 Multiple choice: $_isMultipleChoice');
    print('📋 Has already voted: $_hasVoted');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildQuestionContent(),
                      _buildVotingOptions(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.help_outline, color: AppColors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.question.title,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87, size: 22),
              onPressed: () => Navigator.of(context).pop(),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.question.description.isNotEmpty) ...[
            Text(
              widget.question.description,
              style: const TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 16,
                height: 1.7,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 28),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_hasVoted ? AppColors.success : AppColors.blue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _hasVoted
                      ? Icons.check_circle
                      : (_isMultipleChoice ? Icons.checklist : Icons.touch_app),
                  color: _hasVoted ? AppColors.success : AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _hasVoted ? 'Votre vote' : 'Choisissez votre réponse',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _hasVoted
                ? 'Merci pour votre participation !'
                : _isMultipleChoice
                    ? 'Sélectionnez une ou plusieurs options'
                    : 'Sélectionnez une option ci-dessous',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingOptions() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎨 BUILD VOTING OPTIONS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Options to display: ${widget.question.options.length}');
    print('🗳️ Has voted: $_hasVoted');
    print('🔒 Is voting: $_isVoting');
    print('✅ Selected options: $_selectedOptionIds');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final optionId = option.id ?? index.toString();
            final isSelected = _selectedOptionIds.contains(optionId);
            final voteCount = _voteCounts[optionId] ?? option.votes;
            final percentage =
                _totalVotes > 0 ? (voteCount / _totalVotes * 100).round() : 0;

            return GestureDetector(
              onTap: !_hasVoted && !_isVoting
                  ? () => _toggleOption(optionId)
                  : null,
              child: Container(
                height: 62,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.blue
                        : Colors.grey[300]!,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected && !_hasVoted
                      ? [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    children: [
                      if (_hasVoted && percentage > 0)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: percentage / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppColors.blue.withOpacity(0.7),
                                      AppColors.blue.withOpacity(0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: _isMultipleChoice
                                    ? BoxShape.rectangle
                                    : BoxShape.circle,
                                borderRadius: _isMultipleChoice
                                    ? BorderRadius.circular(7)
                                    : null,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.blue
                                      : Colors.black.withOpacity(0.3),
                                  width: 2,
                                ),
                                color: isSelected
                                    ? AppColors.blue
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_hasVoted)
                              Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 0),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.blue,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$percentage%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
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
          if (!_hasVoted &&
              _isMultipleChoice &&
              _selectedOptionIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVoting ? null : _submitVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isVoting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Valider (${_selectedOptionIds.length} sélectionnée${_selectedOptionIds.length > 1 ? 's' : ''})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
          if (_hasVoted) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_vote,
                      color: Colors.black.withOpacity(0.6), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '$_totalVotes vote${_totalVotes > 1 ? 's' : ''} au total',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _toggleOption(String optionId) {
    if (_hasVoted || _isVoting) return;

    setState(() {
      if (_isMultipleChoice) {
        if (_selectedOptionIds.contains(optionId)) {
          _selectedOptionIds.remove(optionId);
        } else {
          _selectedOptionIds.add(optionId);
        }
      } else {
        _selectedOptionIds = {optionId};
        _submitVote();
      }
    });

    HapticFeedback.selectionClick();
  }

  Future<void> _submitVote() async {
    if (_isVoting || _hasVoted || _selectedOptionIds.isEmpty) return;

    setState(() {
      _isVoting = true;
    });

    try {
      HapticFeedback.mediumImpact();

      final postRepository = ServiceLocator.instance.postRepository;

      if (_isMultipleChoice) {
        // TODO: API pour choix multiple
        // Pour l'instant on vote sur chaque option
        for (final optionId in _selectedOptionIds) {
          await postRepository.voteOnQuestion(widget.post.id, optionId);
        }
      } else {
        final optionId = _selectedOptionIds.first;
        final voteResult =
            await postRepository.voteOnQuestion(widget.post.id, optionId);
        print('✅ Vote result: $voteResult');
      }

      setState(() {
        _hasVoted = true;
        for (final optionId in _selectedOptionIds) {
          _voteCounts[optionId] = (_voteCounts[optionId] ?? 0) + 1;
        }
        _totalVotes += _selectedOptionIds.length;
        _isVoting = false;
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Vote enregistré avec succès',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error voting: $e');
      if (mounted) {
        setState(() {
          _selectedOptionIds.clear();
          _isVoting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors du vote: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
