import 'package:flutter/material.dart';
enum NotificationFilter {
  all,
  mention,
  postLike,
  comment,
  newFollower;
  String get label => switch (this) {
        NotificationFilter.all => 'Toutes',
        NotificationFilter.mention => 'Mentions',
        NotificationFilter.postLike => 'J\'aime',
        NotificationFilter.comment => 'Commentaires',
        NotificationFilter.newFollower => 'Abonnés',
      };
  String? get apiParam => switch (this) {
        NotificationFilter.all => null,
        NotificationFilter.mention => 'mention',
        NotificationFilter.postLike => 'post_like',
        NotificationFilter.comment => 'comment',
        NotificationFilter.newFollower => 'new_follower',
      };
  IconData get icon => switch (this) {
        NotificationFilter.all => Icons.inbox,
        NotificationFilter.mention => Icons.alternate_email,
        NotificationFilter.postLike => Icons.favorite,
        NotificationFilter.comment => Icons.comment,
        NotificationFilter.newFollower => Icons.person_add,
      };
}