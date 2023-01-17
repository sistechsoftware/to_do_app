import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/config/recognition_config.dart';
import 'package:google_speech/config/recognition_config_v1.dart';
import 'package:google_speech/config/streaming_recognition_config.dart';
import 'package:google_speech/speech_client_authenticator.dart';
import 'package:google_speech/speech_to_text.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record_windows/record_windows.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:to_do/dao/task_dao.dart';
import 'package:to_do/record/src/types/types.dart';
import 'models/task_model.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'To Do Application'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late final Database db;
  final TaskDao _taskDao = TaskDao();
  String _description = "";
  String _title = "";
  String _audioDirectory = "";
  String _status = "";
  List<Task> _tasks = [];
  Task? task;
  int? selected = 3;
  String _fileName = "";
  String _pathFile = "";
  bool _isRecording = false;
  bool recognizing = false;
  bool recognizeFinished = false;
  bool isPlaying = false;
  String text = '';
  bool hasAudio =  false;



  final player = AudioPlayer();



  static const countUpDuration = Duration(minutes: 0);
  Duration duration = Duration();
  Timer? timer;
  bool countUp =true;

  TextEditingController descriptionController = TextEditingController();

  final record = RecordWindows();

  void recognize(StateSetter setState) async {
    setState(() {
      recognizing = true;
    });
    final serviceAccount = ServiceAccount.fromString((await rootBundle.loadString('assets/erudite-course-338305-3be0bd2d321b.json')));
    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);
    final config = _getConfig();
    final String path = File(Platform.resolvedExecutable).parent.path + '/audios/' + _fileName + '.flac';
    final audio = await _getAudioContent(path);

    await speechToText.recognize(config, audio).then((value) {
      setState(() {
        text = value.results.
                 map((e) => e.alternatives.first.transcript)
                 .join('\n');
        descriptionController.text = text;
        _description = text.toString();
        _audioDirectory = path;
      });
    }).whenComplete(() =>
        setState(() {
          recognizeFinished = true;
          recognizing = false;
        }));
  }

  Widget waitMessage(StateSetter stateSetter) {
    return Center(child: Row(
      children: const [
        SizedBox(height: 20,),
        CircularProgressIndicator(),
        SizedBox(width: 10,),
        Text("Converting audio...")
      ],
    ),);
  }

  void playAudio(String localFile) async {
    await player.play(DeviceFileSource(localFile));

    player.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });

    setState(() {
      isPlaying = true;
    });
  }

  void stopAudio() async {
    await player.stop();

    setState(() {
      isPlaying = false;
    });
  }

  void streamingRecognize() async {
    setState(() {
      recognizing = true;
    });
    final serviceAccount = ServiceAccount.fromString(
        (await rootBundle.loadString('assets/erudite-course-338305-3be0bd2d321b.json')));
    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);
    final config = _getConfig();

    final responseStream = speechToText.streamingRecognize(
        StreamingRecognitionConfig(config: config, interimResults: true),
        await _getAudioStream('C:/Users/ueric/AndroidStudioProjects/to_do/build/windows/runner/Debug/uericlis.m4a'));

    responseStream.listen((data) {
      setState(() {
        text = data.results.map((e) => e.alternatives.first.transcript).join('\n');
        _description = data.results.map((e) => e.alternatives.first.transcript).join('\n');
        recognizeFinished = true;
        log("Response " + text);
      });
    }, onDone: () {
      setState(() {
        recognizing = false;
      });
    });
  }

  RecognitionConfig _getConfig() => RecognitionConfig(
      encoding: AudioEncoding.FLAC,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: false,
      sampleRateHertz: 44100,
      audioChannelCount: 1,
      languageCode: 'en-US');

  Future<void> _copyFileFromAssets(String name) async {
    var data = await rootBundle.load('assets/$name');
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + '/$name';
    await File(path).writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<List<int>> _getAudioContent(String name) async {
    String path = name; //"C:/Users/ueric/AndroidStudioProjects/to_do" '/$name'; //await Utilities.getVoiceFilePath() + '/$name'; //databaseFactoryFfi.getDatabasesPath() + '/$name'; //directory.path + '/$name';
    if (!File(path).existsSync()) {
      await _copyFileFromAssets(name);
    }
    return File(path).readAsBytesSync().toList();
  }

  Future<Stream<List<int>>> _getAudioStream(String name) async {
    final path = name; //await databaseFactoryFfi.getDatabasesPath() + '/$name';//directory.path + '/$name';
    if (!File(path).existsSync()) {
      await _copyFileFromAssets(name);
    }
    return File(path).openRead();
  }

  void _save(Task task) async {
    TaskDao taskDao = TaskDao();
    try {

      if (task.status == "") {
        task.status = "W";
      }

      Task t = await taskDao.addNewTask(task);
      task.id = t.id;

      _loadItems();
    } catch (error) {
      log(error.toString());
    }
  }

  Future<void> initPlatformState() async {
    //_hasMicPermission = await recorder.hasMicPermission();
    if (!mounted) return;
    setState(() {});
  }

  void _update(Task task) async {
    TaskDao taskDao = TaskDao();
    try {
      bool success  = await taskDao.updateTask(task);
      _loadItems();
      setState(() {});
    } catch(error) {
      log(error.toString());
    }
  }

  void _delete(Task task) async {
    TaskDao taskDao = TaskDao();
    try {
      bool success = await taskDao.delete(task);

      if (success) {
        setState(() {
          hasAudio = false;
        });
      }

    } catch(error) {
      log(error.toString());
    }
  }

  void _loadItems() async {

    try {
      List<Task> tasks = await _taskDao.getAll();

      _tasks.clear();
      _tasks.addAll(tasks);

      initVariables();
    } catch(error) {
      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('An error occured loading the taks')));
    }
  }

  void initVariables() {
    log("Cleaning variables");
    setState(() {
      _status = "";
      _description = "";
      _title = "";
      _audioDirectory = "";
      _fileName = "";
      selected = 3;
      descriptionController.text = "";
    });
  }

  void _addNewTask() {
    showDialog(
        context: this.context,
        builder: (context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Add a new task", style: TextStyle(fontSize: 18),),
              titlePadding: const EdgeInsets.all(20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Press to record an andio'),
                  const SizedBox(height: 10,),
                  _isRecording ? buildTime()
                      : Row(),
                  !_isRecording ?
                  IconButton(
                    icon: const Icon(Icons.mic, size: 40),
                    onPressed: () => {
                      start(),
                      startTimer(setState)
                    },
                  )
                  :
                  IconButton(
                    icon: const Icon(Icons.stop, size: 40),
                    onPressed: () => {
                        stop(setState),
                        recognize(setState)
                    },
                  ),

                  const SizedBox(height: 20,),

                  TextField(
                    decoration: const InputDecoration(
                        labelText: "Title"
                    ),
                    onChanged: (text) {
                      _title = text;
                    },
                  ),

                  const SizedBox(height: 20,),

                  recognizing ? Center(child: waitMessage(setState), )
                  : TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                        labelText: "Type your task"
                    ),
                    onChanged: (text) {
                      _description = text;
                    },
                  ),


                  const SizedBox(height: 30,),

                  hasAudio ? Container(
                    width: 300,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    // color: Colors.white12,
                    child: Center(
                      child: Row(

                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                            onPressed: () => {
                              if (!isPlaying)
                                playAudio(_pathFile)
                              else
                                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('This audio is already playing')))
                            },
                          ),

                          const SizedBox(height: 20,),

                          IconButton(
                            icon: const Icon(Icons.stop, color: Colors.white, size: 40),
                            onPressed: () => {
                              if (isPlaying)
                                stopAudio()
                            },
                          ),
                        ],),
                    ),
                  )
                      :
                  Row(),

                  const SizedBox(height: 30,),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RadioListTile<int>(
                        title: const Text('Done'),
                        groupValue: selected,
                        value: 1,
                        onChanged:(int? value) {
                          if (!_isRecording && !recognizing) {
                            setStatus(value!, setState);
                          }
                        },
                      ),
                      RadioListTile<int>(
                        title: const Text('Running'),
                        groupValue: selected,
                        value: 2,
                        onChanged:(int? value) {
                          if (!_isRecording && !recognizing) {
                            setStatus(value!, setState);
                          }
                        },
                      ),
                      RadioListTile<int>(
                        //tileColor: Colors.red,
                        title: const Text('Waiting'),
                        groupValue: selected,
                        value: 3,
                        onChanged:(int? value) {
                          if (!_isRecording && !recognizing) {
                            setStatus(value!, setState);
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    if (recognizing || _isRecording) {
                      _cancelDialog();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                TextButton(
                  child: const Text("Save"),
                  onPressed: () {
                    if (!_isRecording && !recognizing) {
                      task = Task(description: _description,
                          status: _status,
                          title: _title,
                          audioDirectory: _audioDirectory);
                      _save(task!);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('A record is running, please, wait!')));
                    }
                  },
                ),
              ],
              contentPadding: const EdgeInsets.all(10),
            );
          });
        });
  }

  void _deleteDialog(int index, Task task) {
    showDialog(
        context: this.context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Confirm"),
            titlePadding: const EdgeInsets.all(20),
            content: const Text("Are you sure you want to remove this task?"),
            actions: <Widget>[
              TextButton(
                child: const Text("No"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Yes"),
                onPressed: () {
                  _delete(task);
                  _loadItems();
                  Navigator.pop(context);
                },
              ),
            ],
            contentPadding: const EdgeInsets.all(10),
          );
        });
  }

  void _cancelDialog() {
    showDialog(
        context: this.context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Confirm"),
            titlePadding: const EdgeInsets.all(20),
            content: const Text("Are you sure you want to exit and discard this audio record?"),
            actions: <Widget>[
              TextButton(
                child: const Text("No"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Yes"),
                onPressed: () {
                  stop(setState);
                  Navigator.pop(context);
                },
              ),
            ],
            contentPadding: const EdgeInsets.all(10),
          );
        });
  }

  void setStatus(int value, StateSetter setState) {
    setState(() {
      selected = value;

      if (selected == 1) {
        _status = 'D';
      }

      if (selected == 2) {
        _status = 'R';
      }

      if (selected == 3) {
        _status = 'W';
      }
    });
  }

  void updateTask(Task task) {

    hasAudio = task.audioDirectory != "";

    var descController = TextEditingController();
    descController.text = task.description;

    var titleController = TextEditingController();
    titleController.text = task.title;

    String status = task.status;

    task.description = descController.text;
    task.title = titleController.text;
    _title = titleController.text;
    _description = descController.text;
    if (status == 'R') {
      selected = 2;
      task.status = 'R';
    }

    if (status == 'W') {
      selected = 3;
      task.status = 'W';
    }

    if (status == 'D') {
      selected = 1;
      task.status = 'D';
    }

    showDialog(
        context: this.context,
        builder: (context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Update task", style: TextStyle(fontSize: 18),),
              titlePadding: const EdgeInsets.all(20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Press to record an audio'),
                  const SizedBox(height: 10,),
                  _isRecording ? buildTime()
                      : Row(),
                  !_isRecording ?
                  IconButton(
                    icon: const Icon(Icons.mic, size: 40),
                    onPressed: () => {
                      start(),
                      startTimer(setState)
                    },
                  )
                      :
                  IconButton(
                    icon: const Icon(Icons.stop, size: 40),
                    onPressed: () => {
                      stop(setState),
                      recognize(setState)
                    },
                  ),

                  recognizing ? const CircularProgressIndicator() : Row(),

                  TextField(
                    controller: titleController,
                    enabled: !recognizing && !_isRecording,
                    decoration: const InputDecoration(
                        labelText: "Title"
                    ),
                    onChanged: (text) {
                      _title = text;
                    },
                  ),

                  const SizedBox(height: 20,),

                  recognizing ? Center(child: waitMessage(setState), )
                    : TextField(
                    controller: descController,
                    enabled: !recognizing && !_isRecording,
                    decoration: const InputDecoration(
                        labelText: "Type your task"
                    ),
                    onChanged: (text) {
                      _description = text;
                    },
                  ),

                  const SizedBox(height: 30,),

                   hasAudio ? Container(
                     width: 300,
                     height: 50,
                     decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                     ),

                    // color: Colors.white12,
                    child: Center(
                      child: Row(

                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                            onPressed: () => {
                              if (!isPlaying)
                                playAudio(task.audioDirectory)
                              else
                                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('This audio is already playing')))
                            },
                          ),

                          const SizedBox(height: 20,),

                          IconButton(
                            icon: const Icon(Icons.stop, color: Colors.white, size: 40),
                            onPressed: () => {
                              if (isPlaying)
                                stopAudio()
                            },
                          ),
                        ],),
                    ),
                  )
                  :
                  Row(),
                  const SizedBox(height: 30,),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RadioListTile<int>(
                        title: const Text('Done'),
                        groupValue: selected,
                        value: 1,
                        onChanged:(int? value) {
                          if (!_isRecording && !recognizing) {
                            setState(() {;
                              setStatus(value!, setState);
                            });
                          }
                        },
                      ),
                      RadioListTile<int>(
                        title: const Text('Running'),
                        groupValue: selected,
                        value: 2,
                        onChanged:(int? value) {
                          if (!_isRecording && !recognizing) {
                            setState(() {
                              setStatus(value!, setState);
                            });
                          }
                        },
                      ),
                      RadioListTile<int>(
                        //tileColor: Colors.red,
                        title: const Text('Waiting'),
                        groupValue: selected,
                        value: 3,
                        onChanged:(int? value) {
                          if (!_isRecording && !recognizing) {
                            setState(() {
                              setStatus(value!, setState);
                            });
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    if (_isRecording || recognizing) {
                      _cancelDialog();
                    } else {
                      Navigator.pop(context);
                    }
                  }
                ),
                TextButton(
                  child: const Text("Update"),
                  onPressed: () {
                    if (!_isRecording && !recognizing) {
                      task = Task(id: task.id, description: _description,
                          status: _status,
                          title: _title,
                          audioDirectory: task.audioDirectory);
                      _update(task!);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('A record is running, please, wait!')));
                    }
                  },
                ),
              ],
              contentPadding: const EdgeInsets.all(10),
            );
          });
        });
  }

  Future start() async {
    _fileName = DateTime.now().millisecondsSinceEpoch.toString();
    _pathFile = join(File(Platform.resolvedExecutable).parent.path, 'audios/' + _fileName + '.flac');

    setState(() {
      _isRecording = true;
    });

    await record.start(
      path: join(_pathFile), encoder: AudioEncoder.flac, numChannels: 1
    );
  }

  Future stop( StateSetter setState) async {
    await record.stop();

    setState(() {
      _isRecording = false;
      hasAudio = true;
    });

    stopTimer(setState);
  }
  @override
  void initState() {
    super.initState();
    _loadItems();
    initPlatformState();
    selected = 3;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_tasks[index].title),
                subtitle: Text(_tasks[index].description),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget> [
                    _tasks[index].status == 'D' ?
                    const Icon(Icons.done_rounded, color: Colors.green) :
                    Row(
                        children: const [
                        ]
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget> [
                  _tasks[index].audioDirectory != "" ?
                    IconButton(
                    icon: !isPlaying ? const Icon(Icons.play_circle) : const Icon(Icons.stop_circle_rounded),
                      onPressed: () {
                        if (isPlaying) {
                          stopAudio();
                        } else {
                          playAudio(_tasks[index].audioDirectory);
                        }
                      }
                    )
                    : const SizedBox(height: 10, width: 10,),
                    const SizedBox(width: 40,),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Task t = _tasks.elementAt(index);
                        updateTask(t);
                      }
                    ),
                    const SizedBox(width: 20,),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () {
                           Task t = _tasks.elementAt(index);
                           _deleteDialog(index, t);
                        },
                    ),
                  ],
                ),
                onTap: () {
                  Task t = _tasks.elementAt(index);
                  updateTask(t);
                },
              );
            }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        tooltip: 'New Task',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void addTime(StateSetter setState){
    final addSeconds = countUp ? 1 : 1;
    setState(() {
      final seconds = duration.inSeconds + addSeconds;
      if (seconds < 0){
        timer?.cancel();
      } else{
        duration = Duration(seconds: seconds);
      }
    });
  }

  Widget buildTimeCard({required String time, required String header}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20)
            ),
            child: Text(
              time, style: const TextStyle(fontWeight: FontWeight.bold,
                color: Colors.black26, fontSize: 30),),
          ),
          const SizedBox(height: 24,),
        ],
      );

  Widget buildTime(){
    String twoDigits(int n) => n.toString().padLeft(2,'0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildTimeCard(time: hours, header:'HOURS'),
          const SizedBox(width: 8,),
          buildTimeCard(time: minutes, header:'MINUTES'),
          const SizedBox(width: 8,),
          buildTimeCard(time: seconds, header:'SECONDS'),
        ]
    );
  }

  void stopTimer(StateSetter setState, {bool resets = true}){
    if (resets){
      reset();
    }
    setState(() => timer?.cancel());
  }

  void reset(){
    if (countUp){
      setState(() =>
      duration = countUpDuration);
    } else{
      setState(() =>
      duration = Duration());
    }
  }

  void startTimer(StateSetter stateSetter){
    timer = Timer.periodic(const Duration(seconds: 1),(_) => addTime(stateSetter));
  }
}

class Utilities {
  static Future<String> getVoiceFilePath() async {

    final String path = await databaseFactoryFfi.getDatabasesPath();
    if (path == null) {
      throw Exception(
          'Unable to get application documents directory');
    }

    Directory appDocumentsDirectory = await Directory(path); // 1
    String appDocumentsPath = appDocumentsDirectory.path; // 2
    String filePath = appDocumentsPath; // 3

    return filePath;
  }

}

