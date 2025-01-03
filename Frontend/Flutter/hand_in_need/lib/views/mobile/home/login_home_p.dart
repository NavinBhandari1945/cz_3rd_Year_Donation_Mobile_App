import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hand_in_need/views/constant/styles.dart';
import 'package:hand_in_need/views/mobile/commonwidget/common_button_loading.dart';
import '../../../models/mobile/PostInfoModel.dart';
import '../commonwidget/CommonMethod.dart';
import '../commonwidget/VideoPlayer_controller.dart';
import '../commonwidget/circularprogressind.dart';
import '../commonwidget/toast.dart';
import 'getx_cont/getx_cont_isloading_donate.dart';
import 'getx_cont/getx_cont_isloading_qr.dart';
import 'home_p.dart';
import 'package:http/http.dart' as http;

class Login_HomeScreen extends StatefulWidget {
  final String username;
  final String usertype;
  final String jwttoken;
  const Login_HomeScreen({super.key,required this.username,required this.usertype,
    required this.jwttoken});

  @override
  State<Login_HomeScreen> createState() => _Login_HomeScreenState();
}

class _Login_HomeScreenState extends State<Login_HomeScreen>
{
  final IsLoading_QR=Get.put(Isloading_QR());
  final IsLoading_Donate=Get.put(Isloading_Donate());

  @override
  void initState() {
    super.initState();
    checkJWTExpiation();
  }

  Future<void> checkJWTExpiation()async {
    try {
      print("check jwt called");
      int result = await checkJwtToken_initistate_user(
          widget.username, widget.usertype, widget.jwttoken);
      if (result == 0) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context)
        {
          return Home();
        },)
        );
        Toastget().Toastmsg("Session End. Relogin please.");
      }
    }
    catch(obj) {
      print("Exception caught while navigating home page of from initstate of home_login page.");
      print(obj.toString());
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) {
        return Home();
      },)
      );
      Toastget().Toastmsg("Error. Relogin please.");
    }
  }

  List<PostInfoModel> PostInfoList = [];

  Future<void> GetPostInfo() async {
    try {
      print("post info method called");
      var url = "http://10.0.2.2:5074/api/Home/getpostinfo";
      final headers =
      {
        'Authorization': 'Bearer ${widget.jwttoken}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        PostInfoList.clear();
        PostInfoList.addAll
            (
            responseData.map((data) => PostInfoModel.fromJson(data)).toList(),
          );
        print("post list count value");
        print(PostInfoList.length);
        return;
      } else
      {
        PostInfoList.clear();
        print("Data insert in post info list failed.");
        return;
      }
    } catch (obj) {
      PostInfoList.clear();
      print("Exception caught while fetching post data for home screen in http method");
      print(obj.toString());
      return;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    var shortestval = MediaQuery.of(context).size.shortestSide;
    var widthval = MediaQuery.of(context).size.width;
    var heightval = MediaQuery.of(context).size.height;
    return Scaffold(

      appBar: AppBar(
        title: Text("User Home Screen"),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
      ),
      body:
      OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait)
          {
            return
              FutureBuilder<void>(
              future: GetPostInfo(),
              builder: (context, snapshot)
              {
                if (snapshot.connectionState == ConnectionState.waiting)
                {
                  return Circularproindicator(context);
                }
                else if (snapshot.hasError)
                {
                  // Handle any error from the future
                  return Center(
                    child: Text(
                      "Error fetching posts. Please try again.",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  );
                }
                else if (snapshot.connectionState == ConnectionState.done)
                {
                    return PostInfoList.isEmpty
                        ? const Center(child: Text("No post available."))
                        : ListView.builder(
                      itemCount: PostInfoList.length,
                      itemBuilder: (context, index) {
                        return _buildPostCard(PostInfoList[index], context);
                      },
                    );
                }
                else
                {
                  return
                    Center(
                    child: Text(
                      "Please reopen app.",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  );
                }

              },
            );
          }
          else if (orientation == Orientation.landscape)
          {
            return Container(
              // Add your landscape-specific layout here
            );
          }
          else
          {
            return
              Center(
              child: Text(
                "Mobile orientation must be either protrait or landscape.",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPostCard(PostInfoModel post, BuildContext context) {
    var shortestval = MediaQuery.of(context).size.shortestSide;
    var widthval = MediaQuery.of(context).size.width;
    var heightval = MediaQuery.of(context).size.height;
    return
      Container(
        width: widthval,
        margin: EdgeInsets.only(bottom: shortestval*0.03),
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey,
        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
      ),
      child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children:
        [
          // Row 1: Username ,date and 3-dot button for downloading resources
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:
            [
              Text("${post.username} posted post.", style: TextStyle(fontFamily: semibold,fontSize: shortestval*0.06)),
              Text('${post.dateCreated.toString().split("T").first}', style: TextStyle(color: Colors.black,fontSize: shortestval*0.05)),
              PopupMenuButton<String>(
                onSelected: (value) async
                {
                  if (value == 'download file')
                  {
                    await downloadFilePost(post.postFile!,post.fileExtension!);
                  }
                },
                itemBuilder: (context) =>
                [
                  PopupMenuItem(value: 'download file', child: Text('Download Resources',style: TextStyle(fontFamily:semibold,color: Colors.black,fontSize: shortestval*0.06),)),
                ],
              ),
            ],
          ),
          // Row 3: Description for the post
          ExpansionTile(
            title:Text("Description for need"),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
          children:
          [
            Container(
                alignment: Alignment.centerLeft,
                child: Text(post.description!, style: TextStyle(color: Colors.black,fontSize: shortestval*0.05))),
          ],
          ),
          SizedBox(height: 8),

          // Row 4: Image (Decode base64 and display)
          Image.memory(base64Decode(post.photo!), width: widthval, height: heightval * 0.3, fit: BoxFit.cover),
          SizedBox(height: 8),

          // Row 5: Video (Placeholder for now, video player to be added later)
          // We'll add the video player functionality later
          Container(
            color: Colors.teal,
            height: heightval*0.06,
            child: Center(
              child: ElevatedButton(
                onPressed: ()async
                {
                  String video_file_path=await writeBase64VideoToTempFilePost(post.video!);
                  if(video_file_path != null && video_file_path.isNotEmpty)
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return VideoPlayerControllerScreen(video_file_path:video_file_path);
                      },
                      )
                      );
                    }
                  else
                    {
                      Toastget().Toastmsg("No video data available.");
                      return;
                    }

                },
                child: Text("Play Video"),
              ),
            ),
          ),


          SizedBox(height: 8),

          // Row 6: QR Code and Donate buttons
          Row(
            children:
            [

             Expanded(
               child: CommonButton_loading(
                 label:"QR",
                 onPressed: (){},
                 color:Colors.red,
                 textStyle: TextStyle(fontFamily: bold,color: Colors.black,fontSize: shortestval*0.30),
                 padding: const EdgeInsets.all(12),
                 borderRadius:25.0,
                 width: widthval*0.30,
                 height: heightval*0.05,
                 isLoading: IsLoading_QR.isloading.value,

               ),
             ),
                SizedBox(width: shortestval*0.02,),
              Expanded(
                child: CommonButton_loading(
                  label:"Donate",
                  onPressed: (){},
                  color:Colors.red,
                  textStyle: TextStyle(fontFamily: bold,color: Colors.black,fontSize: shortestval*0.30),
                  padding: const EdgeInsets.all(12),
                  borderRadius:25.0,
                  width: widthval*0.30,
                  height: heightval*0.05,
                  isLoading: IsLoading_Donate.isloading.value,

                ),
              ),

            ],
          ),
        ],
      ),
    );
  }
}





