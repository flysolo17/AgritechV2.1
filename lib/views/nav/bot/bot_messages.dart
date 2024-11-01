import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  final List messages;
  const MessagesScreen({Key? key, required this.messages}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    return ListView.separated(
      itemBuilder: (context, index) {
        bool isUserMessage = widget.messages[index]['isUserMessage'];
        bool isLoading = widget.messages[index]['isLoading'] ??
            false; // Check if the message is being loaded
        return Container(
          margin: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUserMessage) // Add icon for bot response
                const Icon(Icons.flutter_dash_rounded,
                    color: Colors.green, size: 36.0), // Increase the size here
              const SizedBox(width: 8), // Add spacing between icon and message
              if (isLoading) // Show typing indicator if message is being loaded
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey), // Change the color here
                  ),
                ),
              if (!isLoading) // Show message if not loading
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomRight: Radius.circular(isUserMessage ? 20 : 20),
                      topLeft: Radius.circular(isUserMessage ? 20 : 20),
                    ),
                    color: isUserMessage
                        ? const Color(0xFFECECEC)
                        : const Color(0xFFD04848),
                  ),
                  constraints: BoxConstraints(maxWidth: w * 2 / 3),
                  child: Text(
                    widget.messages[index]['message'].text.text[0],
                    style: TextStyle(
                        color: isUserMessage
                            ? Colors.black
                            : const Color(0xFFECECEC)),
                  ),
                ),
            ],
          ),
        );
      },
      separatorBuilder: (_, i) =>
          const Padding(padding: EdgeInsets.only(top: 10)),
      itemCount: widget.messages.length,
    );
  }
}
