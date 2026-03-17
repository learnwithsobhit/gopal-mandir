import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ApiService _api = ApiService();
  String _selectedCategory = 'All';
  List<GalleryItem> _items = [];
  bool _loading = true;
  final Map<int, int> _likeCounts = {};
  final Map<int, int> _commentCounts = {};

  List<String> get _categories {
    final set = <String>{'All'};
    for (final item in _items) {
      set.add(item.category);
    }
    return set.toList();
  }

  List<GalleryItem> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items.where((i) => i.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _api.getGallery();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('चित्र गैलरी'),
        backgroundColor: AppColors.krishnaBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.krishnaBlue))
          : Column(
        children: [
          // Category filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.krishnaBlue : AppColors.softWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.krishnaBlue
                              : AppColors.krishnaBlue.withAlpha(30),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return GestureDetector(
                  onTap: () => _showFullImage(context, item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.softWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.krishnaBlue.withAlpha(12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              item.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.krishnaBlue,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_not_supported, color: AppColors.warmGrey),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.category,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: AppColors.krishnaBlue,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.favorite, size: 18, color: AppColors.urgentRed),
                                    onPressed: () => _likeGallery(item.id),
                                  ),
                                  Text(
                                    '${_likeCounts[item.id] ?? 0}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.warmGrey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.krishnaBlue),
                                    onPressed: () => _showCommentsSheet(context, item),
                                  ),
                                  Text(
                                    '${_commentCounts[item.id] ?? 0}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.warmGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, GalleryItem item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                item.imageUrl,
                fit: BoxFit.contain,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withAlpha(120),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(150)],
                    ),
                  ),
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _likeGallery(int id) async {
    setState(() {
      _likeCounts[id] = (_likeCounts[id] ?? 0) + 1;
    });
    await _api.likeGallery(id);
  }

  Future<void> _showCommentsSheet(BuildContext context, GalleryItem item) async {
    List<GalleryComment> comments = await _api.getGalleryComments(item.id);
    _commentCounts[item.id] = comments.length;

    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comments for ${item.title}',
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 240,
                    child: comments.isEmpty
                        ? const Center(
                            child: Text(
                              'No comments yet. Be the first!',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.warmGrey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final c = comments[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  c.comment,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.warmGrey,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final text = commentCtrl.text.trim();
                        if (name.isEmpty || text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter name and comment'),
                              backgroundColor: AppColors.urgentRed,
                            ),
                          );
                          return;
                        }
                        final ok = await _api.addGalleryComment(
                          item.id,
                          NewCommentRequest(name: name, comment: text),
                        );
                        if (!ok) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add comment'),
                              backgroundColor: AppColors.urgentRed,
                            ),
                          );
                          return;
                        }
                        comments = await _api.getGalleryComments(item.id);
                        setModalState(() {});
                        setState(() {
                          _commentCounts[item.id] = comments.length;
                        });
                        nameCtrl.clear();
                        commentCtrl.clear();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.krishnaBlue,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Post Comment'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
