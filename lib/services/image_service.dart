import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Resolves descriptive image strings (from Claude) into real image URLs.
///
/// If an Unsplash API key is provided, searches Unsplash first.
/// Falls back to a curated map of NYC-relevant category → Unsplash photo URLs.
class ImageService {
  final String? _unsplashKey;

  /// Simple in-memory cache so we don't re-resolve the same descriptor.
  final Map<String, String> _cache = {};

  /// Pass [unsplashAccessKey] directly, or leave null to read from .env.
  ImageService({String? unsplashAccessKey})
      : _unsplashKey = unsplashAccessKey ??
            dotenv.maybeGet('UNSPLASH_ACCESS_KEY');

  /// Resolves a descriptor like `"chinatown_dumpling_shop"` into a real URL.
  Future<String> resolve(String descriptor) async {
    if (descriptor.startsWith('http')) return descriptor;

    if (_cache.containsKey(descriptor)) return _cache[descriptor]!;

    // Try Unsplash API if key is available
    if (_unsplashKey != null && _unsplashKey!.isNotEmpty) {
      final url = await _searchUnsplash(descriptor);
      if (url != null) {
        _cache[descriptor] = url;
        return url;
      }
    }

    // Fall back to curated map
    final url = _matchFallback(descriptor);
    _cache[descriptor] = url;
    return url;
  }

  /// Batch-resolve a list of descriptors.
  Future<List<String>> resolveAll(List<String> descriptors) {
    return Future.wait(descriptors.map(resolve));
  }

  // ---------------------------------------------------------------------------
  // Unsplash API search
  // ---------------------------------------------------------------------------

