// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart' hide cupertinoTextSelectionControls;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide materialTextSelectionControls;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rich_editor/logger/flutter_logger.dart';
import 'package:rich_editor/src/cupertino/text_selection.dart';
import 'package:rich_editor/src/extensions.dart';
import 'package:rich_editor/src/material/text_selection.dart';
import 'package:rich_editor/src/widgets/rich_editable_text.dart';

export 'package:flutter/services.dart' show TextInputType;

const Duration _kTransitionDuration = const Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;

/// A material design text field.
///
/// A text field lets the user enter text, either with hardware keyboard or with
/// an onscreen keyboard.
///
/// The text field calls the [onChanged] callback whenever the user changes the
/// text in the field. If the user indicates that they are done typing in the
/// field (e.g., by pressing a button on the soft keyboard), the text field
/// calls the [onSubmitted] callback.
///
/// To control the text that is displayed in the text field, use the
/// [controller]. For example, to set the initial value of the text field, use
/// a [controller] that already contains some text. The [controller] can also
/// control the selection and composing region (and to observe changes to the
/// text, selection, and composing region).
///
/// By default, a text field has a [decoration] that draws a divider below the
/// text field. You can use the [decoration] property to control the decoration,
/// for example by adding a label or an icon. If you set the [decoration]
/// property to null, the decoration will be removed entirely, including the
/// extra padding introduced by the decoration to save space for the labels.
///
/// If [decoration] is non-null (which is the default), the text field requires
/// one of its ancestors to be a [Material] widget.
///
/// To integrate the [RichTextField] into a [Form] with other [FormField] widgets,
/// consider using [TextFormField].
///
/// See also:
///
///  * <https://material.google.com/components/text-fields.html>
///  * [TextFormField], which integrates with the [Form] widget.
///  * [InputDecorator], which shows the labels and other visual elements that
///    surround the actual text editing widget.
///  * [EditableText], which is the raw text editing control at the heart of a
///    [TextField]. (The [EditableText] widget is rarely used directly unless
///    you are implementing an entirely different design language, such as
///    Cupertino.)
class RichTextField extends StatefulWidget {
  /// Creates a Material Design text field.
  ///
  /// If [decoration] is non-null (which is the default), the text field requires
  /// one of its ancestors to be a [Material] widget.
  ///
  /// To remove the decoration entirely (including the extra padding introduced
  /// by the decoration to save space for the labels), set the [decoration] to
  /// null.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is one, meaning this is a single-line
  /// text field. [maxLines] must not be zero. If [maxLines] is not one, then
  /// [keyboardType] is ignored, and the [TextInputType.multiline] keyboard type
  /// is used.
  ///
  /// The [keyboardType], [textAlign], [autofocus], and
  /// [autocorrect] arguments must not be null.
  const RichTextField({
    Key key,
    this.controller,
    this.styleController,
    this.focusNode,
    this.decoration: const InputDecoration(),
    TextInputType keyboardType: TextInputType.text,
    this.style,
    this.textAlign: TextAlign.start,
    this.autofocus: false,
    this.autocorrect: true,
    this.maxLines: 1,
    this.onChanged,
    this.onSubmitted,
  })
      : assert(keyboardType != null),
        assert(textAlign != null),
        assert(autofocus != null),
        assert(autocorrect != null),
        assert(maxLines == null || maxLines > 0),
        keyboardType = maxLines == 1 ? keyboardType : TextInputType.multiline,
        super(key: key);

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [TextEditingController].
  final RichTextEditingController controller;

  /// Control the style of the [RichTextField] as the user types.
  ///
  /// If null the [RichTextField] will act as a normal [TextField].
  final StyleController styleController;

  /// Controls whether this widget has keyboard focus.
  ///
  /// If null, this widget will create its own [FocusNode].
  final FocusNode focusNode;

  /// The decoration to show around the text field.
  ///
  /// By default, draws a horizontal line under the text field but can be
  /// configured to show an icon, label, hint text, and error text.
  ///
  /// Set this field to null to remove the decoration entirely (including the
  /// extra padding introduced by the decoration to save space for the labels).
  final InputDecoration decoration;

  /// The type of keyboard to use for editing the text.
  ///
  /// Defaults to [TextInputType.text]. Must not be null. If
  /// [maxLines] is not one, then [keyboardType] is ignored, and the
  /// [TextInputType.multiline] keyboard type is used.
  final TextInputType keyboardType;

  /// The style to use for the text being edited.
  ///
  /// This text style is also used as the base style for the [decoration].
  ///
  /// If null, defaults to a text style from the current [Theme].
  final TextStyle style;

