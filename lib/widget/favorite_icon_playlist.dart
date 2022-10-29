import 'package:flutter/material.dart';
import 'package:flutter_music_player/dao/music_db_playlist.dart';

class FavoritePlayListIcon extends StatefulWidget {
  final Map play;
  const FavoritePlayListIcon(this.play, {Key? key}) : super(key: key);

  @override
  _FavoritePlayListIconState createState() => _FavoritePlayListIconState();
}

class _FavoritePlayListIconState extends State<FavoritePlayListIcon> {
  bool _isFavorited = false;
  late Map _play;

  void _checkFavorite() {
    PlayListDB().getPlayListById(_play['id']).then((Map<String, dynamic>? fav) {
      //print('getFavoriteById : $fav');
      setState(() {
        _isFavorited = fav != null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.play != _play) {
      _play = widget.play;
      _checkFavorite();
    }
    return IconButton(
      icon: Icon(
        Icons.favorite,
        color: _isFavorited ? Colors.white : Colors.white30,
      ),
      onPressed: () {
        if (this._isFavorited) {
          _cancelFavorite(context);
        } else {
          _addFavorite(context);
        }
      },
    );
  }

  void _addFavorite(context) {
    PlayListDB().addPlayList(widget.play).then((re) {
      print('addFavorite re: $re , play: ${widget.play}');
      setState(() {
        _isFavorited = true;
      });
    }).catchError((error) {
      print('addFavorite error: $error');
    });
  }

  void _cancelFavorite(context) {
    PlayListDB().deletePlayList(widget.play['id']).then((re) {
      setState(() {
        _isFavorited = false;
      });
    }).catchError((error) {
      print('deleteFavorite error: $error');
      throw Exception('取消收藏失败');
    });
  }
}
