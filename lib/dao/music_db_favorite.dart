import 'package:flutter_music_player/model/song_util.dart';
import 'package:sqflite/sqflite.dart';

import 'music_db.dart';

class FavoriteDB {
  static const table_name = 't_favorite';

  /// 单例对象的写法
  // 私有静态instance
  static FavoriteDB? _instance;

  // 对外访问点,指向私有静态方法
  factory FavoriteDB() => _getInstance();

  static FavoriteDB _getInstance() {
    return _instance ??= FavoriteDB._();
  }

  // 将默认构造函数私有化
  FavoriteDB._();

  /// 在数据库onCreate的时候,创建表。
  /// 注意：onUpgrade中添加的字段要在这儿添加,不然第一次安装就没有那个字段了。
  createTable(Database db) {
    db.execute('''create table $table_name (
          id integer primary key,
          name text not null,
          artist text,
          cover text,
          url text,
          createTime integer)
    ''');
  }

  Future<int> addFavorite(Map song) async {
    var fav = {
      'id': song['id'],
      'name': song['name'],
      'artist': SongUtil.getArtistNames(song),
      'cover': SongUtil.getSongImage(song, size: 0),
      'url': SongUtil.getSongUrl(song),
      // 查看sqflite文档,发现不支持DateTime字段,用int来存储。
      'createTime': DateTime.now().millisecondsSinceEpoch,
    };

    return (await MusicDB().getDB()).insert(table_name, fav);
  }

  Future<int> updateFavorite(Map song) async {
    var fav = {
      'cover': song['imageUrl'],
    };

    return (await MusicDB().getDB())
        .update(table_name, fav, where: 'id = ${song['id']}');
  }

  Future<List> getFavoriteList() async {
    Database db = await MusicDB().getDB();
    List list = await db.query(table_name, orderBy: 'createTime desc');
    List songs = list
        .map((fav) => {
              'id': fav['id'],
              'name': fav['name'],
              'artistNames': fav['artist'],
              'imageUrl': fav['cover']
            })
        .toList();

    return songs;
  }

  Future<Map<String, dynamic>> getFavoriteById(var id) async {
    Database db = await MusicDB().getDB();
    List list = await db.query(table_name, where: 'id = ?', whereArgs: [id]);
    return list.length > 0 ? list[0] : null;
  }

  Future<int> deleteFavorite(var id) async {
    Database db = await MusicDB().getDB();
    int re = await db.delete(table_name, where: 'id = ?', whereArgs: [id]);
    if (re <= 0) {
      throw Exception('删除失败');
    } else {
      return re;
    }
  }
}
