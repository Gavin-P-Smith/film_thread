import 'dart:collection';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tmdb_service.dart';

class PathStep {
  final String actorName;
  final int actorId;
  final String? mediaTitle;
  final int? mediaId;
  final bool isTV;

  PathStep({
    required this.actorName,
    required this.actorId,
    this.mediaTitle,
    this.mediaId,
    this.isTV = false,
  });
}

class BaconService {
  static const int kevinBaconId = 4724;
  static const int maxDepth = 6;

  static final Map<int, List<dynamic>> _creditCache = {};
  static final Map<String, List<dynamic>> _castCache = {};

  static Future<List<PathStep>> findConnection(int startActorId, String startActorName) async {
    final visited = <int>{};
    final queue = Queue<List<PathStep>>();

    queue.add([PathStep(actorName: startActorName, actorId: startActorId)]);

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final last = path.last;

      if (last.actorId == kevinBaconId) return path;
      if (path.length > maxDepth * 2) continue; // each step is actor+media

      if (visited.contains(last.actorId)) continue;
      visited.add(last.actorId);

      List<dynamic> credits;
      if (_creditCache.containsKey(last.actorId)) {
        credits = _creditCache[last.actorId]!;
      } else {
        final rawCredits = await TMDbService.getCombinedCredits(last.actorId);
        credits = rawCredits.where((c) => (c['vote_count'] ?? 0) > 100).toList();
        _creditCache[last.actorId] = credits;
      }

      for (final credit in credits) {
        final isTV = credit['media_type'] == 'tv';
        final creditId = credit['id'];
        final creditTitle = isTV ? credit['name'] : credit['title'];

        final cacheKey = '${isTV ? 'tv' : 'movie'}_$creditId';
        List<dynamic> castList;
        if (_castCache.containsKey(cacheKey)) {
          castList = _castCache[cacheKey]!;
        } else {
          castList = await TMDbService.getCredits(creditId, isTV: isTV);
          castList = castList.take(10).toList();
          _castCache[cacheKey] = castList;
        }

        for (final actor in castList) {
          final coActorId = actor['id'];
          final coActorName = actor['name'];

          if (visited.contains(coActorId)) continue;

          final newPath = List<PathStep>.from(path)
            ..add(PathStep(
              actorName: creditTitle,
              actorId: last.actorId,
              mediaTitle: creditTitle,
              mediaId: creditId,
              isTV: isTV,
            ))
            ..add(PathStep(
              actorName: coActorName,
              actorId: coActorId,
            ));

          if (coActorId == kevinBaconId) {
            return newPath;
          }

          queue.add(newPath);
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return [];
  }
}