  /// How the text being edited should be aligned horizontally.
  ///
  /// Defaults to [TextAlign.start].
  final TextAlign textAlign;

  /// Whether this text field should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this text field obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false. Cannot be null.
  // See https://github.com/flutter/flutter/issues/7035 for the rationale for this
  // keyboard behavior.
  final bool autofocus;

  /// Whether to enable autocorrection.
  ///
  /// Defaults to true. Cannot be null.
  final bool autocorrect;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  ///
  /// If this is null, there is no limit to the number of lines. If it is not
  /// null, the value must be greater than zero.
  final int maxLines;

  /// Called when the text being edited changes.
  final ValueChanged<String> onChanged;

  /// Called when the user indicates that they are done editing the text in the
  /// field.
  final ValueChanged<String> onSubmitted;

  void setNewStyle(TextStyle textStyle) {}

  @override
  RichTextFieldState createState() => new RichTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DiagnosticsProperty<RichTextEditingController>(
        'controller', controller,
        defaultValue: null));
    description.add(new DiagnosticsProperty<FocusNode>('focusNode', focusNode,
        defaultValue: null));
    description.add(
        new DiagnosticsProperty<InputDecoration>('decoration', decoration));
    description.add(new EnumProperty<TextInputType>(
        'keyboardType', keyboardType,
        defaultValue: TextInputType.text));
    description.add(
        new DiagnosticsProperty<TextStyle>('style', style, defaultValue: null));
    description.add(new DiagnosticsProperty<bool>('autofocus', autofocus,
        defaultValue: false));
    description.add(new DiagnosticsProperty<bool>('autocorrect', autocorrect,
        defaultValue: false));
    description.add(new IntProperty('maxLines', maxLines, defaultValue: 1));
  }
}

class RichTextFieldState extends State<RichTextField> {
  final Log log = new Log("_TextFieldState");

  final GlobalKey<RichEditableTextState> _editableTextKey =
      new GlobalKey<RichEditableTextState>();

  RichTextEditingController _controller;

  RichTextEditingController get _effectiveController =>
      widget.controller ?? _controller;

  FocusNode _focusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= new FocusNode());

  @override
  void initState() {
    super.initState();
    if (widget.controller == null)
      _controller = new RichTextEditingController();
  }

  @override
  void didUpdateWidget(RichTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null)
      _controller =
          new RichTextEditingController.fromValue(oldWidget.controller.value);
    else if (widget.controller != null && oldWidget.controller == null)
      _controller = null;
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  void _requestKeyboard() {
    _editableTextKey.currentState?.requestKeyboard();
  }

  void prepareForFocusLoss({bool closeKeyboardIfNeeded = false}) {
    _editableTextKey.currentState?.saveValueBeforeFocusLoss = true;
    _editableTextKey.currentState?.closeKeyboardIfNeeded = closeKeyboardIfNeeded;
  }

  void restoreFocus() {
    _editableTextKey.currentState?.requestFocus();
  }

  void _onSelectionChanged(
      BuildContext context, TextSelection selection, bool longPress) {
    log.d("_onSelectionChanged $selection");
    if (longPress) Feedback.forLongPress(context);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle style = widget.style ?? themeData.textTheme.body1;
    final RichTextEditingController controller = _effectiveController;
    final FocusNode focusNode = _effectiveFocusNode;

    Widget child = new RepaintBoundary(
      child: new RichEditableText(
          key: _editableTextKey,
          controller: controller,
          styleController: widget.styleController,
          focusNode: focusNode,
          keyboardType: widget.keyboardType,
          style: style,
          textAlign: widget.textAlign,
          autofocus: widget.autofocus,
          autocorrect: widget.autocorrect,
          maxLines: widget.maxLines,
          cursorColor: themeData.textSelectionColor,
          selectionColor: themeData.textSelectionColor,
          selectionControls: themeData.platform == TargetPlatform.iOS
              ? cupertinoTextSelectionControls
              : materialTextSelectionControls,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onSelectionChanged: (TextSelection selection, bool longPress) =>
              _onSelectionChanged(context, selection, longPress)),
    );

    if (widget.decoration != null) {
      child = new AnimatedBuilder(
        animation: new Listenable.merge(<Listenable>[focusNode, controller]),
        builder: (BuildContext context, Widget child) {
          return new InputDecorator(
            decoration: widget.decoration,
            baseStyle: widget.style,
            textAlign: widget.textAlign,
            isFocused: focusNode.hasFocus,
            isEmpty: Extensions.isEmpty(controller.value.value),
            child: child,
          );
        },
        child: child,
      );
    }

    return new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _requestKeyboard,
      child: child,
    );
  }
}
