import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String userId;
  final String userName;
  final String feedbackText;
  final Timestamp timestamp;

  FeedbackModel({
    required this.userId,
    required this.userName,
    required this.feedbackText,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'feedbackText': feedbackText,
      'timestamp': timestamp,
    };
  }
}

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _firestore.collection('feedback').add(feedback.toMap());
      print('Feedback submitted successfully.');
    } catch (e) {
      print('Error submitting feedback: $e');
    }
  }
}
