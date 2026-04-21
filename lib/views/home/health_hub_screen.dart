import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import '../../models/health_article.dart';

class HealthHubScreen extends StatelessWidget {
  const HealthHubScreen({super.key});

  // Get articles by category
  List<HealthArticle> _getArticlesByCategory(String category) {
    return healthArticles.where((article) => article.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Fitness', 'Nutrition', 'Hydration', 'Sleep', 'Weight'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Hub'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Health Articles',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((category) {
            final articles = _getArticlesByCategory(category);
            return Column(
              children: [
                _buildCategoryHeader(category),
                const SizedBox(height: 8),
                ...articles.map((article) =>
                    _buildArticleCard(context, article)),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String category) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, HealthArticle article) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                _showYouTubeLink(context, article);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Watch Video',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showYouTubeLink(BuildContext context, HealthArticle article) async {
    try {
      // Validate and format URL
      if (article.youtubeUrl.isEmpty) {
        developer.log('[HealthHub] INVALID URL: Empty');
        if (context.mounted) {
          _showLaunchErrorDialog(context, article);
        }
        return;
      }

      // Convert youtu.be URLs to youtube.com format for better compatibility
      var urlToLaunch = article.youtubeUrl;
      if (urlToLaunch.contains('youtu.be/')) {
        // Extract video ID from youtu.be/xxxxx format
        final videoId = urlToLaunch.split('youtu.be/').last.split('?').first;
        urlToLaunch = 'https://www.youtube.com/watch?v=$videoId';
        developer.log('[HealthHub] Converted youtu.be URL to: $urlToLaunch');
      }

      developer.log('[HealthHub] [URL] Launching: $urlToLaunch');
      final Uri url = Uri.parse(urlToLaunch);
      
      // Attempt to launch directly without canLaunchUrl check
      // canLaunchUrl is unreliable on Android and often returns false incorrectly
      try {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        developer.log('[HealthHub] [SUCCESS] URL launched successfully');
      } catch (launchError) {
        developer.log('[HealthHub] [FAIL] Launch error: $launchError', error: launchError);
        if (context.mounted) {
          _showLaunchErrorDialog(context, article);
        }
      }
    } catch (e) {
      developer.log('[HealthHub] [ERROR] Unexpected exception: $e', error: e);
      if (context.mounted) {
        _showLaunchErrorDialog(context, article);
      }
    }
  }

  // Fallback dialog if URL launch fails
  void _showLaunchErrorDialog(BuildContext context, HealthArticle article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Could Not Open Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Please open this link manually:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                article.youtubeUrl,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
