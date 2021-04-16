import 'dart:async';
import 'package:agorartm/firebaseDB/firestoreDB.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:agorartm/models/message.dart';
import 'package:agorartm/models/user.dart';
import 'package:agorartm/utils/setting.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:math' as math;
import 'package:agora_rtc_engine/rtc_channel.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:hexcolor/hexcolor.dart';


import '../HearAnim.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;

  final String image;
  final time;
  /// Creates a call page with given channel name.
  const CallPage({Key key, this.channelName, this.time,this.image}) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>{

  static final _users = <int>[];
  String channelName;
  List<User> userList = [];
  RtcEngine _engine;
  RtcChannel _chanel;
   String token;
  bool muted = false;
  bool _isLogin = true;
  bool _isInChannel = true;
  int userNo = 0;
  var userMap ;
  var tryingToEnd = false;
  bool personBool = false;
  bool accepted =false;


  final _channelMessageController = TextEditingController();

  final _infoStrings = <Message>[];

  AgoraRtmClient _client;
  AgoraRtmChannel _channel;
  bool heart = false;
  bool anyPerson = false;

  //Love animation
  final _random = math.Random();
  Timer _timer;
  double height = 0.0;
  int _numConfetti = 5;
  int guestID=-1;
  bool waiting=false;


  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _channelMessageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
    userMap = {'khan': widget.image};
    _createClient();
  }



  Future<void> initialize() async {

    _engine = await RtcEngine.create(APP_ID);
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await _engine.enableWebSdkInteroperability(true);
    await _engine.setParameters(
        '''{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}}''');
    await _engine.joinChannel('006826827a4658e40ec99d1c39bc71ec824IADayeNXLxL5U0kX2Qxqiv+Zwx91gNcRKqR5+zVFOYrxsz8jS10AAAAAEACU3jyLw4l6YAEAAQDDiXpg','khan', null, 0);
  }
