import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';
import '../services/api_service.dart';
import 'inner_circle_join_page.dart';
import '../ui/app_theme.dart';

class InnerCirclePage extends StatefulWidget {
  const InnerCirclePage({super.key});

  @override
  State<InnerCirclePage> createState() => _InnerCirclePageState();
}

class _InnerCirclePageState extends State<InnerCirclePage> {
  String? token;
  String? userId;
  bool loading = false;
  bool loadingInvite = false;
  String? inviteLink;
  List<InnerCirclePost> posts = [];

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetch();
  }

  Future<void> _loadAuthAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    userId = prefs.getString("user_id");

    if (token == null || userId == null) return;

    await Future.wait([
      _fetchInviteLink(),
      _fetchPosts(),
    ]);
  }

  Future<void> _fetchInviteLink() async {
    if (token == null || userId == null) return;
    setState(() => loadingInvite = true);

    final res = await ApiService.getInnerCircleInviteLink(token!, userId!);
    String? link;

    if (res != null && res["status"] == true) {
      if (res["link"] != null) {
        link = res["link"].toString();
      } else if (res["data"] is Map && res["data"]["link"] != null) {
        link = res["data"]["link"].toString();
      }
    }

    setState(() {
      inviteLink = link;
      loadingInvite = false;
    });
  }

  Future<void> _fetchPosts() async {
    if (token == null || userId == null) return;
    setState(() => loading = true);

    final res = await ApiService.getInnerCirclePosts(token!, userId!);
    final parsed = <InnerCirclePost>[];

    if (res != null && res["status"] == true) {
      dynamic list = res["data"];
      if (list is Map && list["posts"] is List) {
        list = list["posts"];
      }
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            parsed.add(InnerCirclePost.fromJson(item));
          }
        }
      }
    }

    setState(() {
      posts = parsed;
      loading = false;
    });
  }

  Future<void> _copyInviteLink() async {
    if (token == null || userId == null) return;
    if (inviteLink == null) {
      await _fetchInviteLink();
    }

    if (inviteLink == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not load invite link"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: inviteLink!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invite link copied")),
    );
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Invite to Inner Circle"),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? "";
                    if (value.isEmpty) return "Enter email";
                    if (!value.contains("@")) return "Enter valid email";
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (token == null || userId == null) return;
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => sending = true);
                          final res = await ApiService.sendInnerCircleInvite(
                            token!,
                            userId: userId!,
                            email: emailController.text.trim(),
                          );
                          setDialogState(() => sending = false);

                          if (res != null && res["status"] == true) {
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invite sent")),
                            );
                          } else {
                            if (!mounted) return;
                            final msg = res != null && res["message"] != null
                                ? res["message"].toString()
                                : "Failed to send invite";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Send"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openJoinPage() async {
    final joined = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const InnerCircleJoinPage()),
    );

    if (joined == true) {
      await _fetchPosts();
      await _fetchInviteLink();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're in the circle")),
      );
    }
  }

  Future<void> _toggleLike(InnerCirclePost post) async {
    if (token == null) return;
    final res = post.likedByMe
        ? await ApiService.unlikeInnerCirclePost(token!, post.id)
        : await ApiService.likeInnerCirclePost(token!, post.id);

    if (res != null && res["status"] == true) {
      final likes = int.tryParse((res["likes_count"] ?? post.likes).toString()) ??
          post.likes;
      final liked = res["liked_by_me"] == true;

      setState(() {
        final idx = posts.indexWhere((p) => p.id == post.id);
        if (idx >= 0) {
          posts[idx] = posts[idx].copyWith(
            likes: likes,
            likedByMe: liked,
          );
        }
      });
    }
  }

  Future<void> _showCommentsDialog(InnerCirclePost post) async {
    if (token == null) return;
    final controller = TextEditingController();
    bool loadingComments = true;
    bool saving = false;
    List<InnerCircleComment> comments = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadIfNeeded() async {
              if (!loadingComments) return;
              final res = await ApiService.getInnerCircleComments(
                token!,
                post.id,
              );
              if (res != null && res["status"] == true) {
                final list = res["data"];
                if (list is List) {
                  comments = list
                      .whereType<Map>()
                      .map((e) => InnerCircleComment.fromJson(e))
                      .toList();
                }
              }
              setDialogState(() => loadingComments = false);
            }

            loadIfNeeded();

            return AlertDialog(
              title: const Text("Comments"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loadingComments)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    else if (comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "No comments yet",
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => const Divider(height: 12),
                          itemBuilder: (context, i) {
                            final c = comments[i];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (c.isMine)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          final res = await ApiService
                                              .deleteInnerCircleComment(
                                            token!,
                                            c.id,
                                          );
                                          if (res != null &&
                                              res["status"] == true) {
                                            comments.removeAt(i);
                                            setState(() {
                                              final idx = posts.indexWhere(
                                                (p) => p.id == post.id,
                                              );
                                              if (idx >= 0) {
                                                posts[idx] = posts[idx].copyWith(
                                                  comments: comments.length,
                                                );
                                              }
                                            });
                                            setDialogState(() {});
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.comment),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: "Add a comment",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          setDialogState(() => saving = true);

                          final res = await ApiService.addInnerCircleComment(
                            token!,
                            post.id,
                            comment: text,
                          );

                          if (res != null && res["status"] == true) {
                            controller.clear();
                            final refreshed =
                                await ApiService.getInnerCircleComments(
                              token!,
                              post.id,
                            );
                            if (refreshed != null &&
                                refreshed["status"] == true &&
                                refreshed["data"] is List) {
                              comments = (refreshed["data"] as List)
                                  .whereType<Map>()
                                  .map((e) => InnerCircleComment.fromJson(e))
                                  .toList();
                            }

                            setState(() {
                              final idx = posts.indexWhere((p) => p.id == post.id);
                              if (idx >= 0) {
                                posts[idx] = posts[idx].copyWith(
                                  comments: comments.length,
                                );
                              }
                            });
                          }

                          setDialogState(() => saving = false);
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Post"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadShareImages() async {
    if (token == null || userId == null) return [];
    final res = await ApiService.getImages(token!, userId!);
    if (res != null && res["status"] == true && res["data"] is List) {
      return List<Map<String, dynamic>>.from(res["data"]);
    }
    return [];
  }

  Future<void> _showShareDialog() async {
    final captionController = TextEditingController();
    String? selectedImageId;
    bool saving = false;
    bool loadingImages = true;
    List<Map<String, dynamic>> images = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadIfNeeded() async {
              if (!loadingImages) return;
              images = await _loadShareImages();
              if (images.isNotEmpty) {
                selectedImageId = images.first["id"].toString();
              }
              setDialogState(() => loadingImages = false);
            }

            loadIfNeeded();

            return AlertDialog(
              title: const Text("Share outfit"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: captionController,
                      decoration: const InputDecoration(
                        labelText: "Caption",
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (loadingImages)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    else if (images.isEmpty)
                      const Text("No wardrobe images yet")
                    else
                      DropdownButtonFormField<String>(
                        initialValue: selectedImageId,
                        items: images.map((img) {
                          return DropdownMenuItem<String>(
                            value: img["id"].toString(),
                            child: Text(
                              (img["image_name"] ?? "Outfit").toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setDialogState(() => selectedImageId = value),
                        decoration: const InputDecoration(
                          labelText: "Select outfit",
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (token == null || userId == null) return;
                          setDialogState(() => saving = true);

                          final res = await ApiService.createInnerCirclePost(
                            token!,
                            userId: userId!,
                            caption: captionController.text.trim(),
                            imageId: selectedImageId,
                          );

                          setDialogState(() => saving = false);

                          if (res != null && res["status"] == true) {
                            if (!mounted) return;
                            Navigator.pop(context);
                            await _fetchPosts();
                          } else {
                            if (!mounted) return;
                            final msg = res != null && res["message"] != null
                                ? res["message"].toString()
                                : "Failed to share outfit";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Share"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inner Circle"),
        actions: [
          IconButton(
            onPressed: _showInviteDialog,
            icon: const Icon(Icons.person_add_alt),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InviteCard(
            onCopy: _copyInviteLink,
            onJoin: _openJoinPage,
            loading: loadingInvite,
            link: inviteLink,
          ),
          const SizedBox(height: 16),
          Text("Shared Outfits", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (posts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "No shared outfits yet",
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            for (final post in posts)
              _PostCard(
                name: post.name,
                caption: post.caption,
                likes: post.likes,
                comments: post.comments,
                likedByMe: post.likedByMe,
                imageUrl: post.imageUrl,
                onLike: () => _toggleLike(post),
                onComments: () => _showCommentsDialog(post),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "inner_circle_share_fab",
        onPressed: _showShareDialog,
        backgroundColor: AppTheme.plum,
        icon: const Icon(Icons.share),
        label: const Text("Share outfit"),
      ),
    );
  }
}

class InnerCirclePost {
  const InnerCirclePost({
    required this.id,
    required this.name,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.likedByMe,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String caption;
  final int likes;
  final int comments;
  final bool likedByMe;
  final String? imageUrl;

  static InnerCirclePost fromJson(Map data) {
    final name = data["name"] ??
        data["user_name"] ??
        data["owner_name"] ??
        "Inner Circle";
    return InnerCirclePost(
      id: data["id"].toString(),
      name: name.toString(),
      caption: (data["caption"] ?? "").toString(),
      likes: int.tryParse((data["likes"] ?? data["likes_count"] ?? 0).toString()) ?? 0,
      comments:
          int.tryParse((data["comments"] ?? data["comments_count"] ?? 0).toString()) ?? 0,
      likedByMe: data["liked_by_me"] == true,
      imageUrl: ApiConfig.imageUrl(
        data["image_url"] ?? data["image"] ?? data["imageUrl"],
      ),
    );
  }

  InnerCirclePost copyWith({
    int? likes,
    int? comments,
    bool? likedByMe,
  }) {
    return InnerCirclePost(
      id: id,
      name: name,
      caption: caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      likedByMe: likedByMe ?? this.likedByMe,
      imageUrl: imageUrl,
    );
  }
}

class InnerCircleComment {
  const InnerCircleComment({
    required this.id,
    required this.name,
    required this.comment,
    required this.isMine,
  });

  final String id;
  final String name;
  final String comment;
  final bool isMine;

  static InnerCircleComment fromJson(Map data) {
    return InnerCircleComment(
      id: data["id"].toString(),
      name: (data["name"] ?? "Member").toString(),
      comment: (data["comment"] ?? "").toString(),
      isMine: data["is_mine"] == true,
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.onCopy,
    required this.onJoin,
    required this.loading,
    required this.link,
  });

  final VoidCallback onCopy;
  final VoidCallback onJoin;
  final bool loading;
  final String? link;

  @override
  Widget build(BuildContext context) {
    final subtitle = loading
        ? "Loading invite link..."
        : (link == null || link!.isEmpty)
            ? "Share read-only wardrobe access with friends and stylists."
            : link!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.mint.withOpacity(0.6),
            child: const Icon(Icons.link, color: AppTheme.plum),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Invite your circle",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: onJoin,
                    child: const Text("Join with code"),
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onCopy, child: const Text("Copy link")),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.name,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.likedByMe,
    this.imageUrl,
    this.onLike,
    this.onComments,
  });

  final String name;
  final String caption;
  final int likes;
  final int comments;
  final bool likedByMe;
  final String? imageUrl;
  final VoidCallback? onLike;
  final VoidCallback? onComments;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 18, child: Icon(Icons.person)),
              const SizedBox(width: 10),
              Text(name, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.cloud,
              borderRadius: BorderRadius.circular(16),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stack) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 40),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(Icons.checkroom, color: AppTheme.plum, size: 48),
                  ),
          ),
          const SizedBox(height: 10),
          Text(caption, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                likedByMe ? Icons.favorite : Icons.favorite_border,
                color: AppTheme.coral,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text("$likes"),
              const SizedBox(width: 16),
              IconButton(
                onPressed: onComments,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Text("$comments"),
              const Spacer(),
              IconButton(
                onPressed: onLike,
                icon: Icon(
                  likedByMe ? Icons.favorite : Icons.emoji_emotions_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
