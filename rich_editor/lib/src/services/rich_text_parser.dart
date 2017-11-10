import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_logger/flutter_logger.dart';
import 'package:rich_editor/src/extensions.dart';
import 'package:rich_editor/src/services/text_input.dart';

class RichTextEditingValueParser {
  static final Log log = new Log("RichTextEditingValueParser");

  static RichTextEditingValue parse(
      {@required RichTextEditingValue oldValue,
      @required RichTextEditingValue newValue,
      @required TextStyle style}) {
    if (_equalTextValue(oldValue, newValue)) {
      log.d("equalTextValue");
      return oldValue;
    } else if (_sameTextDiffSelection(oldValue, newValue)) {
      log.d("sameTextDiffSelection");
      return newValue.copyWith(value: oldValue.value);
    }

    final TextSpan currentSpan = oldValue.value;
    final TextSelection currentSelection = oldValue.selection;
    final TextSelection newSelection = newValue.selection;

    log.d("has children: ${currentSpan.children != null}");

    /// If the root [TextSpan] doesn't have any children we can simply set the
    /// root text to the new value.
    ///
    /// Otherwise we look to the span that changed.
    if (currentSpan.children == null) {
      log.d("same style: ${currentSpan.style == style}");

      /// If the user didn't changed the default [TextStyle] we update the root
      /// text value with the new value. Also if the user DID changed the
      /// [style] but is deleting, we just set the new value.
      ///
      /// Otherwise we create a new [TextSpan] with the added text
      if (currentSpan.style == style ||
          currentSelection.baseOffset > newSelection.baseOffset) {
        log.d("returnValue = newValue");
      } else {
        var text = newValue.text
            .substring(currentSelection.baseOffset, newSelection.baseOffset);
        log.d(text);

        /// If the insert position, indicated by [currentSelection.baseOffset]
        /// is contained in the text of the root [TextSpan], we recreate the
        /// root with the first part of the root text, and the below children:
        ///
        /// [1]: a new [TextSpan] with the text added by the user and the
        /// [style] style;
        ///
        /// [2]: another [TextSpan] with the last part of root text, but keeping
        /// the  same style as the root.
        if (oldValue.value.text.length > currentSelection.baseOffset) {
          var children = [
            new TextSpan(style: style, text: text),
            new TextSpan(
                style: currentSpan.style,
                text: currentSelection.textAfter(currentSpan.text))
          ];

          newValue = newValue.copyWith(
              value: new TextSpan(
                  style: currentSpan.style,
                  text: currentSelection.textBefore(currentSpan.text),
                  children: children));
        } else {
          var children = [new TextSpan(style: style, text: text)];
          log.d(children.first.style);
          newValue = newValue.copyWith(
              value: new TextSpan(
                  style: currentSpan.style,
                  text: currentSpan.text,
                  children: children));

          log.d(newValue.value.children.length);
        }
      }
    } else {
      /// Something was added
      if (currentSelection.baseOffset < newSelection.baseOffset) {
        log.d("currentTextSpan.last.style: ${currentSpan.children.last.style ==
            style}");

        String oldPlainText = oldValue.value.toPlainText();

        /// If the insert position, indicated by [currentSelection.start] is
        /// contained in the [text] of the root [TextSpan], just update the text
        /// of the root element.
        if (oldValue.value.text.length >= currentSelection.start) {
          log.d(
              "----------------------------------------------ADD TO ROOT TEXT");
          var text = newValue.text
              .substring(currentSelection.start, newSelection.start);

          newValue = newValue.copyWith(
              value: Extensions.copySpanWith(
            base: oldValue.value,
            text: currentSelection.textBefore(oldValue.value.text) +
                text +
                currentSelection.textAfter(oldValue.value.text),
          ));
        }

        /// If the insert position is in one of the children then we retrieve
        /// that child and find its start and end position in the parent. Then
        /// we update the text of that [TextSpan] with the new value.
        else if (oldPlainText.length > currentSelection.start) {
          log.d(
              "-----------------------------------------------ADD TO CHILDREN");
          var text = newValue.text
              .substring(currentSelection.start, newSelection.start);
          log.d(text);
          List<TextSpan> children = [];

          /// We need a copy of the children list to avoid changing the
          /// [oldValue] content. <b>Remove this and see what happens. :D</b>
          currentSpan.children.forEach((it) => children.add(it));

          var spanPosition = currentSelection.start - 1;
          if (spanPosition == -1) spanPosition++;

          TextSpan affectedSpan = currentSpan.getSpanForPosition(
              new TextPosition(
                  offset: currentSelection.start - 1,
                  affinity: currentSelection.affinity));

          var index = children.indexOf(affectedSpan);
          children.removeAt(index);

          var affectedSpanStart =
              Extensions.getOffsetInParent(currentSpan, affectedSpan);
          var affectedSpanEnd = affectedSpanStart + affectedSpan.text.length;

          String beforeText = oldPlainText.substring(
              affectedSpanStart, currentSelection.base.offset);

          String afterText = oldPlainText.substring(
              currentSelection.base.offset, affectedSpanEnd);

          /// If the user deliberately changed the style while on this span then
          /// we honor this request by splitting the span and and adding the new
          /// text with the selected style.
          if (affectedSpan.style == style) {
            log.d(
                "----------------------------------------------------SAME STYLE");
            affectedSpan = Extensions.copySpanWith(
                base: affectedSpan, text: beforeText + text + afterText);
            children.insert(index, affectedSpan);
          } else {
            log.d(
                "-----------------------------------------------DIFFERENT STYLE");
            children.insert(index,
                Extensions.copySpanWith(base: affectedSpan, text: beforeText));
            children.insert(
                index + 1,
                Extensions.copySpanWith(
                    base: affectedSpan, text: text, style: style));
            children.insert(index + 2,
                Extensions.copySpanWith(base: affectedSpan, text: afterText));
          }

          log.d(children);

          TextSpan root =
              Extensions.copySpanWith(base: oldValue.value, children: children);
          newValue = newValue.copyWith(value: root);
        }

        /// If the user inserts text at the end, check if the style of the
        /// last span matches with the current style, if so just add the new
        /// text to the text of the last [TextSpan] in children list.
        ///
        /// Otherwise add a new [TextSpan] with the new [style] and add it to
        /// the end of the children list.
        else {
          log.d(
              "----------------------------------------------------ADD TO END");

          if (currentSpan.children.last.style == style) {
            log.d(
                "----------------------------------------------------SAME STYLE");
            var text = newValue.text
                .substring(currentSelection.start, newSelection.start);

            List<TextSpan> children = [];

            /// We need a copy of the children list to avoid changing the
            /// [oldValue] content. <b>Remove this and see what happens. :D</b>
            currentSpan.children.forEach((it) => children.add(it));

            var lastSpan = children.last;
            lastSpan =
                Extensions.copySpanWith(base: lastSpan, text: lastSpan.text + text);
            children.removeLast();
            children.add(lastSpan);
            TextSpan root =
                Extensions.copySpanWith(base: oldValue.value, children: children);

            newValue = newValue.copyWith(value: root);
          } else {
            log.d(
                "-----------------------------------------------DIFFERENT STYLE");
            var text = newValue.text
                .substring(currentSelection.start, newSelection.start);

            List<TextSpan> children = [];

            /// We need a copy of the children list to avoid changing the
            /// [oldValue] content. <b>Remove this and see what happens. :D</b>
            currentSpan.children.forEach((it) => children.add(it));

            children.add(new TextSpan(text: text, style: style));
            TextSpan root =
                Extensions.copySpanWith(base: oldValue.value, children: children);

            newValue = newValue.copyWith(value: root);
          }
        }
      }

      /// Something was deleted
      else {
        String oldPlainText = oldValue.value.toPlainText();

        /// If the insert position, indicated by [currentSelection.start] is
        /// contained in the [text] of the root [TextSpan], just update the text
        /// of the root element by subtracting the deleted text.
        if (oldValue.value.text.length >= currentSelection.start) {
          log.d(
              "-----------------------------------------DELETE FROM ROOT TEXT");
          var text = currentSpan.text.substring(0, newSelection.extentOffset) +
              currentSpan.text.substring(oldValue.selection.extentOffset);

          newValue = newValue.copyWith(
              value: Extensions.copySpanWith(base: oldValue.value, text: text));
        }

        /// If the insert position is in one of the children then we retrieve
        /// that child and find its start and end position in the parent. Then
        /// we update the text of that [TextSpan] with the new value.
        ///
        /// If the new text is empty then just remove the child from the list.
        else if (oldPlainText.length > currentSelection.start) {
          log.d(
              "------------------------------------------DELETE FROM CHILDREN");
          List<TextSpan> children = [];

          log.d(oldValue.selection);
          log.d(newValue.selection);

          /// We need a copy of the children list to avoid changing the
          /// [oldValue] content. <b>Remove this and see what happens. :D</b>
          currentSpan.children.forEach((it) => children.add(it));

          TextSpan affectedSpan = currentSpan.getSpanForPosition(
              new TextPosition(
                  offset: currentSelection.start - 1,
                  affinity: currentSelection.affinity));

          log.d(affectedSpan.toStringDeep());

          var index = children.indexOf(affectedSpan);
          children.removeAt(index);

          var affectedSpanStart =
              Extensions.getOffsetInParent(currentSpan, affectedSpan);
          log.d(affectedSpanStart);
          var affectedSpanEnd = affectedSpanStart + affectedSpan.text.length;
          log.d(affectedSpanEnd);

          var beforeText = oldPlainText.substring(
              affectedSpanStart, newSelection.baseOffset);
          log.d(beforeText);

          var afterText = oldPlainText.substring(
              currentSelection.extentOffset, affectedSpanEnd);
          log.d(afterText);

          String newText = beforeText + afterText;

          if (newText.isNotEmpty) {
            affectedSpan =
                Extensions.copySpanWith(base: affectedSpan, text: newText);
            children.insert(index, affectedSpan);
          } else if (children.isEmpty) children = null;

          TextSpan root = new TextSpan(
              style: currentSpan.style,
              text: currentSpan.text,
              children: children,
              recognizer: currentSpan.recognizer);

          newValue = newValue.copyWith(value: root);
        }

        /// If the user deletes text from the end, just remove the text from the
        /// last [TextSpan] in children list.
        ///
        /// If the text is empty remove the child from list.
        else {
          log.d(
              "-----------------------------------------------DELETE FROM END");
          List<TextSpan> children = [];

          /// We need a copy of the children list to avoid changing the
          /// [oldValue] content. <b>Remove this and see what happens. :D</b>
          currentSpan.children.forEach((it) => children.add(it));
          var lastSpan = children.last;
          children.removeLast();

          var text = newValue.value.text
              .substring(Extensions.getOffsetInParent(currentSpan, lastSpan));

          if (text.isNotEmpty) {
            lastSpan = Extensions.copySpanWith(base: lastSpan, text: text);
            children.add(lastSpan);
          } else if (children.isEmpty) children = null;

          log.d("children: $children");

          TextSpan root = new TextSpan(
              style: currentSpan.style,
              text: currentSpan.text,
              children: children,
              recognizer: currentSpan.recognizer);

          newValue = newValue.copyWith(value: root);
        }
      }
    }

    return newValue;
  }

