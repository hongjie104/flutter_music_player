import 'package:flutter/material.dart';
import 'package:flutter_music_player/dao/music_163.dart';
import 'package:flutter_music_player/model/Lyric.dart';
import 'package:flutter_music_player/utils/screen_size.dart';
import 'package:flutter_music_player/utils/shared_preference_util.dart';

import 'gradient_text.dart';

class LyricPage extends StatefulWidget {
  _LyricPageState? _state;

  LyricPage({Key? key}) : super(key: key);

  @override
  _LyricPageState createState() {
    _state = _LyricPageState();
    return _state!;
  }

  // 对比发现,从外面调用触发build的次数要少,而不是从父控件传入position。

  int updatePositionCount = 0;
  void updatePosition(int position, {isTaping: false}) {
    //print('updatePosition: $position');
    if (_state == null) {
      if (updatePositionCount > 5) {
        return;
      }
      print('_LyricPageState is null, retryCount: $updatePositionCount');
      Future.delayed(Duration(milliseconds: 200)).then((_) {
        updatePositionCount++;
        updatePosition(position, isTaping: isTaping);
      });
    } else {
      updatePositionCount = 0;
      _state!.updatePosition(position, isTaping: isTaping);
    }
  }

  int updateSongCount = 0;
  void updateSong(Map song) {
    if (_state == null) {
      if (updateSongCount > 5) {
        return;
      }
      print('_LyricPageState is null, retryCount: $updateSongCount');
      Future.delayed(Duration(milliseconds: 200)).then((_) {
        updateSongCount++;
        updateSong(song);
      });
    } else {
      updateSongCount = 0;
      _state!.updateSong(song);
    }
  }
}

class _LyricPageState extends State<LyricPage> {
  Map song;
  final double itemHeight = 30.0;
  int visibleItemSize = 7;
  Lyric lyric;
  ScrollController _controller;
  int _currentIndex = -1;
  int position = 0;
  bool success = true;
  bool isFirst = true;
  bool isItemsEmpty = false;
  bool islyricMask = true;

  @override
  void initState() {
    super.initState();

    visibleItemSize = ScreenSize.height < 700 ? 5 : 7;
    _controller = ScrollController();

    islyricMask = SharedPreferenceUtil.getInstance().get('lyricMask') ?? true;

    print('LyricPage initState, 歌词可见行数：$visibleItemSize');
  }

  void _getLyric() {
    // 进入加载中状态
    if (lyric != null) {
      setState(() {
        lyric = null;
      });
    }
    // 获取歌词
    MusicDao.getLyric(song['id']).then((result) {
      if (mounted && result != null) {
        setState(() {
          success = true;
          lyric = result;
        });
      }
    }).catchError((e) {
      print(e);
      setState(() {
        success = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Widget _buildInfo(String msg) {
    isItemsEmpty = true;
    return Center(
        child:
            Text(msg, style: TextStyle(color: Colors.white30, fontSize: 13.0)));
  }

  @override
  Widget build(BuildContext context) {
    //print('LyricPage build $_currentIndex');

    if (!success) {
      return _buildInfo('歌词加载失败');
    } else if (lyric == null) {
      return _buildInfo('歌词加载中...');
    } else if (lyric.items.length == 0) {
      return _buildInfo('...纯音乐,无歌词...');
    } else {
      isItemsEmpty = false;
    }

    return Container(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: itemHeight * visibleItemSize),
          child: CustomScrollView(controller: _controller, slivers: <Widget>[
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return _getItem(lyric.items[index]);
              },
              childCount: lyric.items.length,
            )),
          ]),
        ));
  }

  Widget _getItem(LyricItem item) {
    bool isCurrent = item.index == _currentIndex;
    Widget itemText = Text(
      item.content,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          fontSize: 13.0, color: isCurrent ? Colors.white : Colors.white60),
    );

    if (isCurrent) {
      if (islyricMask) {
        itemText = GradientText(text: itemText);
        currentLyricItem = itemText;
      }
    }