var msg=new Message();
  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    //await RtcEngine.create(APP_ID);
    _engine = await RtcEngine.create(APP_ID);
    await _engine.enableVideo();
    await _engine.enableLocalAudio(true);

  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {

    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          String info = 'onError: $code';
          msg.message=info;
          _infoStrings.add(msg);
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          final info = 'onJoinChannel: $channel, uid: $uid';
         // _infoStrings.add(info);
        });
      },
      leaveChannel: (stats) {
        setState(() {
          //_infoStrings.add('onLeaveChannel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'userJoined: $uid';
         // _infoStrings.add(info);
          _users.add(uid);
        });
      },
      userOffline: (uid, reason) {
        setState(() {
          final info = 'userOffline: $uid , reason: $reason';
        //  _infoStrings.add(info);
          _users.remove(uid);
        });
      },
    ));

  }

  /// Helper function to get list of native views
  // List<Widget> _getRenderViews() {
  //   final list = [
  //     AgoraRenderWidget(0, local: true, preview: true),
  //   ];
  //   if(accepted==true) {
  //     _users.forEach((int uid) {
  //       if(uid!=0){
  //         guestID = uid;
  //       }
  //       list.add(AgoraRenderWidget(uid));
  //     });
  //   }
  //   return list;
  // }
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    _users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: ClipRRect(child: view));
  }


  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }


  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();

    switch (views.length) {
      case 1:
        return Container(
            child: Column(
              children: <Widget>[_videoView(views[0])],
            ));
      case 2:
        return Container(
            child: Column(
              children: <Widget>[
                _expandedVideoRow([views[0]]),
                _expandedVideoRow([views[1]])
              ],
            ));
    }
    return Container();


    /*    return Container(
        child: Column(
          children: <Widget>[_videoView(views[0])],
        ));*/
  }


  void popUp() async{
    setState(() {
      heart=true;
    });

    _timer = Timer.periodic(Duration(milliseconds: 125), (Timer t) {
      setState(() {
        height += _random.nextInt(20);
      });
    });

    Timer(Duration(seconds: 4), () =>
    {
      _timer.cancel(),
      setState(() {
        heart=false;
      })
    });
  }
  Widget heartPop(){
    final size = MediaQuery.of(context).size;
    final confetti = <Widget>[];
    for (var i = 0; i < _numConfetti; i++) {
      final height = _random.nextInt(size.height.floor());
      final width = 20;
      confetti.add(HeartAnim(height % 200.0,
          width.toDouble(), 0.5,));
    }


    return Container(
      child: Padding(
        padding: const EdgeInsets.only(bottom:20),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            height: 400,
            width: 200,
            child: Stack(
              children: confetti,
            ),
          ),
        ),
      ),
    );
  }



  /// Info panel to show logs
  Widget messageList() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return null;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: (_infoStrings[index].type=='join')? Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      CachedNetworkImage(
                        imageUrl: _infoStrings[index].image,
                        imageBuilder: (context, imageProvider) => Container(
                          width: 32.0,
                          height: 32.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const  EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        child: Text(
                          '${_infoStrings[index].user} joined',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : (_infoStrings[index].type=='message')?
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      CachedNetworkImage(
                        imageUrl: _infoStrings[index].image,
                        imageBuilder: (context, imageProvider) => Container(
                          width: 32.0,
                          height: 32.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const  EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            child: Text(
                              _infoStrings[index].user,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          SizedBox(height: 5,),
                          Padding(
                            padding: const  EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            child: Text(
                              _infoStrings[index].message,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
                    :null,
              );
            },
          ),
        ),
      ),
    );
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  Future<bool> _willPopCallback() async {
    if(personBool==true){
      setState(() {
        personBool=false;
      });

    }else {
      setState(() {
        tryingToEnd = !tryingToEnd;
      });
    }
    return false;// return true if the route to be popped
  }

  Widget _endCall(){
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15,15,15,15),
            child: GestureDetector(
              onTap: () {
                _logout();
                if(personBool==true){
                  setState(() {
                    personBool=false;
                  });
                }
                setState(() {
                  if(waiting==true){
                    waiting=false;
                  }
                  tryingToEnd=true;
                });
              },
              child:Padding(
                padding: const EdgeInsets.only(left:10,top: 20),
                child: Container(
                  width: 50,
                  height: 25,
                  decoration: BoxDecoration(
                      color:HexColor('#f02e63'),
                      borderRadius: BorderRadius.all(Radius.circular(20.0))
                  ),
                  child:  Center(child: Text('END',style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),)),
                ),
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveText(){
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4.0))
              ),
              child: Padding(
                padding: const EdgeInsets.only(left:10,top: 20),
                child: Container(
                  width: 50,
                    height: 25,
                    decoration: BoxDecoration(
                        color:HexColor('#f02e63'),
                        borderRadius: BorderRadius.all(Radius.circular(20.0))
                    ),
                    child: Center(child: Text('LIVE',style: TextStyle(color: Colors.white,fontSize: 15,fontWeight: FontWeight.bold),))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left:10,right:10,top: 20),
              child: Container(
                  decoration: BoxDecoration(
                     color:HexColor('#f02e63'),
                      borderRadius: BorderRadius.all(Radius.circular(20.0))
                  ),
                  height: 25,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                             Icon(FontAwesomeIcons.eye,color: Colors.white,size: 13,),
                             SizedBox(width: 5,),
                             Text('$userNo',style: TextStyle(color: Colors.white,fontSize: 11),),
                           ],
                         ),
                       ),
                  )
      ),
                           ],
    )
    ),
    );
  }

  Widget endLive(){
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Stack(
        children: <Widget>[
          Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  'Are you sure you want to end your live video?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize:20
                  ),
                ),
              ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0,right: 4.0,top:8.0,bottom:8.0),
                    child: RaisedButton(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text('End Video',style: TextStyle(color: Colors.white),),
                      ),
                      elevation: 2.0,
                      color: Colors.blue,
                      onPressed: () async{
                        await Wakelock.disable();
                        _logout();
                        _leaveChannel();
                        _chanel.leaveChannel();
                        _chanel.destroy();
                        FireStoreClass.deleteUser(username: channelName);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0,right: 8.0,top:8.0,bottom:8.0),
                    child: RaisedButton(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text('Cancel',style: TextStyle(color:Colors.white),),
                      ),
                      elevation: 2.0,
                      color: Colors.grey,
                      onPressed: (){
                        setState(() {
                          tryingToEnd=false;
                        });
                      },
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget personList(){
    return Container(
      alignment: Alignment.bottomRight,
      child: Container(
        height: 2*MediaQuery.of(context).size.height/3,
        width: MediaQuery.of(context).size.height,
        decoration: new BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25)
          ),
        ),
        child: Stack(
          children: <Widget>[
            Container(
              height: 2*MediaQuery.of(context).size.height/3 -50,
              child: Column(
                children: <Widget>[
                  SizedBox(height: 10,),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    width: MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    child: Text('Go Live with',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white),),
                  ),
                  SizedBox(height: 10,),
                  Divider(color: Colors.grey[800],thickness: 0.5,height: 0,),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: Text(
                      'When you go live with someone, anyone who can watch their live videos will be able to watch it too.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  anyPerson==true?Container(
                      padding: EdgeInsets.symmetric(vertical: 10,horizontal: 15),
                      width: double.maxFinite,
                      child: Text(
                        'INVITE',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.start,
                      )
                  ):
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('No Viewers',style: TextStyle(color: Colors.grey[400]),),
                  ),
                  Expanded(
                    child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        children: getUserStories()
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: (){
                  setState(() {
                    personBool= !personBool;
                  });
                },
                child: Container(
                  color: Colors.grey[850],
                  alignment: Alignment.bottomCenter,
                  height: 50,
                  child: Stack(
                    children: <Widget>[
                      Container(
                        height: double.maxFinite,
                        alignment: Alignment.center ,
                        child: Text('Cancel',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> getUserStories() {
    List<Widget> stories = [];
    for (User users in userList) {
      stories.add(getStory(users));
    }
    return stories;
  }

  Widget getStory(User users) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 7.5),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: ()async{
              setState(() {
                waiting=true;
              });
              await _channel.sendMessage(AgoraRtmMessage.fromText('d1a2v3i4s5h6 ${users.username}'));
            },
            child: Container(
              padding: EdgeInsets.only(left: 15),
                color: Colors.grey[850 ],
                child: Row(
                  children: <Widget>[
                    CachedNetworkImage(
                      imageUrl: users.image,
                      imageBuilder: (context, imageProvider) => Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              image: imageProvider, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        children: <Widget>[
                          Text(users.username,style: TextStyle(fontSize: 18,color: Colors.white),),
                          SizedBox(height: 2,),
                          Text(users.name,style: TextStyle(color: Colors.grey),),
                        ],
                      ),
                    )
                  ],
                )
            ),
          ),
        ],
      ),
    );
  }

  Widget stopSharing(){
    return Container(
      height: MediaQuery.of(context).size.height/2+40,
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: MaterialButton(
          minWidth: 0,
          onPressed: ()async{
            stopFunction();
            await _channel.sendMessage(AgoraRtmMessage.fromText('E1m2I3l4i5E6 stoping'));
          },
          child: Icon(
            Icons.clear,
            color: Colors.white,
            size: 15.0,
          ),
          shape: CircleBorder(),
          elevation: 2.0,
          color: Colors.blue[400],
          padding: const EdgeInsets.all(5.0),
        ),
      ),
    );
  }

  Widget guestWaiting(){
    return Container(
      alignment: Alignment.bottomRight,
      child: Container(
        height: 100,
        width: double.maxFinite,
        alignment: Alignment.center,
        color: Colors.black,
        child: Wrap(
          children: <Widget>[
            Text('Waiting for the user to accept...',style: TextStyle(color: Colors.white,fontSize: 20),)
          ],
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child:SafeArea(
          child: Scaffold(
            bottomNavigationBar: BottomAppBar(
              child: Container(
                color: Colors.black,
                child:
                TextField(
                    cursorColor: Colors.blue,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    style: TextStyle(color: Colors.white),
                    controller: _channelMessageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send,color: Colors.blue,),
                        onPressed: _toggleSendChannelMessage,
                      ),
                      isDense: true,
                      hintText: 'Comment',
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50.0),
                          borderSide: BorderSide(color: Colors.white)
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50.0),
                          borderSide: BorderSide(color: Colors.white)
                      ),
                    ),

                ),

              ),
            ),
            body: Container(
              color: Colors.black,
              child: Center(
                child: Stack(
                  children: <Widget>[
                    _viewRows(),// Video Widget
                    if(tryingToEnd==false)_endCall(),
                    if(tryingToEnd==false)_liveText(),
                    if(heart == true && tryingToEnd==false) heartPop(),
                    if(tryingToEnd==false) 
                     Align(
                       alignment: Alignment.bottomRight,
                     child: _bottomBar(),
                     ),
                     // send message
                    if(tryingToEnd==false)messageList(),
                    if(tryingToEnd==true)endLive(),// view message
                    if(personBool==true && waiting==false) personList(),
                    if(accepted == true) stopSharing(),
                    if(waiting == true) guestWaiting(),
                  ],
                ),
              ),
            ),
          ),
        ),
        onWillPop: _willPopCallback
    );
  }
