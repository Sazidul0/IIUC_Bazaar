// model: 'gemini-2.5-flash', // Updated to a more recent model
// apiKey: 'AIzaSyA4eSbxSXxsjSMw6hWDGubrcTaRrvfceBU',

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBotViewModel extends GetxController {
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late GenerativeModel model;

  final RxBool isBangla = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey:dotenv.get('GEMINI_API_KEY'),
    );
  }

  void setLanguage(bool bangla) {
    isBangla.value = bangla;
  }

  Future<void> sendMessage() async {
    final userInput = inputController.text.trim();
    if (userInput.isEmpty || isLoading.value) return;

    isLoading.value = true;
    messages.add({'text': userInput, 'isUser': true});
    inputController.clear();
    _scrollToBottom();

    messages.add({'text': '...', 'isUser': false});
    _scrollToBottom();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messages.last['text'] = isBangla.value
          ? "অনুগ্রহ করে AI ব্যবহার করতে লগইন করুন।"
          : "Please login first to use AI Assistant.";
      messages.refresh();
      isLoading.value = false;
      _scrollToBottom();
      return;
    }

    final productSnap = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: user.uid)
        .get();

    final products = productSnap.docs.map((e) => e.data().toString()).toList();

    final prompt = """
    You are a friendly and helpful AI assistant for an e-commerce platform called 'IIUC Bazaar'.
    Your answers should be brief, clear, and directly related to the user's question.
    Strictly answer in the requested language.
    Current Language for response: ${isBangla.value ? "Bengali" : "English"}.
    User's product data: ${products.isEmpty ? "User has no products." : products.join(", ")}
    User's question: "$userInput"
    """;

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final output = response.text ?? (isBangla.value ? "দুঃখিত, বুঝতে পারিনি।" : "Sorry, I couldn't understand.");

      messages.last['text'] = output;
    } catch (e) {
      // --- THIS IS THE CRITICAL DEBUGGING STEP ---
      print("----------- GEMINI API ERROR -----------");
      print(e);
      print("--------------------------------------");

      messages.last['text'] = isBangla.value ? "আপনি ফ্রি টিয়ার ব্যবহার করছেন, এবং অনেক ব্যবহারকারী বর্তমানে ব্যস্ত। অনুগ্রহ করে কিছুক্ষণ পর আবার চেষ্টা করুন।" : "As you are using free tier, and there are too many users, please try again after some time.";
    } finally {
      isLoading.value = false;
      messages.refresh();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}