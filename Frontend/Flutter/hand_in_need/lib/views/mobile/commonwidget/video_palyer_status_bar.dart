import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BasicOverlayWidget extends StatelessWidget {
  final VideoPlayerController controller;

  const BasicOverlayWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) =>

      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: (){
          controller.value.isPlaying?controller.pause():controller.play();
        },
        child: Stack(
          children:
          [

            buildPlay(),

           Positioned(
             bottom: 0,
             left: 0,
             right: 0,
             child: buildIndicator(),
           ),

          ],
        ),
      );

  Widget buildIndicator()=>
      VideoProgressIndicator(controller, allowScrubbing: true);

  Widget buildPlay()=>controller.value.isPlaying?
  Container():
  Container(
      color: Colors.black,
      alignment:  Alignment.center,
      child: Icon(Icons.play_arrow,color: Colors.white,size: 80,
      )
  )
  ;
}