// Agora RTM

  Widget _bottomBar() {
    if (!_isLogin || !_isInChannel) {
      return Container();
    }
    return Container(
        height: 300,
        width: 100.0,
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.only(bottom: 50.0),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 10, 5, 0),
                child: MaterialButton(
                  minWidth: 0,
                  onPressed: _toggleSendChannelMessage,
                  child: RawMaterialButton(
                    onPressed: _onToggleMute,
                    child: Icon(
                      muted ? Icons.mic_off : Icons.mic,
                      color: muted ? Colors.white : Colors.blueAccent,
                      size: 20.0,
                    ),
                    shape: CircleBorder(),
                    elevation: 2.0,
                    fillColor: muted ? Colors.blueAccent : Colors.white,
                    padding: const EdgeInsets.all(12.0),
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  color: Colors.blue[400],
                  padding: const EdgeInsets.all(12.0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 10, 5, 0),
                child: MaterialButton(
                  minWidth: 0,
                  onPressed: (){
                    print("Khan");
                  },
                  child: Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  color:Colors.blue[400] ,
                  padding: const EdgeInsets.all(12.0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 10, 5, 0),
                child: MaterialButton(
                  minWidth: 0,
                  onPressed: _onSwitchCamera,
                  child: Icon(
                    Icons.switch_camera,
                    color: Colors.blue[400],
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  color: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                ),
              )
            ]
        ),
      );
  }

  void _addPerson() {
    print("Khan");
    setState(() {
      personBool = !personBool;
    });
  }

  void stopFunction(){
    setState(() {
      accepted= false;
    });
  }


  void _logout() async {
    try {
      await _client.logout();
      //_log(info:'Logout success.',type: 'logout');
    } catch (errorCode) {
      //_log(info: 'Logout error: ' + errorCode.toString(), type: 'error');
    }
  }



  void _leaveChannel() async {
    try {
      await _channel.leave();
      //_log(info: 'Leave channel success.',type: 'leave');
      _client.releaseChannel(_channel.channelId);
      _channelMessageController.text = null;

    } catch (errorCode) {
     _log(info: 'Leave channel error: ' + errorCode.toString(),type: 'error');
    }
  }

  void _toggleSendChannelMessage() async {
    String text = _channelMessageController.text;
    if (text.isEmpty) {
      return;
    }
    try {
      _channelMessageController.clear();
      await _channel.sendMessage(AgoraRtmMessage.fromText(text));
      _log(user: 'khan', info: text,type: 'message');
    } catch (errorCode) {
      //_log(info: 'Send channel message error: ' + errorCode.toString(), type: 'error');
    }
  }

  void _sendMessage(text) async {
    if (text.isEmpty) {
      return;
    }
    try {
      _channelMessageController.clear();
      await _channel.sendMessage(AgoraRtmMessage.fromText(text));
      _log(user: widget.channelName, info:text,type: 'message');
    } catch (errorCode) {
     // _log('Send channel message error: ' + errorCode.toString());
    }
  }

  void _createClient() async {
    _client =
    await AgoraRtmClient.createInstance('826827a4658e40ec99d1c39bc71ec824');
    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      _log(user: peerId,  info: message.text, type: 'message');
    };
    _client.onConnectionStateChanged = (int state, int reason) {
      if (state == 5) {
        _client.logout();
        //_log('Logout.');
        setState(() {
          _isLogin = false;
        });
      }
    };
    await _client.login(null, 'khan' );
   // print("log in");
    _channel = await _createChannel('khan');
    await _channel.join();
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel channel = await _client.createChannel(name);
    channel.onMemberJoined = (AgoraRtmMember member) async {
      var img = await FireStoreClass.getImage(username: member.userId);
      var nm = await FireStoreClass.getName(username: member.userId);
      setState(() {
        userList.add(new User(username: member.userId, name: nm, image: img));
        if(userList.length>0)
          anyPerson =true;
      });
      userMap.putIfAbsent(member.userId, () => img);
      var len;
      _channel.getMembers().then((value) {
        len = value.length;
        setState(() {
          userNo= len-1 ;
        });
      });

      _log(info: 'Member joined: ',  user: member.userId,type: 'join');
    };
    channel.onMemberLeft = (AgoraRtmMember member) {
      var len;
      setState(() {
        userList.removeWhere((element) => element.username == member.userId);
        if(userList.length==0)
          anyPerson = false;
      });

      _channel.getMembers().then((value) {
        len = value.length;
        setState(() {
          userNo= len-1 ;
        });
      });
    };
    channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      _log(user: member.userId, info: message.text,type: 'message');
    };
    return channel;
  }

  void _log({String info,String type,String user}) {
    if(type=='message' && info.contains('m1x2y3z4p5t6l7k8')){
      popUp();
    }
    else if(type=='message' && info.contains('k1r2i3s4t5i6e7')){
      setState(() {
        accepted=true;
        personBool=false;
        personBool=false;
        waiting= false;
      });
    }
    else if(type=='message' && info.contains('E1m2I3l4i5E6')){
      stopFunction();
    }
    else if(type=='message' && info.contains('R1e2j3e4c5t6i7o8n9e0d')){
      setState(() {
        waiting=false;
      });
      /*FlutterToast.showToast(
          msg: "Guest Declined",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0
      );*/

    }
    else {
      var image = userMap[user];
      Message m = new Message(
          message: info, type: type, user: user, image: image);
      setState(() {
        _infoStrings.insert(0, m);
      });
    }
  }
  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }
}
