import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hand_in_need/models/mobile/DonationModel.dart';
import 'package:hand_in_need/models/mobile/NotificationsModel.dart';
import 'package:hand_in_need/views/mobile/constant/constant.dart';
import 'package:hand_in_need/views/mobile/profile/update_phone_number.dart';
import 'package:hand_in_need/views/mobile/profile/getx_cont_profile/is_new_notification.dart';
import 'package:hand_in_need/views/mobile/profile/update_address.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../models/mobile/FriendInfoModel.dart';
import '../../../models/mobile/PostInfoModel.dart';
import '../../../models/mobile/UserInfoModel.dart';
import '../../constant/styles.dart';
import '../commonwidget/CommonMethod.dart';
import '../commonwidget/DonateOptionDialog.dart';
import '../commonwidget/Generate_QrCode_ScreenPost_p.dart';
import '../commonwidget/VideoPlayer_controller.dart';
import '../commonwidget/circular_progress_ind_yellow.dart';
import '../commonwidget/common_button_loading.dart';
import '../commonwidget/getx_cont_pick_single_photo.dart';
import '../commonwidget/toast.dart';
import '../home/home_p.dart';
import 'package:http/http.dart' as http;
import 'UpdateEmail_p.dart';
import 'UpdatePassword_p.dart';
import 'User_Friend_Profile_Screen_P.dart';
import 'getx_cont_profile/getx_cont_isloading_chnage_photo.dart';
import 'getx_cont_profile/getx_cont_isloading_donate_profile.dart';
import 'getx_cont_profile/getx_cont_isloading_logout_button.dart';
import 'getx_cont_profile/getx_cont_isloading_qr_profile.dart';
import 'package:excel/excel.dart' as Excel;

class Profilescreen_P extends StatefulWidget {
  final String username;
  final String usertype;
  final String jwttoken;
  const Profilescreen_P({super.key,required this.username,required this.usertype,
    required this.jwttoken});
  @override
  State<Profilescreen_P> createState() => _Profilescreen_PState();
}

class _Profilescreen_PState extends State<Profilescreen_P>
{
  final change_photo_cont_getx=Get.put(pick_single_photo_getx());
  final change_photo_cont_isloading=Get.put(Isloading_change_photo_profile_screen());
  final logout_button_cont_isloading=Get.put(Isloading_logout_button_profile_screen());
  final IsLoading_QR_Profile=Get.put(Isloading_QR_Profile());
  final IsLoading_Donate_Profile=Get.put(Isloading_Donate_Profile());

  @override
  void initState(){
    super.initState();
    checkJWTExpiration_Outside_Widget_Build_Method();
    New_Notification_Cont.Change_Is_New_Notification(false);
  }

  Future<void> checkJWTExpiration_Outside_Widget_Build_Method()async
  {
    try {
      int result = await checkJwtToken_initistate_user(
          widget.username, widget.usertype, widget.jwttoken);
      print(widget.jwttoken);
      if (result == 0) {
        await clearUserData();
        await deleteTempDirectoryPostVideo();
        await deleteTempDirectoryCampaignVideo();
        print("Deleteing temporary directory success.");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) {
          return Home();
        },)
        );
        Toastget().Toastmsg("Session End.Relogin please.");
      }
    }
    catch(obj)
    {
      print("Exception caught while verifying jwt for Profile screen.");
      print(obj.toString());
      await clearUserData();
      await deleteTempDirectoryPostVideo();
      await deleteTempDirectoryCampaignVideo();
      print("Deleteing temporary directory success.");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) {
        return Home();
      },)
      );
      Toastget().Toastmsg("Error.Relogin please.");
    }

  }

  List<UserInfoModel> userinfomodel_list=[];

