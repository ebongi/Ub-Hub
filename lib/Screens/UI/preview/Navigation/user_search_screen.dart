import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_study/services/friends_service.dart';
import 'package:google_fonts/google_fonts.dart';

/// Search for other users by name and send/view friend requests.
class UserSearchScreen extends StatefulWidget {
  final FriendsService friendsService;

  const UserSearchScreen({super.key, required this.friendsService});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FriendProfile> _results = [];
  final Map<String, String> _statusCache = {}; // userId -> status
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await widget.friendsService.searchUsers(query);
      // fetch relationship status for each result
      final statuses = await Future.wait(
        results.map((r) => widget.friendsService.getRelationshipStatus(r.id)),
      );
      final newCache = <String, String>{};
      for (var i = 0; i < results.length; i++) {
        newCache[results[i].id] = statuses[i];
      }
      setState(() {
        _results = results;
        _statusCache.addAll(newCache);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest(FriendProfile user) async {
    setState(() => _statusCache[user.id] = 'pending_sent');
    try {
      await widget.friendsService.sendFriendRequest(user.id);
    } catch (e) {
      setState(() => _statusCache[user.id] = 'none');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Find Friends',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _search,
              style: GoogleFonts.outfit(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search by name…',
                hintStyle: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: theme.colorScheme.primary),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 72,
                        color: theme.colorScheme.primary.withOpacity(0.25),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Search for students to add'
                            : 'No users found',
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final user = _results[i];
                    final status = _statusCache[user.id] ?? 'none';
                    return _UserSearchTile(
                      user: user,
                      status: status,
                      theme: theme,
                      onAddFriend: () => _sendRequest(user),
                    );
                  },
                ),
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  final FriendProfile user;
  final String status; // 'none' | 'pending_sent' | 'pending_received' | 'accepted'
  final ThemeData theme;
  final VoidCallback onAddFriend;

  const _UserSearchTile({
    required this.user,
    required this.status,
    required this.theme,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    Widget actionWidget;
    switch (status) {
      case 'accepted':
        actionWidget = Chip(
          label: Text('Friends',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: Colors.green[700])),
          backgroundColor: Colors.green.withOpacity(0.1),
          side: BorderSide(color: Colors.green.withOpacity(0.3)),
          padding: EdgeInsets.zero,
        );
        break;
      case 'pending_sent':
        actionWidget = Chip(
          label: Text('Pending',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5))),
          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
          side: BorderSide.none,
          padding: EdgeInsets.zero,
        );
        break;
      case 'pending_received':
        actionWidget = Chip(
          label: Text('Requested you',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: theme.colorScheme.primary)),
          backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
          padding: EdgeInsets.zero,
        );
        break;
      default:
        actionWidget = FilledButton.icon(
          onPressed: onAddFriend,
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: Text('Add', style: GoogleFonts.outfit(fontSize: 13)),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Icon(Icons.person_rounded,
                      color: theme.colorScheme.primary, size: 24)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                user.name ?? 'Unknown',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            actionWidget,
          ],
        ),
      ),
    );
  }
}