  static TextSpan updateSpansWithStyle(TextSpan span, TextSelection selection,
      TextStyle currentStyle, TextStyle newStyle) {
    if (newStyle == Extensions.emptyStyle) {
      log.w("The new style is empty. We are not touching anything!");
      return span;
    }

    List<TextSpan> children = [];

    if (span.children != null) {
      /// We need a copy of the children list to avoid changing the
      /// [oldValue] content. <b>Remove this and see what happens. :D</b>
      span.children.forEach((it) => children.add(it));
    }

    var newSpan = span;
    var rootTextLength = span.text.length;
    TextStyle diffStyle = Extensions.getDifferenceStyle(currentStyle, newStyle);

    /// The selection include the root text.
    if (rootTextLength > selection.baseOffset) {
      log.d("----------------------------------------------START: ROOT TEXT");

      /// The selection ends in the root text.
      if (rootTextLength >= selection.extentOffset) {
        log.d("-----------------------------------------END: ROOT TEXT");

        var beforeText = selection.textBefore(span.text);
        var insideText = selection.textInside(span.text);

        children.insert(
            0,
            new TextSpan(
                text: insideText,
                style: Extensions.deepMerge(span.style, diffStyle)));

        if (rootTextLength != selection.extentOffset) {
          var afterText = selection.textAfter(span.text);
          children.insert(1, new TextSpan(text: afterText, style: span.style));
        }

        newSpan = Extensions.copySpanWith(
            base: span, text: beforeText, children: children);
      }

      /// The selection ends in one of the children.
      else {
        assert(children.isNotEmpty);

        //handle root text
        var rootTextBeforeSelection = selection.textBefore(span.text);
        var rootTextInSelection = span.text.substring(selection.baseOffset);

        //handle children
        var startSpan = span.getSpanForPosition(new TextPosition(
            offset: span.text.length, affinity: selection.affinity));

        var endSpan = span.getSpanForPosition(selection.extent);

        var startIndex = children.indexOf(startSpan); //must be 0
        var endIndex = children.indexOf(endSpan);

        /// The selection ends in the first child.
        if (startIndex == endIndex) {
          log.d(
              "-------------------------------------------------END: CHILDREN: startIndex == endIndex");

          var startSpanText = startSpan.text;

          var beforeText = startSpanText.substring(
              0, selection.extentOffset - span.text.length);
          var afterText = startSpanText.substring(beforeText.length);

          children.remove(startSpan);
          children.insert(
              0,
              Extensions.copySpanWith(
                  base: startSpan,
                  text: beforeText,
                  style: Extensions.deepMerge(startSpan.style, diffStyle)));

          if (afterText.isNotEmpty) {
            children.insert(
                1, Extensions.copySpanWith(base: startSpan, text: afterText));
          }
        }

        /// The selection ends in the second child.
        else if (endIndex - startIndex == 1) {
          log.d(
              "-------------------------------------------------END: CHILDREN: endIndex - startIndex == 1");
          var endSpanText = endSpan.text;

          var beforeText = endSpanText.substring(
              0,
              selection.extentOffset -
                  Extensions.getOffsetInParent(span, endSpan));
          var afterText = endSpanText.substring(beforeText.length);

          children.remove(startSpan);
          children.remove(endSpan);

          children.insert(
              0,
              Extensions.copySpanWith(
                  base: startSpan,
                  style: Extensions.deepMerge(startSpan.style, diffStyle)));
          children.insert(
              1,
              Extensions.copySpanWith(
                  base: endSpan,
                  text: beforeText,
                  style: Extensions.deepMerge(endSpan.style, diffStyle)));

          if (afterText.isNotEmpty) {
            children.insert(
                2, Extensions.copySpanWith(base: endSpan, text: afterText));
          }
        }

        /// The selection ends in another child
        else {
          log.d(
              "-------------------------------------------------END: CHILDREN: else");
          var endSpanText = endSpan.text;

          var beforeEndText = endSpanText.substring(
              0,
              selection.extentOffset -
                  Extensions.getOffsetInParent(span, endSpan));
          assert(beforeEndText.isNotEmpty);

          var afterEndText = endSpanText.substring(beforeEndText.length);

          var newChildren = [];
          children.getRange(0, endIndex).forEach((span) => newChildren.add(
              Extensions.copySpanWith(
                  base: span,
                  style: Extensions.deepMerge(span.style, diffStyle))));
          newChildren.add(Extensions.copySpanWith(
              base: endSpan,
              text: beforeEndText,
              style: Extensions.deepMerge(endSpan.style, diffStyle)));

          if (afterEndText.isNotEmpty)
            newChildren
                .add(Extensions.copySpanWith(base: endSpan, text: afterEndText));

          newChildren.addAll(children.getRange(endIndex + 1, children.length));

          children = newChildren;
        }

        children.insert(
            0,
            new TextSpan(
                text: rootTextInSelection,
                style: Extensions.deepMerge(span.style, diffStyle)));

        children = _optimiseChildren(children);
        newSpan = Extensions.copySpanWith(
            base: span, text: rootTextBeforeSelection, children: children);
      }
    }

    /// The selection is only in children.
    else {
      log.d("--------------------------------START: CHILDREN <> END: CHILDREN");

      var startSpan = span.getSpanForPosition(selection.base);
      var endSpan = span.getSpanForPosition(new TextPosition(
          offset: selection.end - 1, affinity: selection.affinity));

      var startIndex = children.indexOf(startSpan);
      var endIndex = children.indexOf(endSpan);

      /// Get the children before the selection if there are any.
      var beforeChildren = [];
      if (startIndex != 0) {
        //
        children
            .getRange(0, startIndex)
            .forEach((span) => beforeChildren.add(span));
      }

      /// Get the children after the selection if there are any.
      var afterChildren = [];
      if (endIndex != children.length - 1) {
        children
            .getRange(endIndex + 1, children.length)
            .forEach((span) => afterChildren.add(span));
      }

      /// The selection is starts and ends in the same span.
      if (startIndex == endIndex) {
        log.d(
            "-------------------------------------------------startIndex == endIndex");
        var startSpanText = startSpan.text;

        var beforeText = startSpanText.substring(
            0,
            selection.baseOffset -
                Extensions.getOffsetInParent(span, startSpan));

        var insideText = startSpanText.substring(beforeText.length,
            beforeText.length + selection.extentOffset - selection.baseOffset);

        var afterText =
            startSpanText.substring(beforeText.length + insideText.length);

        if (beforeText.isNotEmpty) {
          beforeChildren
              .add(Extensions.copySpanWith(base: startSpan, text: beforeText));
        }

        if (insideText.isNotEmpty) {
          beforeChildren.add(Extensions.copySpanWith(
              base: startSpan,
              text: insideText,
              style: Extensions.deepMerge(startSpan.style, diffStyle)));
        }

        if (afterText.isNotEmpty) {
          beforeChildren
              .add(Extensions.copySpanWith(base: startSpan, text: afterText));
        }
      }

      /// The selection start in on span and ends in another one.
      else {
        log.d(
            "-------------------------------------------------endIndex - startIndex == 1");
        //start span
        var startSpanText = startSpan.text;
        var beforeStartText = startSpanText.substring(
            0,
            selection.baseOffset -
                Extensions.getOffsetInParent(span, startSpan));
        var afterStartText = startSpanText.substring(beforeStartText.length);

        //end span
        var endSpanText = endSpan.text;
        var beforeEndText = endSpanText.substring(
            0,
            selection.extentOffset -
                Extensions.getOffsetInParent(span, endSpan));
        var afterEndText = endSpanText.substring(beforeEndText.length);

        if (beforeStartText.isNotEmpty) {
          beforeChildren
              .add(Extensions.copySpanWith(base: startSpan, text: beforeStartText));
        }

        beforeChildren.add(Extensions.copySpanWith(
            base: startSpan,
            text: afterStartText,
            style: Extensions.deepMerge(startSpan.style, diffStyle)));

        if (endIndex - startIndex > 1) {
          children.getRange(startIndex + 1, endIndex).forEach((span) =>
              beforeChildren.add(Extensions.copySpanWith(
                  base: span,
                  style: Extensions.deepMerge(span.style, diffStyle))));
        }

        beforeChildren.add(Extensions.copySpanWith(
            base: endSpan,
            text: beforeEndText,
            style: Extensions.deepMerge(endSpan.style, diffStyle)));
        if (afterEndText.isNotEmpty) {
          beforeChildren
              .add(Extensions.copySpanWith(base: endSpan, text: afterEndText));
        }
      }

      beforeChildren.addAll(afterChildren);
      beforeChildren = _optimiseChildren(beforeChildren);
      newSpan = Extensions.copySpanWith(base: span, children: beforeChildren);
    }

    return newSpan;
  }

