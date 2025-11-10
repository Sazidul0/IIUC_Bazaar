import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../MVVM/View Model/chatbotViewModel.dart';

// --- MAIN CHAT VIEW WIDGET ---
class ChatBotView extends StatelessWidget {
  const ChatBotView({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatBotViewModel controller = Get.put(ChatBotViewModel());
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // FIX 1: Ensure the Scaffold resizes when the keyboard appears.
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF3F6F9), // A softer, more modern background
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black26,
        backgroundColor: Colors.redAccent,
        // FIX 2: Wrap the title in a Flexible widget to prevent overflow.
        title: Flexible(
          child: Text(
            "Bazaar AI Assistant",
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis, // Handle very long titles gracefully
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Obx(
                  () => ToggleButtons(
                isSelected: [!controller.isBangla.value, controller.isBangla.value],
                onPressed: (index) => controller.setLanguage(index == 1),
                color: Colors.white70,
                selectedColor: Colors.redAccent,
                fillColor: Colors.white,
                splashColor: Colors.red.shade100,
                borderColor: Colors.white54,
                selectedBorderColor: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                constraints: const BoxConstraints(minHeight: 32.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('EN', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('BN', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(
                  () => ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                itemCount: controller.messages.length + (controller.isLoading.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.messages.length && controller.isLoading.value) {
                    return const AnimatedAITypingIndicator();
                  }

                  final msg = controller.messages[index];
                  return ChatMessageBubble(
                    text: msg['text']!,
                    isUser: msg['isUser']!,
                  );
                },
              ),
            ),
          ),
          _buildTextComposer(controller),
        ],
      ),
    );
  }

  /// The redesigned text input area.
  Widget _buildTextComposer(ChatBotViewModel controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Obx(
                    () => TextField(
                  controller: controller.inputController,
                  style: GoogleFonts.nunitoSans(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: controller.isBangla.value ? 'এখানে জিজ্ঞাসা করুন...' : "Ask anything...",
                    hintStyle: GoogleFonts.nunitoSans(color: Colors.grey.shade500),
                    fillColor: const Color(0xFFF3F6F9),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!controller.isLoading.value) {
                      controller.sendMessage();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
                  () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: controller.isLoading.value
                    ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.redAccent),
                  ),
                )
                    : CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 22),
                    onPressed: controller.sendMessage,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DYNAMIC & BEAUTIFUL CHAT BUBBLE WIDGET ---
class ChatMessageBubble extends StatefulWidget {
  final String text;
  final bool isUser;

  const ChatMessageBubble({super.key, required this.text, required this.isUser});

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: widget.isUser ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Row(
          mainAxisAlignment: widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isUser)
              const Padding(
                padding: EdgeInsets.only(right: 8.0, bottom: 4),
                child: CircleAvatar(
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(Icons.smart_toy, color: Colors.black54, size: 20),
                ),
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: widget.isUser
                      ? const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Colors.redAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: widget.isUser ? null : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: widget.isUser ? const Radius.circular(20) : const Radius.circular(4),
                    bottomRight: widget.isUser ? const Radius.circular(4) : const Radius.circular(20),
                  ),
                ),
                child: Text(
                  widget.text,
                  style: GoogleFonts.nunitoSans(
                    color: widget.isUser ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DYNAMIC & BEAUTIFUL AI TYPING INDICATOR ---
class AnimatedAITypingIndicator extends StatefulWidget {
  const AnimatedAITypingIndicator({super.key});

  @override
  State<AnimatedAITypingIndicator> createState() => _AnimatedAITypingIndicatorState();
}

class _AnimatedAITypingIndicatorState extends State<AnimatedAITypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final List<Widget> _dots = [];
  final int _dotCount = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_dotCount, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      )..forward();
    });

    for (int i = 0; i < _dotCount; i++) {
      _dots.add(
        FutureBuilder(
          future: Future.delayed(Duration(milliseconds: i * 200)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ScaleTransition(
                scale: Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controllers[i],
                    curve: Curves.elasticOut,
                  ),
                ),
                child: _buildDot(),
              );
            }
            return const SizedBox();
          },
        ),
      );
    }
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black26,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _dots,
        ),
      ),
    );
  }
}