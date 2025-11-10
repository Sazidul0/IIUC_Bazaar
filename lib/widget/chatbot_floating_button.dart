import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../MVVM/View Model/chatbotViewModel.dart';

// --- MAIN FLOATING CHATBOT WIDGET ---
class FloatingChatbot extends StatefulWidget {
  const FloatingChatbot({super.key});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> {
  late Offset position;
  bool isOpen = false;
  bool isInitialized = false;
  final ChatBotViewModel controller = Get.put(ChatBotViewModel());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      position = Offset(screenSize.width - 80, screenSize.height - 150);
      isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Chat Window (with animation)
        // This AnimatedPositioned will make the window slide in and out smoothly
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          // When closed, move it off-screen. When open, position it correctly.
          bottom: isOpen ? 100 : -screenSize.height,
          right: 20,
          child: Material(
            elevation: 16,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: screenSize.width * 0.9 > 380 ? 380 : screenSize.width * 0.9,
              height: screenSize.height * 0.7 > 550 ? 550 : screenSize.height * 0.7,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F9), // Use the beautiful soft background
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // --- Redesigned Header ---
                  _buildChatHeader(),

                  // --- Redesigned Messages Area ---
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

                  // --- Redesigned Input Field ---
                  _buildTextComposer(),
                ],
              ),
            ),
          ),
        ),

        // --- Floating Action Button ---
        Positioned(
          left: position.dx,
          top: position.dy,
          child: Draggable(
            feedback: _buildFloatingButton(isFeedback: true),
            childWhenDragging: Container(),
            onDragEnd: (details) => _updateButtonPosition(details, context),
            child: _buildFloatingButton(),
          ),
        ),
      ],
    );
  }

  /// Builds the floating chat button.
  Widget _buildFloatingButton({bool isFeedback = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => isOpen = !isOpen),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: isFeedback ? 70 : 64,
          height: isFeedback ? 70 : 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(
              isOpen ? Icons.close_rounded : Icons.chat_bubble_rounded,
              key: ValueKey<bool>(isOpen), // Important for AnimatedSwitcher
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  /// Keeps the floating button within the screen bounds after dragging.
  void _updateButtonPosition(DraggableDetails details, BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    double newX = details.offset.dx;
    double newY = details.offset.dy;

    if (newX < 0) newX = 0;
    if (newX > screenSize.width - 64) newX = screenSize.width - 64;
    if (newY < 40) newY = 40;
    if (newY > screenSize.height - 100) newY = screenSize.height - 100;

    setState(() => position = Offset(newX, newY));
  }

  /// Builds the beautiful, redesigned header for the chat window.
  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FIX: Wrap title in Flexible to prevent overflow
          Flexible(
            child: Text(
              'Bazaar AI Assistant',
              style: GoogleFonts.nunitoSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Obx(
                () => ToggleButtons(
              isSelected: [!controller.isBangla.value, controller.isBangla.value],
              onPressed: (index) => controller.setLanguage(index == 1),
              color: Colors.white70,
              selectedColor: Colors.redAccent,
              fillColor: Colors.white,
              borderColor: Colors.white54,
              selectedBorderColor: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              constraints: const BoxConstraints(minHeight: 30.0),
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
        ],
      ),
    );
  }

  /// Builds the beautiful, redesigned text input composer.
  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
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
                  key: const ValueKey('send_button'),
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
// (Copy the ChatMessageBubble and AnimatedAITypingIndicator classes from the previous answer
// and paste them here, right below the _FloatingChatbotState class.)
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