    return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        alignment: Alignment.center,
        height: itemHeight,
        child: itemText);
  }

  GradientText currentLyricItem;
  void updateCurrentLyricItem() {
    if (islyricMask &&
        currentLyricItem != null &&
        _currentIndex >= 0 &&
        _currentIndex < lyric.items.length) {
      LyricItem item = lyric.items[_currentIndex];
      double offsetX; // 遮住的比例
      if (item.duration > 0) {
        offsetX = (position - item.position) / item.duration;
      } else {
        offsetX = 1.0;
      }
      currentLyricItem.setOffsetX(offsetX);
    }
  }

  /// 比较播放位置和歌词时间戳,获取当前是哪条歌词。
  /// milliseconds 当前播放位置,单位：毫秒
  int getIndexByTime(int milliseconds) {
    if (lyric == null ||
        lyric.items.length == 0 ||
        lyric.items[0].position > milliseconds) {
      // 刚开始未选中的情况。
      return -1;
    }

    // 选取比较的范围,不用每次都从头遍历。
    int start;
    int end;
    if (_currentIndex <= 1 || _currentIndex >= lyric.items.length) {
      start = 0;
      end = lyric.items.length;
    } else if (milliseconds >= lyric.items[_currentIndex - 1].position) {
      start = _currentIndex;
      end = lyric.items.length;
    } else {
      start = 0;
      end = _currentIndex;
    }

    int index = start;
    for (; index < end - 1; index++) {
      if (lyric.items[index + 1].position >= milliseconds) {
        break;
      }
    }
    return index;
  }

  void scrollTo(int index) {
    int itemSize = lyric.items.length;
    // 选中的Index是否超出边界
    /* if (index < 0 || index >= itemSize) {
      return;
    } */

    int offset = (visibleItemSize - 1) ~/ 2;
    int topIndex = index - offset; // 选中元素居中时,top的Index
    int bottomIndex = index + offset;

    setState(() {
      _currentIndex = index;
    });

    // 是否需要滚动(top和bottom到边界时不滚动了)
    if (topIndex < 0 && _controller.offset <= 0) {
      return;
    }
    if (bottomIndex >= itemSize &&
        _controller.offset >= (itemSize - visibleItemSize) * itemHeight) {
      return;
    }

    if (isFirst) {
      // 第一次进入时不用滚动。
      isFirst = false;
      _controller.jumpTo(topIndex * itemHeight);
    } else {
      _controller.animateTo(topIndex * itemHeight,
          duration: Duration(seconds: 1), curve: Curves.easeInOut);
    }
  }

  // 根据歌曲播放的位置确定滚动的位置
  void updatePosition(int milliseconds, {isTaping: false}) {
    if (isItemsEmpty) {
      return;
    }

    if (isScrolling) {
      lastScrollPosition = milliseconds;
      return;
    }

    position = milliseconds;

    // 更新单条歌词进度
    updateCurrentLyricItem();

    int _index = getIndexByTime(position);
    //print("update index : $_index, currentIndex: $_currentIndex");
    if (_index != _currentIndex) {
      _currentIndex = _index;
      scrollTo(_currentIndex);

      if (isTaping) {
        // 如果是手动拖动,就要控制滚动的频率。
        delayNextScroll();
      }
    }
  }

  /// 在手动拖动时,控制滚动的频率。不然多次动画叠在一起界面卡顿。
  bool isScrolling = false;
  int lastScrollPosition = -1;
  void delayNextScroll() {
    isScrolling = true;
    Future.delayed(Duration(milliseconds: 200)).then((re) {
      isScrolling = false;
      if (lastScrollPosition != -1) {
        updatePosition(lastScrollPosition, isTaping: true);
        lastScrollPosition = -1;
      }
    });
  }

  void updateSong(Map song) {
    if (song != this.song) {
      this.song = song;
      _getLyric();
    }
  }
}