//extract userinfo to show profile
  Future<void> getUserInfo(String username, String jwttoken) async {
    try {
      print("profile user info method called");
      // API endpoint

      const String url = Backend_Server_Url+"api/Profile/getuserinfo";
      Map<String, dynamic> usernameDict =
      {
        "Username": username,
      };

      // Send the POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwttoken'
        },
        body: json.encode(usernameDict),
      );

      print("status code");
      print(response.statusCode);

      // Handling the response
      if (response.statusCode == 200)
      {
        print("profile user info");
        Map<dynamic, dynamic> responseData = await jsonDecode(response.body);
        userinfomodel_list.clear();
        userinfomodel_list.add(UserInfoModel.fromJson(responseData));
        return;
      }
      else
      {
        userinfomodel_list.clear();
        print("Data insert in userinfo list failed.");
        return;
      }
    } catch (obj) {
      userinfomodel_list.clear();
      print("Exception caught while fetching user data for profile screen");
      print(obj.toString());
      return;
    }
  }

  Future<bool> UpdatePhoto({required String username,required String jwttoken,required photo_bytes}) async {

    try
    {
      final String base64Image = base64Encode(photo_bytes as List<int>);
      // API endpoint
      const String url = Backend_Server_Url+"api/Profile/updatephoto";
      Map<String, dynamic> new_photo =
      {
        "Username": username,
        "Photo":base64Image,
      };

      // Send the POST request
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwttoken'
        },
        body: json.encode(new_photo),
      );

      // Handling the response
      if (response.statusCode == 200) {
        print("User authenticated");
        return true;
      }
      else
      {
        print("error");
        return false;
      }
    } catch (obj) {
      print("Exception caught while fetching user data for profile screen");
      print(obj.toString());
      return false;
    }
  }


  List<PostInfoModel> ProfilePostInfoList = [];

  Future<void> GetProfilePostInfo() async {
    try {
      print("Profile post info method called");
      // var url = "http://10.0.2.2:5074/api/Profile/getprofilepostinfo";
      const String url = Backend_Server_Url+"api/Profile/getprofilepostinfo";
      final headers =
      {
        'Authorization': 'Bearer ${widget.jwttoken}',
        'Content-Type': 'application/json',
      };

      Map<String, dynamic> profilePostInfoBody =
      {
        "Username": "${widget.username}"
      };
      final response = await http.post(
          Uri.parse(url),
          headers: headers,
        body: json.encode(profilePostInfoBody)
      );

      if (response.statusCode == 200)
      {
        List<dynamic> responseData = await jsonDecode(response.body);
        ProfilePostInfoList.clear();
        ProfilePostInfoList.addAll
          (
          responseData.map((data) => PostInfoModel.fromJson(data)).toList(),
        );
        print("profile post list for profile count value");
        print(ProfilePostInfoList.length);
        return;
      } else
      {
        ProfilePostInfoList.clear();
        print("Data insert in profile post info for profile in list failed.");
        return;
      }
    } catch (obj) {
      ProfilePostInfoList.clear();
      print("Exception caught while fetching post data for profile screen in http method");
      print(obj.toString());
      return;
    }
  }


  List<DonationModel> Donation_Info_Profile_Post = [];

  Future<int> Get_Profile_Donation_Post_Info() async {
    try{
      print("Profile post info method called");
      // var url = "http://10.0.2.2:5074/api/Profile/get_donation_info";
      const String url = Backend_Server_Url+"api/Profile/get_donation_info";
      final headers =
      {
        'Authorization': 'Bearer ${widget.jwttoken}',
        'Content-Type': 'application/json',
      };

      Map<String, dynamic> Profile_Donation_PostInfoBody =
      {
        "Username": "${widget.username}"
      };
      final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: json.encode(Profile_Donation_PostInfoBody)
      );

      if (response.statusCode == 200)
      {
        List<dynamic> responseData = await jsonDecode(response.body);
        Donation_Info_Profile_Post.clear();
        Donation_Info_Profile_Post.addAll
          (
          responseData.map((data) => DonationModel.fromJson(data)).toList(),
        );
        print("profile post donation list for profile count value");
        print(Donation_Info_Profile_Post.length);
        return 1;
      } else
      {
        Donation_Info_Profile_Post.clear();
        print("Data insert in profile donation post info for profile in list failed.");
        return 2;
      }
    } catch (obj) {
      Donation_Info_Profile_Post.clear();
      print("Exception caught while fetching post donation data for profile screen in http method");
      print(obj.toString());
      return 0;
    }
  }


  Widget _buildPostCardProfilePostInfo(PostInfoModel post, BuildContext context)
  {
    var shortestval = MediaQuery.of(context).size.shortestSide;
    var widthval = MediaQuery.of(context).size.width;
    var heightval = MediaQuery.of(context).size.height;
    return
      Container(
        width: widthval,
        height: heightval*0.65,
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

                PopupMenuButton<String>(
                  onSelected: (value) async
                  {
                    if (value == 'download file')
                    {
                      await downloadFilePost(post.postFile!,post.fileExtension!);
                    }

                    if (value == 'download donation info')
                    {


                      var excel = Excel.Excel.createExcel();
                      var sheet = excel['Donations'];

                      // Add headers
                      sheet.appendRow([
                        Excel.TextCellValue("Donate ID"),
                        Excel.TextCellValue("Donor Username"),
                        Excel.TextCellValue("Receiver Username"),
                        Excel.TextCellValue("Amount"),
                        Excel.TextCellValue("Date"),
                        Excel.TextCellValue("Post ID"),
                        Excel.TextCellValue("Payment Method"),
                      ]);

                      // Filter donations by postId
                      var filteredDonations = Donation_Info_Profile_Post.where((donation) => donation.postId == post.postId).toList();

                      // Add data rows
                      for (var donation in filteredDonations) {
                        sheet.appendRow([
                          donation.donateId != null ?  Excel.IntCellValue(donation.donateId!.toInt()) : null,
                          Excel.TextCellValue(donation.donerUsername ?? ""),
                          Excel.TextCellValue(donation.receiverUsername ?? ""),
                          donation.donateAmount != null ?  Excel.DoubleCellValue(donation.donateAmount!.toDouble()) : null,
                          Excel.TextCellValue(donation.donateDate ?? ""),
                          donation.postId != null ?  Excel.IntCellValue(donation.postId!.toInt()) : null,
                          Excel.TextCellValue(donation.paymentMethod ?? ""),
                        ]);
                      }

                      // Save the Excel file and convert it to Base64
                      var fileBytes = excel.save();
                      if (fileBytes != null) {
                        String base64String = base64Encode(fileBytes);
                        String fileExtension = "xlsx"; // Excel file extension

                        // Send the Base64 encoded string to the method
                        await Download_Donation_File_Post(base64String, fileExtension);
                      }
                    }


                  },
                  itemBuilder: (context) =>
                  [
                    PopupMenuItem(value: 'download file', child: Text('Download Resources',
                      style: TextStyle(fontFamily:semibold,color: Colors.black,fontSize: shortestval*0.06),)),

                    PopupMenuItem (
                      value: 'download donation info',
                        child:
                        FutureBuilder(
                          future: Get_Profile_Donation_Post_Info(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting)
                            {
                              return CircularProgressIndicator(); // While waiting for response
                            }
                            else if (snapshot.hasError)
                            {
                              return Text('Error: ${snapshot.error}'); // If there's an error
                            }
                            else if (snapshot.connectionState == ConnectionState.done)
                            {
                              if (userinfomodel_list.isNotEmpty || userinfomodel_list.length>=1)
                              {
                                return
                                  Text('Download donation info.',
                                    style: TextStyle(fontFamily:semibold,color: Colors.black,fontSize: shortestval*0.06),
                                  );
                              }
                              else
                              {
                                return Text('No dontaion data available'); // If no user data
                              }
                            }
                            else
                            {
                              return Text('Error.Relogin.'); // Default loading state
                            }
                          },
                        ),
                    ),

                  ],
                ),
              ],
            ),
            Text("Post id = ${post.postId}", style: TextStyle(fontSize: shortestval*0.06)),
            Text('${post.dateCreated.toString().split("T").first}', style: TextStyle(color: Colors.black,fontSize: shortestval*0.05)),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
              [

                Obx(
                      ()=>Container(
                    width: widthval*0.50,
                    child: CommonButton_loading(
                      label:"Generate QR",
                      onPressed:
                          ()
                      {
                        IsLoading_QR_Profile.change_isloadingval(true);
                        IsLoading_QR_Profile.change_isloadingval(false);
                        Navigator.push(context, MaterialPageRoute(builder: (context)
                        {
                          return QrCodeScreenPost_p(post: post,);
                        },
                        )
                        );
                      },

                      color:Colors.red,
                      textStyle: const TextStyle(fontFamily: bold,color: Colors.black,),
                      padding: const EdgeInsets.all(12),
                      borderRadius:25.0,
                      width: widthval*0.30,
                      height: heightval*0.05,
                      isLoading: IsLoading_QR_Profile.isloading.value,
                    ),
                  ),
                ),

                Obx(
                      ()=>Container(
                    width: widthval*0.50,
                    child: CommonButton_loading(
                      label:"Donate",
                      onPressed: ()
                      {
                        IsLoading_Donate_Profile.change_isloadingval(true);
                        DonateOption().donate(
                            context: context,
                            donerUsername: widget.username,
                            postId: post.postId!.toInt(),
                            receiver_useranme: post.username.toString(),
                            jwttoken: widget.jwttoken,
                            userType: widget.usertype
                        );
                        IsLoading_Donate_Profile.change_isloadingval(false);
                      },
                      color:Colors.red,
                      textStyle: TextStyle(fontFamily: bold,color: Colors.black),
                      padding: const EdgeInsets.all(12),
                      borderRadius:25.0,
                      width: widthval*0.30,
                      height: heightval*0.05,
                      isLoading: IsLoading_Donate_Profile.isloading.value,
                    ),
                  ),
                ),

              ],
            ),
          ],
        ),
      );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<FriendInfoModel> FriendInfoList = [];

  Future<void> GetFriendInfo() async
  {
    try {
      print("post info method called for user Home screen.");
      // Const String url = "http://10.0.2.2:5074/api/Home/getpostinfo";
      const String url = Backend_Server_Url+"api/Profile/getfriendinfo";
      final headers =
      {
        'Authorization': 'Bearer ${widget.jwttoken}',
        'Content-Type': 'application/json',
      };

      Map<String, dynamic> usernameDict =
      {
        "Username": widget.username,
      };

      final response = await http.post(Uri.parse(url), headers: headers,body: json.encode(usernameDict));

      if (response.statusCode == 200)
      {
        List<dynamic> responseData = await jsonDecode(response.body);
        FriendInfoList.clear();
        FriendInfoList.addAll
          (
          responseData.map((data) => FriendInfoModel.fromJson(data)).toList(),
        );
        print("Friend info list count value for profile scareen.");
        print(FriendInfoList.length);
        return;
      } else
      {
        FriendInfoList.clear();
        print("Data insert in Friend info list for profile scareen failed  in profile screen..");
        return;
      }
    } catch (obj) {
      FriendInfoList.clear();
      print("Exception caught while fetching friend info data for profile screen in http method");
      print(obj.toString());
      return;
    }
  }

  List<NotificationsModel> Notification_Info_List = [];
  List<NotificationsModel> Filter_New_Notifications = [];

  final New_Notification_Cont=Get.put(Is_New_Notification());

  Future<void> Get_Notification_Info() async {
    try {
      print("Get_Notification_Info method called for profile screen.");

      const String url = Backend_Server_Url+"api/Profile/get_not";
      final headers = {
        'Authorization': 'Bearer ${widget.jwttoken}',
        'Content-Type': 'application/json',
      };

      Map<String, dynamic> usernameDict = {
        "Username": widget.username,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(usernameDict),
      );

      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);

        // Clear the previous lists before populating
        Notification_Info_List.clear();
        Notification_Info_List.addAll(
          responseData.map((data) => NotificationsModel.fromJson(data)).toList(),
        );

        print("Notification info list count: ${Notification_Info_List.length}");

        // Get user login date from Hive storage
        Map<dynamic, dynamic> userCredentials = await getUserCredentials();
        String? userLoginDateStr = userCredentials['UserLogindate'];

        if (userLoginDateStr != null && userLoginDateStr.isNotEmpty && Notification_Info_List.isNotEmpty) {
          DateTime userLoginDate = DateTime.parse(userLoginDateStr).toUtc();

          print("User Login Date (UTC): $userLoginDate");

          // Clear the filtered list before adding new items
          Filter_New_Notifications.clear();

          // Filter notifications that are received AFTER user login
          Filter_New_Notifications.addAll(
            Notification_Info_List.where((notification) {
              DateTime notificationDate = DateTime.parse(notification.notDate!).toUtc();

              print("Notification Date (UTC): $notificationDate");

              return notificationDate.isAfter(userLoginDate);
            }).toList(),
          );

          print("Filtered Notifications Count: ${Filter_New_Notifications.length}");

          // Update new notification flag
          New_Notification_Cont.Change_Is_New_Notification(Filter_New_Notifications.isNotEmpty);
        } else {
          // No new notifications or invalid login date
          Notification_Info_List.clear();
          Filter_New_Notifications.clear();
          New_Notification_Cont.Change_Is_New_Notification(false);
          print("No new notifications or invalid login date.");
        }
      } else {
        // API response failed
        Notification_Info_List.clear();
        New_Notification_Cont.Change_Is_New_Notification(false);
        print("Failed to fetch notifications from API.");
      }
    } catch (e) {
      // Handle exceptions
      Notification_Info_List.clear();
      Filter_New_Notifications.clear();
      New_Notification_Cont.Change_Is_New_Notification(false);
      print("Exception while fetching notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var widthval=MediaQuery.of(context).size.width;
    var heightval=MediaQuery.of(context).size.height;
    var shortestval=MediaQuery.of(context).size.shortestSide;
    return
      Scaffold (
      key: _scaffoldKey, // Assign the GlobalKey to the Scaffold
      appBar: AppBar(
        title: Text("profilescreen"),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions:
        [
          IconButton(onPressed: (){
            _scaffoldKey.currentState!.openDrawer();
          },
              icon: Icon(Icons.people_alt_outlined)
          ),

          // Builder(
          //   builder: (BuildContext context) {
          //     return IconButton
          //       (
          //       onPressed: ()
          //       {
          //         Scaffold.of(context).openDrawer(); // Use context from Builder
          //       },
          //       icon: Icon(Icons.people_alt_outlined),
          //     );
          //   },
          // ),

          SizedBox(width: shortestval*0.01,),

              FutureBuilder<void>(
              future:Get_Notification_Info(),
              builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
              {
              // Show a loading indicator while the future is executing
              return Circular_pro_indicator_Yellow(context);
              }
              else if (snapshot.hasError)
              {
              // Handle any error from the future
              return Icon(Icons.notifications_none);
              }
              else if (snapshot.connectionState == ConnectionState.done)
              {
              return
              Notification_Info_List.isEmpty
              ? Icon(Icons.notifications_none)
                  :
              IconButton (
                onPressed: ()
                {
                  New_Notification_Cont.Change_Is_New_Notification(false);
                  showDialog (
                    context: context,
                    builder: (BuildContext context)
                    {
                      return AlertDialog
                        (
                        title: Text("Notifications"),
                        content:SizedBox(
                          width: double.maxFinite,
                          height: 300, // Adjust height as needed
                          child:
                          ListView.builder(
                            itemCount: Notification_Info_List.length,
                            itemBuilder: (context, index) {
                              final notification = Notification_Info_List[index];
                              return
                                Card(
                                  child: Column(
                                    children: [
                                      ListTile(
                                      title: Text("Tittle:${notification.notType}",style: TextStyle(fontFamily: semibold),), // notType as title
                                      subtitle: Text("Message:${notification.notMessage}"),
                                      // notMessage as body
                                      ),
                                      SizedBox(height: heightval*0.02,),
                                      Text(notification.notDate.toString()),
                                    ],
                                  ),
                                );
                            },
                          )
                        ),
                        actions:
                        [
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Closes dialog
                              },
                              child: Text("Close"),
                            ),
                          ),
                        ],

                      );

                    },
                  );//show dialogue

                },
                icon:
                Obx(
                      ()=>New_Notification_Cont.Is_New_Notification_Value.value==true?Icon(Icons.notifications_active)
                      :Icon(Icons.notifications),
                ),
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
              ),

          SizedBox(width: shortestval*0.01,),


        ],
      ),

      drawer: Drawer(
        child:
        FutureBuilder(
          future: GetFriendInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
            {
              return Circular_pro_indicator_Yellow(context); // While waiting for response
            }
            else if (snapshot.hasError)
            {
              return Text('Error: ${snapshot.error}'); // If there's an error
            }
            else if (snapshot.connectionState == ConnectionState.done)
            {
              if (FriendInfoList.isNotEmpty || FriendInfoList.length>=1)
              {
                return ListView.builder(
                    itemBuilder: (context, index) {
                      return
                        Container (
                        child:
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children:
                              [
                                Text("Friend Username:${FriendInfoList[index].firendUsername}",style: TextStyle(fontFamily: semibold,fontSize: shortestval*0.05),),
                                Icon(Icons.people_rounded),
                              ],
                            ).onTap((){
                              Navigator.push(context,MaterialPageRoute(builder: (context)
                              {
                                return User_Friend_Profile_Screen_P(
                                  FriendUsername:FriendInfoList[index].firendUsername!,
                                  Current_User_Usertype:widget.usertype ,
                                Current_User_Username: widget.username,
                                Current_User_Jwt_Token: widget.jwttoken,);
                              },));
                            }),
                            Container(
                              height: heightval*0.006,
                              color: Colors.teal,
                              width: widthval,
                            ),
                          ],
                        ),
                      ) ;

                    },
                    itemCount: FriendInfoList.length
                );

              }
              else
              {
                return Center(child: Text('No friend info.Please close and reopen app or add friend.')); // If no user data
              }
            }
            else
            {
              return Center(child: Text('Error.Relogin.')); // Default loading state
            }
          },

        ),
      ),

      body:
      Container (
        width:widthval,
        height: heightval,
        color: Colors.grey,
        child:
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: BouncingScrollPhysics(),
          child: Column(
            children:
            [

              (shortestval*0.01).heightBox,

              FutureBuilder(
                future: getUserInfo(widget.username, widget.jwttoken),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                  {
                    return CircularProgressIndicator(); // While waiting for response
                  }
                  else if (snapshot.hasError)
                  {
                    return Text('Error: ${snapshot.error}'); // If there's an error
                  }
                  else if (snapshot.connectionState == ConnectionState.done)
                  {
                    if (userinfomodel_list.isNotEmpty || userinfomodel_list.length>=1)
                    {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: userinfomodel_list[0].photo == null ||
                              userinfomodel_list[0].photo!.isEmpty
                              ? Image.asset('assets/default_photo.jpg') // Default image if no photo
                              : Image.memory(
                            base64Decode(userinfomodel_list[0].photo!),
                            fit: BoxFit.fill,
                          ),
                        ),
                      );
                    }
                    else
                    {
                      return Text('No image data available'); // If no user data
                    }
                  }
                  else
                  {
                    return Text('Error.Relogin.'); // Default loading state
                  }
                },

              ),

              (shortestval*0.01).heightBox,

          Container(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(shortestval*0.03), // Border radius here
                      ),
                    ),
                    onPressed: ()async
                    {
                      try {
                        change_photo_cont_isloading.change_isloadingval(true);
                        bool result1 = await change_photo_cont_getx.pickImage();
                        print(result1);
                        if (result1 == true) {
                          print(change_photo_cont_getx.imagePath.toString());
                          print(change_photo_cont_getx.imageBytes.value);
                          bool result2 = await UpdatePhoto(username: widget
                              .username,
                              jwttoken: widget.jwttoken,
                              photo_bytes: change_photo_cont_getx.imageBytes
                                  .value);
                          print(result2);
                          if (result2 == true)
                          {
                            Toastget().Toastmsg("Update success");
                            change_photo_cont_getx.imageBytes.value = null;
                            change_photo_cont_getx.imagePath.value = "";
                            change_photo_cont_isloading.change_isloadingval(false);
                            setState(() {

                            });
                            return;
                          }
                          else {
                            change_photo_cont_isloading.change_isloadingval(false);
                            Toastget().Toastmsg("Update failed");
                            return;
                          }
                        }
                        else {
                          change_photo_cont_isloading.change_isloadingval(false);
                          Toastget().Toastmsg("No image select.Try again.");
                          return;
                        }
                      }catch(obj){
                        change_photo_cont_isloading.change_isloadingval(false);
                        print("Exception caught in change photo method.");
                        Toastget().Toastmsg("Change photo fail.Try again.");
                        return;
                      }


                    },
                    child: change_photo_cont_isloading.isloading.value==true?Circular_pro_indicator_Yellow(context):Text("Change photo",style:
                    TextStyle(
                        fontFamily: semibold,
                        color: Colors.black,
                        fontSize: shortestval*0.05
                    ),
                    ),
                  ),
                ),
              (shortestval*0.03).heightBox,
              FutureBuilder(
                            future: getUserInfo(widget.username, widget.jwttoken),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Text('UserName:');
                              }
                              else if (snapshot.hasError)
                              {
                                return Text('UserName:');
                              }
                              else if (snapshot.connectionState == ConnectionState.done)
                              {
                                if (userinfomodel_list.isNotEmpty || userinfomodel_list.length>=1)
                                {
                                 return Container (
                                   child: Column(
                                     children: [
                                       Text("UserName:${userinfomodel_list[0].username}",style: TextStyle(
                                           fontFamily: semibold,
                                           color: Colors.white,
                                           fontSize: shortestval*0.05
                                       ),
                                       ),
                                     ],
                                   ),
                                 );
                                }
                                else
                                {
                                  return Text('UserName:');
                                }
                              }
                              else
                              {
                                return Text('UserName:');
                              }
                            },
                        ),



              (shortestval*0.03).heightBox,

              Container (
                color: Colors.green,
                child: Column(
                  children: [

                    Container (
                        width: widthval,
                        height: heightval*0.06,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          border: Border.all(
                            color: Colors.blue,
                            width: shortestval*0.0080,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(shortestval*0.03),
                        ),
                        child:
                        Row(
                          children: [

                            Expanded(
                              child: Text("Change password",style:
                              TextStyle(
                                  fontFamily: semibold,
                                  color: Colors.black,
                                  fontSize: shortestval*0.06
                              ),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(right: shortestval*0.05),
                              child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.change_circle)),
                            ),

                          ],
                        )
                    ).onTap(()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (context)
                      {
                        return Updatepassword(jwttoken: widget.jwttoken,username: widget.username,
                            usertype: widget.usertype);
                      },
                      )
                      );

                    }),

                    Container (
                        width: widthval,
                        height: heightval*0.06,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          border: Border.all(
                            color: Colors.blue,
                            width: shortestval*0.0080,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(shortestval*0.03),
                        ),
                        child:
                        Row(
                          children: [

                            Expanded(
                              child: Text("Change Email",style:
                              TextStyle(
                                  fontFamily: semibold,
                                  color: Colors.black,
                                  fontSize: shortestval*0.06
                              ),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(right: shortestval*0.05),
                              child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.change_circle)),
                            ),

                          ],
                        )
                    ).onTap(()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (context)
                      {
                        return Updateemail(jwttoken: widget.jwttoken,usertype: widget.usertype,username: widget.username,);
                      },
                      )
                      );

                    }),


                    Container (
                        width: widthval,
                        height: heightval*0.06,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          border: Border.all(
                            color: Colors.blue,
                            width: shortestval*0.0080,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(shortestval*0.03),
                        ),
                        child:
                        Row(
                          children: [

                            Expanded(
                              child: Text("Change Phone Number",style:
                              TextStyle(
                                  fontFamily: semibold,
                                  color: Colors.black,
                                  fontSize: shortestval*0.06
                              ),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(right: shortestval*0.05),
                              child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.change_circle)),
                            ),

                          ],
                        )
                    ).onTap(()
                    {

                      Navigator.push(context, MaterialPageRoute(builder: (context)
                      {
                        return ChangePhoneNumber(jwttoken: widget.jwttoken,usertype: widget.usertype,username: widget.username,);
                      },
                      )
                      );
                    }),

                    Container (
                        width: widthval,
                        height: heightval*0.06,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          border: Border.all(
                            color: Colors.blue,
                            width: shortestval*0.0080,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(shortestval*0.03),
                        ),
                        child:
                        Row(
                          children: [

                            Expanded(
                              child: Text("Change Address",style:
                              TextStyle(
                                  fontFamily: semibold,
                                  color: Colors.black,
                                  fontSize: shortestval*0.06
                              ),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(right: shortestval*0.05),
                              child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.change_circle)),
                            ),

                          ],
                        )
                    ).onTap (()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (context)
                      {
                        return UpdateAddress(jwttoken: widget.jwttoken,usertype: widget.usertype,username: widget.username,);
                      },
                      )
                      );
                    }),


                  ],
                ),
              ),

              (shortestval*0.03).heightBox,

              Align(
                alignment: Alignment.center,
                child: Container(
                  child:

                  ElevatedButton (
                    onPressed:
                        () async
                    {
                      try{
                        logout_button_cont_isloading.change_isloadingval(true);
                        await clearUserData();
                        logout_button_cont_isloading.change_isloadingval(false);
                        await deleteTempDirectoryPostVideo();
                        await deleteTempDirectoryCampaignVideo();
                        print("Deleteing temporary directory success.");
                        Toastget().Toastmsg("Logout Success");
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)
                        {
                          return Home();
                        },
                        )
                        );
                      }catch(obj)
                      {
                        logout_button_cont_isloading.change_isloadingval(false);
                        print("Logout fail.Exception occur.");
                        print("${obj.toString()}");
                        Toastget().Toastmsg("Logout fail.Try again.");
                      }
                    }
                    ,
                    child:logout_button_cont_isloading.isloading.value==true?Circular_pro_indicator_Yellow(context):Text("Log Out",style:
                    TextStyle(
                        fontFamily: semibold,
                        color: Colors.blue,
                        fontSize: shortestval*0.05
                    ),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreenAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(shortestval*0.03),
                        )
                    ),
                  ),
                ),
              ),

              (shortestval*0.03).heightBox,
              ExpansionTile(
                title:Text("Note.", style: TextStyle(fontFamily: bold,fontSize: shortestval*0.07,color: Colors.black),),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                children:
                [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Keep the screenshot of profile screen which is need in future for confirmation of user while recoverring password.",
                      style: TextStyle(fontFamily: semibold,fontSize: shortestval*0.06,color: Colors.black),
                      textAlign: TextAlign.justify,
                    ),
                  ),

                ],
              ),
              (shortestval*0.03).heightBox,
              FutureBuilder<void>(
                future: GetProfilePostInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();  // Make sure this is the right indicator
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error fetching posts. Please try again.",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  } else if (snapshot.connectionState == ConnectionState.done) {
                    return ProfilePostInfoList.isEmpty
                        ? const Center(child: Text("No post available."))
                        : Column(
                          children: ProfilePostInfoList.map((post)
                          {
                            return _buildPostCardProfilePostInfo(post, context);
                          }).toList(),
                        );
                  } else {
                    return Center(
                      child: Text(
                        "Please reopen app.",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }
                },
              ),


            ],
          ),
        ),
      ),

    );
  }

}


