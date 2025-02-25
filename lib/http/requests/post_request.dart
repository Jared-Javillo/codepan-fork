import 'dart:convert';
import 'dart:io';

import 'package:codepan/extensions/map.dart';
import 'package:codepan/http/handlers.dart';
import 'package:codepan/http/requests/base_request.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

abstract class PostRequest<T>
    extends HttpRequest<T, List<Map<String, dynamic>>> {
  const PostRequest({
    required super.db,
    required super.client,
  });

  Future<Map<String, dynamic>> get params;

  @override
  Future<Response> get response async {
    final p = await params;
    final h = await headers;
    final uri = Uri.https(authority, path);
    final encoder = JsonEncoder.withIndent(indent);
    final body = encoder.convert(p..clean());
    debugPrint('Url: ${uri.toString()}');
    debugPrint('Payload:\n${body.toString()}');
    return client.post(
      uri,
      headers: h..addAll(postHeaders),
      body: body,
      encoding: utf8,
    );
  }

  @override
  DataInitHandler get handler;

  @override
  Future<T> onResponse(Response response) async {
    if (response.statusCode == HttpStatus.ok) {
      final body = json.decode(response.body);
      final data = handler.init(body);
      if (data.isNotEmpty || handler.allowEmpty) {
        return await onSuccess(data);
      }
    }
    throw await onError(response.statusCode);
  }
}
