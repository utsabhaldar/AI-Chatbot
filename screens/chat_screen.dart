import 'dart:developer';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:fifth_app/constants/constants.dart';
import 'package:fifth_app/services/assets_manager.dart';
import 'package:fifth_app/widgets/chat_widgets.dart';
import 'package:fifth_app/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:velocity_x/velocity_x.dart';
import '../providers/chat_provider.dart';
import '../providers/models_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;
  bool _isTyping = false;

  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;
  late stt.SpeechToText _speech;

  @override
  void initState() {
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
    _speech = stt.SpeechToText();
    super.initState();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // List<ChatModel> chatList = [];
  @override
  Widget build(BuildContext context) {
    final modelsProvider = Provider.of<ModelsProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Image.asset(AssetsManager.Logo_remove_bg),
          ),
        ),
        title: const Text("Universal AI"),
        // actions: [
        //   IconButton(
        //     onPressed: () async {
        //       await Services.showModalSheet(context: context);
        //     },
        //     icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
        //   ),
        // ],
        actions: const [
          Padding(
            padding: EdgeInsets.all(18.0),
            child: Icon(Icons.sort_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Flexible(
            child: ListView.builder(
                controller: _listScrollController,
                itemCount: chatProvider.getChatList.length, //chatList.length,
                itemBuilder: (context, index) {
                  return ChatWidget(
                    msg: chatProvider.getChatList[index].msg,
                    chatIndex: chatProvider.getChatList[index].chatIndex,
                  );
                }),
          ),
          if (_isTyping) ...[
            const SpinKitThreeBounce(
              color: Colors.white,
              size: 18,
            ),
          ],
          const SizedBox(
            height: 15,
          ),
          Material(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            onPressed: () async {
                              const ClearSelectionEvent();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: TextWidget(
                                    label: "Message already generated",
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }, //To be set
                            icon: const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 35,
                            ).shimmer(
                                primaryColor: Colors.white,
                                secondaryColor: Colors.red,
                                duration: const Duration(seconds: 2)),
                          ),
                          const Text(
                            "Stop\nGenerating",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      AvatarGlow(
                        animate: _isListening,
                        glowColor: Colors.white,
                        endRadius: 55.0,
                        duration: const Duration(seconds: 2),
                        repeatPauseDuration: const Duration(milliseconds: 1),
                        repeat: true,
                        child: FloatingActionButton(
                          onPressed: () {
                            setState(() {
                              _listen();
                            });
                          },
                          backgroundColor: Colors.black,
                          child:
                              Icon(_isListening ? Icons.mic : Icons.mic_none),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () async {
                              _listScrollController.animToTop();
                            },
                            icon: const Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                              size: 30,
                            ).shimmer(
                                primaryColor: Colors.white,
                                secondaryColor: Colors.yellow.shade300,
                                duration: const Duration(seconds: 2)),
                          ),
                          const Text(
                            "Scroll up",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          IconButton(
                            onPressed: () async {
                              _listScrollController.animToBottom();
                            },
                            icon: const Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.white,
                              size: 30,
                            ).shimmer(
                                primaryColor: Colors.white,
                                secondaryColor: Colors.yellow.shade300,
                                duration: const Duration(seconds: 2)),
                          ),
                          const Text(
                            "Scroll down",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Text(
                          'Tap me and start speaking',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: focusNode,
                          style: const TextStyle(color: Colors.white),
                          controller: textEditingController,
                          onSubmitted: (value) async {
                            await sendMessageFCT(
                                modelsProvider: modelsProvider,
                                chatProvider: chatProvider);
                          },
                          decoration: const InputDecoration.collapsed(
                              hintText: "How can I help you?   [ English(US) ]",
                              hintStyle: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await sendMessageFCT(
                              modelsProvider: modelsProvider,
                              chatProvider: chatProvider);
                        },
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 30,
                        ).shimmer(
                            primaryColor: Colors.white,
                            secondaryColor: Colors.green,
                            duration: const Duration(seconds: 2)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void scrollListToEnd() {
    _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut);
  }

  Future<void> sendMessageFCT(
      {required ModelsProvider modelsProvider,
      required ChatProvider chatProvider}) async {
    if (_isTyping && _isListening) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: TextWidget(
          label: "You can not send multiple messages at a time",
        ),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: TextWidget(
          label: "Please type a message",
        ),
        backgroundColor: Colors.red,
      ));
      return;
    }
    try {
      String msg = textEditingController.text;
      setState(() {
        _isTyping = true;
        _isListening = false;
        // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));
        chatProvider.addUserMessage(msg: msg);
        textEditingController.clear();
        focusNode.unfocus();
      });
      await chatProvider.sendMessageAadGetAnswers(
          msg: msg, chosenModelId: modelsProvider.getCurrentModel);
      // chatList.addAll(await ApiService.sendMessage(
      //   message: textEditingController.text,
      //   modelId: modelsProvider.getCurrentModel,
      // ));
      setState(() {});
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TextWidget(
          label: error.toString(),
        ),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        scrollListToEnd();
        _isTyping = false;
        _isListening = false;
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;

            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
              textEditingController.text = _text;
            }
          }),
        );
      } else {
        setState(() {
          _isListening = false;
          _isTyping = false;
          _speech.stop();
        });
      }
    }
  }
}
