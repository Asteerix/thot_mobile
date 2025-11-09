#!/usr/bin/env python3
"""
Script to replace ALL Material Icons with Lucide Icons in Flutter project.
"""

import os
import re
from pathlib import Path

# Icon mapping dictionary
ICON_MAPPING = {
    'Icons.home_outlined': 'LucideIcons.home',
    'Icons.home_rounded': 'LucideIcons.home',
    'Icons.home': 'LucideIcons.home',
    'Icons.subscriptions_outlined': 'LucideIcons.rss',
    'Icons.subscriptions': 'LucideIcons.rss',
    'Icons.play_circle_outline': 'LucideIcons.playCircle',
    'Icons.play_circle_filled': 'LucideIcons.playCircle',
    'Icons.play_circle': 'LucideIcons.playCircle',
    'Icons.explore_outlined': 'LucideIcons.compass',
    'Icons.explore': 'LucideIcons.compass',
    'Icons.account_circle_outlined': 'LucideIcons.user',
    'Icons.account_circle': 'LucideIcons.userCircle',
    'Icons.person_outline': 'LucideIcons.user',
    'Icons.person': 'LucideIcons.user',
    'Icons.favorite': 'LucideIcons.heart',
    'Icons.favorite_border': 'LucideIcons.heart',
    'Icons.mode_comment_outlined': 'LucideIcons.messageCircle',
    'Icons.comment': 'LucideIcons.messageCircle',
    'Icons.bookmark': 'LucideIcons.bookmark',
    'Icons.bookmark_border': 'LucideIcons.bookmark',
    'Icons.visibility': 'LucideIcons.eye',
    'Icons.visibility_off': 'LucideIcons.eyeOff',
    'Icons.public': 'LucideIcons.globe',
    'Icons.arrow_back_ios_new': 'LucideIcons.chevronLeft',
    'Icons.arrow_back': 'LucideIcons.arrowLeft',
    'Icons.share_outlined': 'LucideIcons.share2',
    'Icons.share': 'LucideIcons.share2',
    'Icons.flag_outlined': 'LucideIcons.flag',
    'Icons.flag': 'LucideIcons.flag',
    'Icons.link': 'LucideIcons.link',
    'Icons.close': 'LucideIcons.x',
    'Icons.search': 'LucideIcons.search',
    'Icons.search_outlined': 'LucideIcons.search',
    'Icons.search_rounded': 'LucideIcons.search',
    'Icons.clear': 'LucideIcons.x',
    'Icons.add': 'LucideIcons.plus',
    'Icons.check': 'LucideIcons.check',
    'Icons.check_circle_outline': 'LucideIcons.checkCircle',
    'Icons.check_circle': 'LucideIcons.checkCircle',
    'Icons.check_rounded': 'LucideIcons.check',
    'Icons.error_outline': 'LucideIcons.alertCircle',
    'Icons.error': 'LucideIcons.alertCircle',
    'Icons.email_outlined': 'LucideIcons.mail',
    'Icons.email': 'LucideIcons.mail',
    'Icons.lock_outline': 'LucideIcons.lock',
    'Icons.lock': 'LucideIcons.lock',
    'Icons.arrow_forward': 'LucideIcons.arrowRight',
    'Icons.arrow_forward_ios': 'LucideIcons.chevronRight',
    'Icons.edit': 'LucideIcons.edit2',
    'Icons.delete': 'LucideIcons.trash2',
    'Icons.more_vert': 'LucideIcons.moreVertical',
    'Icons.more_horiz': 'LucideIcons.moreHorizontal',
    'Icons.settings': 'LucideIcons.settings',
    'Icons.notifications': 'LucideIcons.bell',
    'Icons.notifications_outlined': 'LucideIcons.bell',
    'Icons.send': 'LucideIcons.send',
    'Icons.refresh': 'LucideIcons.refreshCw',
    'Icons.rotate_left': 'LucideIcons.rotateCcw',
    'Icons.rotate_right': 'LucideIcons.rotateCw',
    'Icons.flip': 'LucideIcons.flipHorizontal',
    'Icons.flip_camera_android': 'LucideIcons.flipHorizontal',
    'Icons.badge_outlined': 'LucideIcons.badgeCheck',
    'Icons.badge': 'LucideIcons.badgeCheck',
    'Icons.business_outlined': 'LucideIcons.building',
    'Icons.business': 'LucideIcons.building',
    'Icons.circle_outlined': 'LucideIcons.circle',
    'Icons.history': 'LucideIcons.history',
    'Icons.wifi': 'LucideIcons.wifi',
    'Icons.wifi_off': 'LucideIcons.wifiOff',
    'Icons.signal_wifi_off': 'LucideIcons.wifiOff',
    'Icons.cloud_off': 'LucideIcons.cloudOff',
    'Icons.cloud_off_outlined': 'LucideIcons.cloudOff',
    'Icons.help_outline': 'LucideIcons.helpCircle',
    'Icons.hourglass_top_rounded': 'LucideIcons.hourglass',
    'Icons.block': 'LucideIcons.ban',
    'Icons.gavel_rounded': 'LucideIcons.gavel',
    'Icons.gavel': 'LucideIcons.gavel',
    'Icons.message_outlined': 'LucideIcons.messageSquare',
    'Icons.message': 'LucideIcons.messageSquare',
    'Icons.copy_rounded': 'LucideIcons.copy',
    'Icons.copy': 'LucideIcons.copy',
    'Icons.schedule': 'LucideIcons.clock',
    'Icons.help_center_outlined': 'LucideIcons.helpCircle',
    'Icons.rule_folder_outlined': 'LucideIcons.fileText',
    'Icons.logout': 'LucideIcons.logOut',
    'Icons.person_search': 'LucideIcons.userSearch',
    'Icons.description_outlined': 'LucideIcons.fileText',
    'Icons.description': 'LucideIcons.fileText',
    'Icons.privacy_tip_outlined': 'LucideIcons.shieldCheck',
    'Icons.verified_user': 'LucideIcons.shieldCheck',
    'Icons.play_arrow': 'LucideIcons.play',
    'Icons.pause': 'LucideIcons.pause',
    'Icons.stop': 'LucideIcons.square',
    'Icons.skip_next': 'LucideIcons.skipForward',
    'Icons.skip_previous': 'LucideIcons.skipBack',
    'Icons.fast_forward': 'LucideIcons.fastForward',
    'Icons.fast_rewind': 'LucideIcons.rewind',
    'Icons.volume_up': 'LucideIcons.volume2',
    'Icons.volume_off': 'LucideIcons.volumeX',
    'Icons.fullscreen': 'LucideIcons.maximize',
    'Icons.fullscreen_exit': 'LucideIcons.minimize',
    'Icons.camera': 'LucideIcons.camera',
    'Icons.camera_alt': 'LucideIcons.camera',
    'Icons.photo_camera': 'LucideIcons.camera',
    'Icons.photo': 'LucideIcons.image',
    'Icons.image': 'LucideIcons.image',
    'Icons.video_library': 'LucideIcons.video',
    'Icons.videocam': 'LucideIcons.video',
    'Icons.mic': 'LucideIcons.mic',
    'Icons.mic_off': 'LucideIcons.micOff',
    'Icons.attach_file': 'LucideIcons.paperclip',
    'Icons.download': 'LucideIcons.download',
    'Icons.upload': 'LucideIcons.upload',
    'Icons.cloud_upload': 'LucideIcons.cloudUpload',
    'Icons.cloud_download': 'LucideIcons.cloudDownload',
    'Icons.filter_list': 'LucideIcons.filter',
    'Icons.sort': 'LucideIcons.arrowUpDown',
    'Icons.info': 'LucideIcons.info',
    'Icons.info_outline': 'LucideIcons.info',
    'Icons.warning': 'LucideIcons.alertTriangle',
    'Icons.warning_amber': 'LucideIcons.alertTriangle',
    'Icons.done': 'LucideIcons.check',
    'Icons.done_all': 'LucideIcons.checkCheck',
    'Icons.cancel': 'LucideIcons.x',
    'Icons.remove': 'LucideIcons.minus',
    'Icons.remove_circle': 'LucideIcons.minusCircle',
    'Icons.add_circle': 'LucideIcons.plusCircle',
    'Icons.create': 'LucideIcons.edit',
    'Icons.star': 'LucideIcons.star',
    'Icons.star_border': 'LucideIcons.star',
    'Icons.thumb_up': 'LucideIcons.thumbsUp',
    'Icons.thumb_down': 'LucideIcons.thumbsDown',
    'Icons.trending_up': 'LucideIcons.trendingUp',
    'Icons.trending_down': 'LucideIcons.trendingDown',
    'Icons.location_on': 'LucideIcons.mapPin',
    'Icons.location_off': 'LucideIcons.mapPinOff',
    'Icons.calendar_today': 'LucideIcons.calendar',
    'Icons.access_time': 'LucideIcons.clock',
    'Icons.folder': 'LucideIcons.folder',
    'Icons.folder_open': 'LucideIcons.folderOpen',
    'Icons.dashboard': 'LucideIcons.layoutDashboard',
    'Icons.menu': 'LucideIcons.menu',
    'Icons.apps': 'LucideIcons.grid',
    'Icons.grid_view': 'LucideIcons.grid',
    'Icons.list': 'LucideIcons.list',
    'Icons.view_list': 'LucideIcons.list',
    'Icons.view_module': 'LucideIcons.grid',
    'Icons.zoom_in': 'LucideIcons.zoomIn',
    'Icons.zoom_out': 'LucideIcons.zoomOut',
    'Icons.crop': 'LucideIcons.crop',
    'Icons.brightness_high': 'LucideIcons.sun',
    'Icons.brightness_low': 'LucideIcons.moon',
    'Icons.dark_mode': 'LucideIcons.moon',
    'Icons.light_mode': 'LucideIcons.sun',
    'Icons.language': 'LucideIcons.languages',
    'Icons.translate': 'LucideIcons.languages',
    'Icons.security': 'LucideIcons.shield',
    'Icons.privacy': 'LucideIcons.shieldCheck',
    'Icons.verified': 'LucideIcons.badgeCheck',
    'Icons.admin_panel_settings': 'LucideIcons.shieldAlert',
    'Icons.group': 'LucideIcons.users',
    'Icons.people': 'LucideIcons.users',
    'Icons.person_add': 'LucideIcons.userPlus',
    'Icons.person_remove': 'LucideIcons.userMinus',
    'Icons.login': 'LucideIcons.logIn',
    'Icons.exit_to_app': 'LucideIcons.logOut',
    'Icons.lock_open': 'LucideIcons.lockOpen',
    'Icons.vpn_key': 'LucideIcons.key',
    'Icons.fingerprint': 'LucideIcons.fingerprint',
    'Icons.notifications_outline': 'LucideIcons.bell',
    'Icons.notifications_outlined': 'LucideIcons.bell',
    'Icons.notifications_active_outlined': 'LucideIcons.bellRing',
    'Icons.palette_outlined': 'LucideIcons.palette',
    'Icons.accessibility': 'LucideIcons.accessibility',
    'Icons.edit_outlined': 'LucideIcons.edit2',
    'Icons.lock_outlined': 'LucideIcons.lock',
    'Icons.delete_outline': 'LucideIcons.trash2',
    'Icons.delete_forever': 'LucideIcons.trash2',
    'Icons.chevron_right': 'LucideIcons.chevronRight',
    'Icons.open_in_new': 'LucideIcons.externalLink',
    'Icons.build': 'LucideIcons.wrench',
    'Icons.speed': 'LucideIcons.gauge',
    'Icons.design_services': 'LucideIcons.paintbrush',
    'Icons.add_photo_alternate': 'LucideIcons.imagePlus',
    'Icons.subscriptions_rounded': 'LucideIcons.rss',
    'Icons.view_agenda_rounded': 'LucideIcons.layoutList',
    'Icons.dashboard_rounded': 'LucideIcons.layoutGrid',
    'Icons.shield_outlined': 'LucideIcons.shield',
    'Icons.folder_outlined': 'LucideIcons.folder',
    'Icons.analytics_outlined': 'LucideIcons.barChart',
    'Icons.cookie_outlined': 'LucideIcons.cookie',
    'Icons.child_care': 'LucideIcons.baby',
    'Icons.support_agent': 'LucideIcons.headphones',
    'Icons.article_outlined': 'LucideIcons.fileText',
    'Icons.block_outlined': 'LucideIcons.ban',
    'Icons.copyright_outlined': 'LucideIcons.copyright',
    'Icons.warning_outlined': 'LucideIcons.alertTriangle',
    'Icons.mail_outline': 'LucideIcons.mail',
    'Icons.warning_amber_rounded': 'LucideIcons.alertTriangle',
    'Icons.warning_amber': 'LucideIcons.alertTriangle',
    'Icons.bug_report_outlined': 'LucideIcons.bug',
    'Icons.newspaper': 'LucideIcons.newspaper',
    'Icons.visibility_outlined': 'LucideIcons.eye',
    'Icons.visibility_off_outlined': 'LucideIcons.eyeOff',
    'Icons.reply': 'LucideIcons.reply',
    'Icons.expand_less': 'LucideIcons.chevronUp',
    'Icons.expand_more': 'LucideIcons.chevronDown',
    'Icons.chat_bubble_outline': 'LucideIcons.messageCircle',
    'Icons.send_rounded': 'LucideIcons.send',
    'Icons.account_balance': 'LucideIcons.landmark',
    'Icons.show_chart': 'LucideIcons.trendingUp',
    'Icons.theater_comedy': 'LucideIcons.drama',
    'Icons.sports_soccer': 'LucideIcons.trophy',
    'Icons.computer': 'LucideIcons.laptop',
    'Icons.inbox_rounded': 'LucideIcons.inbox',
    'Icons.add_photo_alternate_outlined': 'LucideIcons.imagePlus',
    'Icons.live_tv': 'LucideIcons.tv',
    'Icons.bookmark_outline': 'LucideIcons.bookmark',
    'Icons.person_add_outlined': 'LucideIcons.userPlus',
    'Icons.health_and_safety': 'LucideIcons.heartPulse',
    'Icons.comment_outlined': 'LucideIcons.messageCircle',
    'Icons.videocam_outlined': 'LucideIcons.video',
    'Icons.format_bold': 'LucideIcons.bold',
    'Icons.format_italic': 'LucideIcons.italic',
    'Icons.title': 'LucideIcons.heading',
    'Icons.format_quote': 'LucideIcons.quote',
    'Icons.format_list_bulleted': 'LucideIcons.list',
    'Icons.format_list_numbered': 'LucideIcons.listOrdered',
    'Icons.how_to_vote_outlined': 'LucideIcons.vote',
    'Icons.science': 'LucideIcons.flask',
    'Icons.groups': 'LucideIcons.users',
    'Icons.psychology': 'LucideIcons.brain',
    'Icons.balance': 'LucideIcons.scale',
    'Icons.psychology_alt': 'LucideIcons.brain',
    'Icons.podcasts_outlined': 'LucideIcons.podcast',
    'Icons.podcasts': 'LucideIcons.podcast',
    'Icons.audiotrack': 'LucideIcons.audioLines',
    'Icons.audiotrack_outlined': 'LucideIcons.audioLines',
    'Icons.video_library_outlined': 'LucideIcons.video',
    'Icons.add_circle_outline': 'LucideIcons.plusCircle',
    'Icons.image_outlined': 'LucideIcons.image',
    'Icons.image_not_supported': 'LucideIcons.imageOff',
    'Icons.image_not_supported_outlined': 'LucideIcons.imageOff',
    'Icons.list_alt': 'LucideIcons.list',
    'Icons.play_arrow_rounded': 'LucideIcons.play',
    'Icons.pause_rounded': 'LucideIcons.pause',
    'Icons.favorite_rounded': 'LucideIcons.heart',
    'Icons.bookmark_rounded': 'LucideIcons.bookmark',
    'Icons.swap_horiz': 'LucideIcons.arrowLeftRight',
    'Icons.emoji_events': 'LucideIcons.trophy',
    'Icons.checklist': 'LucideIcons.listChecks',
    'Icons.forward_30_rounded': 'LucideIcons.forward',
    'Icons.forward_10': 'LucideIcons.forward',
    'Icons.replay_10': 'LucideIcons.rewind',
    'Icons.replay_10_rounded': 'LucideIcons.rewind',
    'Icons.people_outline': 'LucideIcons.users',
    'Icons.poll': 'LucideIcons.barChart3',
    'Icons.camera_front': 'LucideIcons.camera',
    'Icons.pause_circle_filled': 'LucideIcons.pauseCircle',
    'Icons.pending': 'LucideIcons.loader',
    'Icons.text_snippet_outlined': 'LucideIcons.fileText',
    'Icons.group_outlined': 'LucideIcons.users',
    'Icons.check_box': 'LucideIcons.checkSquare',
    'Icons.radio_button_checked': 'LucideIcons.circle',
    'Icons.remove_circle_outline': 'LucideIcons.minusCircle',
    'Icons.add_comment': 'LucideIcons.messagePlus',
    'Icons.compare_arrows': 'LucideIcons.arrowUpDown',
    'Icons.manage_accounts': 'LucideIcons.userCog',
    'Icons.search_off': 'LucideIcons.searchX',
    'Icons.signal_wifi_statusbar_connected_no_internet_4': 'LucideIcons.wifiOff',
    'Icons.headphones': 'LucideIcons.headphones',
    'Icons.arrow_forward_rounded': 'LucideIcons.arrowRight',
    'Icons.forum_rounded': 'LucideIcons.messageSquare',
    'Icons.how_to_vote': 'LucideIcons.vote',
    'Icons.location_on_outlined': 'LucideIcons.mapPin',
    'Icons.photo_camera_outlined': 'LucideIcons.camera',
    'Icons.alternate_email': 'LucideIcons.atSign',
    'Icons.hourglass_empty': 'LucideIcons.hourglass',
    'Icons.work': 'LucideIcons.briefcase',
    'Icons.play_circle_fill': 'LucideIcons.playCircle',
    'Icons.calendar_today_outlined': 'LucideIcons.calendar',
    'Icons.forum_outlined': 'LucideIcons.messageSquare',
    'Icons.poll_outlined': 'LucideIcons.barChart3',
    'Icons.post_add': 'LucideIcons.filePlus',
    'Icons.video_call': 'LucideIcons.videoPlus',
    'Icons.category_outlined': 'LucideIcons.tag',
    'Icons.north_west': 'LucideIcons.arrowUpLeft',
    'Icons.calendar_month': 'LucideIcons.calendar',
    'Icons.qr_code': 'LucideIcons.qrCode',
    'Icons.contact_page': 'LucideIcons.fileUser',
    'Icons.data_usage': 'LucideIcons.pieChart',
    'Icons.folder_special': 'LucideIcons.folderStar',
    'Icons.approval': 'LucideIcons.checkCheck',
    'Icons.sync': 'LucideIcons.refreshCw',
    'Icons.trending': 'LucideIcons.trendingUp',
    'Icons.bookmark_add': 'LucideIcons.bookmarkPlus',
    'Icons.videocam': 'LucideIcons.video',
    'Icons.article': 'LucideIcons.fileText',
    'Icons.code': 'LucideIcons.code',
    'Icons.tag': 'LucideIcons.tag',
    'Icons.upload': 'LucideIcons.upload',
    'Icons.image_search': 'LucideIcons.imageSearch',
}