  /// Return an optimized list of children where [TextSpan]s that are next to
  /// each other and have the same [TextStyle] are merged.
  static List<TextSpan> _optimiseChildren(List<TextSpan> children) {
    var newChildren = [];
    children.forEach((span) {
      var i = children.indexOf(span);

      if (i == 0) {
        newChildren.add(span);
        return;
      }

      var previousSpan = children[i - 1];

      if (span.style == previousSpan.style) {
        TextSpan lastSpanInNewChildren = newChildren.last;
        newChildren[newChildren.length - 1] = Extensions.copySpanWith(
            base: previousSpan, text: lastSpanInNewChildren.text + span.text);
      } else
        newChildren.add(span);
    });

    return newChildren;
  }

  static TextStyle getDifferenceStyle(TextStyle base, TextStyle style) {
    log.d(base);
    log.d(style);

    Color color;
    if (base.color != style.color) {
      log.d("color: base=${base.color} style:${style.color}");
      color = style.color;
    }

    String fontFamily;
    if (base.fontFamily != style.fontFamily) {
      log.d("fontFamily: base=${base.fontFamily} style:${style.fontFamily}");
      fontFamily = style.fontFamily;
    }

    double fontSize;
    if (base.fontSize != style.fontSize) {
      log.d("fontSize: base=${base.fontSize} style:${style.fontSize}");
      fontSize = style.fontSize;
    }

    FontWeight fontWeight;
    if (base.fontWeight != style.fontWeight) {
      log.d("fontWeight: base=${base.fontWeight} style:${style.fontWeight}");
      fontWeight = style.fontWeight;
    }

    FontStyle fontStyle;
    if (base.fontStyle != style.fontStyle) {
      log.d("fontStyle: base=${base.fontStyle} style:${style.fontStyle}");
      fontStyle = style.fontStyle;
    }

    double letterSpacing;
    if (base.letterSpacing != style.letterSpacing) {
      log.d("letterSpacing: base=${base.letterSpacing} style:${style
          .letterSpacing}");
      letterSpacing = style.letterSpacing;
    }

    double wordSpacing;
    if (base.wordSpacing != style.wordSpacing) {
      log.d("wordSpacing: base=${base.wordSpacing} style:${style.wordSpacing}");
      wordSpacing = style.wordSpacing;
    }

    TextBaseline textBaseline;
    if (base.textBaseline != style.textBaseline) {
      log.d("textBaseline: base=${base.textBaseline} style:${style
          .textBaseline}");
      textBaseline = style.textBaseline;
    }

    double height;
    if (base.height != style.height) {
      log.d("height: base=${base.height} style:${style.height}");
      height = style.height;
    }

    TextDecoration decoration;
    if (base.decoration == style.decoration) {
      log.d("decoration: base=${base.decoration} style:${style.decoration}");
      decoration = style.decoration;
    }

    Color decorationColor;
    if (base.decorationColor != style.decorationColor) {
      log.d("decorationColor: base=${base.decorationColor} style:${style
          .decorationColor}");
      decorationColor = style.decorationColor;
    }

    TextDecorationStyle decorationStyle;
    if (base.decorationStyle != style.decorationStyle) {
      log.d("decorationStyle: base=${base.decorationStyle} style:${style
          .decorationStyle}");
      decorationStyle = style.decorationStyle;
    }

    TextStyle newStyle = new TextStyle(
        color: color,
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle);

    log.d(newStyle);
    return newStyle;
  }

  static bool _equalTextValue(RichTextEditingValue a, RichTextEditingValue b) {
    return a.value.toPlainText() == b.value.toPlainText() &&
        a.selection == b.selection &&
        a.composing == b.composing;
  }

  static bool _sameTextDiffSelection(
      RichTextEditingValue a, RichTextEditingValue b) {
    return a.value.toPlainText() == b.value.toPlainText() &&
        (a.selection != b.selection || a.composing != b.composing);
  }
}
