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
  String? get apiParam => this == NotificationFilter.all ? null : name;
  IconData get icon => switch (this) {
        NotificationFilter.all => Icons.inbox_rounded,
        NotificationFilter.mention => Icons.alternate_email,
        NotificationFilter.postLike => Icons.favorite_rounded,
        NotificationFilter.comment => Icons.chat_bubble_rounded,
        NotificationFilter.newFollower => Icons.group_add_rounded,
      };
}