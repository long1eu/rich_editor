// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show TextAffinity, hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:rich_editor/logger/flutter_logger.dart';
import 'package:rich_editor/src/extensions.dart';
import 'package:rich_editor/src/services/rich_text_parser.dart';
import 'package:rich_editor/src/widgets/rich_editable_text.dart';

export 'dart:ui' show TextAffinity;

TextAffinity _toTextAffinity(String affinity) {
  switch (affinity) {
    case 'TextAffinity.downstream':
      return TextAffinity.downstream;
    case 'TextAffinity.upstream':
      return TextAffinity.upstream;
  }
  return null;
}

/// The current text, selection, and composing state for editing a run of text.
@immutable
class RichTextEditingValue extends AbstractTextEditingValue<TextSpan> {
  /// Creates information for editing a run of text.
  ///
  /// The selection and composing range must be within the text.
  ///
  /// The [value], [selection], and [composing] arguments must not be null but
  /// each have default values.
  const RichTextEditingValue(
      {this.value: const TextSpan(text: "", style: StyleController.material),
      this.selection: const TextSelection.collapsed(offset: -1),
      this.composing: TextRange.empty})
      : assert(value != null),
        assert(selection != null),
        assert(composing != null);

  /// Creates an instance of this class from a JSON object.
  factory RichTextEditingValue.fromJSON(
      Map<String, dynamic> encoded, TextStyle style) {
    return new RichTextEditingValue(
      value: new TextSpan(text: encoded['text'], style: style),
      selection: new TextSelection(
        baseOffset: encoded['selectionBase'] ?? -1,
        extentOffset: encoded['selectionExtent'] ?? -1,
        affinity: _toTextAffinity(encoded['selectionAffinity']) ??
            TextAffinity.downstream,
        isDirectional: encoded['selectionIsDirectional'] ?? false,
      ),
      composing: new TextRange(
        start: encoded['composingBase'] ?? -1,
        end: encoded['composingExtent'] ?? -1,
      ),
    );
  }

  /// The current text being edited.
  final TextSpan value;

  /// The range of text that is currently selected.
  final TextSelection selection;

  /// The range of text that is still being composed.
  final TextRange composing;

  /// A value that corresponds to the empty string with no selection and no composing range.
  static const RichTextEditingValue empty = const RichTextEditingValue();

  /// Creates a copy of this value but with the given fields replaced with the new values.
  @override
  AbstractTextEditingValue copyWith(
      {TextSpan value, TextSelection selection, TextRange composing}) {
    return new RichTextEditingValue(
        value: value ?? this.value,
        selection: selection ?? this.selection,
        composing: composing ?? this.composing);
  }

  @override
  String getSelectedText() => selection.textInside(value.toPlainText());

  @override
  TextSpan getUnselectedText() {
    String plainText = value.toPlainText();

    String newText =
        selection.textBefore(plainText) + selection.textAfter(plainText);

    return RichTextEditingValueParser
        .parse(
          oldValue: this,
          newValue: copyWith(value: new TextSpan(text: newText)),
          style: null,
        )
        .value;
  }

  @override
  AbstractTextEditingValue insert(String text) {
    String plainText = value.toPlainText();

    String newText =
        selection.textBefore(plainText) + text + selection.textAfter(plainText);

    print(newText);
    return RichTextEditingValueParser.parse(
      oldValue: this,
      newValue: copyWith(value: new TextSpan(text: newText)),
      style: null,
    );
  }

  @override
  int get length => Extensions.length(value);

  @override
  bool get isNotEmpty => Extensions.isNotEmpty(value);

  @override
  String get text => value.toPlainText();

  @override
  String toString() =>
      '$runtimeType(textSpan: \u2524$value\u251C, selection: $selection, composing: $composing)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! RichTextEditingValue) return false;
    final RichTextEditingValue typedOther = other;
    return typedOther.value == value &&
        typedOther.selection == selection &&
        typedOther.composing == composing;
  }

  @override
  int get hashCode =>
      hashValues(value.hashCode, selection.hashCode, composing.hashCode);
}

abstract class AbstractTextEditingValue<Value> {
  const AbstractTextEditingValue({this.value, this.selection, this.composing});

