import 'package:flutter/material.dart';
import 'package:flutter_music_player/dao/music_163.dart';
import 'package:flutter_music_player/dao/music_db_playlist.dart';
import 'package:flutter_music_player/widget/play_list_item.dart';

class PlayListTabPage extends StatefulWidget {
  static const TYPE_DB = 'db'; // 表示从数据库去取
  final String type;
  final String heroTag;
  final String error;
  PlayListTabPage(
      {Key key, required this.type, this.heroTag = 'from_list', this.error})
      : super(key: key);

  @override
  _PlayListTabPageState createState() => _PlayListTabPageState();
}

class _PlayListTabPageState extends State<PlayListTabPage> {
  List _playlist;

  _getPlaylists() async {
    try {
      if (widget.type == PlayListTabPage.TYPE_DB) {
        _playlist = await PlayListDB().getPlayList();
      } else {
        _playlist = await MusicDao.getPlayList(widget.type);
      }
    } catch (e) {
      print('Failed: $e');
    }

    // 界面未加载或者已关闭,返回。
    if (!mounted) return;
    setState(() {
      _playlist = _playlist;
    });
  }

  @override
  void initState() {
    super.initState();
    print("PlayList: initState ${widget.type}");
    _getPlaylists();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (this._playlist == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (this._playlist.length == 0) {
      return _getErrorView(widget.error);
    } else {
      return GridView.builder(
        itemCount: this._playlist == null ? 0 : this._playlist.length,
        padding: EdgeInsets.all(6.0), // 四周边距,注意Card也有默认的边距
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // 网格样式
            crossAxisCount: 2, // 列数
            mainAxisSpacing: 2.0, // 主轴的间距
            crossAxisSpacing: 2.0, // cross轴间距
            childAspectRatio: 1 // item横竖比
            ),
        itemBuilder: (context, index) => _bulidItem(context, index),
      );
    }
  }

  _bulidItem(BuildContext context, int index) {
    Map play = _playlist[index];
    return Card(
      elevation: 4.0,
      child: PlayListItem(play, heroTag: widget.heroTag),
    );
  }

  _getErrorView(String error) {
    if (error == null) {
      error = '加载失败';
    }
    return Center(
        child: Text(
      error,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey, height: 1.5),
    ));
  }
}
