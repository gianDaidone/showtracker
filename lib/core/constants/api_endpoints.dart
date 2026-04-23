abstract class TmdbEndpoints {
  static const _base = 'https://api.themoviedb.org/3';
  static const _imageBase = 'https://image.tmdb.org/t/p';

  static Uri search(String query, {String type = 'multi'}) =>
      Uri.parse('$_base/search/$type').replace(queryParameters: {'query': query});

  static Uri tvDetails(int id) => Uri.parse('$_base/tv/$id');
  static Uri tvSeason(int id, int season) => Uri.parse('$_base/tv/$id/season/$season');
  static Uri movieDetails(int id) => Uri.parse('$_base/movie/$id');

  static String poster(String path, {String size = 'w342'}) =>
      '$_imageBase/$size$path';
}

abstract class RawgEndpoints {
  static const _base = 'https://api.rawg.io/api';

  static Uri search(String query) =>
      Uri.parse('$_base/games').replace(queryParameters: {'search': query});

  static Uri gameDetails(int id) => Uri.parse('$_base/games/$id');
}

