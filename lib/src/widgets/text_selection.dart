// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:rich_editor/src/rendering/rich_editable.dart';
import 'package:rich_editor/src/services/text_input.dart';

/// Which type of selection handle to be displayed.
///
/// With mixed-direction text, both handles may be the same type. Examples:
///
/// * LTR text: 'the <quick brown> fox':
///   The '<' is drawn with the [left] type, the '>' with the [right]
///
/// * RTL text: 'xof <nworb kciuq> eht':
///   Same as above.
///
/// * mixed text: '<the nwor<b quick fox'
///   Here 'the b' is selected, but 'brown' is RTL. Both are drawn with the
///   [left] type.
enum TextSelectionHandleType {
  /// The selection handle is to the left of the selection end point.
  left,

  /// The selection handle is to the right of the selection end point.
  right,

  /// The start and end of the selection are co-incident at this point.
  collapsed,
}

/// The text position that a give selection handle manipulates. Dragging the
/// [start] handle always moves the [start]/[baseOffset] of the selection.
enum _TextSelectionHandlePosition { start, end }

/// Signature for reporting changes to the selection component of a
/// [RichTextEditingValue] for the purposes of a [TextSelectionOverlay]. The
/// [caretRect] argument gives the location of the caret in the coordinate space
/// of the [RenderBox] given by the [TextSelectionOverlay.renderObject].
///
/// Used by [TextSelectionOverlay.onSelectionOverlayChanged].
typedef void TextSelectionOverlayChanged(
    AbstractTextEditingValue value, Rect caretRect);

/// An interface for manipulating the selection, to be used by the implementor
/// of the toolbar widget.
abstract class TextSelectionDelegate {
  /// Gets the current text input.
  AbstractTextEditingValue get textEditingValue;

  /// Sets the current text input (replaces the whole line).
  set textEditingValue(AbstractTextEditingValue value);

  /// Hides the text selection toolbar.
  void hideToolbar();
}

/// An interface for building the selection UI, to be provided by the
/// implementor of the toolbar widget.
///
/// Override text operations such as [handleCut] if needed.
abstract class TextSelectionControls {
  /// Builds a selection handle of the given type.
  ///
  /// The top left corner of this widget is positioned at the bottom of the
  /// selection position.
  Widget buildHandle(BuildContext context, TextSelectionHandleType type,
      double textLineHeight);

  /// Builds a toolbar near a text selection.
  ///
  /// Typically displays buttons for copying and pasting text.
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion,
      Offset position, TextSelectionDelegate delegate);

  /// Returns the size of the selection handle.
  Size get handleSize;

  /// Copy the current selection of the text field managed by the given
  /// `delegate` to the [Clipboard]. Then, remove the selected text from the
  /// text field and hide the toolbar.
  ///
  /// This is called by subclasses when their cut affordance is activated by
  /// the user.
  void handleCut(TextSelectionDelegate delegate) {
    final AbstractTextEditingValue value = delegate.textEditingValue;
    Clipboard.setData(new ClipboardData(
      text: value.getSelectedText(),
    ));
    delegate.textEditingValue = value.copyWith(
        value: value.getUnselectedText(),
        selection: new TextSelection.collapsed(offset: value.selection.start));
    delegate.hideToolbar();
  }

  /// Copy the current selection of the text field managed by the given
  /// `delegate` to the [Clipboard]. Then, move the cursor to the end of the
  /// text (collapsing the selection in the process), and hide the toolbar.
  ///
  /// This is called by subclasses when their copy affordance is activated by
  /// the user.
  void handleCopy(TextSelectionDelegate delegate) {
    final AbstractTextEditingValue value = delegate.textEditingValue;
    Clipboard.setData(new ClipboardData(
      text: value.getSelectedText(),
    ));
    delegate.textEditingValue = value.copyWith(
        selection: new TextSelection.collapsed(offset: value.selection.end));
    delegate.hideToolbar();
  }

  /// Paste the current clipboard selection (obtained from [Clipboard]) into
  /// the text field managed by the given `delegate`, replacing its current
  /// selection, if any. Then, hide the toolbar.
  ///
  /// This is called by subclasses when their paste affordance is activated by
  /// the user.
  ///
  /// This function is asynchronous since interacting with the clipboard is
  /// asynchronous. Race conditions may exist with this API as currently
  /// implemented.
  // TODO(ianh): https://github.com/flutter/flutter/issues/11427
  Future<Null> handlePaste(TextSelectionDelegate delegate) async {
    // Snapshot the input before using `await`.
    final AbstractTextEditingValue value = delegate.textEditingValue;

    final ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      delegate.textEditingValue = value.insert(data.text);
    }
    delegate.hideToolbar();
  }

  /// Adjust the selection of the text field managed by the given `delegate` so
  /// that everything is selected.
  ///
  /// Does not hide the toolbar.
  ///
  /// This is called by subclasses when their select-all affordance is activated
  /// by the user.
  void handleSelectAll(TextSelectionDelegate delegate) {
    final AbstractTextEditingValue value = delegate.textEditingValue;
    delegate.textEditingValue = value.copyWith(
        selection:
            new TextSelection(baseOffset: 0, extentOffset: value.length));
  }
}

