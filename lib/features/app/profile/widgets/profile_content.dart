import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/models/question.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'profile_grid.dart';
import 'package:thot/features/app/content/posts/questions/widgets/question_cards.dart';
import 'package:thot/features/app/content/posts/questions/widgets/question_card_with_voting.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/core/routing/app_router.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
class ProfileContent extends StatefulWidget {
  final List<dynamic>? posts;
  final List<dynamic>? shorts;
  final List<Map<String, dynamic>>? questions;
  final String journalistId;
  final bool isJournalist;
  final TabController controller;
  const ProfileContent({
    super.key,
    required this.posts,
    required this.shorts,
    required this.questions,
    required this.journalistId,
    required this.isJournalist,
    required this.controller,
  });
  @override
  State<ProfileContent> createState() => _ProfileContentState();
}
class _ProfileContentState extends State<ProfileContent> {
  final _postService = ServiceLocator.instance.postRepository;
  final Map<String, Map<String, dynamic>> _questionsRawData = {};
  final Map<String, Post> _questionPosts = {};
  bool _isLoadingQuestions = false;
  @override
  void initState() {
    super.initState();
    _loadQuestionPosts();
  }
  Future<void> _loadQuestionPosts() async {
    if (widget.questions == null || widget.questions!.isEmpty) return;
    setState(() {
      _isLoadingQuestions = true;
    });
    try {
      final postsStateProvider = context.read<PostsStateProvider>();
      for (final questionData in widget.questions!) {
        final questionId = questionData['id']?.toString() ??
            questionData['_id']?.toString() ??
            '';
        if (questionId.isNotEmpty) {
          try {
            final post = await postsStateProvider.loadPost(questionId);
            if (post != null) {
              _questionPosts[questionId] = post;
            }
            final rawData = await _postService.getPost(questionId);
            _questionsRawData[questionId] = rawData;
          } catch (e) {
            LoggerService.instance
                .error('Error loading question $questionId: $e');
          }
        }
      }
    } catch (e) {
      LoggerService.instance.error('Error loading questions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingQuestions = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.controller,
      children: [
        widget.posts == null
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 1,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = widget.posts![index];
                        return ProfileGridItem(
                          imageUrl: post['imageUrl'] ??
                              post['mediaUrl'] ??
                              'assets/images/defaults/default_journalist_avatar.png',
                          type: post['type'] ?? PostType.article,
                        );
                      },
                      childCount: widget.posts!.length,
                    ),
                  ),
                ],
              ),
        if (widget.isJournalist) ...[
          widget.shorts == null
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 1,
                        crossAxisSpacing: 1,
                        childAspectRatio: 0.6,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final short = widget.shorts![index];
                          return ProfileGridItem(
                            imageUrl: short['imageUrl'] ??
                                short['mediaUrl'] ??
                                'assets/images/defaults/default_journalist_avatar.png',
                            type: PostType.short.name,
                          );
                        },
                        childCount: widget.shorts!.length,
                      ),
                    ),
                  ],
                ),
          widget.questions == null || _isLoadingQuestions
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final questionData = widget.questions![index];
                          final questionId = questionData['id']?.toString() ??
                              questionData['_id']?.toString() ??
                              '';
                          final questionPost = _questionPosts[questionId];
                          final rawData = _questionsRawData[questionId];
                          if (questionPost == null || rawData == null) {
                            final question = Question.fromJson(questionData);
                            return GestureDetector(
                              onTap: () {
                                AppRouter.navigateTo(
                                  context,
                                  RouteNames.question,
                                  arguments: {
                                    'questionId': question.id,
                                    'journalistId': widget.journalistId,
                                  },
                                );
                              },
                              child: QuestionCard(
                                question: question,
                                onVote: (optionId, optionText) {},
                                isExpanded: false,
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () {
                              AppRouter.navigateTo(
                                context,
                                RouteNames.question,
                                arguments: {
                                  'questionId': questionId,
                                  'journalistId': widget.journalistId,
                                },
                              );
                            },
                            child: QuestionCardWithVoting(
                              questionPost: questionPost,
                              rawQuestionData: rawData,
                              isFromProfile: true,
                              onVoteCompleted: () {
                                _loadQuestionPosts();
                              },
                            ),
                          );
                        },
                        childCount: widget.questions!.length,
                      ),
                    ),
                  ],
                ),
        ] else
          const Center(
              child:
                  Text('Sauvegardés', style: TextStyle(color: Colors.white))),
      ],
    );
  }
}