def add_lucide_import(content):
    """Add lucide_icons import if not already present."""
    if 'lucide_icons' in content.lower():
        return content

    # Find the last import statement
    import_pattern = r'^import\s+.*?;$'
    matches = list(re.finditer(import_pattern, content, re.MULTILINE))

    if matches:
        last_import = matches[-1]
        insert_pos = last_import.end()
        return content[:insert_pos] + "\nimport 'package:lucide_icons/lucide_icons.dart';" + content[insert_pos:]
    else:
        # If no imports found, add at the beginning
        return "import 'package:lucide_icons/lucide_icons.dart';\n" + content

def replace_icons_in_file(file_path):
    """Replace all Material Icons with Lucide Icons in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        replacements_made = 0

        # Replace each icon
        for old_icon, new_icon in ICON_MAPPING.items():
            # Use word boundary to avoid partial matches
            pattern = r'\b' + re.escape(old_icon) + r'\b'
            count = len(re.findall(pattern, content))
            if count > 0:
                content = re.sub(pattern, new_icon, content)
                replacements_made += count

        # If replacements were made, add the import
        if replacements_made > 0:
            content = add_lucide_import(content)

            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

            return replacements_made

        return 0

    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return 0

def process_directory(directory):
    """Process all .dart files in directory recursively."""
    total_files = 0
    total_replacements = 0
    modified_files = []

    dart_files = list(Path(directory).rglob('*.dart'))

    print(f"Found {len(dart_files)} Dart files to process...")

    for dart_file in dart_files:
        replacements = replace_icons_in_file(str(dart_file))
        if replacements > 0:
            total_files += 1
            total_replacements += replacements
            modified_files.append(str(dart_file))
            print(f"✓ {dart_file.name}: {replacements} icons replaced")

    return total_files, total_replacements, modified_files

if __name__ == '__main__':
    lib_dir = '/Users/amaury/Desktop/backup/thot/thot_mobile/lib'

    print("=" * 80)
    print("Material Icons → Lucide Icons Replacement Script")
    print("=" * 80)
    print()

    total_files, total_replacements, modified_files = process_directory(lib_dir)

    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total files modified: {total_files}")
    print(f"Total icon replacements: {total_replacements}")
    print()

    if modified_files:
        print("Modified files:")
        for file_path in modified_files[:20]:  # Show first 20
            print(f"  - {file_path}")
        if len(modified_files) > 20:
            print(f"  ... and {len(modified_files) - 20} more files")

