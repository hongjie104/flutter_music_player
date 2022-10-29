import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_player/model/music_controller.dart';
import 'package:flutter_music_player/model/song_util.dart';
import 'package:flutter_music_player/pages/player_page.dart';
import 'package:provider/provider.dart';

class FloatingPlayer extends StatefulWidget {
  FloatingPlayer({Key? key}) : super(key: key);

  @override
  _FloatingPlayerState createState() => _FloatingPlayerState();
}

class _FloatingPlayerState extends State<FloatingPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  late MusicController _musicController;

  MusicListener? _musicListener;

  PlayerState playerState = PlayerState.playing;

  @override
  void initState() {
    super.initState();
    print('FloatingPlayer initState');

    _animController = AnimationController(
      duration: const Duration(
        seconds: 16,
      ),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // listen: true,当Provider中notifyListeners时,自动触发更新。
    // 默认为true,所以在不需要自动触发更新的地方要设为false。
    initMusicListener();
  }

  void initMusicListener() {
    if (_musicListener == null) {
      _musicListener = MusicListener(
          getName: () => "FloatingPlayer",
          onLoading: () {},
          onStart: (duration) {},
          onPosition: (position) {},
          onStateChanged: (state) {
            setState(() => this.playerState = state);
          },
          onError: (msg) => {});
    }

    _musicController = Provider.of<MusicController>(context, listen: true);
    _musicController.addMusicListener(_musicListener!);
  }

  @override
  void dispose() {
    // 这儿有个问题,要在后面调用super.dispose
    // at the time dispose() was called on the mixin,
    // that Ticker was still active.
    // The Ticker must be disposed before calling super.dispose().
    _animController.dispose();
    _musicController.removeMusicListener(_musicListener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map? song = _musicController.getCurrentSong();
    _buildAnim();
    return GestureDetector(
        // 加了双击事件之后,单击事件就变迟缓了。
        /* onDoubleTap: (){
        print('onDoubleTap');
        musicController.toggle();
      }, */
        onLongPress: () {
          print('onLongPress');
        },
        child: Container(
            width: 70.0,
            height: 70.0,
            child: FloatingActionButton(
              onPressed: () {
                if (song != null) {
                  PlayerPage.gotoPlayer(context);
                }
              },
              elevation: 2.0,
              backgroundColor: Colors.black26,
              heroTag: 'FloatingPlayer',
              child: Container(
                  padding: EdgeInsets.all(2.0),
                  child: RotationTransition(
                      //设置动画的旋转中心
                      alignment: Alignment.center,
                      //动画控制器
                      turns: _animController,
                      child: ClipOval(
                        child: song == null
                            ? Image.asset('images/music_2.jpg',
                                fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: SongUtil.getSongImage(song),
                                fit: BoxFit.cover),
                      ))),
            )));
  }

  void _buildAnim() {
    playerState = _musicController.getCurrentState();
    if (playerState == PlayerState.playing) {
      if (!_animController.isAnimating) {
        _animController.forward();
        _animController.repeat();
      }
    } else {
      if (_animController.isAnimating) {
        _animController.stop();
      }
    }
  }
}