/// An object that manages a pair of text selection handles.
///
/// The selection handles are displayed in the [Overlay] that most closely
/// encloses the given [BuildContext].
class TextSelectionOverlay implements TextSelectionDelegate {
  /// Creates an object that manages overly entries for selection handles.
  ///
  /// The [context] must not be null and must have an [Overlay] as an ancestor.
  TextSelectionOverlay({
    @required AbstractTextEditingValue value,
    @required this.context,
    this.debugRequiredFor,
    @required this.layerLink,
    @required this.renderObject,
    this.onSelectionOverlayChanged,
    this.selectionControls,
  })
      : assert(value != null),
        assert(context != null),
        _value = value {
    final OverlayState overlay = Overlay.of(context);
    assert(overlay != null);
    _handleController =
        new AnimationController(duration: _kFadeDuration, vsync: overlay);
    _toolbarController =
        new AnimationController(duration: _kFadeDuration, vsync: overlay);
  }

  /// The context in which the selection handles should appear.
  ///
  /// This context must have an [Overlay] as an ancestor because this object
  /// will display the text selection handles in that [Overlay].
  final BuildContext context;

  /// Debugging information for explaining why the [Overlay] is required.
  final Widget debugRequiredFor;

  /// The object supplied to the [CompositedTransformTarget] that wraps the text
  /// field.
  final LayerLink layerLink;

  // TODO(mpcomplete): what if the renderObject is removed or replaced, or
  // moves? Not sure what cases I need to handle, or how to handle them.
  /// The editable line in which the selected text is being displayed.
  final RenderRichEditable renderObject;

  /// Called when the the selection changes.
  ///
  /// For example, if the use drags one of the selection handles, this function
  /// will be called with a new input value with an updated selection.
  final TextSelectionOverlayChanged onSelectionOverlayChanged;

  /// Builds text selection handles and toolbar.
  final TextSelectionControls selectionControls;

  /// Controls the fade-in animations.
  static const Duration _kFadeDuration = const Duration(milliseconds: 150);
  AnimationController _handleController;
  AnimationController _toolbarController;

  Animation<double> get _handleOpacity => _handleController.view;

  Animation<double> get _toolbarOpacity => _toolbarController.view;

  AbstractTextEditingValue _value;

  /// A pair of handles. If this is non-null, there are always 2, though the
  /// second is hidden when the selection is collapsed.
  List<OverlayEntry> _handles;

  /// A copy/paste toolbar.
  OverlayEntry _toolbar;

  TextSelection get _selection => _value.selection;

  /// Shows the handles by inserting them into the [context]'s overlay.
  void showHandles() {
    assert(_handles == null);
    _handles = <OverlayEntry>[
      new OverlayEntry(
          builder: (BuildContext context) =>
              _buildHandle(context, _TextSelectionHandlePosition.start)),
      new OverlayEntry(
          builder: (BuildContext context) =>
              _buildHandle(context, _TextSelectionHandlePosition.end)),
    ];
    Overlay.of(context, debugRequiredFor: debugRequiredFor).insertAll(_handles);
    _handleController.forward(from: 0.0);
  }