  Future<String?> _searchUnsplash(String query) async {
    try {
      final searchQuery = query.replaceAll('_', ' ');
      final uri = Uri.https('api.unsplash.com', '/search/photos', {
        'query': searchQuery,
        'per_page': '1',
        'orientation': 'landscape',
      });

      final resp = await http.get(uri, headers: {
        'Authorization': 'Client-ID $_unsplashKey',
      }).timeout(const Duration(seconds: 5));

      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      return results[0]['urls']['small'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Fallback matching
  // ---------------------------------------------------------------------------

  String _matchFallback(String descriptor) {
    final tokens = descriptor.toLowerCase().split(RegExp(r'[_\s\-]+'));
    // First pass: prefer specific nouns over generic vibe words
    for (final token in tokens) {
      if (_fallbacks.containsKey(token) && !_vibeTokens.contains(token)) {
        return _fallbacks[token]!;
      }
    }
    // Second pass: accept vibe words
    for (final token in tokens) {
      if (_fallbacks.containsKey(token)) return _fallbacks[token]!;
    }
    // Try substring matching for compound words (e.g. "bookshop" matches "book")
    for (final key in _fallbacks.keys) {
      for (final token in tokens) {
        if (token.contains(key) || key.contains(token)) {
          return _fallbacks[key]!;
        }
      }
    }
    return _fallbacks['nyc']!;
  }

  /// Generic vibe words — deprioritized so more specific tokens match first.
  /// e.g. "outdoor food market vendors" should match 'market' not 'outdoor'.
  static const _vibeTokens = {
    'outdoor', 'casual', 'cozy', 'trendy', 'lively', 'quiet',
    'fancy', 'upscale', 'romantic', 'food', 'urban', 'scenic',
    'active', 'chill', 'iconic', 'intimate', 'artsy', 'classic',
    'cultural', 'adventurous', 'quick', 'elegant', 'peaceful',
    'warm', 'moody',
  };

  // ---------------------------------------------------------------------------
  // Curated fallback images (Unsplash direct URLs — no key needed)
  // ---------------------------------------------------------------------------

  static const _fallbacks = <String, String>{
    // Breakfast / brunch
    'breakfast':
        'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=400&fit=crop',
    'brunch':
        'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400&fit=crop',
    'bagel':
        'https://images.unsplash.com/photo-1585535838516-e782edba3fd7?w=400&fit=crop',
    'coffee':
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&fit=crop',
    'pastry':
        'https://images.unsplash.com/photo-1517433367941-f210f9c2de21?w=400&fit=crop',
    'cafe':
        'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&fit=crop',
    'pancake':
        'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400&fit=crop',
    'donut':
        'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=400&fit=crop',
    'bakery':
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&fit=crop',
    'flatbread':
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&fit=crop',

    // Lunch / dinner
    'ramen':
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&fit=crop',
    'pizza':
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&fit=crop',
    'sushi':
        'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400&fit=crop',
    'dumpling':
        'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=400&fit=crop',
    'taco':
        'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&fit=crop',
    'burger':
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&fit=crop',
    'pasta':
        'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=400&fit=crop',
    'seafood':
        'https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=400&fit=crop',
    'steak':
        'https://images.unsplash.com/photo-1600891964092-4316c288032e?w=400&fit=crop',
    'dim':
        'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400&fit=crop',
    'sandwich':
        'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&fit=crop',
    'salad':
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&fit=crop',
    'thai':
        'https://images.unsplash.com/photo-1562565652-a0d8f0c59eb4?w=400&fit=crop',
    'indian':
        'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&fit=crop',
    'mexican':
        'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&fit=crop',
    'chinese':
        'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400&fit=crop',
    'italian':
        'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=400&fit=crop',
    'korean':
        'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400&fit=crop',
    'deli':
        'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&fit=crop',
    'bbq':
        'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=400&fit=crop',
    'brisket':
        'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=400&fit=crop',
    'oyster':
        'https://images.unsplash.com/photo-1606859191214-25572e874943?w=400&fit=crop',
    'yakitori':
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&fit=crop',
    'skewer':
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&fit=crop',
    'cocktail':
        'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400&fit=crop',
    'dining':
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&fit=crop',
    'mole':
        'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&fit=crop',
    'fish':
        'https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=400&fit=crop',

    // Activities — urban-appropriate images
    'museum':
        'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=400&fit=crop',
    'park':
        'https://images.unsplash.com/photo-1697122235851-1f65dac50d9a?w=400&fit=crop',
    'gallery':
        'https://images.unsplash.com/photo-1578301978693-85fa9c0320b9?w=400&fit=crop',
    'shopping':
        'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400&fit=crop',
    'walk':
        'https://images.unsplash.com/photo-1563506555774-45a862b5f91b?w=400&fit=crop',
    'rooftop':
        'https://images.unsplash.com/photo-1566836296711-5b9043c76769?w=400&fit=crop',
    'bar':
        'https://images.unsplash.com/photo-1543007630-9710e4a00a20?w=400&fit=crop',
    'broadway':
        'https://images.unsplash.com/photo-1503095396549-807759245b35?w=400&fit=crop',
    'comedy':
        'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?w=400&fit=crop',
    'bookstore':
        'https://images.unsplash.com/photo-1526243741027-444d633d7365?w=400&fit=crop',
    'market':
        'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?w=400&fit=crop',
    'bridge':
        'https://images.unsplash.com/photo-1496588152823-86ff7695e68f?w=400&fit=crop',
    'concert':
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&fit=crop',
    'theater':
        'https://images.unsplash.com/photo-1503095396549-807759245b35?w=400&fit=crop',
    'sport':
        'https://images.unsplash.com/photo-1461896836934-bd45ba7b5494?w=400&fit=crop',

    // Urban places & Brooklyn-specific categories
    'waterfront':
        'https://images.unsplash.com/photo-1615067738929-1cc876672258?w=400&fit=crop',
    'flea':
        'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?w=400&fit=crop',
    'industrial':
        'https://images.unsplash.com/photo-1508162397467-82d021dfee45?w=400&fit=crop',
    'warehouse':
        'https://images.unsplash.com/photo-1508162397467-82d021dfee45?w=400&fit=crop',
    'brownstone':
        'https://images.unsplash.com/photo-1563506555774-45a862b5f91b?w=400&fit=crop',
    'garden':
        'https://images.unsplash.com/photo-1561730328-725eda77668e?w=400&fit=crop',
    'botanical':
        'https://images.unsplash.com/photo-1561730328-725eda77668e?w=400&fit=crop',
    'cherry':
        'https://images.unsplash.com/photo-1561730328-725eda77668e?w=400&fit=crop',
    'cemetery':
        'https://images.unsplash.com/photo-1509128841709-611b4aca1ee0?w=400&fit=crop',
    'boardwalk':
        'https://images.unsplash.com/photo-1623766647719-9972b994e598?w=400&fit=crop',
    'carousel':
        'https://images.unsplash.com/photo-1568652377458-72a9e0e27a64?w=400&fit=crop',
    'promenade':
        'https://images.unsplash.com/photo-1615067738929-1cc876672258?w=400&fit=crop',
    'pier':
        'https://images.unsplash.com/photo-1615067738929-1cc876672258?w=400&fit=crop',
    'cobblestone':
        'https://images.unsplash.com/photo-1563506555774-45a862b5f91b?w=400&fit=crop',
    'vendors':
        'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?w=400&fit=crop',
    'forest':
        'https://images.unsplash.com/photo-1697122235851-1f65dac50d9a?w=400&fit=crop',
    'lake':
        'https://images.unsplash.com/photo-1697122235851-1f65dac50d9a?w=400&fit=crop',
    'trail':
        'https://images.unsplash.com/photo-1697122235851-1f65dac50d9a?w=400&fit=crop',
    'library':
        'https://images.unsplash.com/photo-1526243741027-444d633d7365?w=400&fit=crop',
    'neon':
        'https://images.unsplash.com/photo-1543007630-9710e4a00a20?w=400&fit=crop',

    // Vibes / generic
    'cozy':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&fit=crop',
    'upscale':
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&fit=crop',
    'casual':
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&fit=crop',
    'outdoor':
        'https://images.unsplash.com/photo-1697122235851-1f65dac50d9a?w=400&fit=crop',
    'trendy':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&fit=crop',
    'romantic':
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&fit=crop',
    'lively':
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&fit=crop',
    'quiet':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&fit=crop',
    'fancy':
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&fit=crop',
    'restaurant':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&fit=crop',
    'food':
        'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=400&fit=crop',

    // Default — brownstone street scene
    'nyc':
        'https://images.unsplash.com/photo-1563506555774-45a862b5f91b?w=400&fit=crop',
  };
}
