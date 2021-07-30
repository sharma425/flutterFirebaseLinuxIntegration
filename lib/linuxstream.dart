// import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var fsConnect = FirebaseFirestore.instance;

  var cmd;

  // var now = new DateTime.now();

  var output;

  var errorText;
  var msgTextController = TextEditingController();

  uploadData(cmd, output) async {
    var date = new DateTime.now().toString();
    var timeStamp = DateTime.parse(date).millisecondsSinceEpoch;
    fsConnect
        .collection("linuxCommand")
        .add({"command": cmd, "output": output, "timeStamp": timeStamp});
  }

  myWeb(cmd) async {
    try {
      errorText = null;
      var url = "http://192.168.43.13/cgi-bin/web.py?x=${cmd}";
      var response = await http.get(url);
      output = response.body;
      uploadData(cmd, output);
    } catch (e) {
      setState(() {
        print("object");
        errorText = "Cannot connect to Linux";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Center(child: Text("root@localhost:/")),
        ),
        body: DraggableScrollableSheet(
          initialChildSize: 1,
          builder: (
            context,
            scrollController,
          ) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                height: 800,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      builder: (context, snapshot) {
                        var msg = snapshot.data.docs;
                        List<Widget> y = [];
                        print(msg);
                        print("hello");
                        for (var d in msg) {
                          var msgcmd = d.data()['command'];
                          var msgout = d.data()['output'];
                          var msgcmdwidget = Row(
                            children: [
                              Text(
                                "[root@localhost ~]# ",
                                style: TextStyle(color: Colors.amber),
                              ),
                              Text("$msgcmd",
                                  style: TextStyle(
                                    color: Colors.blue,
                                  ))
                            ],
                          );
                          var msgoutwidget = Row(
                            children: [Text("$msgout")],
                          );

                          y.add(msgcmdwidget);
                          y.add(msgoutwidget);
                        }
                        return Column(
                          children: [
                            Column(children: y),
                            TextField(
                              onChanged: (value) {
                                cmd = value;
                                print(cmd);
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixText: "[root@localhost ~]# ",
                                prefixStyle: TextStyle(color: Colors.amber),
                                errorText: errorText ?? null,
                              ),
                              style: TextStyle(color: Colors.blue),
                              controller: msgTextController,
                            )
                          ],
                        );
                      },
                      stream: fsConnect
                          .collection("linuxCommand")
                          .orderBy('timeStamp', descending: false)
                          .snapshots(),
                    ),
                    Material(
                      child: MaterialButton(
                        minWidth: double.infinity,
                        height: 40,
                        onPressed: () async {
                          msgTextController.clear();
                          myWeb(cmd);
                        },
                        child: Text("Enter"),
                      ),
                      color: Colors.black,
                      elevation: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