  /// Shows the toolbar by inserting it into the [context]'s overlay.
  void showToolbar() {
    assert(_toolbar == null);
    _toolbar = new OverlayEntry(builder: _buildToolbar);
    Overlay.of(context, debugRequiredFor: debugRequiredFor).insert(_toolbar);
    _toolbarController.forward(from: 0.0);
  }

  /// Updates the overlay after the selection has changed.
  ///
  /// If this method is called while the [SchedulerBinding.schedulerPhase] is
  /// [SchedulerPhase.persistentCallbacks], i.e. during the build, layout, or
  /// paint phases (see [WidgetsBinding.drawFrame]), then the update is delayed
  /// until the post-frame callbacks phase. Otherwise the update is done
  /// synchronously. This means that it is safe to call during builds, but also
  /// that if you do call this during a build, the UI will not update until the
  /// next frame (i.e. many milliseconds later).
  void update(AbstractTextEditingValue newValue) {
    if (_value == newValue) return;
    _value = newValue;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(_markNeedsBuild);
    } else {
      _markNeedsBuild();
    }
  }

  /// Causes the overlay to update its rendering.
  ///
  /// This is intended to be called when the [renderObject] may have changed its
  /// text metrics (e.g. because the text was scrolled).
  void updateForScroll() {
    _markNeedsBuild();
  }

  void _markNeedsBuild([Duration duration]) {
    if (_handles != null) {
      _handles[0].markNeedsBuild();
      _handles[1].markNeedsBuild();
    }
    _toolbar?.markNeedsBuild();
  }

  /// Hides the overlay.
  void hide() {
    if (_handles != null) {
      _handles[0].remove();
      _handles[1].remove();
      _handles = null;
    }
    _toolbar?.remove();
    _toolbar = null;

    _handleController.stop();
    _toolbarController.stop();
  }

  /// Final cleanup.
  void dispose() {
    hide();
    _handleController.dispose();
    _toolbarController.dispose();
  }

  Widget _buildHandle(
      BuildContext context, _TextSelectionHandlePosition position) {
    if ((_selection.isCollapsed &&
            position == _TextSelectionHandlePosition.end) ||
        selectionControls == null)
      return new Container(); // hide the second handle when collapsed

    return new FadeTransition(
        opacity: _handleOpacity,
        child: new _TextSelectionHandleOverlay(
          onSelectionHandleChanged: (TextSelection newSelection) {
            _handleSelectionHandleChanged(newSelection, position);
          },
          onSelectionHandleTapped: _handleSelectionHandleTapped,
          layerLink: layerLink,
          renderObject: renderObject,
          selection: _selection,
          selectionControls: selectionControls,
          position: position,
        ));
  }

  Widget _buildToolbar(BuildContext context) {
    if (selectionControls == null) return new Container();

    // Find the horizontal midpoint, just above the selected text.
    final List<TextSelectionPoint> endpoints =
        renderObject.getEndpointsForSelection(_selection);
    final Offset midpoint = new Offset(
      (endpoints.length == 1)
          ? endpoints[0].point.dx
          : (endpoints[0].point.dx + endpoints[1].point.dx) / 2.0,
      endpoints[0].point.dy - renderObject.size.height,
    );

    final Rect editingRegion = new Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero)),
    );

    return new FadeTransition(
      opacity: _toolbarOpacity,
      child: new CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: -editingRegion.topLeft,
        child: selectionControls.buildToolbar(
            context, editingRegion, midpoint, this),
      ),
    );
  }

  void _handleSelectionHandleChanged(
      TextSelection newSelection, _TextSelectionHandlePosition position) {
    Rect caretRect;
    switch (position) {
      case _TextSelectionHandlePosition.start:
        caretRect = renderObject.getLocalRectForCaret(newSelection.base);
        break;
      case _TextSelectionHandlePosition.end:
        caretRect = renderObject.getLocalRectForCaret(newSelection.extent);
        break;
    }
    update(
        _value.copyWith(selection: newSelection, composing: TextRange.empty));
    if (onSelectionOverlayChanged != null)
      onSelectionOverlayChanged(_value, caretRect);
  }

  void _handleSelectionHandleTapped() {
    if (_value.selection.isCollapsed) {
      if (_toolbar != null) {
        _toolbar?.remove();
        _toolbar = null;
      } else {
        showToolbar();
      }
    }
  }

  @override
  AbstractTextEditingValue get textEditingValue => _value;

  @override
  set textEditingValue(AbstractTextEditingValue newValue) {
    update(newValue);
    if (onSelectionOverlayChanged != null) {
      final Rect caretRect =
          renderObject.getLocalRectForCaret(newValue.selection.extent);
      onSelectionOverlayChanged(newValue, caretRect);
    }
  }

  @override
  void hideToolbar() {
    hide();
  }
}

