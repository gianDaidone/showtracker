// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TrackedShowsTable extends TrackedShows
    with TableInfo<$TrackedShowsTable, TrackedShow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackedShowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
      'tmdb_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _overviewMeta =
      const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
      'overview', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _posterPathMeta =
      const VerificationMeta('posterPath');
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
      'poster_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<MediaStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MediaStatus>($TrackedShowsTable.$converterstatus);
  static const VerificationMeta _userRatingMeta =
      const VerificationMeta('userRating');
  @override
  late final GeneratedColumn<double> userRating = GeneratedColumn<double>(
      'user_rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _userNotesMeta =
      const VerificationMeta('userNotes');
  @override
  late final GeneratedColumn<String> userNotes = GeneratedColumn<String>(
      'user_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalSeasonsMeta =
      const VerificationMeta('totalSeasons');
  @override
  late final GeneratedColumn<int> totalSeasons = GeneratedColumn<int>(
      'total_seasons', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalEpisodesMeta =
      const VerificationMeta('totalEpisodes');
  @override
  late final GeneratedColumn<int> totalEpisodes = GeneratedColumn<int>(
      'total_episodes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tmdbStatusMeta =
      const VerificationMeta('tmdbStatus');
  @override
  late final GeneratedColumn<String> tmdbStatus = GeneratedColumn<String>(
      'tmdb_status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isAnimeMeta =
      const VerificationMeta('isAnime');
  @override
  late final GeneratedColumn<bool> isAnime = GeneratedColumn<bool>(
      'is_anime', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_anime" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastWatchedAtMeta =
      const VerificationMeta('lastWatchedAt');
  @override
  late final GeneratedColumn<DateTime> lastWatchedAt =
      GeneratedColumn<DateTime>('last_watched_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextEpisodeNumberMeta =
      const VerificationMeta('nextEpisodeNumber');
  @override
  late final GeneratedColumn<int> nextEpisodeNumber = GeneratedColumn<int>(
      'next_episode_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nextEpisodeSeasonMeta =
      const VerificationMeta('nextEpisodeSeason');
  @override
  late final GeneratedColumn<int> nextEpisodeSeason = GeneratedColumn<int>(
      'next_episode_season', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nextEpisodeNameMeta =
      const VerificationMeta('nextEpisodeName');
  @override
  late final GeneratedColumn<String> nextEpisodeName = GeneratedColumn<String>(
      'next_episode_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextEpisodeAirDateMeta =
      const VerificationMeta('nextEpisodeAirDate');
  @override
  late final GeneratedColumn<DateTime> nextEpisodeAirDate =
      GeneratedColumn<DateTime>('next_episode_air_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tmdbId,
        title,
        overview,
        posterPath,
        status,
        userRating,
        userNotes,
        totalSeasons,
        totalEpisodes,
        tmdbStatus,
        isAnime,
        addedAt,
        lastWatchedAt,
        nextEpisodeNumber,
        nextEpisodeSeason,
        nextEpisodeName,
        nextEpisodeAirDate,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracked_shows';
  @override
  VerificationContext validateIntegrity(Insertable<TrackedShow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta,
          tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta,
          overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('poster_path')) {
      context.handle(
          _posterPathMeta,
          posterPath.isAcceptableOrUnknown(
              data['poster_path']!, _posterPathMeta));
    }
    if (data.containsKey('user_rating')) {
      context.handle(
          _userRatingMeta,
          userRating.isAcceptableOrUnknown(
              data['user_rating']!, _userRatingMeta));
    }
    if (data.containsKey('user_notes')) {
      context.handle(_userNotesMeta,
          userNotes.isAcceptableOrUnknown(data['user_notes']!, _userNotesMeta));
    }
    if (data.containsKey('total_seasons')) {
      context.handle(
          _totalSeasonsMeta,
          totalSeasons.isAcceptableOrUnknown(
              data['total_seasons']!, _totalSeasonsMeta));
    }
    if (data.containsKey('total_episodes')) {
      context.handle(
          _totalEpisodesMeta,
          totalEpisodes.isAcceptableOrUnknown(
              data['total_episodes']!, _totalEpisodesMeta));
    }
    if (data.containsKey('tmdb_status')) {
      context.handle(
          _tmdbStatusMeta,
          tmdbStatus.isAcceptableOrUnknown(
              data['tmdb_status']!, _tmdbStatusMeta));
    }
    if (data.containsKey('is_anime')) {
      context.handle(_isAnimeMeta,
          isAnime.isAcceptableOrUnknown(data['is_anime']!, _isAnimeMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
          _lastWatchedAtMeta,
          lastWatchedAt.isAcceptableOrUnknown(
              data['last_watched_at']!, _lastWatchedAtMeta));
    }
    if (data.containsKey('next_episode_number')) {
      context.handle(
          _nextEpisodeNumberMeta,
          nextEpisodeNumber.isAcceptableOrUnknown(
              data['next_episode_number']!, _nextEpisodeNumberMeta));
    }
    if (data.containsKey('next_episode_season')) {
      context.handle(
          _nextEpisodeSeasonMeta,
          nextEpisodeSeason.isAcceptableOrUnknown(
              data['next_episode_season']!, _nextEpisodeSeasonMeta));
    }
    if (data.containsKey('next_episode_name')) {
      context.handle(
          _nextEpisodeNameMeta,
          nextEpisodeName.isAcceptableOrUnknown(
              data['next_episode_name']!, _nextEpisodeNameMeta));
    }
    if (data.containsKey('next_episode_air_date')) {
      context.handle(
          _nextEpisodeAirDateMeta,
          nextEpisodeAirDate.isAcceptableOrUnknown(
              data['next_episode_air_date']!, _nextEpisodeAirDateMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackedShow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackedShow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tmdbId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tmdb_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      overview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}overview']),
      posterPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_path']),
      status: $TrackedShowsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      userRating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}user_rating']),
      userNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_notes']),
      totalSeasons: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_seasons']),
      totalEpisodes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_episodes']),
      tmdbStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tmdb_status']),
      isAnime: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_anime'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      lastWatchedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_watched_at']),
      nextEpisodeNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}next_episode_number']),
      nextEpisodeSeason: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}next_episode_season']),
      nextEpisodeName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}next_episode_name']),
      nextEpisodeAirDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}next_episode_air_date']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $TrackedShowsTable createAlias(String alias) {
    return $TrackedShowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaStatus, String, String> $converterstatus =
      const EnumNameConverter<MediaStatus>(MediaStatus.values);
}

class TrackedShow extends DataClass implements Insertable<TrackedShow> {
  final int id;
  final int tmdbId;
  final String title;
  final String? overview;
  final String? posterPath;
  final MediaStatus status;
  final double? userRating;
  final String? userNotes;
  final int? totalSeasons;
  final int? totalEpisodes;

  /// Stato TMDB della serie: "Returning Series", "Ended", "Canceled", ecc.
  /// Usato per calcolare il TTL della cache episodi in modo intelligente.
  final String? tmdbStatus;
  final bool isAnime;
  final DateTime addedAt;
  final DateTime? lastWatchedAt;
  final int? nextEpisodeNumber;
  final int? nextEpisodeSeason;
  final String? nextEpisodeName;
  final DateTime? nextEpisodeAirDate;
  final DateTime? updatedAt;
  const TrackedShow(
      {required this.id,
      required this.tmdbId,
      required this.title,
      this.overview,
      this.posterPath,
      required this.status,
      this.userRating,
      this.userNotes,
      this.totalSeasons,
      this.totalEpisodes,
      this.tmdbStatus,
      required this.isAnime,
      required this.addedAt,
      this.lastWatchedAt,
      this.nextEpisodeNumber,
      this.nextEpisodeSeason,
      this.nextEpisodeName,
      this.nextEpisodeAirDate,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    {
      map['status'] =
          Variable<String>($TrackedShowsTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || userRating != null) {
      map['user_rating'] = Variable<double>(userRating);
    }
    if (!nullToAbsent || userNotes != null) {
      map['user_notes'] = Variable<String>(userNotes);
    }
    if (!nullToAbsent || totalSeasons != null) {
      map['total_seasons'] = Variable<int>(totalSeasons);
    }
    if (!nullToAbsent || totalEpisodes != null) {
      map['total_episodes'] = Variable<int>(totalEpisodes);
    }
    if (!nullToAbsent || tmdbStatus != null) {
      map['tmdb_status'] = Variable<String>(tmdbStatus);
    }
    map['is_anime'] = Variable<bool>(isAnime);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || lastWatchedAt != null) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt);
    }
    if (!nullToAbsent || nextEpisodeNumber != null) {
      map['next_episode_number'] = Variable<int>(nextEpisodeNumber);
    }
    if (!nullToAbsent || nextEpisodeSeason != null) {
      map['next_episode_season'] = Variable<int>(nextEpisodeSeason);
    }
    if (!nullToAbsent || nextEpisodeName != null) {
      map['next_episode_name'] = Variable<String>(nextEpisodeName);
    }
    if (!nullToAbsent || nextEpisodeAirDate != null) {
      map['next_episode_air_date'] = Variable<DateTime>(nextEpisodeAirDate);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  TrackedShowsCompanion toCompanion(bool nullToAbsent) {
    return TrackedShowsCompanion(
      id: Value(id),
      tmdbId: Value(tmdbId),
      title: Value(title),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      status: Value(status),
      userRating: userRating == null && nullToAbsent
          ? const Value.absent()
          : Value(userRating),
      userNotes: userNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(userNotes),
      totalSeasons: totalSeasons == null && nullToAbsent
          ? const Value.absent()
          : Value(totalSeasons),
      totalEpisodes: totalEpisodes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalEpisodes),
      tmdbStatus: tmdbStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbStatus),
      isAnime: Value(isAnime),
      addedAt: Value(addedAt),
      lastWatchedAt: lastWatchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWatchedAt),
      nextEpisodeNumber: nextEpisodeNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(nextEpisodeNumber),
      nextEpisodeSeason: nextEpisodeSeason == null && nullToAbsent
          ? const Value.absent()
          : Value(nextEpisodeSeason),
      nextEpisodeName: nextEpisodeName == null && nullToAbsent
          ? const Value.absent()
          : Value(nextEpisodeName),
      nextEpisodeAirDate: nextEpisodeAirDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextEpisodeAirDate),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory TrackedShow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackedShow(
      id: serializer.fromJson<int>(json['id']),
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      title: serializer.fromJson<String>(json['title']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      status: $TrackedShowsTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
      userRating: serializer.fromJson<double?>(json['userRating']),
      userNotes: serializer.fromJson<String?>(json['userNotes']),
      totalSeasons: serializer.fromJson<int?>(json['totalSeasons']),
      totalEpisodes: serializer.fromJson<int?>(json['totalEpisodes']),
      tmdbStatus: serializer.fromJson<String?>(json['tmdbStatus']),
      isAnime: serializer.fromJson<bool>(json['isAnime']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastWatchedAt: serializer.fromJson<DateTime?>(json['lastWatchedAt']),
      nextEpisodeNumber: serializer.fromJson<int?>(json['nextEpisodeNumber']),
      nextEpisodeSeason: serializer.fromJson<int?>(json['nextEpisodeSeason']),
      nextEpisodeName: serializer.fromJson<String?>(json['nextEpisodeName']),
      nextEpisodeAirDate:
          serializer.fromJson<DateTime?>(json['nextEpisodeAirDate']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tmdbId': serializer.toJson<int>(tmdbId),
      'title': serializer.toJson<String>(title),
      'overview': serializer.toJson<String?>(overview),
      'posterPath': serializer.toJson<String?>(posterPath),
      'status': serializer
          .toJson<String>($TrackedShowsTable.$converterstatus.toJson(status)),
      'userRating': serializer.toJson<double?>(userRating),
      'userNotes': serializer.toJson<String?>(userNotes),
      'totalSeasons': serializer.toJson<int?>(totalSeasons),
      'totalEpisodes': serializer.toJson<int?>(totalEpisodes),
      'tmdbStatus': serializer.toJson<String?>(tmdbStatus),
      'isAnime': serializer.toJson<bool>(isAnime),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastWatchedAt': serializer.toJson<DateTime?>(lastWatchedAt),
      'nextEpisodeNumber': serializer.toJson<int?>(nextEpisodeNumber),
      'nextEpisodeSeason': serializer.toJson<int?>(nextEpisodeSeason),
      'nextEpisodeName': serializer.toJson<String?>(nextEpisodeName),
      'nextEpisodeAirDate': serializer.toJson<DateTime?>(nextEpisodeAirDate),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  TrackedShow copyWith(
          {int? id,
          int? tmdbId,
          String? title,
          Value<String?> overview = const Value.absent(),
          Value<String?> posterPath = const Value.absent(),
          MediaStatus? status,
          Value<double?> userRating = const Value.absent(),
          Value<String?> userNotes = const Value.absent(),
          Value<int?> totalSeasons = const Value.absent(),
          Value<int?> totalEpisodes = const Value.absent(),
          Value<String?> tmdbStatus = const Value.absent(),
          bool? isAnime,
          DateTime? addedAt,
          Value<DateTime?> lastWatchedAt = const Value.absent(),
          Value<int?> nextEpisodeNumber = const Value.absent(),
          Value<int?> nextEpisodeSeason = const Value.absent(),
          Value<String?> nextEpisodeName = const Value.absent(),
          Value<DateTime?> nextEpisodeAirDate = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      TrackedShow(
        id: id ?? this.id,
        tmdbId: tmdbId ?? this.tmdbId,
        title: title ?? this.title,
        overview: overview.present ? overview.value : this.overview,
        posterPath: posterPath.present ? posterPath.value : this.posterPath,
        status: status ?? this.status,
        userRating: userRating.present ? userRating.value : this.userRating,
        userNotes: userNotes.present ? userNotes.value : this.userNotes,
        totalSeasons:
            totalSeasons.present ? totalSeasons.value : this.totalSeasons,
        totalEpisodes:
            totalEpisodes.present ? totalEpisodes.value : this.totalEpisodes,
        tmdbStatus: tmdbStatus.present ? tmdbStatus.value : this.tmdbStatus,
        isAnime: isAnime ?? this.isAnime,
        addedAt: addedAt ?? this.addedAt,
        lastWatchedAt:
            lastWatchedAt.present ? lastWatchedAt.value : this.lastWatchedAt,
        nextEpisodeNumber: nextEpisodeNumber.present
            ? nextEpisodeNumber.value
            : this.nextEpisodeNumber,
        nextEpisodeSeason: nextEpisodeSeason.present
            ? nextEpisodeSeason.value
            : this.nextEpisodeSeason,
        nextEpisodeName: nextEpisodeName.present
            ? nextEpisodeName.value
            : this.nextEpisodeName,
        nextEpisodeAirDate: nextEpisodeAirDate.present
            ? nextEpisodeAirDate.value
            : this.nextEpisodeAirDate,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  TrackedShow copyWithCompanion(TrackedShowsCompanion data) {
    return TrackedShow(
      id: data.id.present ? data.id.value : this.id,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      title: data.title.present ? data.title.value : this.title,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterPath:
          data.posterPath.present ? data.posterPath.value : this.posterPath,
      status: data.status.present ? data.status.value : this.status,
      userRating:
          data.userRating.present ? data.userRating.value : this.userRating,
      userNotes: data.userNotes.present ? data.userNotes.value : this.userNotes,
      totalSeasons: data.totalSeasons.present
          ? data.totalSeasons.value
          : this.totalSeasons,
      totalEpisodes: data.totalEpisodes.present
          ? data.totalEpisodes.value
          : this.totalEpisodes,
      tmdbStatus:
          data.tmdbStatus.present ? data.tmdbStatus.value : this.tmdbStatus,
      isAnime: data.isAnime.present ? data.isAnime.value : this.isAnime,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastWatchedAt: data.lastWatchedAt.present
          ? data.lastWatchedAt.value
          : this.lastWatchedAt,
      nextEpisodeNumber: data.nextEpisodeNumber.present
          ? data.nextEpisodeNumber.value
          : this.nextEpisodeNumber,
      nextEpisodeSeason: data.nextEpisodeSeason.present
          ? data.nextEpisodeSeason.value
          : this.nextEpisodeSeason,
      nextEpisodeName: data.nextEpisodeName.present
          ? data.nextEpisodeName.value
          : this.nextEpisodeName,
      nextEpisodeAirDate: data.nextEpisodeAirDate.present
          ? data.nextEpisodeAirDate.value
          : this.nextEpisodeAirDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackedShow(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('status: $status, ')
          ..write('userRating: $userRating, ')
          ..write('userNotes: $userNotes, ')
          ..write('totalSeasons: $totalSeasons, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('tmdbStatus: $tmdbStatus, ')
          ..write('isAnime: $isAnime, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('nextEpisodeNumber: $nextEpisodeNumber, ')
          ..write('nextEpisodeSeason: $nextEpisodeSeason, ')
          ..write('nextEpisodeName: $nextEpisodeName, ')
          ..write('nextEpisodeAirDate: $nextEpisodeAirDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tmdbId,
      title,
      overview,
      posterPath,
      status,
      userRating,
      userNotes,
      totalSeasons,
      totalEpisodes,
      tmdbStatus,
      isAnime,
      addedAt,
      lastWatchedAt,
      nextEpisodeNumber,
      nextEpisodeSeason,
      nextEpisodeName,
      nextEpisodeAirDate,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackedShow &&
          other.id == this.id &&
          other.tmdbId == this.tmdbId &&
          other.title == this.title &&
          other.overview == this.overview &&
          other.posterPath == this.posterPath &&
          other.status == this.status &&
          other.userRating == this.userRating &&
          other.userNotes == this.userNotes &&
          other.totalSeasons == this.totalSeasons &&
          other.totalEpisodes == this.totalEpisodes &&
          other.tmdbStatus == this.tmdbStatus &&
          other.isAnime == this.isAnime &&
          other.addedAt == this.addedAt &&
          other.lastWatchedAt == this.lastWatchedAt &&
          other.nextEpisodeNumber == this.nextEpisodeNumber &&
          other.nextEpisodeSeason == this.nextEpisodeSeason &&
          other.nextEpisodeName == this.nextEpisodeName &&
          other.nextEpisodeAirDate == this.nextEpisodeAirDate &&
          other.updatedAt == this.updatedAt);
}

class TrackedShowsCompanion extends UpdateCompanion<TrackedShow> {
  final Value<int> id;
  final Value<int> tmdbId;
  final Value<String> title;
  final Value<String?> overview;
  final Value<String?> posterPath;
  final Value<MediaStatus> status;
  final Value<double?> userRating;
  final Value<String?> userNotes;
  final Value<int?> totalSeasons;
  final Value<int?> totalEpisodes;
  final Value<String?> tmdbStatus;
  final Value<bool> isAnime;
  final Value<DateTime> addedAt;
  final Value<DateTime?> lastWatchedAt;
  final Value<int?> nextEpisodeNumber;
  final Value<int?> nextEpisodeSeason;
  final Value<String?> nextEpisodeName;
  final Value<DateTime?> nextEpisodeAirDate;
  final Value<DateTime?> updatedAt;
  const TrackedShowsCompanion({
    this.id = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.status = const Value.absent(),
    this.userRating = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.totalSeasons = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.tmdbStatus = const Value.absent(),
    this.isAnime = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.nextEpisodeNumber = const Value.absent(),
    this.nextEpisodeSeason = const Value.absent(),
    this.nextEpisodeName = const Value.absent(),
    this.nextEpisodeAirDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TrackedShowsCompanion.insert({
    this.id = const Value.absent(),
    required int tmdbId,
    required String title,
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    required MediaStatus status,
    this.userRating = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.totalSeasons = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.tmdbStatus = const Value.absent(),
    this.isAnime = const Value.absent(),
    required DateTime addedAt,
    this.lastWatchedAt = const Value.absent(),
    this.nextEpisodeNumber = const Value.absent(),
    this.nextEpisodeSeason = const Value.absent(),
    this.nextEpisodeName = const Value.absent(),
    this.nextEpisodeAirDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : tmdbId = Value(tmdbId),
        title = Value(title),
        status = Value(status),
        addedAt = Value(addedAt);
  static Insertable<TrackedShow> custom({
    Expression<int>? id,
    Expression<int>? tmdbId,
    Expression<String>? title,
    Expression<String>? overview,
    Expression<String>? posterPath,
    Expression<String>? status,
    Expression<double>? userRating,
    Expression<String>? userNotes,
    Expression<int>? totalSeasons,
    Expression<int>? totalEpisodes,
    Expression<String>? tmdbStatus,
    Expression<bool>? isAnime,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastWatchedAt,
    Expression<int>? nextEpisodeNumber,
    Expression<int>? nextEpisodeSeason,
    Expression<String>? nextEpisodeName,
    Expression<DateTime>? nextEpisodeAirDate,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (overview != null) 'overview': overview,
      if (posterPath != null) 'poster_path': posterPath,
      if (status != null) 'status': status,
      if (userRating != null) 'user_rating': userRating,
      if (userNotes != null) 'user_notes': userNotes,
      if (totalSeasons != null) 'total_seasons': totalSeasons,
      if (totalEpisodes != null) 'total_episodes': totalEpisodes,
      if (tmdbStatus != null) 'tmdb_status': tmdbStatus,
      if (isAnime != null) 'is_anime': isAnime,
      if (addedAt != null) 'added_at': addedAt,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
      if (nextEpisodeNumber != null) 'next_episode_number': nextEpisodeNumber,
      if (nextEpisodeSeason != null) 'next_episode_season': nextEpisodeSeason,
      if (nextEpisodeName != null) 'next_episode_name': nextEpisodeName,
      if (nextEpisodeAirDate != null)
        'next_episode_air_date': nextEpisodeAirDate,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TrackedShowsCompanion copyWith(
      {Value<int>? id,
      Value<int>? tmdbId,
      Value<String>? title,
      Value<String?>? overview,
      Value<String?>? posterPath,
      Value<MediaStatus>? status,
      Value<double?>? userRating,
      Value<String?>? userNotes,
      Value<int?>? totalSeasons,
      Value<int?>? totalEpisodes,
      Value<String?>? tmdbStatus,
      Value<bool>? isAnime,
      Value<DateTime>? addedAt,
      Value<DateTime?>? lastWatchedAt,
      Value<int?>? nextEpisodeNumber,
      Value<int?>? nextEpisodeSeason,
      Value<String?>? nextEpisodeName,
      Value<DateTime?>? nextEpisodeAirDate,
      Value<DateTime?>? updatedAt}) {
    return TrackedShowsCompanion(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      status: status ?? this.status,
      userRating: userRating ?? this.userRating,
      userNotes: userNotes ?? this.userNotes,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      tmdbStatus: tmdbStatus ?? this.tmdbStatus,
      isAnime: isAnime ?? this.isAnime,
      addedAt: addedAt ?? this.addedAt,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      nextEpisodeNumber: nextEpisodeNumber ?? this.nextEpisodeNumber,
      nextEpisodeSeason: nextEpisodeSeason ?? this.nextEpisodeSeason,
      nextEpisodeName: nextEpisodeName ?? this.nextEpisodeName,
      nextEpisodeAirDate: nextEpisodeAirDate ?? this.nextEpisodeAirDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
          $TrackedShowsTable.$converterstatus.toSql(status.value));
    }
    if (userRating.present) {
      map['user_rating'] = Variable<double>(userRating.value);
    }
    if (userNotes.present) {
      map['user_notes'] = Variable<String>(userNotes.value);
    }
    if (totalSeasons.present) {
      map['total_seasons'] = Variable<int>(totalSeasons.value);
    }
    if (totalEpisodes.present) {
      map['total_episodes'] = Variable<int>(totalEpisodes.value);
    }
    if (tmdbStatus.present) {
      map['tmdb_status'] = Variable<String>(tmdbStatus.value);
    }
    if (isAnime.present) {
      map['is_anime'] = Variable<bool>(isAnime.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    if (nextEpisodeNumber.present) {
      map['next_episode_number'] = Variable<int>(nextEpisodeNumber.value);
    }
    if (nextEpisodeSeason.present) {
      map['next_episode_season'] = Variable<int>(nextEpisodeSeason.value);
    }
    if (nextEpisodeName.present) {
      map['next_episode_name'] = Variable<String>(nextEpisodeName.value);
    }
    if (nextEpisodeAirDate.present) {
      map['next_episode_air_date'] =
          Variable<DateTime>(nextEpisodeAirDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackedShowsCompanion(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('status: $status, ')
          ..write('userRating: $userRating, ')
          ..write('userNotes: $userNotes, ')
          ..write('totalSeasons: $totalSeasons, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('tmdbStatus: $tmdbStatus, ')
          ..write('isAnime: $isAnime, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('nextEpisodeNumber: $nextEpisodeNumber, ')
          ..write('nextEpisodeSeason: $nextEpisodeSeason, ')
          ..write('nextEpisodeName: $nextEpisodeName, ')
          ..write('nextEpisodeAirDate: $nextEpisodeAirDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackedEpisodesTable extends TrackedEpisodes
    with TableInfo<$TrackedEpisodesTable, TrackedEpisode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackedEpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _showIdMeta = const VerificationMeta('showId');
  @override
  late final GeneratedColumn<int> showId = GeneratedColumn<int>(
      'show_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tracked_shows (id)'));
  static const VerificationMeta _seasonNumberMeta =
      const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
      'season_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _episodeNumberMeta =
      const VerificationMeta('episodeNumber');
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
      'episode_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _watchedMeta =
      const VerificationMeta('watched');
  @override
  late final GeneratedColumn<bool> watched = GeneratedColumn<bool>(
      'watched', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("watched" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, showId, seasonNumber, episodeNumber, watched, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracked_episodes';
  @override
  VerificationContext validateIntegrity(Insertable<TrackedEpisode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('show_id')) {
      context.handle(_showIdMeta,
          showId.isAcceptableOrUnknown(data['show_id']!, _showIdMeta));
    } else if (isInserting) {
      context.missing(_showIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
          _seasonNumberMeta,
          seasonNumber.isAcceptableOrUnknown(
              data['season_number']!, _seasonNumberMeta));
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
          _episodeNumberMeta,
          episodeNumber.isAcceptableOrUnknown(
              data['episode_number']!, _episodeNumberMeta));
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('watched')) {
      context.handle(_watchedMeta,
          watched.isAcceptableOrUnknown(data['watched']!, _watchedMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {showId, seasonNumber, episodeNumber},
      ];
  @override
  TrackedEpisode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackedEpisode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      showId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}show_id'])!,
      seasonNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_number'])!,
      episodeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_number'])!,
      watched: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}watched'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $TrackedEpisodesTable createAlias(String alias) {
    return $TrackedEpisodesTable(attachedDatabase, alias);
  }
}

class TrackedEpisode extends DataClass implements Insertable<TrackedEpisode> {
  final int id;
  final int showId;
  final int seasonNumber;
  final int episodeNumber;
  final bool watched;
  final DateTime? updatedAt;
  const TrackedEpisode(
      {required this.id,
      required this.showId,
      required this.seasonNumber,
      required this.episodeNumber,
      required this.watched,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['show_id'] = Variable<int>(showId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['watched'] = Variable<bool>(watched);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  TrackedEpisodesCompanion toCompanion(bool nullToAbsent) {
    return TrackedEpisodesCompanion(
      id: Value(id),
      showId: Value(showId),
      seasonNumber: Value(seasonNumber),
      episodeNumber: Value(episodeNumber),
      watched: Value(watched),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory TrackedEpisode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackedEpisode(
      id: serializer.fromJson<int>(json['id']),
      showId: serializer.fromJson<int>(json['showId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      watched: serializer.fromJson<bool>(json['watched']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'showId': serializer.toJson<int>(showId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'watched': serializer.toJson<bool>(watched),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  TrackedEpisode copyWith(
          {int? id,
          int? showId,
          int? seasonNumber,
          int? episodeNumber,
          bool? watched,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      TrackedEpisode(
        id: id ?? this.id,
        showId: showId ?? this.showId,
        seasonNumber: seasonNumber ?? this.seasonNumber,
        episodeNumber: episodeNumber ?? this.episodeNumber,
        watched: watched ?? this.watched,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  TrackedEpisode copyWithCompanion(TrackedEpisodesCompanion data) {
    return TrackedEpisode(
      id: data.id.present ? data.id.value : this.id,
      showId: data.showId.present ? data.showId.value : this.showId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      watched: data.watched.present ? data.watched.value : this.watched,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackedEpisode(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('watched: $watched, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, showId, seasonNumber, episodeNumber, watched, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackedEpisode &&
          other.id == this.id &&
          other.showId == this.showId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.watched == this.watched &&
          other.updatedAt == this.updatedAt);
}

class TrackedEpisodesCompanion extends UpdateCompanion<TrackedEpisode> {
  final Value<int> id;
  final Value<int> showId;
  final Value<int> seasonNumber;
  final Value<int> episodeNumber;
  final Value<bool> watched;
  final Value<DateTime?> updatedAt;
  const TrackedEpisodesCompanion({
    this.id = const Value.absent(),
    this.showId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.watched = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TrackedEpisodesCompanion.insert({
    this.id = const Value.absent(),
    required int showId,
    required int seasonNumber,
    required int episodeNumber,
    this.watched = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : showId = Value(showId),
        seasonNumber = Value(seasonNumber),
        episodeNumber = Value(episodeNumber);
  static Insertable<TrackedEpisode> custom({
    Expression<int>? id,
    Expression<int>? showId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<bool>? watched,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (showId != null) 'show_id': showId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (watched != null) 'watched': watched,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TrackedEpisodesCompanion copyWith(
      {Value<int>? id,
      Value<int>? showId,
      Value<int>? seasonNumber,
      Value<int>? episodeNumber,
      Value<bool>? watched,
      Value<DateTime?>? updatedAt}) {
    return TrackedEpisodesCompanion(
      id: id ?? this.id,
      showId: showId ?? this.showId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      watched: watched ?? this.watched,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (showId.present) {
      map['show_id'] = Variable<int>(showId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (watched.present) {
      map['watched'] = Variable<bool>(watched.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackedEpisodesCompanion(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('watched: $watched, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackedSeasonsTable extends TrackedSeasons
    with TableInfo<$TrackedSeasonsTable, TrackedSeason> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackedSeasonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _showIdMeta = const VerificationMeta('showId');
  @override
  late final GeneratedColumn<int> showId = GeneratedColumn<int>(
      'show_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tracked_shows (id)'));
  static const VerificationMeta _seasonNumberMeta =
      const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
      'season_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _episodeCountMeta =
      const VerificationMeta('episodeCount');
  @override
  late final GeneratedColumn<int> episodeCount = GeneratedColumn<int>(
      'episode_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, showId, seasonNumber, episodeCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracked_seasons';
  @override
  VerificationContext validateIntegrity(Insertable<TrackedSeason> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('show_id')) {
      context.handle(_showIdMeta,
          showId.isAcceptableOrUnknown(data['show_id']!, _showIdMeta));
    } else if (isInserting) {
      context.missing(_showIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
          _seasonNumberMeta,
          seasonNumber.isAcceptableOrUnknown(
              data['season_number']!, _seasonNumberMeta));
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('episode_count')) {
      context.handle(
          _episodeCountMeta,
          episodeCount.isAcceptableOrUnknown(
              data['episode_count']!, _episodeCountMeta));
    } else if (isInserting) {
      context.missing(_episodeCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {showId, seasonNumber},
      ];
  @override
  TrackedSeason map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackedSeason(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      showId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}show_id'])!,
      seasonNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_number'])!,
      episodeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_count'])!,
    );
  }

  @override
  $TrackedSeasonsTable createAlias(String alias) {
    return $TrackedSeasonsTable(attachedDatabase, alias);
  }
}

class TrackedSeason extends DataClass implements Insertable<TrackedSeason> {
  final int id;
  final int showId;
  final int seasonNumber;
  final int episodeCount;
  const TrackedSeason(
      {required this.id,
      required this.showId,
      required this.seasonNumber,
      required this.episodeCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['show_id'] = Variable<int>(showId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_count'] = Variable<int>(episodeCount);
    return map;
  }

  TrackedSeasonsCompanion toCompanion(bool nullToAbsent) {
    return TrackedSeasonsCompanion(
      id: Value(id),
      showId: Value(showId),
      seasonNumber: Value(seasonNumber),
      episodeCount: Value(episodeCount),
    );
  }

  factory TrackedSeason.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackedSeason(
      id: serializer.fromJson<int>(json['id']),
      showId: serializer.fromJson<int>(json['showId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeCount: serializer.fromJson<int>(json['episodeCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'showId': serializer.toJson<int>(showId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeCount': serializer.toJson<int>(episodeCount),
    };
  }

  TrackedSeason copyWith(
          {int? id, int? showId, int? seasonNumber, int? episodeCount}) =>
      TrackedSeason(
        id: id ?? this.id,
        showId: showId ?? this.showId,
        seasonNumber: seasonNumber ?? this.seasonNumber,
        episodeCount: episodeCount ?? this.episodeCount,
      );
  TrackedSeason copyWithCompanion(TrackedSeasonsCompanion data) {
    return TrackedSeason(
      id: data.id.present ? data.id.value : this.id,
      showId: data.showId.present ? data.showId.value : this.showId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeCount: data.episodeCount.present
          ? data.episodeCount.value
          : this.episodeCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackedSeason(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeCount: $episodeCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, showId, seasonNumber, episodeCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackedSeason &&
          other.id == this.id &&
          other.showId == this.showId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeCount == this.episodeCount);
}

class TrackedSeasonsCompanion extends UpdateCompanion<TrackedSeason> {
  final Value<int> id;
  final Value<int> showId;
  final Value<int> seasonNumber;
  final Value<int> episodeCount;
  const TrackedSeasonsCompanion({
    this.id = const Value.absent(),
    this.showId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeCount = const Value.absent(),
  });
  TrackedSeasonsCompanion.insert({
    this.id = const Value.absent(),
    required int showId,
    required int seasonNumber,
    required int episodeCount,
  })  : showId = Value(showId),
        seasonNumber = Value(seasonNumber),
        episodeCount = Value(episodeCount);
  static Insertable<TrackedSeason> custom({
    Expression<int>? id,
    Expression<int>? showId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (showId != null) 'show_id': showId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeCount != null) 'episode_count': episodeCount,
    });
  }

  TrackedSeasonsCompanion copyWith(
      {Value<int>? id,
      Value<int>? showId,
      Value<int>? seasonNumber,
      Value<int>? episodeCount}) {
    return TrackedSeasonsCompanion(
      id: id ?? this.id,
      showId: showId ?? this.showId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeCount: episodeCount ?? this.episodeCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (showId.present) {
      map['show_id'] = Variable<int>(showId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeCount.present) {
      map['episode_count'] = Variable<int>(episodeCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackedSeasonsCompanion(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeCount: $episodeCount')
          ..write(')'))
        .toString();
  }
}

class $CachedEpisodesTable extends CachedEpisodes
    with TableInfo<$CachedEpisodesTable, CachedEpisode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedEpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tmdbShowIdMeta =
      const VerificationMeta('tmdbShowId');
  @override
  late final GeneratedColumn<int> tmdbShowId = GeneratedColumn<int>(
      'tmdb_show_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _seasonNumberMeta =
      const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
      'season_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _episodeNumberMeta =
      const VerificationMeta('episodeNumber');
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
      'episode_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _overviewMeta =
      const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
      'overview', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stillPathMeta =
      const VerificationMeta('stillPath');
  @override
  late final GeneratedColumn<String> stillPath = GeneratedColumn<String>(
      'still_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _airDateMeta =
      const VerificationMeta('airDate');
  @override
  late final GeneratedColumn<String> airDate = GeneratedColumn<String>(
      'air_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _voteAverageMeta =
      const VerificationMeta('voteAverage');
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
      'vote_average', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _absoluteEpisodeNumberMeta =
      const VerificationMeta('absoluteEpisodeNumber');
  @override
  late final GeneratedColumn<int> absoluteEpisodeNumber = GeneratedColumn<int>(
      'absolute_episode_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _airingAtMeta =
      const VerificationMeta('airingAt');
  @override
  late final GeneratedColumn<DateTime> airingAt = GeneratedColumn<DateTime>(
      'airing_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tmdbShowId,
        seasonNumber,
        episodeNumber,
        name,
        overview,
        stillPath,
        airDate,
        voteAverage,
        absoluteEpisodeNumber,
        airingAt,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_episodes';
  @override
  VerificationContext validateIntegrity(Insertable<CachedEpisode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tmdb_show_id')) {
      context.handle(
          _tmdbShowIdMeta,
          tmdbShowId.isAcceptableOrUnknown(
              data['tmdb_show_id']!, _tmdbShowIdMeta));
    } else if (isInserting) {
      context.missing(_tmdbShowIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
          _seasonNumberMeta,
          seasonNumber.isAcceptableOrUnknown(
              data['season_number']!, _seasonNumberMeta));
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
          _episodeNumberMeta,
          episodeNumber.isAcceptableOrUnknown(
              data['episode_number']!, _episodeNumberMeta));
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta,
          overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('still_path')) {
      context.handle(_stillPathMeta,
          stillPath.isAcceptableOrUnknown(data['still_path']!, _stillPathMeta));
    }
    if (data.containsKey('air_date')) {
      context.handle(_airDateMeta,
          airDate.isAcceptableOrUnknown(data['air_date']!, _airDateMeta));
    }
    if (data.containsKey('vote_average')) {
      context.handle(
          _voteAverageMeta,
          voteAverage.isAcceptableOrUnknown(
              data['vote_average']!, _voteAverageMeta));
    }
    if (data.containsKey('absolute_episode_number')) {
      context.handle(
          _absoluteEpisodeNumberMeta,
          absoluteEpisodeNumber.isAcceptableOrUnknown(
              data['absolute_episode_number']!, _absoluteEpisodeNumberMeta));
    }
    if (data.containsKey('airing_at')) {
      context.handle(_airingAtMeta,
          airingAt.isAcceptableOrUnknown(data['airing_at']!, _airingAtMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {tmdbShowId, seasonNumber, episodeNumber},
      ];
  @override
  CachedEpisode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedEpisode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tmdbShowId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tmdb_show_id'])!,
      seasonNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_number'])!,
      episodeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_number'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      overview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}overview']),
      stillPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}still_path']),
      airDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}air_date']),
      voteAverage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}vote_average']),
      absoluteEpisodeNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}absolute_episode_number']),
      airingAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}airing_at']),
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedEpisodesTable createAlias(String alias) {
    return $CachedEpisodesTable(attachedDatabase, alias);
  }
}

class CachedEpisode extends DataClass implements Insertable<CachedEpisode> {
  final int id;
  final int tmdbShowId;
  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final double? voteAverage;
  final int? absoluteEpisodeNumber;
  final DateTime? airingAt;
  final DateTime cachedAt;
  const CachedEpisode(
      {required this.id,
      required this.tmdbShowId,
      required this.seasonNumber,
      required this.episodeNumber,
      required this.name,
      this.overview,
      this.stillPath,
      this.airDate,
      this.voteAverage,
      this.absoluteEpisodeNumber,
      this.airingAt,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tmdb_show_id'] = Variable<int>(tmdbShowId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || stillPath != null) {
      map['still_path'] = Variable<String>(stillPath);
    }
    if (!nullToAbsent || airDate != null) {
      map['air_date'] = Variable<String>(airDate);
    }
    if (!nullToAbsent || voteAverage != null) {
      map['vote_average'] = Variable<double>(voteAverage);
    }
    if (!nullToAbsent || absoluteEpisodeNumber != null) {
      map['absolute_episode_number'] = Variable<int>(absoluteEpisodeNumber);
    }
    if (!nullToAbsent || airingAt != null) {
      map['airing_at'] = Variable<DateTime>(airingAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedEpisodesCompanion toCompanion(bool nullToAbsent) {
    return CachedEpisodesCompanion(
      id: Value(id),
      tmdbShowId: Value(tmdbShowId),
      seasonNumber: Value(seasonNumber),
      episodeNumber: Value(episodeNumber),
      name: Value(name),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      stillPath: stillPath == null && nullToAbsent
          ? const Value.absent()
          : Value(stillPath),
      airDate: airDate == null && nullToAbsent
          ? const Value.absent()
          : Value(airDate),
      voteAverage: voteAverage == null && nullToAbsent
          ? const Value.absent()
          : Value(voteAverage),
      absoluteEpisodeNumber: absoluteEpisodeNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(absoluteEpisodeNumber),
      airingAt: airingAt == null && nullToAbsent
          ? const Value.absent()
          : Value(airingAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedEpisode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedEpisode(
      id: serializer.fromJson<int>(json['id']),
      tmdbShowId: serializer.fromJson<int>(json['tmdbShowId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      name: serializer.fromJson<String>(json['name']),
      overview: serializer.fromJson<String?>(json['overview']),
      stillPath: serializer.fromJson<String?>(json['stillPath']),
      airDate: serializer.fromJson<String?>(json['airDate']),
      voteAverage: serializer.fromJson<double?>(json['voteAverage']),
      absoluteEpisodeNumber:
          serializer.fromJson<int?>(json['absoluteEpisodeNumber']),
      airingAt: serializer.fromJson<DateTime?>(json['airingAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tmdbShowId': serializer.toJson<int>(tmdbShowId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'name': serializer.toJson<String>(name),
      'overview': serializer.toJson<String?>(overview),
      'stillPath': serializer.toJson<String?>(stillPath),
      'airDate': serializer.toJson<String?>(airDate),
      'voteAverage': serializer.toJson<double?>(voteAverage),
      'absoluteEpisodeNumber': serializer.toJson<int?>(absoluteEpisodeNumber),
      'airingAt': serializer.toJson<DateTime?>(airingAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedEpisode copyWith(
          {int? id,
          int? tmdbShowId,
          int? seasonNumber,
          int? episodeNumber,
          String? name,
          Value<String?> overview = const Value.absent(),
          Value<String?> stillPath = const Value.absent(),
          Value<String?> airDate = const Value.absent(),
          Value<double?> voteAverage = const Value.absent(),
          Value<int?> absoluteEpisodeNumber = const Value.absent(),
          Value<DateTime?> airingAt = const Value.absent(),
          DateTime? cachedAt}) =>
      CachedEpisode(
        id: id ?? this.id,
        tmdbShowId: tmdbShowId ?? this.tmdbShowId,
        seasonNumber: seasonNumber ?? this.seasonNumber,
        episodeNumber: episodeNumber ?? this.episodeNumber,
        name: name ?? this.name,
        overview: overview.present ? overview.value : this.overview,
        stillPath: stillPath.present ? stillPath.value : this.stillPath,
        airDate: airDate.present ? airDate.value : this.airDate,
        voteAverage: voteAverage.present ? voteAverage.value : this.voteAverage,
        absoluteEpisodeNumber: absoluteEpisodeNumber.present
            ? absoluteEpisodeNumber.value
            : this.absoluteEpisodeNumber,
        airingAt: airingAt.present ? airingAt.value : this.airingAt,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedEpisode copyWithCompanion(CachedEpisodesCompanion data) {
    return CachedEpisode(
      id: data.id.present ? data.id.value : this.id,
      tmdbShowId:
          data.tmdbShowId.present ? data.tmdbShowId.value : this.tmdbShowId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      name: data.name.present ? data.name.value : this.name,
      overview: data.overview.present ? data.overview.value : this.overview,
      stillPath: data.stillPath.present ? data.stillPath.value : this.stillPath,
      airDate: data.airDate.present ? data.airDate.value : this.airDate,
      voteAverage:
          data.voteAverage.present ? data.voteAverage.value : this.voteAverage,
      absoluteEpisodeNumber: data.absoluteEpisodeNumber.present
          ? data.absoluteEpisodeNumber.value
          : this.absoluteEpisodeNumber,
      airingAt: data.airingAt.present ? data.airingAt.value : this.airingAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedEpisode(')
          ..write('id: $id, ')
          ..write('tmdbShowId: $tmdbShowId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('stillPath: $stillPath, ')
          ..write('airDate: $airDate, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('absoluteEpisodeNumber: $absoluteEpisodeNumber, ')
          ..write('airingAt: $airingAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tmdbShowId,
      seasonNumber,
      episodeNumber,
      name,
      overview,
      stillPath,
      airDate,
      voteAverage,
      absoluteEpisodeNumber,
      airingAt,
      cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedEpisode &&
          other.id == this.id &&
          other.tmdbShowId == this.tmdbShowId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.name == this.name &&
          other.overview == this.overview &&
          other.stillPath == this.stillPath &&
          other.airDate == this.airDate &&
          other.voteAverage == this.voteAverage &&
          other.absoluteEpisodeNumber == this.absoluteEpisodeNumber &&
          other.airingAt == this.airingAt &&
          other.cachedAt == this.cachedAt);
}

class CachedEpisodesCompanion extends UpdateCompanion<CachedEpisode> {
  final Value<int> id;
  final Value<int> tmdbShowId;
  final Value<int> seasonNumber;
  final Value<int> episodeNumber;
  final Value<String> name;
  final Value<String?> overview;
  final Value<String?> stillPath;
  final Value<String?> airDate;
  final Value<double?> voteAverage;
  final Value<int?> absoluteEpisodeNumber;
  final Value<DateTime?> airingAt;
  final Value<DateTime> cachedAt;
  const CachedEpisodesCompanion({
    this.id = const Value.absent(),
    this.tmdbShowId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.overview = const Value.absent(),
    this.stillPath = const Value.absent(),
    this.airDate = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.absoluteEpisodeNumber = const Value.absent(),
    this.airingAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedEpisodesCompanion.insert({
    this.id = const Value.absent(),
    required int tmdbShowId,
    required int seasonNumber,
    required int episodeNumber,
    required String name,
    this.overview = const Value.absent(),
    this.stillPath = const Value.absent(),
    this.airDate = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.absoluteEpisodeNumber = const Value.absent(),
    this.airingAt = const Value.absent(),
    required DateTime cachedAt,
  })  : tmdbShowId = Value(tmdbShowId),
        seasonNumber = Value(seasonNumber),
        episodeNumber = Value(episodeNumber),
        name = Value(name),
        cachedAt = Value(cachedAt);
  static Insertable<CachedEpisode> custom({
    Expression<int>? id,
    Expression<int>? tmdbShowId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<String>? name,
    Expression<String>? overview,
    Expression<String>? stillPath,
    Expression<String>? airDate,
    Expression<double>? voteAverage,
    Expression<int>? absoluteEpisodeNumber,
    Expression<DateTime>? airingAt,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tmdbShowId != null) 'tmdb_show_id': tmdbShowId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (name != null) 'name': name,
      if (overview != null) 'overview': overview,
      if (stillPath != null) 'still_path': stillPath,
      if (airDate != null) 'air_date': airDate,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (absoluteEpisodeNumber != null)
        'absolute_episode_number': absoluteEpisodeNumber,
      if (airingAt != null) 'airing_at': airingAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedEpisodesCompanion copyWith(
      {Value<int>? id,
      Value<int>? tmdbShowId,
      Value<int>? seasonNumber,
      Value<int>? episodeNumber,
      Value<String>? name,
      Value<String?>? overview,
      Value<String?>? stillPath,
      Value<String?>? airDate,
      Value<double?>? voteAverage,
      Value<int?>? absoluteEpisodeNumber,
      Value<DateTime?>? airingAt,
      Value<DateTime>? cachedAt}) {
    return CachedEpisodesCompanion(
      id: id ?? this.id,
      tmdbShowId: tmdbShowId ?? this.tmdbShowId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      stillPath: stillPath ?? this.stillPath,
      airDate: airDate ?? this.airDate,
      voteAverage: voteAverage ?? this.voteAverage,
      absoluteEpisodeNumber:
          absoluteEpisodeNumber ?? this.absoluteEpisodeNumber,
      airingAt: airingAt ?? this.airingAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tmdbShowId.present) {
      map['tmdb_show_id'] = Variable<int>(tmdbShowId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (stillPath.present) {
      map['still_path'] = Variable<String>(stillPath.value);
    }
    if (airDate.present) {
      map['air_date'] = Variable<String>(airDate.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    if (absoluteEpisodeNumber.present) {
      map['absolute_episode_number'] =
          Variable<int>(absoluteEpisodeNumber.value);
    }
    if (airingAt.present) {
      map['airing_at'] = Variable<DateTime>(airingAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedEpisodesCompanion(')
          ..write('id: $id, ')
          ..write('tmdbShowId: $tmdbShowId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('stillPath: $stillPath, ')
          ..write('airDate: $airDate, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('absoluteEpisodeNumber: $absoluteEpisodeNumber, ')
          ..write('airingAt: $airingAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackedMoviesTable extends TrackedMovies
    with TableInfo<$TrackedMoviesTable, TrackedMovy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackedMoviesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
      'tmdb_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _overviewMeta =
      const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
      'overview', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _posterPathMeta =
      const VerificationMeta('posterPath');
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
      'poster_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<MediaStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MediaStatus>($TrackedMoviesTable.$converterstatus);
  static const VerificationMeta _userRatingMeta =
      const VerificationMeta('userRating');
  @override
  late final GeneratedColumn<double> userRating = GeneratedColumn<double>(
      'user_rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _userNotesMeta =
      const VerificationMeta('userNotes');
  @override
  late final GeneratedColumn<String> userNotes = GeneratedColumn<String>(
      'user_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _releaseYearMeta =
      const VerificationMeta('releaseYear');
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
      'release_year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _releaseDateMeta =
      const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<DateTime> releaseDate = GeneratedColumn<DateTime>(
      'release_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tmdbId,
        title,
        overview,
        posterPath,
        status,
        userRating,
        userNotes,
        releaseYear,
        releaseDate,
        addedAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracked_movies';
  @override
  VerificationContext validateIntegrity(Insertable<TrackedMovy> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta,
          tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta,
          overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('poster_path')) {
      context.handle(
          _posterPathMeta,
          posterPath.isAcceptableOrUnknown(
              data['poster_path']!, _posterPathMeta));
    }
    if (data.containsKey('user_rating')) {
      context.handle(
          _userRatingMeta,
          userRating.isAcceptableOrUnknown(
              data['user_rating']!, _userRatingMeta));
    }
    if (data.containsKey('user_notes')) {
      context.handle(_userNotesMeta,
          userNotes.isAcceptableOrUnknown(data['user_notes']!, _userNotesMeta));
    }
    if (data.containsKey('release_year')) {
      context.handle(
          _releaseYearMeta,
          releaseYear.isAcceptableOrUnknown(
              data['release_year']!, _releaseYearMeta));
    }
    if (data.containsKey('release_date')) {
      context.handle(
          _releaseDateMeta,
          releaseDate.isAcceptableOrUnknown(
              data['release_date']!, _releaseDateMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackedMovy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackedMovy(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tmdbId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tmdb_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      overview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}overview']),
      posterPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_path']),
      status: $TrackedMoviesTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      userRating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}user_rating']),
      userNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_notes']),
      releaseYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}release_year']),
      releaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}release_date']),
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $TrackedMoviesTable createAlias(String alias) {
    return $TrackedMoviesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaStatus, String, String> $converterstatus =
      const EnumNameConverter<MediaStatus>(MediaStatus.values);
}

class TrackedMovy extends DataClass implements Insertable<TrackedMovy> {
  final int id;
  final int tmdbId;
  final String title;
  final String? overview;
  final String? posterPath;
  final MediaStatus status;
  final double? userRating;
  final String? userNotes;
  final int? releaseYear;
  final DateTime? releaseDate;
  final DateTime addedAt;
  final DateTime? updatedAt;
  const TrackedMovy(
      {required this.id,
      required this.tmdbId,
      required this.title,
      this.overview,
      this.posterPath,
      required this.status,
      this.userRating,
      this.userNotes,
      this.releaseYear,
      this.releaseDate,
      required this.addedAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    {
      map['status'] =
          Variable<String>($TrackedMoviesTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || userRating != null) {
      map['user_rating'] = Variable<double>(userRating);
    }
    if (!nullToAbsent || userNotes != null) {
      map['user_notes'] = Variable<String>(userNotes);
    }
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<DateTime>(releaseDate);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  TrackedMoviesCompanion toCompanion(bool nullToAbsent) {
    return TrackedMoviesCompanion(
      id: Value(id),
      tmdbId: Value(tmdbId),
      title: Value(title),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      status: Value(status),
      userRating: userRating == null && nullToAbsent
          ? const Value.absent()
          : Value(userRating),
      userNotes: userNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(userNotes),
      releaseYear: releaseYear == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseYear),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      addedAt: Value(addedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory TrackedMovy.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackedMovy(
      id: serializer.fromJson<int>(json['id']),
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      title: serializer.fromJson<String>(json['title']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      status: $TrackedMoviesTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
      userRating: serializer.fromJson<double?>(json['userRating']),
      userNotes: serializer.fromJson<String?>(json['userNotes']),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      releaseDate: serializer.fromJson<DateTime?>(json['releaseDate']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tmdbId': serializer.toJson<int>(tmdbId),
      'title': serializer.toJson<String>(title),
      'overview': serializer.toJson<String?>(overview),
      'posterPath': serializer.toJson<String?>(posterPath),
      'status': serializer
          .toJson<String>($TrackedMoviesTable.$converterstatus.toJson(status)),
      'userRating': serializer.toJson<double?>(userRating),
      'userNotes': serializer.toJson<String?>(userNotes),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'releaseDate': serializer.toJson<DateTime?>(releaseDate),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  TrackedMovy copyWith(
          {int? id,
          int? tmdbId,
          String? title,
          Value<String?> overview = const Value.absent(),
          Value<String?> posterPath = const Value.absent(),
          MediaStatus? status,
          Value<double?> userRating = const Value.absent(),
          Value<String?> userNotes = const Value.absent(),
          Value<int?> releaseYear = const Value.absent(),
          Value<DateTime?> releaseDate = const Value.absent(),
          DateTime? addedAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      TrackedMovy(
        id: id ?? this.id,
        tmdbId: tmdbId ?? this.tmdbId,
        title: title ?? this.title,
        overview: overview.present ? overview.value : this.overview,
        posterPath: posterPath.present ? posterPath.value : this.posterPath,
        status: status ?? this.status,
        userRating: userRating.present ? userRating.value : this.userRating,
        userNotes: userNotes.present ? userNotes.value : this.userNotes,
        releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
        releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
        addedAt: addedAt ?? this.addedAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  TrackedMovy copyWithCompanion(TrackedMoviesCompanion data) {
    return TrackedMovy(
      id: data.id.present ? data.id.value : this.id,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      title: data.title.present ? data.title.value : this.title,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterPath:
          data.posterPath.present ? data.posterPath.value : this.posterPath,
      status: data.status.present ? data.status.value : this.status,
      userRating:
          data.userRating.present ? data.userRating.value : this.userRating,
      userNotes: data.userNotes.present ? data.userNotes.value : this.userNotes,
      releaseYear:
          data.releaseYear.present ? data.releaseYear.value : this.releaseYear,
      releaseDate:
          data.releaseDate.present ? data.releaseDate.value : this.releaseDate,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackedMovy(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('status: $status, ')
          ..write('userRating: $userRating, ')
          ..write('userNotes: $userNotes, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tmdbId,
      title,
      overview,
      posterPath,
      status,
      userRating,
      userNotes,
      releaseYear,
      releaseDate,
      addedAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackedMovy &&
          other.id == this.id &&
          other.tmdbId == this.tmdbId &&
          other.title == this.title &&
          other.overview == this.overview &&
          other.posterPath == this.posterPath &&
          other.status == this.status &&
          other.userRating == this.userRating &&
          other.userNotes == this.userNotes &&
          other.releaseYear == this.releaseYear &&
          other.releaseDate == this.releaseDate &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt);
}

class TrackedMoviesCompanion extends UpdateCompanion<TrackedMovy> {
  final Value<int> id;
  final Value<int> tmdbId;
  final Value<String> title;
  final Value<String?> overview;
  final Value<String?> posterPath;
  final Value<MediaStatus> status;
  final Value<double?> userRating;
  final Value<String?> userNotes;
  final Value<int?> releaseYear;
  final Value<DateTime?> releaseDate;
  final Value<DateTime> addedAt;
  final Value<DateTime?> updatedAt;
  const TrackedMoviesCompanion({
    this.id = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.status = const Value.absent(),
    this.userRating = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TrackedMoviesCompanion.insert({
    this.id = const Value.absent(),
    required int tmdbId,
    required String title,
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    required MediaStatus status,
    this.userRating = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.releaseDate = const Value.absent(),
    required DateTime addedAt,
    this.updatedAt = const Value.absent(),
  })  : tmdbId = Value(tmdbId),
        title = Value(title),
        status = Value(status),
        addedAt = Value(addedAt);
  static Insertable<TrackedMovy> custom({
    Expression<int>? id,
    Expression<int>? tmdbId,
    Expression<String>? title,
    Expression<String>? overview,
    Expression<String>? posterPath,
    Expression<String>? status,
    Expression<double>? userRating,
    Expression<String>? userNotes,
    Expression<int>? releaseYear,
    Expression<DateTime>? releaseDate,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (overview != null) 'overview': overview,
      if (posterPath != null) 'poster_path': posterPath,
      if (status != null) 'status': status,
      if (userRating != null) 'user_rating': userRating,
      if (userNotes != null) 'user_notes': userNotes,
      if (releaseYear != null) 'release_year': releaseYear,
      if (releaseDate != null) 'release_date': releaseDate,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TrackedMoviesCompanion copyWith(
      {Value<int>? id,
      Value<int>? tmdbId,
      Value<String>? title,
      Value<String?>? overview,
      Value<String?>? posterPath,
      Value<MediaStatus>? status,
      Value<double?>? userRating,
      Value<String?>? userNotes,
      Value<int?>? releaseYear,
      Value<DateTime?>? releaseDate,
      Value<DateTime>? addedAt,
      Value<DateTime?>? updatedAt}) {
    return TrackedMoviesCompanion(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      status: status ?? this.status,
      userRating: userRating ?? this.userRating,
      userNotes: userNotes ?? this.userNotes,
      releaseYear: releaseYear ?? this.releaseYear,
      releaseDate: releaseDate ?? this.releaseDate,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
          $TrackedMoviesTable.$converterstatus.toSql(status.value));
    }
    if (userRating.present) {
      map['user_rating'] = Variable<double>(userRating.value);
    }
    if (userNotes.present) {
      map['user_notes'] = Variable<String>(userNotes.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<DateTime>(releaseDate.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackedMoviesCompanion(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('status: $status, ')
          ..write('userRating: $userRating, ')
          ..write('userNotes: $userNotes, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackedGamesTable extends TrackedGames
    with TableInfo<$TrackedGamesTable, TrackedGame> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackedGamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _rawgIdMeta = const VerificationMeta('rawgId');
  @override
  late final GeneratedColumn<int> rawgId = GeneratedColumn<int>(
      'rawg_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<MediaStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MediaStatus>($TrackedGamesTable.$converterstatus);
  static const VerificationMeta _userRatingMeta =
      const VerificationMeta('userRating');
  @override
  late final GeneratedColumn<double> userRating = GeneratedColumn<double>(
      'user_rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _userNotesMeta =
      const VerificationMeta('userNotes');
  @override
  late final GeneratedColumn<String> userNotes = GeneratedColumn<String>(
      'user_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _releaseDateMeta =
      const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<DateTime> releaseDate = GeneratedColumn<DateTime>(
      'release_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _playtimeMeta =
      const VerificationMeta('playtime');
  @override
  late final GeneratedColumn<int> playtime = GeneratedColumn<int>(
      'playtime', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _platformsMeta =
      const VerificationMeta('platforms');
  @override
  late final GeneratedColumn<String> platforms = GeneratedColumn<String>(
      'platforms', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _voteAverageMeta =
      const VerificationMeta('voteAverage');
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
      'vote_average', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        rawgId,
        title,
        coverUrl,
        status,
        userRating,
        userNotes,
        addedAt,
        releaseDate,
        playtime,
        platforms,
        voteAverage,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracked_games';
  @override
  VerificationContext validateIntegrity(Insertable<TrackedGame> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('rawg_id')) {
      context.handle(_rawgIdMeta,
          rawgId.isAcceptableOrUnknown(data['rawg_id']!, _rawgIdMeta));
    } else if (isInserting) {
      context.missing(_rawgIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('user_rating')) {
      context.handle(
          _userRatingMeta,
          userRating.isAcceptableOrUnknown(
              data['user_rating']!, _userRatingMeta));
    }
    if (data.containsKey('user_notes')) {
      context.handle(_userNotesMeta,
          userNotes.isAcceptableOrUnknown(data['user_notes']!, _userNotesMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('release_date')) {
      context.handle(
          _releaseDateMeta,
          releaseDate.isAcceptableOrUnknown(
              data['release_date']!, _releaseDateMeta));
    }
    if (data.containsKey('playtime')) {
      context.handle(_playtimeMeta,
          playtime.isAcceptableOrUnknown(data['playtime']!, _playtimeMeta));
    }
    if (data.containsKey('platforms')) {
      context.handle(_platformsMeta,
          platforms.isAcceptableOrUnknown(data['platforms']!, _platformsMeta));
    }
    if (data.containsKey('vote_average')) {
      context.handle(
          _voteAverageMeta,
          voteAverage.isAcceptableOrUnknown(
              data['vote_average']!, _voteAverageMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackedGame map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackedGame(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      rawgId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rawg_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      status: $TrackedGamesTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      userRating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}user_rating']),
      userNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_notes']),
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      releaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}release_date']),
      playtime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}playtime']),
      platforms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platforms']),
      voteAverage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}vote_average']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $TrackedGamesTable createAlias(String alias) {
    return $TrackedGamesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaStatus, String, String> $converterstatus =
      const EnumNameConverter<MediaStatus>(MediaStatus.values);
}

class TrackedGame extends DataClass implements Insertable<TrackedGame> {
  final int id;
  final int rawgId;
  final String title;
  final String? coverUrl;
  final MediaStatus status;
  final double? userRating;
  final String? userNotes;
  final DateTime addedAt;
  final DateTime? releaseDate;
  final int? playtime;
  final String? platforms;
  final double? voteAverage;
  final DateTime? updatedAt;
  const TrackedGame(
      {required this.id,
      required this.rawgId,
      required this.title,
      this.coverUrl,
      required this.status,
      this.userRating,
      this.userNotes,
      required this.addedAt,
      this.releaseDate,
      this.playtime,
      this.platforms,
      this.voteAverage,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['rawg_id'] = Variable<int>(rawgId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    {
      map['status'] =
          Variable<String>($TrackedGamesTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || userRating != null) {
      map['user_rating'] = Variable<double>(userRating);
    }
    if (!nullToAbsent || userNotes != null) {
      map['user_notes'] = Variable<String>(userNotes);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<DateTime>(releaseDate);
    }
    if (!nullToAbsent || playtime != null) {
      map['playtime'] = Variable<int>(playtime);
    }
    if (!nullToAbsent || platforms != null) {
      map['platforms'] = Variable<String>(platforms);
    }
    if (!nullToAbsent || voteAverage != null) {
      map['vote_average'] = Variable<double>(voteAverage);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  TrackedGamesCompanion toCompanion(bool nullToAbsent) {
    return TrackedGamesCompanion(
      id: Value(id),
      rawgId: Value(rawgId),
      title: Value(title),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      status: Value(status),
      userRating: userRating == null && nullToAbsent
          ? const Value.absent()
          : Value(userRating),
      userNotes: userNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(userNotes),
      addedAt: Value(addedAt),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      playtime: playtime == null && nullToAbsent
          ? const Value.absent()
          : Value(playtime),
      platforms: platforms == null && nullToAbsent
          ? const Value.absent()
          : Value(platforms),
      voteAverage: voteAverage == null && nullToAbsent
          ? const Value.absent()
          : Value(voteAverage),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory TrackedGame.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackedGame(
      id: serializer.fromJson<int>(json['id']),
      rawgId: serializer.fromJson<int>(json['rawgId']),
      title: serializer.fromJson<String>(json['title']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      status: $TrackedGamesTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
      userRating: serializer.fromJson<double?>(json['userRating']),
      userNotes: serializer.fromJson<String?>(json['userNotes']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      releaseDate: serializer.fromJson<DateTime?>(json['releaseDate']),
      playtime: serializer.fromJson<int?>(json['playtime']),
      platforms: serializer.fromJson<String?>(json['platforms']),
      voteAverage: serializer.fromJson<double?>(json['voteAverage']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rawgId': serializer.toJson<int>(rawgId),
      'title': serializer.toJson<String>(title),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'status': serializer
          .toJson<String>($TrackedGamesTable.$converterstatus.toJson(status)),
      'userRating': serializer.toJson<double?>(userRating),
      'userNotes': serializer.toJson<String?>(userNotes),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'releaseDate': serializer.toJson<DateTime?>(releaseDate),
      'playtime': serializer.toJson<int?>(playtime),
      'platforms': serializer.toJson<String?>(platforms),
      'voteAverage': serializer.toJson<double?>(voteAverage),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  TrackedGame copyWith(
          {int? id,
          int? rawgId,
          String? title,
          Value<String?> coverUrl = const Value.absent(),
          MediaStatus? status,
          Value<double?> userRating = const Value.absent(),
          Value<String?> userNotes = const Value.absent(),
          DateTime? addedAt,
          Value<DateTime?> releaseDate = const Value.absent(),
          Value<int?> playtime = const Value.absent(),
          Value<String?> platforms = const Value.absent(),
          Value<double?> voteAverage = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      TrackedGame(
        id: id ?? this.id,
        rawgId: rawgId ?? this.rawgId,
        title: title ?? this.title,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        status: status ?? this.status,
        userRating: userRating.present ? userRating.value : this.userRating,
        userNotes: userNotes.present ? userNotes.value : this.userNotes,
        addedAt: addedAt ?? this.addedAt,
        releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
        playtime: playtime.present ? playtime.value : this.playtime,
        platforms: platforms.present ? platforms.value : this.platforms,
        voteAverage: voteAverage.present ? voteAverage.value : this.voteAverage,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  TrackedGame copyWithCompanion(TrackedGamesCompanion data) {
    return TrackedGame(
      id: data.id.present ? data.id.value : this.id,
      rawgId: data.rawgId.present ? data.rawgId.value : this.rawgId,
      title: data.title.present ? data.title.value : this.title,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      status: data.status.present ? data.status.value : this.status,
      userRating:
          data.userRating.present ? data.userRating.value : this.userRating,
      userNotes: data.userNotes.present ? data.userNotes.value : this.userNotes,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      releaseDate:
          data.releaseDate.present ? data.releaseDate.value : this.releaseDate,
      playtime: data.playtime.present ? data.playtime.value : this.playtime,
      platforms: data.platforms.present ? data.platforms.value : this.platforms,
      voteAverage:
          data.voteAverage.present ? data.voteAverage.value : this.voteAverage,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackedGame(')
          ..write('id: $id, ')
          ..write('rawgId: $rawgId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('status: $status, ')
          ..write('userRating: $userRating, ')
          ..write('userNotes: $userNotes, ')
          ..write('addedAt: $addedAt, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('playtime: $playtime, ')
          ..write('platforms: $platforms, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      rawgId,
      title,
      coverUrl,
      status,
      userRating,
      userNotes,
      addedAt,
      releaseDate,
      playtime,
      platforms,
      voteAverage,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackedGame &&
          other.id == this.id &&
          other.rawgId == this.rawgId &&
          other.title == this.title &&
          other.coverUrl == this.coverUrl &&
          other.status == this.status &&
          other.userRating == this.userRating &&
          other.userNotes == this.userNotes &&
          other.addedAt == this.addedAt &&
          other.releaseDate == this.releaseDate &&
          other.playtime == this.playtime &&
          other.platforms == this.platforms &&
          other.voteAverage == this.voteAverage &&
          other.updatedAt == this.updatedAt);
}

class TrackedGamesCompanion extends UpdateCompanion<TrackedGame> {
  final Value<int> id;
  final Value<int> rawgId;
  final Value<String> title;
  final Value<String?> coverUrl;
  final Value<MediaStatus> status;
  final Value<double?> userRating;
  final Value<String?> userNotes;
  final Value<DateTime> addedAt;
  final Value<DateTime?> releaseDate;
  final Value<int?> playtime;
  final Value<String?> platforms;
  final Value<double?> voteAverage;
  final Value<DateTime?> updatedAt;
  const TrackedGamesCompanion({
    this.id = const Value.absent(),
    this.rawgId = const Value.absent(),
    this.title = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.userRating = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.playtime = const Value.absent(),
    this.platforms = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TrackedGamesCompanion.insert({
    this.id = const Value.absent(),
    required int rawgId,
    required String title,
    this.coverUrl = const Value.absent(),
    required MediaStatus status,
    this.userRating = const Value.absent(),
    this.userNotes = const Value.absent(),
    required DateTime addedAt,
    this.releaseDate = const Value.absent(),
    this.playtime = const Value.absent(),
    this.platforms = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : rawgId = Value(rawgId),
        title = Value(title),
        status = Value(status),
        addedAt = Value(addedAt);
  static Insertable<TrackedGame> custom({
    Expression<int>? id,
    Expression<int>? rawgId,
    Expression<String>? title,
    Expression<String>? coverUrl,
    Expression<String>? status,
    Expression<double>? userRating,
    Expression<String>? userNotes,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? releaseDate,
    Expression<int>? playtime,
    Expression<String>? platforms,
    Expression<double>? voteAverage,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawgId != null) 'rawg_id': rawgId,
      if (title != null) 'title': title,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (status != null) 'status': status,
      if (userRating != null) 'user_rating': userRating,
      if (userNotes != null) 'user_notes': userNotes,
      if (addedAt != null) 'added_at': addedAt,
      if (releaseDate != null) 'release_date': releaseDate,
      if (playtime != null) 'playtime': playtime,
      if (platforms != null) 'platforms': platforms,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TrackedGamesCompanion copyWith(
      {Value<int>? id,
      Value<int>? rawgId,
      Value<String>? title,
      Value<String?>? coverUrl,
      Value<MediaStatus>? status,
      Value<double?>? userRating,
      Value<String?>? userNotes,
      Value<DateTime>? addedAt,
      Value<DateTime?>? releaseDate,
      Value<int?>? playtime,
      Value<String?>? platforms,
      Value<double?>? voteAverage,
      Value<DateTime?>? updatedAt}) {
    return TrackedGamesCompanion(
      id: id ?? this.id,
      rawgId: rawgId ?? this.rawgId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      userRating: userRating ?? this.userRating,
      userNotes: userNotes ?? this.userNotes,
      addedAt: addedAt ?? this.addedAt,
      releaseDate: releaseDate ?? this.releaseDate,
      playtime: playtime ?? this.playtime,
      platforms: platforms ?? this.platforms,
      voteAverage: voteAverage ?? this.voteAverage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rawgId.present) {
      map['rawg_id'] = Variable<int>(rawgId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
          $TrackedGamesTable.$converterstatus.toSql(status.value));
    }
    if (userRating.present) {
      map['user_rating'] = Variable<double>(userRating.value);
    }
    if (userNotes.present) {
      map['user_notes'] = Variable<String>(userNotes.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<DateTime>(releaseDate.value);
    }
    if (playtime.present) {
      map['playtime'] = Variable<int>(playtime.value);
    }
    if (platforms.present) {
      map['platforms'] = Variable<String>(platforms.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackedGamesCompanion(')
          ..write('id: $id, ')
          ..write('rawgId: $rawgId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('status: $status, ')
          ..write('userRating: $userRating, ')
          ..write('userNotes: $userNotes, ')
          ..write('addedAt: $addedAt, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('playtime: $playtime, ')
          ..write('platforms: $platforms, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $YunaCacheTable extends YunaCache
    with TableInfo<$YunaCacheTable, YunaCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $YunaCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
      'tmdb_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _anilistIdsJsonMeta =
      const VerificationMeta('anilistIdsJson');
  @override
  late final GeneratedColumn<String> anilistIdsJson = GeneratedColumn<String>(
      'anilist_ids_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [tmdbId, anilistIdsJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'yuna_cache';
  @override
  VerificationContext validateIntegrity(Insertable<YunaCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta,
          tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    }
    if (data.containsKey('anilist_ids_json')) {
      context.handle(
          _anilistIdsJsonMeta,
          anilistIdsJson.isAcceptableOrUnknown(
              data['anilist_ids_json']!, _anilistIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_anilistIdsJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  YunaCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return YunaCacheData(
      tmdbId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tmdb_id'])!,
      anilistIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}anilist_ids_json'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $YunaCacheTable createAlias(String alias) {
    return $YunaCacheTable(attachedDatabase, alias);
  }
}

class YunaCacheData extends DataClass implements Insertable<YunaCacheData> {
  final int tmdbId;
  final String anilistIdsJson;
  final DateTime cachedAt;
  const YunaCacheData(
      {required this.tmdbId,
      required this.anilistIdsJson,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['anilist_ids_json'] = Variable<String>(anilistIdsJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  YunaCacheCompanion toCompanion(bool nullToAbsent) {
    return YunaCacheCompanion(
      tmdbId: Value(tmdbId),
      anilistIdsJson: Value(anilistIdsJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory YunaCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return YunaCacheData(
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      anilistIdsJson: serializer.fromJson<String>(json['anilistIdsJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tmdbId': serializer.toJson<int>(tmdbId),
      'anilistIdsJson': serializer.toJson<String>(anilistIdsJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  YunaCacheData copyWith(
          {int? tmdbId, String? anilistIdsJson, DateTime? cachedAt}) =>
      YunaCacheData(
        tmdbId: tmdbId ?? this.tmdbId,
        anilistIdsJson: anilistIdsJson ?? this.anilistIdsJson,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  YunaCacheData copyWithCompanion(YunaCacheCompanion data) {
    return YunaCacheData(
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      anilistIdsJson: data.anilistIdsJson.present
          ? data.anilistIdsJson.value
          : this.anilistIdsJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('YunaCacheData(')
          ..write('tmdbId: $tmdbId, ')
          ..write('anilistIdsJson: $anilistIdsJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tmdbId, anilistIdsJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YunaCacheData &&
          other.tmdbId == this.tmdbId &&
          other.anilistIdsJson == this.anilistIdsJson &&
          other.cachedAt == this.cachedAt);
}

class YunaCacheCompanion extends UpdateCompanion<YunaCacheData> {
  final Value<int> tmdbId;
  final Value<String> anilistIdsJson;
  final Value<DateTime> cachedAt;
  const YunaCacheCompanion({
    this.tmdbId = const Value.absent(),
    this.anilistIdsJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  YunaCacheCompanion.insert({
    this.tmdbId = const Value.absent(),
    required String anilistIdsJson,
    required DateTime cachedAt,
  })  : anilistIdsJson = Value(anilistIdsJson),
        cachedAt = Value(cachedAt);
  static Insertable<YunaCacheData> custom({
    Expression<int>? tmdbId,
    Expression<String>? anilistIdsJson,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (anilistIdsJson != null) 'anilist_ids_json': anilistIdsJson,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  YunaCacheCompanion copyWith(
      {Value<int>? tmdbId,
      Value<String>? anilistIdsJson,
      Value<DateTime>? cachedAt}) {
    return YunaCacheCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      anilistIdsJson: anilistIdsJson ?? this.anilistIdsJson,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (anilistIdsJson.present) {
      map['anilist_ids_json'] = Variable<String>(anilistIdsJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('YunaCacheCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('anilistIdsJson: $anilistIdsJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $AnimeSeasonCacheTable extends AnimeSeasonCache
    with TableInfo<$AnimeSeasonCacheTable, AnimeSeasonCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnimeSeasonCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tmdbShowIdMeta =
      const VerificationMeta('tmdbShowId');
  @override
  late final GeneratedColumn<int> tmdbShowId = GeneratedColumn<int>(
      'tmdb_show_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _seasonNumberMeta =
      const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
      'season_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _anilistIdMeta =
      const VerificationMeta('anilistId');
  @override
  late final GeneratedColumn<int> anilistId = GeneratedColumn<int>(
      'anilist_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _episodeCountMeta =
      const VerificationMeta('episodeCount');
  @override
  late final GeneratedColumn<int> episodeCount = GeneratedColumn<int>(
      'episode_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _animeSeasonJsonMeta =
      const VerificationMeta('animeSeasonJson');
  @override
  late final GeneratedColumn<String> animeSeasonJson = GeneratedColumn<String>(
      'anime_season_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _validUntilMeta =
      const VerificationMeta('validUntil');
  @override
  late final GeneratedColumn<DateTime> validUntil = GeneratedColumn<DateTime>(
      'valid_until', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tmdbShowId,
        seasonNumber,
        anilistId,
        episodeCount,
        status,
        animeSeasonJson,
        cachedAt,
        validUntil
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anime_season_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<AnimeSeasonCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tmdb_show_id')) {
      context.handle(
          _tmdbShowIdMeta,
          tmdbShowId.isAcceptableOrUnknown(
              data['tmdb_show_id']!, _tmdbShowIdMeta));
    } else if (isInserting) {
      context.missing(_tmdbShowIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
          _seasonNumberMeta,
          seasonNumber.isAcceptableOrUnknown(
              data['season_number']!, _seasonNumberMeta));
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('anilist_id')) {
      context.handle(_anilistIdMeta,
          anilistId.isAcceptableOrUnknown(data['anilist_id']!, _anilistIdMeta));
    } else if (isInserting) {
      context.missing(_anilistIdMeta);
    }
    if (data.containsKey('episode_count')) {
      context.handle(
          _episodeCountMeta,
          episodeCount.isAcceptableOrUnknown(
              data['episode_count']!, _episodeCountMeta));
    } else if (isInserting) {
      context.missing(_episodeCountMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('anime_season_json')) {
      context.handle(
          _animeSeasonJsonMeta,
          animeSeasonJson.isAcceptableOrUnknown(
              data['anime_season_json']!, _animeSeasonJsonMeta));
    } else if (isInserting) {
      context.missing(_animeSeasonJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('valid_until')) {
      context.handle(
          _validUntilMeta,
          validUntil.isAcceptableOrUnknown(
              data['valid_until']!, _validUntilMeta));
    } else if (isInserting) {
      context.missing(_validUntilMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {tmdbShowId, seasonNumber},
      ];
  @override
  AnimeSeasonCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimeSeasonCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tmdbShowId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tmdb_show_id'])!,
      seasonNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_number'])!,
      anilistId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}anilist_id'])!,
      episodeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_count'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      animeSeasonJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}anime_season_json'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
      validUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}valid_until'])!,
    );
  }

  @override
  $AnimeSeasonCacheTable createAlias(String alias) {
    return $AnimeSeasonCacheTable(attachedDatabase, alias);
  }
}

class AnimeSeasonCacheData extends DataClass
    implements Insertable<AnimeSeasonCacheData> {
  final int id;
  final int tmdbShowId;
  final int seasonNumber;
  final int anilistId;
  final int episodeCount;
  final String status;
  final String animeSeasonJson;
  final DateTime cachedAt;
  final DateTime validUntil;
  const AnimeSeasonCacheData(
      {required this.id,
      required this.tmdbShowId,
      required this.seasonNumber,
      required this.anilistId,
      required this.episodeCount,
      required this.status,
      required this.animeSeasonJson,
      required this.cachedAt,
      required this.validUntil});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tmdb_show_id'] = Variable<int>(tmdbShowId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['anilist_id'] = Variable<int>(anilistId);
    map['episode_count'] = Variable<int>(episodeCount);
    map['status'] = Variable<String>(status);
    map['anime_season_json'] = Variable<String>(animeSeasonJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['valid_until'] = Variable<DateTime>(validUntil);
    return map;
  }

  AnimeSeasonCacheCompanion toCompanion(bool nullToAbsent) {
    return AnimeSeasonCacheCompanion(
      id: Value(id),
      tmdbShowId: Value(tmdbShowId),
      seasonNumber: Value(seasonNumber),
      anilistId: Value(anilistId),
      episodeCount: Value(episodeCount),
      status: Value(status),
      animeSeasonJson: Value(animeSeasonJson),
      cachedAt: Value(cachedAt),
      validUntil: Value(validUntil),
    );
  }

  factory AnimeSeasonCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimeSeasonCacheData(
      id: serializer.fromJson<int>(json['id']),
      tmdbShowId: serializer.fromJson<int>(json['tmdbShowId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      anilistId: serializer.fromJson<int>(json['anilistId']),
      episodeCount: serializer.fromJson<int>(json['episodeCount']),
      status: serializer.fromJson<String>(json['status']),
      animeSeasonJson: serializer.fromJson<String>(json['animeSeasonJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      validUntil: serializer.fromJson<DateTime>(json['validUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tmdbShowId': serializer.toJson<int>(tmdbShowId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'anilistId': serializer.toJson<int>(anilistId),
      'episodeCount': serializer.toJson<int>(episodeCount),
      'status': serializer.toJson<String>(status),
      'animeSeasonJson': serializer.toJson<String>(animeSeasonJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'validUntil': serializer.toJson<DateTime>(validUntil),
    };
  }

  AnimeSeasonCacheData copyWith(
          {int? id,
          int? tmdbShowId,
          int? seasonNumber,
          int? anilistId,
          int? episodeCount,
          String? status,
          String? animeSeasonJson,
          DateTime? cachedAt,
          DateTime? validUntil}) =>
      AnimeSeasonCacheData(
        id: id ?? this.id,
        tmdbShowId: tmdbShowId ?? this.tmdbShowId,
        seasonNumber: seasonNumber ?? this.seasonNumber,
        anilistId: anilistId ?? this.anilistId,
        episodeCount: episodeCount ?? this.episodeCount,
        status: status ?? this.status,
        animeSeasonJson: animeSeasonJson ?? this.animeSeasonJson,
        cachedAt: cachedAt ?? this.cachedAt,
        validUntil: validUntil ?? this.validUntil,
      );
  AnimeSeasonCacheData copyWithCompanion(AnimeSeasonCacheCompanion data) {
    return AnimeSeasonCacheData(
      id: data.id.present ? data.id.value : this.id,
      tmdbShowId:
          data.tmdbShowId.present ? data.tmdbShowId.value : this.tmdbShowId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      anilistId: data.anilistId.present ? data.anilistId.value : this.anilistId,
      episodeCount: data.episodeCount.present
          ? data.episodeCount.value
          : this.episodeCount,
      status: data.status.present ? data.status.value : this.status,
      animeSeasonJson: data.animeSeasonJson.present
          ? data.animeSeasonJson.value
          : this.animeSeasonJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      validUntil:
          data.validUntil.present ? data.validUntil.value : this.validUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimeSeasonCacheData(')
          ..write('id: $id, ')
          ..write('tmdbShowId: $tmdbShowId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('anilistId: $anilistId, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('status: $status, ')
          ..write('animeSeasonJson: $animeSeasonJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('validUntil: $validUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tmdbShowId, seasonNumber, anilistId,
      episodeCount, status, animeSeasonJson, cachedAt, validUntil);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimeSeasonCacheData &&
          other.id == this.id &&
          other.tmdbShowId == this.tmdbShowId &&
          other.seasonNumber == this.seasonNumber &&
          other.anilistId == this.anilistId &&
          other.episodeCount == this.episodeCount &&
          other.status == this.status &&
          other.animeSeasonJson == this.animeSeasonJson &&
          other.cachedAt == this.cachedAt &&
          other.validUntil == this.validUntil);
}

class AnimeSeasonCacheCompanion extends UpdateCompanion<AnimeSeasonCacheData> {
  final Value<int> id;
  final Value<int> tmdbShowId;
  final Value<int> seasonNumber;
  final Value<int> anilistId;
  final Value<int> episodeCount;
  final Value<String> status;
  final Value<String> animeSeasonJson;
  final Value<DateTime> cachedAt;
  final Value<DateTime> validUntil;
  const AnimeSeasonCacheCompanion({
    this.id = const Value.absent(),
    this.tmdbShowId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.anilistId = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.status = const Value.absent(),
    this.animeSeasonJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.validUntil = const Value.absent(),
  });
  AnimeSeasonCacheCompanion.insert({
    this.id = const Value.absent(),
    required int tmdbShowId,
    required int seasonNumber,
    required int anilistId,
    required int episodeCount,
    required String status,
    required String animeSeasonJson,
    required DateTime cachedAt,
    required DateTime validUntil,
  })  : tmdbShowId = Value(tmdbShowId),
        seasonNumber = Value(seasonNumber),
        anilistId = Value(anilistId),
        episodeCount = Value(episodeCount),
        status = Value(status),
        animeSeasonJson = Value(animeSeasonJson),
        cachedAt = Value(cachedAt),
        validUntil = Value(validUntil);
  static Insertable<AnimeSeasonCacheData> custom({
    Expression<int>? id,
    Expression<int>? tmdbShowId,
    Expression<int>? seasonNumber,
    Expression<int>? anilistId,
    Expression<int>? episodeCount,
    Expression<String>? status,
    Expression<String>? animeSeasonJson,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? validUntil,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tmdbShowId != null) 'tmdb_show_id': tmdbShowId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (anilistId != null) 'anilist_id': anilistId,
      if (episodeCount != null) 'episode_count': episodeCount,
      if (status != null) 'status': status,
      if (animeSeasonJson != null) 'anime_season_json': animeSeasonJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (validUntil != null) 'valid_until': validUntil,
    });
  }

  AnimeSeasonCacheCompanion copyWith(
      {Value<int>? id,
      Value<int>? tmdbShowId,
      Value<int>? seasonNumber,
      Value<int>? anilistId,
      Value<int>? episodeCount,
      Value<String>? status,
      Value<String>? animeSeasonJson,
      Value<DateTime>? cachedAt,
      Value<DateTime>? validUntil}) {
    return AnimeSeasonCacheCompanion(
      id: id ?? this.id,
      tmdbShowId: tmdbShowId ?? this.tmdbShowId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      anilistId: anilistId ?? this.anilistId,
      episodeCount: episodeCount ?? this.episodeCount,
      status: status ?? this.status,
      animeSeasonJson: animeSeasonJson ?? this.animeSeasonJson,
      cachedAt: cachedAt ?? this.cachedAt,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tmdbShowId.present) {
      map['tmdb_show_id'] = Variable<int>(tmdbShowId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (anilistId.present) {
      map['anilist_id'] = Variable<int>(anilistId.value);
    }
    if (episodeCount.present) {
      map['episode_count'] = Variable<int>(episodeCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (animeSeasonJson.present) {
      map['anime_season_json'] = Variable<String>(animeSeasonJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<DateTime>(validUntil.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimeSeasonCacheCompanion(')
          ..write('id: $id, ')
          ..write('tmdbShowId: $tmdbShowId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('anilistId: $anilistId, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('status: $status, ')
          ..write('animeSeasonJson: $animeSeasonJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('validUntil: $validUntil')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TrackedShowsTable trackedShows = $TrackedShowsTable(this);
  late final $TrackedEpisodesTable trackedEpisodes =
      $TrackedEpisodesTable(this);
  late final $TrackedSeasonsTable trackedSeasons = $TrackedSeasonsTable(this);
  late final $CachedEpisodesTable cachedEpisodes = $CachedEpisodesTable(this);
  late final $TrackedMoviesTable trackedMovies = $TrackedMoviesTable(this);
  late final $TrackedGamesTable trackedGames = $TrackedGamesTable(this);
  late final $YunaCacheTable yunaCache = $YunaCacheTable(this);
  late final $AnimeSeasonCacheTable animeSeasonCache =
      $AnimeSeasonCacheTable(this);
  late final ShowsDao showsDao = ShowsDao(this as AppDatabase);
  late final MoviesDao moviesDao = MoviesDao(this as AppDatabase);
  late final GamesDao gamesDao = GamesDao(this as AppDatabase);
  late final CacheDao cacheDao = CacheDao(this as AppDatabase);
  late final AnimeCacheDao animeCacheDao = AnimeCacheDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        trackedShows,
        trackedEpisodes,
        trackedSeasons,
        cachedEpisodes,
        trackedMovies,
        trackedGames,
        yunaCache,
        animeSeasonCache
      ];
}

typedef $$TrackedShowsTableCreateCompanionBuilder = TrackedShowsCompanion
    Function({
  Value<int> id,
  required int tmdbId,
  required String title,
  Value<String?> overview,
  Value<String?> posterPath,
  required MediaStatus status,
  Value<double?> userRating,
  Value<String?> userNotes,
  Value<int?> totalSeasons,
  Value<int?> totalEpisodes,
  Value<String?> tmdbStatus,
  Value<bool> isAnime,
  required DateTime addedAt,
  Value<DateTime?> lastWatchedAt,
  Value<int?> nextEpisodeNumber,
  Value<int?> nextEpisodeSeason,
  Value<String?> nextEpisodeName,
  Value<DateTime?> nextEpisodeAirDate,
  Value<DateTime?> updatedAt,
});
typedef $$TrackedShowsTableUpdateCompanionBuilder = TrackedShowsCompanion
    Function({
  Value<int> id,
  Value<int> tmdbId,
  Value<String> title,
  Value<String?> overview,
  Value<String?> posterPath,
  Value<MediaStatus> status,
  Value<double?> userRating,
  Value<String?> userNotes,
  Value<int?> totalSeasons,
  Value<int?> totalEpisodes,
  Value<String?> tmdbStatus,
  Value<bool> isAnime,
  Value<DateTime> addedAt,
  Value<DateTime?> lastWatchedAt,
  Value<int?> nextEpisodeNumber,
  Value<int?> nextEpisodeSeason,
  Value<String?> nextEpisodeName,
  Value<DateTime?> nextEpisodeAirDate,
  Value<DateTime?> updatedAt,
});

final class $$TrackedShowsTableReferences
    extends BaseReferences<_$AppDatabase, $TrackedShowsTable, TrackedShow> {
  $$TrackedShowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackedEpisodesTable, List<TrackedEpisode>>
      _trackedEpisodesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.trackedEpisodes,
              aliasName: $_aliasNameGenerator(
                  db.trackedShows.id, db.trackedEpisodes.showId));

  $$TrackedEpisodesTableProcessedTableManager get trackedEpisodesRefs {
    final manager =
        $$TrackedEpisodesTableTableManager($_db, $_db.trackedEpisodes)
            .filter((f) => f.showId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_trackedEpisodesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TrackedSeasonsTable, List<TrackedSeason>>
      _trackedSeasonsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.trackedSeasons,
              aliasName: $_aliasNameGenerator(
                  db.trackedShows.id, db.trackedSeasons.showId));

  $$TrackedSeasonsTableProcessedTableManager get trackedSeasonsRefs {
    final manager = $$TrackedSeasonsTableTableManager($_db, $_db.trackedSeasons)
        .filter((f) => f.showId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackedSeasonsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TrackedShowsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackedShowsTable> {
  $$TrackedShowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MediaStatus, MediaStatus, String> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get userRating => $composableBuilder(
      column: $table.userRating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSeasons => $composableBuilder(
      column: $table.totalSeasons, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalEpisodes => $composableBuilder(
      column: $table.totalEpisodes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tmdbStatus => $composableBuilder(
      column: $table.tmdbStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAnime => $composableBuilder(
      column: $table.isAnime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastWatchedAt => $composableBuilder(
      column: $table.lastWatchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextEpisodeNumber => $composableBuilder(
      column: $table.nextEpisodeNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextEpisodeSeason => $composableBuilder(
      column: $table.nextEpisodeSeason,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextEpisodeName => $composableBuilder(
      column: $table.nextEpisodeName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextEpisodeAirDate => $composableBuilder(
      column: $table.nextEpisodeAirDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> trackedEpisodesRefs(
      Expression<bool> Function($$TrackedEpisodesTableFilterComposer f) f) {
    final $$TrackedEpisodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trackedEpisodes,
        getReferencedColumn: (t) => t.showId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedEpisodesTableFilterComposer(
              $db: $db,
              $table: $db.trackedEpisodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> trackedSeasonsRefs(
      Expression<bool> Function($$TrackedSeasonsTableFilterComposer f) f) {
    final $$TrackedSeasonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trackedSeasons,
        getReferencedColumn: (t) => t.showId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedSeasonsTableFilterComposer(
              $db: $db,
              $table: $db.trackedSeasons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TrackedShowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackedShowsTable> {
  $$TrackedShowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get userRating => $composableBuilder(
      column: $table.userRating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSeasons => $composableBuilder(
      column: $table.totalSeasons,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalEpisodes => $composableBuilder(
      column: $table.totalEpisodes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tmdbStatus => $composableBuilder(
      column: $table.tmdbStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAnime => $composableBuilder(
      column: $table.isAnime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastWatchedAt => $composableBuilder(
      column: $table.lastWatchedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextEpisodeNumber => $composableBuilder(
      column: $table.nextEpisodeNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextEpisodeSeason => $composableBuilder(
      column: $table.nextEpisodeSeason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextEpisodeName => $composableBuilder(
      column: $table.nextEpisodeName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextEpisodeAirDate => $composableBuilder(
      column: $table.nextEpisodeAirDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TrackedShowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackedShowsTable> {
  $$TrackedShowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get userRating => $composableBuilder(
      column: $table.userRating, builder: (column) => column);

  GeneratedColumn<String> get userNotes =>
      $composableBuilder(column: $table.userNotes, builder: (column) => column);

  GeneratedColumn<int> get totalSeasons => $composableBuilder(
      column: $table.totalSeasons, builder: (column) => column);

  GeneratedColumn<int> get totalEpisodes => $composableBuilder(
      column: $table.totalEpisodes, builder: (column) => column);

  GeneratedColumn<String> get tmdbStatus => $composableBuilder(
      column: $table.tmdbStatus, builder: (column) => column);

  GeneratedColumn<bool> get isAnime =>
      $composableBuilder(column: $table.isAnime, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastWatchedAt => $composableBuilder(
      column: $table.lastWatchedAt, builder: (column) => column);

  GeneratedColumn<int> get nextEpisodeNumber => $composableBuilder(
      column: $table.nextEpisodeNumber, builder: (column) => column);

  GeneratedColumn<int> get nextEpisodeSeason => $composableBuilder(
      column: $table.nextEpisodeSeason, builder: (column) => column);

  GeneratedColumn<String> get nextEpisodeName => $composableBuilder(
      column: $table.nextEpisodeName, builder: (column) => column);

  GeneratedColumn<DateTime> get nextEpisodeAirDate => $composableBuilder(
      column: $table.nextEpisodeAirDate, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> trackedEpisodesRefs<T extends Object>(
      Expression<T> Function($$TrackedEpisodesTableAnnotationComposer a) f) {
    final $$TrackedEpisodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trackedEpisodes,
        getReferencedColumn: (t) => t.showId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedEpisodesTableAnnotationComposer(
              $db: $db,
              $table: $db.trackedEpisodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> trackedSeasonsRefs<T extends Object>(
      Expression<T> Function($$TrackedSeasonsTableAnnotationComposer a) f) {
    final $$TrackedSeasonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trackedSeasons,
        getReferencedColumn: (t) => t.showId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedSeasonsTableAnnotationComposer(
              $db: $db,
              $table: $db.trackedSeasons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TrackedShowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackedShowsTable,
    TrackedShow,
    $$TrackedShowsTableFilterComposer,
    $$TrackedShowsTableOrderingComposer,
    $$TrackedShowsTableAnnotationComposer,
    $$TrackedShowsTableCreateCompanionBuilder,
    $$TrackedShowsTableUpdateCompanionBuilder,
    (TrackedShow, $$TrackedShowsTableReferences),
    TrackedShow,
    PrefetchHooks Function(
        {bool trackedEpisodesRefs, bool trackedSeasonsRefs})> {
  $$TrackedShowsTableTableManager(_$AppDatabase db, $TrackedShowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackedShowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackedShowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackedShowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tmdbId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<String?> posterPath = const Value.absent(),
            Value<MediaStatus> status = const Value.absent(),
            Value<double?> userRating = const Value.absent(),
            Value<String?> userNotes = const Value.absent(),
            Value<int?> totalSeasons = const Value.absent(),
            Value<int?> totalEpisodes = const Value.absent(),
            Value<String?> tmdbStatus = const Value.absent(),
            Value<bool> isAnime = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<DateTime?> lastWatchedAt = const Value.absent(),
            Value<int?> nextEpisodeNumber = const Value.absent(),
            Value<int?> nextEpisodeSeason = const Value.absent(),
            Value<String?> nextEpisodeName = const Value.absent(),
            Value<DateTime?> nextEpisodeAirDate = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              TrackedShowsCompanion(
            id: id,
            tmdbId: tmdbId,
            title: title,
            overview: overview,
            posterPath: posterPath,
            status: status,
            userRating: userRating,
            userNotes: userNotes,
            totalSeasons: totalSeasons,
            totalEpisodes: totalEpisodes,
            tmdbStatus: tmdbStatus,
            isAnime: isAnime,
            addedAt: addedAt,
            lastWatchedAt: lastWatchedAt,
            nextEpisodeNumber: nextEpisodeNumber,
            nextEpisodeSeason: nextEpisodeSeason,
            nextEpisodeName: nextEpisodeName,
            nextEpisodeAirDate: nextEpisodeAirDate,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tmdbId,
            required String title,
            Value<String?> overview = const Value.absent(),
            Value<String?> posterPath = const Value.absent(),
            required MediaStatus status,
            Value<double?> userRating = const Value.absent(),
            Value<String?> userNotes = const Value.absent(),
            Value<int?> totalSeasons = const Value.absent(),
            Value<int?> totalEpisodes = const Value.absent(),
            Value<String?> tmdbStatus = const Value.absent(),
            Value<bool> isAnime = const Value.absent(),
            required DateTime addedAt,
            Value<DateTime?> lastWatchedAt = const Value.absent(),
            Value<int?> nextEpisodeNumber = const Value.absent(),
            Value<int?> nextEpisodeSeason = const Value.absent(),
            Value<String?> nextEpisodeName = const Value.absent(),
            Value<DateTime?> nextEpisodeAirDate = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              TrackedShowsCompanion.insert(
            id: id,
            tmdbId: tmdbId,
            title: title,
            overview: overview,
            posterPath: posterPath,
            status: status,
            userRating: userRating,
            userNotes: userNotes,
            totalSeasons: totalSeasons,
            totalEpisodes: totalEpisodes,
            tmdbStatus: tmdbStatus,
            isAnime: isAnime,
            addedAt: addedAt,
            lastWatchedAt: lastWatchedAt,
            nextEpisodeNumber: nextEpisodeNumber,
            nextEpisodeSeason: nextEpisodeSeason,
            nextEpisodeName: nextEpisodeName,
            nextEpisodeAirDate: nextEpisodeAirDate,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TrackedShowsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {trackedEpisodesRefs = false, trackedSeasonsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (trackedEpisodesRefs) db.trackedEpisodes,
                if (trackedSeasonsRefs) db.trackedSeasons
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackedEpisodesRefs)
                    await $_getPrefetchedData<TrackedShow, $TrackedShowsTable,
                            TrackedEpisode>(
                        currentTable: table,
                        referencedTable: $$TrackedShowsTableReferences
                            ._trackedEpisodesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TrackedShowsTableReferences(db, table, p0)
                                .trackedEpisodesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.showId == item.id),
                        typedResults: items),
                  if (trackedSeasonsRefs)
                    await $_getPrefetchedData<TrackedShow, $TrackedShowsTable,
                            TrackedSeason>(
                        currentTable: table,
                        referencedTable: $$TrackedShowsTableReferences
                            ._trackedSeasonsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TrackedShowsTableReferences(db, table, p0)
                                .trackedSeasonsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.showId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TrackedShowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrackedShowsTable,
    TrackedShow,
    $$TrackedShowsTableFilterComposer,
    $$TrackedShowsTableOrderingComposer,
    $$TrackedShowsTableAnnotationComposer,
    $$TrackedShowsTableCreateCompanionBuilder,
    $$TrackedShowsTableUpdateCompanionBuilder,
    (TrackedShow, $$TrackedShowsTableReferences),
    TrackedShow,
    PrefetchHooks Function(
        {bool trackedEpisodesRefs, bool trackedSeasonsRefs})>;
typedef $$TrackedEpisodesTableCreateCompanionBuilder = TrackedEpisodesCompanion
    Function({
  Value<int> id,
  required int showId,
  required int seasonNumber,
  required int episodeNumber,
  Value<bool> watched,
  Value<DateTime?> updatedAt,
});
typedef $$TrackedEpisodesTableUpdateCompanionBuilder = TrackedEpisodesCompanion
    Function({
  Value<int> id,
  Value<int> showId,
  Value<int> seasonNumber,
  Value<int> episodeNumber,
  Value<bool> watched,
  Value<DateTime?> updatedAt,
});

final class $$TrackedEpisodesTableReferences extends BaseReferences<
    _$AppDatabase, $TrackedEpisodesTable, TrackedEpisode> {
  $$TrackedEpisodesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TrackedShowsTable _showIdTable(_$AppDatabase db) =>
      db.trackedShows.createAlias(
          $_aliasNameGenerator(db.trackedEpisodes.showId, db.trackedShows.id));

  $$TrackedShowsTableProcessedTableManager get showId {
    final $_column = $_itemColumn<int>('show_id')!;

    final manager = $$TrackedShowsTableTableManager($_db, $_db.trackedShows)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_showIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TrackedEpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $TrackedEpisodesTable> {
  $$TrackedEpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get watched => $composableBuilder(
      column: $table.watched, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$TrackedShowsTableFilterComposer get showId {
    final $$TrackedShowsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.showId,
        referencedTable: $db.trackedShows,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedShowsTableFilterComposer(
              $db: $db,
              $table: $db.trackedShows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrackedEpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackedEpisodesTable> {
  $$TrackedEpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get watched => $composableBuilder(
      column: $table.watched, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$TrackedShowsTableOrderingComposer get showId {
    final $$TrackedShowsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.showId,
        referencedTable: $db.trackedShows,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedShowsTableOrderingComposer(
              $db: $db,
              $table: $db.trackedShows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrackedEpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackedEpisodesTable> {
  $$TrackedEpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => column);

  GeneratedColumn<bool> get watched =>
      $composableBuilder(column: $table.watched, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TrackedShowsTableAnnotationComposer get showId {
    final $$TrackedShowsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.showId,
        referencedTable: $db.trackedShows,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedShowsTableAnnotationComposer(
              $db: $db,
              $table: $db.trackedShows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrackedEpisodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackedEpisodesTable,
    TrackedEpisode,
    $$TrackedEpisodesTableFilterComposer,
    $$TrackedEpisodesTableOrderingComposer,
    $$TrackedEpisodesTableAnnotationComposer,
    $$TrackedEpisodesTableCreateCompanionBuilder,
    $$TrackedEpisodesTableUpdateCompanionBuilder,
    (TrackedEpisode, $$TrackedEpisodesTableReferences),
    TrackedEpisode,
    PrefetchHooks Function({bool showId})> {
  $$TrackedEpisodesTableTableManager(
      _$AppDatabase db, $TrackedEpisodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackedEpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackedEpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackedEpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> showId = const Value.absent(),
            Value<int> seasonNumber = const Value.absent(),
            Value<int> episodeNumber = const Value.absent(),
            Value<bool> watched = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              TrackedEpisodesCompanion(
            id: id,
            showId: showId,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            watched: watched,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int showId,
            required int seasonNumber,
            required int episodeNumber,
            Value<bool> watched = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              TrackedEpisodesCompanion.insert(
            id: id,
            showId: showId,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            watched: watched,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TrackedEpisodesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({showId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (showId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.showId,
                    referencedTable:
                        $$TrackedEpisodesTableReferences._showIdTable(db),
                    referencedColumn:
                        $$TrackedEpisodesTableReferences._showIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TrackedEpisodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrackedEpisodesTable,
    TrackedEpisode,
    $$TrackedEpisodesTableFilterComposer,
    $$TrackedEpisodesTableOrderingComposer,
    $$TrackedEpisodesTableAnnotationComposer,
    $$TrackedEpisodesTableCreateCompanionBuilder,
    $$TrackedEpisodesTableUpdateCompanionBuilder,
    (TrackedEpisode, $$TrackedEpisodesTableReferences),
    TrackedEpisode,
    PrefetchHooks Function({bool showId})>;
typedef $$TrackedSeasonsTableCreateCompanionBuilder = TrackedSeasonsCompanion
    Function({
  Value<int> id,
  required int showId,
  required int seasonNumber,
  required int episodeCount,
});
typedef $$TrackedSeasonsTableUpdateCompanionBuilder = TrackedSeasonsCompanion
    Function({
  Value<int> id,
  Value<int> showId,
  Value<int> seasonNumber,
  Value<int> episodeCount,
});

final class $$TrackedSeasonsTableReferences
    extends BaseReferences<_$AppDatabase, $TrackedSeasonsTable, TrackedSeason> {
  $$TrackedSeasonsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TrackedShowsTable _showIdTable(_$AppDatabase db) =>
      db.trackedShows.createAlias(
          $_aliasNameGenerator(db.trackedSeasons.showId, db.trackedShows.id));

  $$TrackedShowsTableProcessedTableManager get showId {
    final $_column = $_itemColumn<int>('show_id')!;

    final manager = $$TrackedShowsTableTableManager($_db, $_db.trackedShows)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_showIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TrackedSeasonsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackedSeasonsTable> {
  $$TrackedSeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount, builder: (column) => ColumnFilters(column));

  $$TrackedShowsTableFilterComposer get showId {
    final $$TrackedShowsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.showId,
        referencedTable: $db.trackedShows,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedShowsTableFilterComposer(
              $db: $db,
              $table: $db.trackedShows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrackedSeasonsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackedSeasonsTable> {
  $$TrackedSeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount,
      builder: (column) => ColumnOrderings(column));

  $$TrackedShowsTableOrderingComposer get showId {
    final $$TrackedShowsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.showId,
        referencedTable: $db.trackedShows,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedShowsTableOrderingComposer(
              $db: $db,
              $table: $db.trackedShows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrackedSeasonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackedSeasonsTable> {
  $$TrackedSeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount, builder: (column) => column);

  $$TrackedShowsTableAnnotationComposer get showId {
    final $$TrackedShowsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.showId,
        referencedTable: $db.trackedShows,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackedShowsTableAnnotationComposer(
              $db: $db,
              $table: $db.trackedShows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrackedSeasonsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackedSeasonsTable,
    TrackedSeason,
    $$TrackedSeasonsTableFilterComposer,
    $$TrackedSeasonsTableOrderingComposer,
    $$TrackedSeasonsTableAnnotationComposer,
    $$TrackedSeasonsTableCreateCompanionBuilder,
    $$TrackedSeasonsTableUpdateCompanionBuilder,
    (TrackedSeason, $$TrackedSeasonsTableReferences),
    TrackedSeason,
    PrefetchHooks Function({bool showId})> {
  $$TrackedSeasonsTableTableManager(
      _$AppDatabase db, $TrackedSeasonsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackedSeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackedSeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackedSeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> showId = const Value.absent(),
            Value<int> seasonNumber = const Value.absent(),
            Value<int> episodeCount = const Value.absent(),
          }) =>
              TrackedSeasonsCompanion(
            id: id,
            showId: showId,
            seasonNumber: seasonNumber,
            episodeCount: episodeCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int showId,
            required int seasonNumber,
            required int episodeCount,
          }) =>
              TrackedSeasonsCompanion.insert(
            id: id,
            showId: showId,
            seasonNumber: seasonNumber,
            episodeCount: episodeCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TrackedSeasonsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({showId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (showId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.showId,
                    referencedTable:
                        $$TrackedSeasonsTableReferences._showIdTable(db),
                    referencedColumn:
                        $$TrackedSeasonsTableReferences._showIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TrackedSeasonsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrackedSeasonsTable,
    TrackedSeason,
    $$TrackedSeasonsTableFilterComposer,
    $$TrackedSeasonsTableOrderingComposer,
    $$TrackedSeasonsTableAnnotationComposer,
    $$TrackedSeasonsTableCreateCompanionBuilder,
    $$TrackedSeasonsTableUpdateCompanionBuilder,
    (TrackedSeason, $$TrackedSeasonsTableReferences),
    TrackedSeason,
    PrefetchHooks Function({bool showId})>;
typedef $$CachedEpisodesTableCreateCompanionBuilder = CachedEpisodesCompanion
    Function({
  Value<int> id,
  required int tmdbShowId,
  required int seasonNumber,
  required int episodeNumber,
  required String name,
  Value<String?> overview,
  Value<String?> stillPath,
  Value<String?> airDate,
  Value<double?> voteAverage,
  Value<int?> absoluteEpisodeNumber,
  Value<DateTime?> airingAt,
  required DateTime cachedAt,
});
typedef $$CachedEpisodesTableUpdateCompanionBuilder = CachedEpisodesCompanion
    Function({
  Value<int> id,
  Value<int> tmdbShowId,
  Value<int> seasonNumber,
  Value<int> episodeNumber,
  Value<String> name,
  Value<String?> overview,
  Value<String?> stillPath,
  Value<String?> airDate,
  Value<double?> voteAverage,
  Value<int?> absoluteEpisodeNumber,
  Value<DateTime?> airingAt,
  Value<DateTime> cachedAt,
});

class $$CachedEpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedEpisodesTable> {
  $$CachedEpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tmdbShowId => $composableBuilder(
      column: $table.tmdbShowId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stillPath => $composableBuilder(
      column: $table.stillPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get airDate => $composableBuilder(
      column: $table.airDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get absoluteEpisodeNumber => $composableBuilder(
      column: $table.absoluteEpisodeNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get airingAt => $composableBuilder(
      column: $table.airingAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedEpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedEpisodesTable> {
  $$CachedEpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tmdbShowId => $composableBuilder(
      column: $table.tmdbShowId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stillPath => $composableBuilder(
      column: $table.stillPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get airDate => $composableBuilder(
      column: $table.airDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get absoluteEpisodeNumber => $composableBuilder(
      column: $table.absoluteEpisodeNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get airingAt => $composableBuilder(
      column: $table.airingAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedEpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedEpisodesTable> {
  $$CachedEpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tmdbShowId => $composableBuilder(
      column: $table.tmdbShowId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get stillPath =>
      $composableBuilder(column: $table.stillPath, builder: (column) => column);

  GeneratedColumn<String> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => column);

  GeneratedColumn<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => column);

  GeneratedColumn<int> get absoluteEpisodeNumber => $composableBuilder(
      column: $table.absoluteEpisodeNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get airingAt =>
      $composableBuilder(column: $table.airingAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedEpisodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedEpisodesTable,
    CachedEpisode,
    $$CachedEpisodesTableFilterComposer,
    $$CachedEpisodesTableOrderingComposer,
    $$CachedEpisodesTableAnnotationComposer,
    $$CachedEpisodesTableCreateCompanionBuilder,
    $$CachedEpisodesTableUpdateCompanionBuilder,
    (
      CachedEpisode,
      BaseReferences<_$AppDatabase, $CachedEpisodesTable, CachedEpisode>
    ),
    CachedEpisode,
    PrefetchHooks Function()> {
  $$CachedEpisodesTableTableManager(
      _$AppDatabase db, $CachedEpisodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedEpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedEpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedEpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tmdbShowId = const Value.absent(),
            Value<int> seasonNumber = const Value.absent(),
            Value<int> episodeNumber = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<String?> stillPath = const Value.absent(),
            Value<String?> airDate = const Value.absent(),
            Value<double?> voteAverage = const Value.absent(),
            Value<int?> absoluteEpisodeNumber = const Value.absent(),
            Value<DateTime?> airingAt = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              CachedEpisodesCompanion(
            id: id,
            tmdbShowId: tmdbShowId,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            name: name,
            overview: overview,
            stillPath: stillPath,
            airDate: airDate,
            voteAverage: voteAverage,
            absoluteEpisodeNumber: absoluteEpisodeNumber,
            airingAt: airingAt,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tmdbShowId,
            required int seasonNumber,
            required int episodeNumber,
            required String name,
            Value<String?> overview = const Value.absent(),
            Value<String?> stillPath = const Value.absent(),
            Value<String?> airDate = const Value.absent(),
            Value<double?> voteAverage = const Value.absent(),
            Value<int?> absoluteEpisodeNumber = const Value.absent(),
            Value<DateTime?> airingAt = const Value.absent(),
            required DateTime cachedAt,
          }) =>
              CachedEpisodesCompanion.insert(
            id: id,
            tmdbShowId: tmdbShowId,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            name: name,
            overview: overview,
            stillPath: stillPath,
            airDate: airDate,
            voteAverage: voteAverage,
            absoluteEpisodeNumber: absoluteEpisodeNumber,
            airingAt: airingAt,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedEpisodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedEpisodesTable,
    CachedEpisode,
    $$CachedEpisodesTableFilterComposer,
    $$CachedEpisodesTableOrderingComposer,
    $$CachedEpisodesTableAnnotationComposer,
    $$CachedEpisodesTableCreateCompanionBuilder,
    $$CachedEpisodesTableUpdateCompanionBuilder,
    (
      CachedEpisode,
      BaseReferences<_$AppDatabase, $CachedEpisodesTable, CachedEpisode>
    ),
    CachedEpisode,
    PrefetchHooks Function()>;
typedef $$TrackedMoviesTableCreateCompanionBuilder = TrackedMoviesCompanion
    Function({
  Value<int> id,
  required int tmdbId,
  required String title,
  Value<String?> overview,
  Value<String?> posterPath,
  required MediaStatus status,
  Value<double?> userRating,
  Value<String?> userNotes,
  Value<int?> releaseYear,
  Value<DateTime?> releaseDate,
  required DateTime addedAt,
  Value<DateTime?> updatedAt,
});
typedef $$TrackedMoviesTableUpdateCompanionBuilder = TrackedMoviesCompanion
    Function({
  Value<int> id,
  Value<int> tmdbId,
  Value<String> title,
  Value<String?> overview,
  Value<String?> posterPath,
  Value<MediaStatus> status,
  Value<double?> userRating,
  Value<String?> userNotes,
  Value<int?> releaseYear,
  Value<DateTime?> releaseDate,
  Value<DateTime> addedAt,
  Value<DateTime?> updatedAt,
});

class $$TrackedMoviesTableFilterComposer
    extends Composer<_$AppDatabase, $TrackedMoviesTable> {
  $$TrackedMoviesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MediaStatus, MediaStatus, String> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get userRating => $composableBuilder(
      column: $table.userRating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get releaseYear => $composableBuilder(
      column: $table.releaseYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TrackedMoviesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackedMoviesTable> {
  $$TrackedMoviesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get userRating => $composableBuilder(
      column: $table.userRating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get releaseYear => $composableBuilder(
      column: $table.releaseYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TrackedMoviesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackedMoviesTable> {
  $$TrackedMoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get userRating => $composableBuilder(
      column: $table.userRating, builder: (column) => column);

  GeneratedColumn<String> get userNotes =>
      $composableBuilder(column: $table.userNotes, builder: (column) => column);

  GeneratedColumn<int> get releaseYear => $composableBuilder(
      column: $table.releaseYear, builder: (column) => column);

  GeneratedColumn<DateTime> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TrackedMoviesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackedMoviesTable,
    TrackedMovy,
    $$TrackedMoviesTableFilterComposer,
    $$TrackedMoviesTableOrderingComposer,
    $$TrackedMoviesTableAnnotationComposer,
    $$TrackedMoviesTableCreateCompanionBuilder,
    $$TrackedMoviesTableUpdateCompanionBuilder,
    (
      TrackedMovy,
      BaseReferences<_$AppDatabase, $TrackedMoviesTable, TrackedMovy>
    ),
    TrackedMovy,
    PrefetchHooks Function()> {
  $$TrackedMoviesTableTableManager(_$AppDatabase db, $TrackedMoviesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackedMoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackedMoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackedMoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tmdbId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<String?> posterPath = const Value.absent(),
            Value<MediaStatus> status = const Value.absent(),
            Value<double?> userRating = const Value.absent(),
            Value<String?> userNotes = const Value.absent(),
            Value<int?> releaseYear = const Value.absent(),
            Value<DateTime?> releaseDate = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              TrackedMoviesCompanion(
            id: id,
            tmdbId: tmdbId,
            title: title,
            overview: overview,
            posterPath: posterPath,
            status: status,
            userRating: userRating,
            userNotes: userNotes,
            releaseYear: releaseYear,
            releaseDate: releaseDate,
            addedAt: addedAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tmdbId,
            required String title,
            Value<String?> overview = const Value.absent(),
            Value<String?> posterPath = const Value.absent(),
            required MediaStatus status,
            Value<double?> userRating = const Value.absent(),
            Value<String?> userNotes = const Value.absent(),
            Value<int?> releaseYear = const Value.absent(),
            Value<DateTime?> releaseDate = const Value.absent(),
            required DateTime addedAt,
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              TrackedMoviesCompanion.insert(
            id: id,
            tmdbId: tmdbId,
            title: title,
            overview: overview,
            posterPath: posterPath,
            status: status,
            userRating: userRating,
            userNotes: userNotes,
            releaseYear: releaseYear,
            releaseDate: releaseDate,
            addedAt: addedAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TrackedMoviesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrackedMoviesTable,
    TrackedMovy,
    $$TrackedMoviesTableFilterComposer,
    $$TrackedMoviesTableOrderingComposer,
    $$TrackedMoviesTableAnnotationComposer,
    $$TrackedMoviesTableCreateCompanionBuilder,
    $$TrackedMoviesTableUpdateCompanionBuilder,
    (
      TrackedMovy,
      BaseReferences<_$AppDatabase, $TrackedMoviesTable, TrackedMovy>
    ),
    TrackedMovy,
    PrefetchHooks Function()>;
typedef $$TrackedGamesTableCreateCompanionBuilder = TrackedGamesCompanion
    Function({
  Value<int> id,
  required int rawgId,
  required String title,
  Value<String?> coverUrl,
  required MediaStatus status,
  Value<double?> userRating,
  Value<String?> userNotes,
  required DateTime addedAt,
  Value<DateTime?> releaseDate,
  Value<int?> playtime,
  Value<String?> platforms,
  Value<double?> voteAverage,
  Value<DateTime?> updatedAt,
});
typedef $$TrackedGamesTableUpdateCompanionBuilder = TrackedGamesCompanion
    Function({
  Value<int> id,
  Value<int> rawgId,
  Value<String> title,
  Value<String?> coverUrl,
  Value<MediaStatus> status,
  Value<double?> userRating,
  Value<String?> userNotes,
  Value<DateTime> addedAt,
  Value<DateTime?> releaseDate,
  Value<int?> playtime,
  Value<String?> platforms,
  Value<double?> voteAverage,
  Value<DateTime?> updatedAt,
});

class $$TrackedGamesTableFilterComposer
    extends Composer<_$AppDatabase, $TrackedGamesTable> {
  $$TrackedGamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rawgId => $composableBuilder(
      column: $table.rawgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MediaStatus, MediaStatus, String> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get userRating => $composableBuilder(
      column: $table.userRating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playtime => $composableBuilder(
      column: $table.playtime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platforms => $composableBuilder(
      column: $table.platforms, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TrackedGamesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackedGamesTable> {
  $$TrackedGamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rawgId => $composableBuilder(
      column: $table.rawgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get userRating => $composableBuilder(
      column: $table.userRating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playtime => $composableBuilder(
      column: $table.playtime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platforms => $composableBuilder(
      column: $table.platforms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TrackedGamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackedGamesTable> {
  $$TrackedGamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rawgId =>
      $composableBuilder(column: $table.rawgId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get userRating => $composableBuilder(
      column: $table.userRating, builder: (column) => column);

  GeneratedColumn<String> get userNotes =>
      $composableBuilder(column: $table.userNotes, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => column);

  GeneratedColumn<int> get playtime =>
      $composableBuilder(column: $table.playtime, builder: (column) => column);

  GeneratedColumn<String> get platforms =>
      $composableBuilder(column: $table.platforms, builder: (column) => column);

  GeneratedColumn<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TrackedGamesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackedGamesTable,
    TrackedGame,
    $$TrackedGamesTableFilterComposer,
    $$TrackedGamesTableOrderingComposer,
    $$TrackedGamesTableAnnotationComposer,
    $$TrackedGamesTableCreateCompanionBuilder,
    $$TrackedGamesTableUpdateCompanionBuilder,
    (
      TrackedGame,
      BaseReferences<_$AppDatabase, $TrackedGamesTable, TrackedGame>
    ),
    TrackedGame,
    PrefetchHooks Function()> {
  $$TrackedGamesTableTableManager(_$AppDatabase db, $TrackedGamesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackedGamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackedGamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackedGamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> rawgId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<MediaStatus> status = const Value.absent(),
            Value<double?> userRating = const Value.absent(),
            Value<String?> userNotes = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<DateTime?> releaseDate = const Value.absent(),
            Value<int?> playtime = const Value.absent(),
            Value<String?> platforms = const Value.absent(),
            Value<double?> voteAverage = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              TrackedGamesCompanion(
            id: id,
            rawgId: rawgId,
            title: title,
            coverUrl: coverUrl,
            status: status,
            userRating: userRating,
            userNotes: userNotes,
            addedAt: addedAt,
            releaseDate: releaseDate,
            playtime: playtime,
            platforms: platforms,
            voteAverage: voteAverage,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int rawgId,
            required String title,
            Value<String?> coverUrl = const Value.absent(),
            required MediaStatus status,
            Value<double?> userRating = const Value.absent(),
            Value<String?> userNotes = const Value.absent(),
            required DateTime addedAt,
            Value<DateTime?> releaseDate = const Value.absent(),
            Value<int?> playtime = const Value.absent(),
            Value<String?> platforms = const Value.absent(),
            Value<double?> voteAverage = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              TrackedGamesCompanion.insert(
            id: id,
            rawgId: rawgId,
            title: title,
            coverUrl: coverUrl,
            status: status,
            userRating: userRating,
            userNotes: userNotes,
            addedAt: addedAt,
            releaseDate: releaseDate,
            playtime: playtime,
            platforms: platforms,
            voteAverage: voteAverage,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TrackedGamesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrackedGamesTable,
    TrackedGame,
    $$TrackedGamesTableFilterComposer,
    $$TrackedGamesTableOrderingComposer,
    $$TrackedGamesTableAnnotationComposer,
    $$TrackedGamesTableCreateCompanionBuilder,
    $$TrackedGamesTableUpdateCompanionBuilder,
    (
      TrackedGame,
      BaseReferences<_$AppDatabase, $TrackedGamesTable, TrackedGame>
    ),
    TrackedGame,
    PrefetchHooks Function()>;
typedef $$YunaCacheTableCreateCompanionBuilder = YunaCacheCompanion Function({
  Value<int> tmdbId,
  required String anilistIdsJson,
  required DateTime cachedAt,
});
typedef $$YunaCacheTableUpdateCompanionBuilder = YunaCacheCompanion Function({
  Value<int> tmdbId,
  Value<String> anilistIdsJson,
  Value<DateTime> cachedAt,
});

class $$YunaCacheTableFilterComposer
    extends Composer<_$AppDatabase, $YunaCacheTable> {
  $$YunaCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get anilistIdsJson => $composableBuilder(
      column: $table.anilistIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$YunaCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $YunaCacheTable> {
  $$YunaCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get anilistIdsJson => $composableBuilder(
      column: $table.anilistIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$YunaCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $YunaCacheTable> {
  $$YunaCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get anilistIdsJson => $composableBuilder(
      column: $table.anilistIdsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$YunaCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $YunaCacheTable,
    YunaCacheData,
    $$YunaCacheTableFilterComposer,
    $$YunaCacheTableOrderingComposer,
    $$YunaCacheTableAnnotationComposer,
    $$YunaCacheTableCreateCompanionBuilder,
    $$YunaCacheTableUpdateCompanionBuilder,
    (
      YunaCacheData,
      BaseReferences<_$AppDatabase, $YunaCacheTable, YunaCacheData>
    ),
    YunaCacheData,
    PrefetchHooks Function()> {
  $$YunaCacheTableTableManager(_$AppDatabase db, $YunaCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$YunaCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$YunaCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$YunaCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> tmdbId = const Value.absent(),
            Value<String> anilistIdsJson = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              YunaCacheCompanion(
            tmdbId: tmdbId,
            anilistIdsJson: anilistIdsJson,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> tmdbId = const Value.absent(),
            required String anilistIdsJson,
            required DateTime cachedAt,
          }) =>
              YunaCacheCompanion.insert(
            tmdbId: tmdbId,
            anilistIdsJson: anilistIdsJson,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$YunaCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $YunaCacheTable,
    YunaCacheData,
    $$YunaCacheTableFilterComposer,
    $$YunaCacheTableOrderingComposer,
    $$YunaCacheTableAnnotationComposer,
    $$YunaCacheTableCreateCompanionBuilder,
    $$YunaCacheTableUpdateCompanionBuilder,
    (
      YunaCacheData,
      BaseReferences<_$AppDatabase, $YunaCacheTable, YunaCacheData>
    ),
    YunaCacheData,
    PrefetchHooks Function()>;
typedef $$AnimeSeasonCacheTableCreateCompanionBuilder
    = AnimeSeasonCacheCompanion Function({
  Value<int> id,
  required int tmdbShowId,
  required int seasonNumber,
  required int anilistId,
  required int episodeCount,
  required String status,
  required String animeSeasonJson,
  required DateTime cachedAt,
  required DateTime validUntil,
});
typedef $$AnimeSeasonCacheTableUpdateCompanionBuilder
    = AnimeSeasonCacheCompanion Function({
  Value<int> id,
  Value<int> tmdbShowId,
  Value<int> seasonNumber,
  Value<int> anilistId,
  Value<int> episodeCount,
  Value<String> status,
  Value<String> animeSeasonJson,
  Value<DateTime> cachedAt,
  Value<DateTime> validUntil,
});

class $$AnimeSeasonCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AnimeSeasonCacheTable> {
  $$AnimeSeasonCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tmdbShowId => $composableBuilder(
      column: $table.tmdbShowId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get anilistId => $composableBuilder(
      column: $table.anilistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get animeSeasonJson => $composableBuilder(
      column: $table.animeSeasonJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get validUntil => $composableBuilder(
      column: $table.validUntil, builder: (column) => ColumnFilters(column));
}

class $$AnimeSeasonCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AnimeSeasonCacheTable> {
  $$AnimeSeasonCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tmdbShowId => $composableBuilder(
      column: $table.tmdbShowId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anilistId => $composableBuilder(
      column: $table.anilistId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get animeSeasonJson => $composableBuilder(
      column: $table.animeSeasonJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get validUntil => $composableBuilder(
      column: $table.validUntil, builder: (column) => ColumnOrderings(column));
}

class $$AnimeSeasonCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnimeSeasonCacheTable> {
  $$AnimeSeasonCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tmdbShowId => $composableBuilder(
      column: $table.tmdbShowId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<int> get anilistId =>
      $composableBuilder(column: $table.anilistId, builder: (column) => column);

  GeneratedColumn<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get animeSeasonJson => $composableBuilder(
      column: $table.animeSeasonJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get validUntil => $composableBuilder(
      column: $table.validUntil, builder: (column) => column);
}

class $$AnimeSeasonCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnimeSeasonCacheTable,
    AnimeSeasonCacheData,
    $$AnimeSeasonCacheTableFilterComposer,
    $$AnimeSeasonCacheTableOrderingComposer,
    $$AnimeSeasonCacheTableAnnotationComposer,
    $$AnimeSeasonCacheTableCreateCompanionBuilder,
    $$AnimeSeasonCacheTableUpdateCompanionBuilder,
    (
      AnimeSeasonCacheData,
      BaseReferences<_$AppDatabase, $AnimeSeasonCacheTable,
          AnimeSeasonCacheData>
    ),
    AnimeSeasonCacheData,
    PrefetchHooks Function()> {
  $$AnimeSeasonCacheTableTableManager(
      _$AppDatabase db, $AnimeSeasonCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnimeSeasonCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnimeSeasonCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnimeSeasonCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tmdbShowId = const Value.absent(),
            Value<int> seasonNumber = const Value.absent(),
            Value<int> anilistId = const Value.absent(),
            Value<int> episodeCount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> animeSeasonJson = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<DateTime> validUntil = const Value.absent(),
          }) =>
              AnimeSeasonCacheCompanion(
            id: id,
            tmdbShowId: tmdbShowId,
            seasonNumber: seasonNumber,
            anilistId: anilistId,
            episodeCount: episodeCount,
            status: status,
            animeSeasonJson: animeSeasonJson,
            cachedAt: cachedAt,
            validUntil: validUntil,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tmdbShowId,
            required int seasonNumber,
            required int anilistId,
            required int episodeCount,
            required String status,
            required String animeSeasonJson,
            required DateTime cachedAt,
            required DateTime validUntil,
          }) =>
              AnimeSeasonCacheCompanion.insert(
            id: id,
            tmdbShowId: tmdbShowId,
            seasonNumber: seasonNumber,
            anilistId: anilistId,
            episodeCount: episodeCount,
            status: status,
            animeSeasonJson: animeSeasonJson,
            cachedAt: cachedAt,
            validUntil: validUntil,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnimeSeasonCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnimeSeasonCacheTable,
    AnimeSeasonCacheData,
    $$AnimeSeasonCacheTableFilterComposer,
    $$AnimeSeasonCacheTableOrderingComposer,
    $$AnimeSeasonCacheTableAnnotationComposer,
    $$AnimeSeasonCacheTableCreateCompanionBuilder,
    $$AnimeSeasonCacheTableUpdateCompanionBuilder,
    (
      AnimeSeasonCacheData,
      BaseReferences<_$AppDatabase, $AnimeSeasonCacheTable,
          AnimeSeasonCacheData>
    ),
    AnimeSeasonCacheData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TrackedShowsTableTableManager get trackedShows =>
      $$TrackedShowsTableTableManager(_db, _db.trackedShows);
  $$TrackedEpisodesTableTableManager get trackedEpisodes =>
      $$TrackedEpisodesTableTableManager(_db, _db.trackedEpisodes);
  $$TrackedSeasonsTableTableManager get trackedSeasons =>
      $$TrackedSeasonsTableTableManager(_db, _db.trackedSeasons);
  $$CachedEpisodesTableTableManager get cachedEpisodes =>
      $$CachedEpisodesTableTableManager(_db, _db.cachedEpisodes);
  $$TrackedMoviesTableTableManager get trackedMovies =>
      $$TrackedMoviesTableTableManager(_db, _db.trackedMovies);
  $$TrackedGamesTableTableManager get trackedGames =>
      $$TrackedGamesTableTableManager(_db, _db.trackedGames);
  $$YunaCacheTableTableManager get yunaCache =>
      $$YunaCacheTableTableManager(_db, _db.yunaCache);
  $$AnimeSeasonCacheTableTableManager get animeSeasonCache =>
      $$AnimeSeasonCacheTableTableManager(_db, _db.animeSeasonCache);
}