  /// Creates a copy of this value but with the given fields replaced with the new values.
  AbstractTextEditingValue copyWith(
      {Value value, TextSelection selection, TextRange composing});

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'text': text,
      'selectionBase': selection.baseOffset,
      'selectionExtent': selection.extentOffset,
      'selectionAffinity': selection.affinity.toString(),
      'selectionIsDirectional': selection.isDirectional,
      'composingBase': composing.start,
      'composingExtent': composing.end,
    };
  }

  /// The current text being edited.
  final Value value;

  /// The range of text that is currently selected.
  final TextSelection selection;

  /// The range of text that is still being composed.
  final TextRange composing;

  String getSelectedText();

  Value getUnselectedText();

  AbstractTextEditingValue insert(String text);

  int get length;

  bool get isNotEmpty;

  String get text;

  @override
  String toString() =>
      '$runtimeType(value: \u2524$value\u251C, selection: $selection, composing: $composing)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! Value) return false;
    final AbstractTextEditingValue typedOther = other;
    return typedOther.value == value &&
        typedOther.selection == selection &&
        typedOther.composing == composing;
  }

  @override
  int get hashCode =>
      hashValues(value.hashCode, selection.hashCode, composing.hashCode);
}

/// An interface to receive information from [TextInput].
///
/// See also:
///
///  * [TextInput.attach]
abstract class TextInputClient<T extends AbstractTextEditingValue> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const TextInputClient();

  /// Requests that this client update its editing state to the given value.
  void updateEditingValue(T value);

  /// Requests that this client perform the given action.
  void performAction(TextInputAction action);

  /// Return the concert implementation of this clients value/
  T getValue(Map<String, dynamic> encoded);
}

/// A interface for interacting with a text input control.
///
/// See also:
///
///  * [TextInput.attach]
class TextInputConnection {
  final Log log = new Log("TextInputConnection");

  TextInputConnection._(this._client)
      : assert(_client != null),
        _id = _nextId++;

  static int _nextId = 1;
  final int _id;

  final TextInputClient _client;

  /// Whether this connection is currently interacting with the text input control.
  bool get attached => _clientHandler._currentConnection == this;

  /// Requests that the text input control become visible.
  void show() {
    assert(attached);
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  /// Requests that the text input control change its internal state to match the given state.
  void setEditingState(AbstractTextEditingValue value) {
    log.d("setEditingState: ${value.toJSON()}");
    assert(attached);
    SystemChannels.textInput.invokeMethod(
      'TextInput.setEditingState',
      value.toJSON(),
    );
  }

  /// Stop interacting with the text input control.
  ///
  /// After calling this method, the text input control might disappear if no
  /// other client attaches to it within this animation frame.
  void close() {
    if (attached) {
      SystemChannels.textInput.invokeMethod('TextInput.clearClient');
      _clientHandler
        .._currentConnection = null
        .._scheduleHide();
    }
    assert(!attached);
  }
}

TextInputAction _toTextInputAction(String action) {
  switch (action) {
    case 'TextInputAction.done':
      return TextInputAction.done;
    case 'TextInputAction.newline':
      return TextInputAction.newline;
  }
  throw new FlutterError('Unknown text input action: $action');
}

class _TextInputClientHandler {
  _TextInputClientHandler() {
    SystemChannels.textInput.setMethodCallHandler(_handleTextInputInvocation);
  }

  TextInputConnection _currentConnection;

  Future<dynamic> _handleTextInputInvocation(MethodCall methodCall) async {
    if (_currentConnection == null) return;
    final String method = methodCall.method;
    final List<dynamic> args = methodCall.arguments;
    final int client = args[0];
    // The incoming message was for a different client.
    if (client != _currentConnection._id) return;
    switch (method) {
      case 'TextInputClient.updateEditingState':
        var value = _currentConnection._client.getValue(args[1]);
        _currentConnection._client.updateEditingValue(value);
        break;
      case 'TextInputClient.performAction':
        _currentConnection._client.performAction(_toTextInputAction(args[1]));
        break;
      default:
        throw new MissingPluginException();
    }
  }

  bool _hidePending = false;

  void _scheduleHide() {
    if (_hidePending) return;
    _hidePending = true;

    // Schedule a deferred task that hides the text input.  If someone else
    // shows the keyboard during this update cycle, then the task will do
    // nothing.
    scheduleMicrotask(() {
      _hidePending = false;
      if (_currentConnection == null)
        SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }
}

final _TextInputClientHandler _clientHandler = new _TextInputClientHandler();

/// An interface to the system's text input control.
class TextInput {
  TextInput._();

  /// Begin interacting with the text input control.
  ///
  /// Calling this function helps multiple clients coordinate about which one is
  /// currently interacting with the text input control. The returned
  /// [TextInputConnection] provides an interface for actually interacting with
  /// the text input control.
  ///
  /// A client that no longer wishes to interact with the text input control
  /// should call [TextInputConnection.close] on the returned
  /// [TextInputConnection].
  static TextInputConnection attach(
      TextInputClient client, TextInputConfiguration configuration) {
    assert(client != null);
    assert(configuration != null);
    final TextInputConnection connection = new TextInputConnection._(client);
    _clientHandler._currentConnection = connection;
    SystemChannels.textInput.invokeMethod(
      'TextInput.setClient',
      <dynamic>[connection._id, configuration.toJson()],
    );
    return connection;
  }
}
