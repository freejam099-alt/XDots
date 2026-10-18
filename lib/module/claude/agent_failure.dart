import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'ai_service.dart';
import 'widgets/agent_avatar.dart';

/// Presentation of an actual failed operation, never inferred from chat text.
AgentActivity activityForFailure(Object error) {
  const retryableStatuses = <int>{408, 425, 429, 500, 502, 503, 504};
  if (error is DioException) {
    if (error.type == DioExceptionType.cancel) return AgentActivity.idle;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        retryableStatuses.contains(error.response?.statusCode)) {
      return AgentActivity.frustrated;
    }
  }
  if (error is SocketException || error is TimeoutException) {
    return AgentActivity.frustrated;
  }
  if (error is MuseAiException &&
      retryableStatuses.contains(error.statusCode)) {
    return AgentActivity.frustrated;
  }
  return AgentActivity.crying;
}