/// This widget represents a single draggable text selection handle.
class _TextSelectionHandleOverlay extends StatefulWidget {
  const _TextSelectionHandleOverlay(
      {Key key,
      @required this.selection,
      @required this.position,
      @required this.layerLink,
      @required this.renderObject,
      @required this.onSelectionHandleChanged,
      @required this.onSelectionHandleTapped,
      @required this.selectionControls})
      : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final LayerLink layerLink;
  final RenderRichEditable renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final VoidCallback onSelectionHandleTapped;
  final TextSelectionControls selectionControls;

  @override
  _TextSelectionHandleOverlayState createState() =>
      new _TextSelectionHandleOverlayState();
}

class _TextSelectionHandleOverlayState
    extends State<_TextSelectionHandleOverlay> {
  Offset _dragPosition;

  void _handleDragStart(DragStartDetails details) {
    _dragPosition = details.globalPosition +
        new Offset(0.0, -widget.selectionControls.handleSize.height);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    final TextPosition position =
        widget.renderObject.getPositionForPoint(_dragPosition);

    if (widget.selection.isCollapsed) {
      widget.onSelectionHandleChanged(new TextSelection.fromPosition(position));
      return;
    }

    TextSelection newSelection;
    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        newSelection = new TextSelection(
            baseOffset: position.offset,
            extentOffset: widget.selection.extentOffset);
        break;
      case _TextSelectionHandlePosition.end:
        newSelection = new TextSelection(
            baseOffset: widget.selection.baseOffset,
            extentOffset: position.offset);
        break;
    }

    if (newSelection.baseOffset >= newSelection.extentOffset)
      return; // don't allow order swapping.

    widget.onSelectionHandleChanged(newSelection);
  }

  void _handleTap() {
    widget.onSelectionHandleTapped();
  }

  @override
  Widget build(BuildContext context) {
    final List<TextSelectionPoint> endpoints =
        widget.renderObject.getEndpointsForSelection(widget.selection);
    Offset point;
    TextSelectionHandleType type;

    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        point = endpoints[0].point;
        type = _chooseType(endpoints[0], TextSelectionHandleType.left,
            TextSelectionHandleType.right);
        break;
      case _TextSelectionHandlePosition.end:
        // [endpoints] will only contain 1 point for collapsed selections, in
        // which case we shouldn't be building the [end] handle.
        assert(endpoints.length == 2);
        point = endpoints[1].point;
        type = _chooseType(endpoints[1], TextSelectionHandleType.right,
            TextSelectionHandleType.left);
        break;
    }

    return new CompositedTransformFollower(
      link: widget.layerLink,
      showWhenUnlinked: false,
      child: new GestureDetector(
        onPanStart: _handleDragStart,
        onPanUpdate: _handleDragUpdate,
        onTap: _handleTap,
        child: new Stack(
          children: <Widget>[
            new Positioned(
              left: point.dx,
              top: point.dy,
              child: widget.selectionControls.buildHandle(
                context,
                type,
                widget.renderObject.size.height /
                    (widget.renderObject.maxLines ?? 0.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSelectionHandleType _chooseType(TextSelectionPoint endpoint,
      TextSelectionHandleType ltrType, TextSelectionHandleType rtlType) {
    if (widget.selection.isCollapsed) return TextSelectionHandleType.collapsed;

    assert(endpoint.direction != null);
    switch (endpoint.direction) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
    return null;
  }
}
