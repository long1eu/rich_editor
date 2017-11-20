import 'package:flutter/material.dart';
import 'package:flutter_logger/flutter_logger.dart';
import 'package:rich_editor/src/extensions.dart';
import 'package:rich_editor/src/services/rich_text_parser.dart';
import 'package:rich_editor/src/services/text_input.dart';
import 'package:rich_editor/src/widgets/rich_editable_text.dart';
import 'package:test/test.dart';

Log log = new Log("rich_text_parser_test");

TextStyle oldStyle = StyleController.material;
TextStyle newStyle = Extensions.copyStyleWith(
  base: oldStyle,
  fontSize: 20.0,
  fontStyle: FontStyle.italic,
);

TextStyle diffStyle = Extensions.getDifferenceStyle(oldStyle, newStyle);

void main() {
  test(
    'changeSelection',
    () => changeSelection(),
  );
  test(
    'changeRange',
    () => changeRange(),
  );
  test(
    'changeStyle',
    () => changeStyle(),
  );

  test(
    'optimizeChildren',
    () => optimizeChildren(),
  );

  //
  test(
    'addToRoot_SameStyle_AtStart',
    () => AddToRoot_WithoutChildren_SameStyle.atStart(),
  );
  test('addToRoot_SameStyle_AtMiddle',
      () => AddToRoot_WithoutChildren_SameStyle.atMiddle());
  test(
    'addToRoot_SameStyle_AtEnd',
    () => AddToRoot_WithoutChildren_SameStyle.atEnd(),
  );

  //
  test(
    'addToRoot_DifferentStyle_AtStart',
    () => AddToRoot_WithoutChildren_DifferentStyle.atStart(),
  );
  test(
    'addToRoot_DifferentStyle_AtMiddle',
    () => AddToRoot_WithoutChildren_DifferentStyle.atMiddle(),
  );
  test(
    'addToRoot_DifferentStyle_AtEnd',
    () => AddToRoot_WithoutChildren_DifferentStyle.atEnd(),
  );

  //
  test(
    "AddToRoot_WithChildren_SameStyle.atStart",
    () => AddToRoot_WithChildren_SameStyle.atStart(),
  );

  test(
    "AddToRoot_WithChildren_SameStyle.atMiddle",
    () => AddToRoot_WithChildren_SameStyle.atMiddle(),
  );

  test(
    "AddToRoot_WithChildren_SameStyle.atEnd",
    () => AddToRoot_WithChildren_SameStyle.atEnd(),
  );

  //
  test(
    "AddToRoot_WithChildren_DifferentStyle.atStart",
    () => AddToRoot_WithChildren_DifferentStyle.atStart(),
  );

  test(
    "AddToRoot_WithChildren_DifferentStyle.atMiddle",
    () => AddToRoot_WithChildren_DifferentStyle.atMiddle(),
  );

  test(
    "AddToRoot_WithChildren_DifferentStyle.atEnd",
    () => AddToRoot_WithChildren_DifferentStyle.atEnd(),
  );

  //
  test(
    "AddToChild_SameStyle.atMiddle",
    () => AddToChild_SameStyle.atMiddle(),
  );

  test(
    "AddToChild_SameStyle.atEndMiddleChild",
    () => AddToChild_SameStyle.atEndMiddleChild(),
  );

  test(
    "AddToChild_SameStyle.atEndLastChild",
    () => AddToChild_SameStyle.atEndLastChild(),
  );

  //
  test(
    "AddToChild_DifferentStyle.atMiddle",
    () => AddToChild_DifferentStyle.atMiddle(),
  );

  test(
    "AddToChild_DifferentStyle.atEnd",
    () => AddToChild_DifferentStyle.atEnd(),
  );

  /////
  /////
  test(
    "Delete.deleteInRootAtStart",
    () => Delete.deleteInRootAtStart(),
  );

  test(
    "Delete.deleteInRootAtMiddle",
    () => Delete.deleteInRootAtMiddle(),
  );

  test(
    "Delete.deleteInRootAtEnd",
    () => Delete.deleteInRootAtEnd(),
  );

  test(
    "Delete.deleteLastChildAtStart",
    () => Delete.deleteLastChildAtStart(),
  );

  test(
    "Delete.deleteLastChildAtMiddle",
    () => Delete.deleteLastChildAtMiddle(),
  );

  test(
    "Delete.deleteLastChildAtEnd",
    () => Delete.deleteLastChildAtEnd(),
  );

  test(
    "Delete.deleteChildAtStart",
    () => Delete.deleteChildAtStart(),
  );

  test(
    "Delete.deleteChildAtMiddle",
    () => Delete.deleteChildAtMiddle(),
  );

  test(
    "Delete.deleteChildAtEnd",
    () => Delete.deleteChildAtEnd(),
  );

  //
  test(
    "Delete.deleteAllChild",
    () => Delete.deleteAllChild(),
  );

  test(
    "Delete.deleteMultipleChildren",
        () => Delete.deleteMultipleChildren(),
  );
}

changeSelection() {
  RichTextEditingValue oldValue = new RichTextEditingValue(
    value: new TextSpan(text: "aa", style: StyleController.material),
    selection: new TextSelection.collapsed(offset: 1),
  );

  TextSelection newSelection =
      new TextSelection(baseOffset: 1, extentOffset: 2);

  RichTextEditingValue newValue = new RichTextEditingValue(
    value: new TextSpan(text: "aa"),
    selection: newSelection,
  );

  expect(
      RichTextEditingValueParser.parse(
        oldValue: oldValue,
        newValue: newValue,
        style: StyleController.material,
      ),
      oldValue.copyWith(selection: newSelection));
}

changeRange() {
  int cursorPosition = 3;

  RichTextEditingValue oldValue = new RichTextEditingValue(
    value: new TextSpan(text: "a a", style: StyleController.material),
    selection: new TextSelection.collapsed(offset: cursorPosition),
  );

  TextRange newRange = new TextRange(start: 2, end: cursorPosition);

  RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: "a a"),
      selection: new TextSelection.collapsed(offset: cursorPosition),
      composing: newRange);

  expect(
      RichTextEditingValueParser.parse(
        oldValue: oldValue,
        newValue: newValue,
        style: StyleController.material,
      ),
      oldValue.copyWith(composing: newRange));
}

changeStyle() {
  RichTextEditingValue oldValue = new RichTextEditingValue(
    value: new TextSpan(text: "aa", style: StyleController.material),
    selection: new TextSelection.collapsed(offset: 1),
  );

  RichTextEditingValue newValue = new RichTextEditingValue(
    value: new TextSpan(text: "aa"),
    selection: new TextSelection.collapsed(offset: 1),
  );

  expect(
      RichTextEditingValueParser.parse(
        oldValue: oldValue,
        newValue: newValue,
        style: StyleController.material.copyWith(color: Colors.red),
      ),
      oldValue);
}

optimizeChildren() {
  List<TextSpan> list = [
    new TextSpan(
      text: "part1 ",
      style: oldStyle,
    ),
    new TextSpan(
      text: "part1 ",
      style: oldStyle.copyWith(
        color: Colors.red,
      ),
    ),
    new TextSpan(
      text: "part1 ",
      style: oldStyle.copyWith(
        color: Colors.red,
      ),
    ),
    new TextSpan(
      text: "part1 ",
      style: oldStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
    ),
    new TextSpan(
      text: "part1 ",
      style: oldStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
    ),
  ];

  List<TextSpan> result = RichTextEditingValueParser.optimiseChildren(list);

  List<TextSpan> expected = [
    new TextSpan(
      text: "part1 ",
      style: oldStyle,
    ),
    new TextSpan(
      text: "part1 part1 ",
      style: oldStyle.copyWith(
        color: Colors.red,
      ),
    ),
    new TextSpan(
      text: "part1 part1 ",
      style: oldStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
    ),
  ];

  expect(result, expected);
}

////////////////////////////////////////////////////////////////////////////////
//// Add to root of the TextSpan

// ignore: camel_case_types
class AddToRoot_WithoutChildren_SameStyle {
  static var part1 = "this is ";
  static var part2 = "the text";
  static var text = part1 + part2;

  static atStart() {
    log.i("AddToRoot_WithoutChildren_SameStyle_AtStart");

    var add = "start";

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(text: text, style: StyleController.material),
      selection: new TextSelection.collapsed(offset: 0),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: add + text),
      selection: new TextSelection.collapsed(offset: add.length),
    );

    expect(
        RichTextEditingValueParser.parse(
          oldValue: oldValue,
          newValue: newValue,
          style: StyleController.material,
        ),
        newValue);
  }

  static atMiddle() {
    log.i("AddToRoot_WithoutChildren_SameStyle_AtMiddle");

    var add = "midlle";

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(text: text, style: StyleController.material),
      selection: new TextSelection.collapsed(offset: part1.length),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: part1 + add + part2),
      selection: new TextSelection.collapsed(offset: part1.length + add.length),
    );

    expect(
        RichTextEditingValueParser.parse(
          oldValue: oldValue,
          newValue: newValue,
          style: StyleController.material,
        ),
        newValue);
  }

  // this is a special case. this is the last span so it has the atEnd().
  static atEnd() {
    log.i("AddToRoot_WithoutChildren_SameStyle_AtEnd");

    var add = "end";

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(text: text, style: StyleController.material),
      selection: new TextSelection.collapsed(offset: 0),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: text + add),
      selection: new TextSelection.collapsed(offset: text.length + add.length),
    );

    expect(
        RichTextEditingValueParser.parse(
          oldValue: oldValue,
          newValue: newValue,
          style: StyleController.material,
        ),
        newValue);
  }
}

// ignore: camel_case_types
class AddToRoot_WithoutChildren_DifferentStyle {
  static var part1 = "this is ";
  static var part2 = "the text";
  static var text = part1 + part2;

  static TextStyle newStyle = Extensions.copyStyleWith(
    base: oldStyle,
    fontSize: 20.0,
  );

  static atStart() {
    log.i("AddToRoot_WithoutChildren_DifferentStyle_AtStart");

    var add = "start";

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(text: text, style: StyleController.material),
      selection: new TextSelection.collapsed(offset: 0),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: add + text),
      selection: new TextSelection.collapsed(offset: add.length),
    );

    //
    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: newStyle,
    );

    RichTextEditingValue expected = oldValue.copyWith(
      value: new TextSpan(
        text: "",
        style: oldStyle,
        children: [
          new TextSpan(
            text: add,
            style: newStyle,
          ),
          new TextSpan(
            text: text,
            style: oldStyle,
          ),
        ],
      ),
      selection: newValue.selection,
    );

    expect(result, expected);
  }

  static atMiddle() {
    log.i("AddToRoot_WithoutChildren_DifferentStyle_AtMiddle");

    var add = "midlle";

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(text: text, style: oldStyle),
      selection: new TextSelection.collapsed(offset: part1.length),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: part1 + add + part2),
      selection: new TextSelection.collapsed(offset: part1.length + add.length),
    );

    //
    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: newStyle,
    );

    RichTextEditingValue expected = oldValue.copyWith(
      value: new TextSpan(
        text: part1,
        style: oldStyle,
        children: [
          new TextSpan(
            text: add,
            style: newStyle,
          ),
          new TextSpan(
            text: part2,
            style: oldStyle,
          )
        ],
      ),
      selection: newValue.selection,
    );

    expect(result, expected);
  }

  static atEnd() {
    log.i("AddToRoot_WithoutChildren_DifferentStyle_AtEnd");

    var add = "end";

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(text: text, style: StyleController.material),
      selection: new TextSelection.collapsed(offset: text.length),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: text + add),
      selection: new TextSelection.collapsed(offset: text.length + add.length),
    );

    //
    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: newStyle,
    );

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: text,
        style: StyleController.material,
        children: [
          new TextSpan(
            text: add,
            style: Extensions.deepMerge(StyleController.material, newStyle),
          ),
        ],
      ),
      selection: newValue.selection,
    );

    expect(result, expected);
  }
}

// ignore: camel_case_types
class AddToRoot_WithChildren_SameStyle {
  //root
  static var part1a = "this is";
  static var part1b = " the text";
  static var part1 = part1a + part1b;

  //children
  static var part2 = " part2";

  static var text = part1 + part2;

  static TextSpan root = new TextSpan(
    text: part1,
    style: oldStyle,
    children: [
      new TextSpan(
        text: part2,
        style: Extensions.copyStyleWith(
          base: StyleController.material,
          fontSize: 20.0,
        ),
      ),
    ],
  );

  static RichTextEditingValue value = new RichTextEditingValue(
    value: root,
  );

  static atStart() {
    log.i("addToRoot_WithChildren_SameStyle_AtStart");

    var add = "start";

    RichTextEditingValue oldValue =
        value.copyWith(selection: new TextSelection.collapsed(offset: 0));

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: add + text),
      selection: new TextSelection.collapsed(offset: add.length),
    );

    //
    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: oldStyle,
    );

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: add + part1,
        style: oldStyle,
        children: oldValue.value.children,
      ),
      selection: newValue.selection,
    );

    expect(result, expected);
  }

  static atMiddle() {
    log.i("addToRoot_WithChildren_SameStyle_AtMiddle");

    var add = "middle";

    RichTextEditingValue oldValue = value.copyWith(
        selection: new TextSelection.collapsed(offset: part1a.length));

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: part1a + add + part1b + part2),
      selection: new TextSelection.collapsed(offset: (part1a + add).length),
    );

    //
    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: oldStyle,
    );

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: part1a + add + part1b,
        style: oldStyle,
        children: oldValue.value.children,
      ),
      selection: newValue.selection,
    );

    expect(result, expected);
  }

  //The edit in this case is not at root text but to the first child. We test to
  //see if the edit is not done in the root.
  static atEnd() {
    log.i("addToRoot_WithChildren_SameStyle_AtEnd");

    var add = "end";

    RichTextEditingValue oldValue = value.copyWith(
        selection: new TextSelection.collapsed(offset: part1.length));

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: part1 + add + part2),
      selection: new TextSelection.collapsed(offset: (part1 + add).length),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: part1 + add,
        style: oldStyle,
        children: [
          new TextSpan(
            text: part2,
            style: Extensions.copyStyleWith(
              base: StyleController.material,
              fontSize: 20.0,
            ),
          ),
        ],
      ),
      selection: newValue.selection,
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: oldStyle,
    );

    expect(result, expected);
  }
}

// ignore: camel_case_types
class AddToRoot_WithChildren_DifferentStyle {
  //root
  static var part1a = "this is";
  static var part1b = " the text";
  static var part1 = part1a + part1b;

  //children
  static var part2 = " part2";

  static var text = part1 + part2;

  static List<TextSpan> children = [
    new TextSpan(
      text: part2,
      style: Extensions.copyStyleWith(
        base: StyleController.material,
        fontSize: 20.0,
      ),
    ),
  ];

  static TextSpan root = new TextSpan(
    text: part1,
    style: oldStyle,
    children: children,
  );

  static RichTextEditingValue value = new RichTextEditingValue(
    value: root,
  );

  static atStart() {
    log.i("addToRoot_WithChildren_DifferentStyle_AtStart");

    var add = "start";

    RichTextEditingValue oldValue =
        value.copyWith(selection: new TextSelection.collapsed(offset: 0));

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: add + text),
      selection: new TextSelection.collapsed(offset: add.length),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: "",
        style: oldStyle,
        children: [
          new TextSpan(
            text: add,
            style: newStyle,
          ),
          new TextSpan(
            text: part1,
            style: oldStyle,
          ),
          children[0],
        ],
      ),
      selection: newValue.selection,
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: newStyle,
    );

    expect(result, expected);
  }

  static atMiddle() {
    log.i("addToRoot_WithChildren_DifferentStyle_AtMiddle");

    var add = "middle";

    RichTextEditingValue oldValue = value.copyWith(
        selection: new TextSelection.collapsed(offset: part1a.length));

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: part1a + add + part1b + part2),
      selection: new TextSelection.collapsed(offset: (part1a + add).length),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: part1a,
        style: oldStyle,
        children: [
          new TextSpan(
            text: add,
            style: newStyle,
          ),
          new TextSpan(text: part1b, style: oldStyle),
          children[0],
        ],
      ),
      selection: newValue.selection,
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: newStyle,
    );

    expect(result, expected);
  }

  static atEnd() {
    log.i("addToRoot_WithChildren_DifferentStyle_AtEnd");

    var add = "end";

    RichTextEditingValue oldValue = value.copyWith(
        selection: new TextSelection.collapsed(offset: part1.length));

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: part1 + add + part2),
      selection: new TextSelection.collapsed(offset: (part1 + add).length),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: part1,
        style: oldStyle,
        children: [
          new TextSpan(
            text: add,
            style: newStyle,
          ),
          children[0],
        ],
      ),
      selection: newValue.selection,
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: newStyle,
    );

    expect(result, expected);
  }
}

// ignore: camel_case_types
class AddToChild_SameStyle {
  //root
  static var part1 = "this is the root text";

  //children

  static var part2a = "aici este";
  static var part2b = " partea a doua";
  static var part2 = part2a + part2b;

  static var part3a = " esta la";
  static var part3b = " tre parte";
  static var part3 = part3a + part3b;

  static var part4 = " part4";

  static var part5a = " c'est la";
  static var part5b = " cinque parte";
  static var part5 = part5a + part5b;

  static var text = part1 + part2 + part3 + part4 + part5;

  static List<TextSpan> children = [
    new TextSpan(
      text: part2,
      style: Extensions.copyStyleWith(
        base: StyleController.material,
        fontSize: 20.0,
      ),
    ),
    new TextSpan(
      text: part3,
      style: StyleController.material,
    ),
    new TextSpan(
      text: part4,
      style: Extensions.copyStyleWith(
        base: StyleController.material,
        fontWeight: FontWeight.w700,
      ),
    ),
    new TextSpan(
      text: part5,
      style: Extensions.copyStyleWith(
        base: StyleController.material,
        color: Colors.red,
      ),
    ),
  ];

  static TextSpan root = new TextSpan(
    text: part1,
    style: oldStyle,
    children: children,
  );

  static RichTextEditingValue value = new RichTextEditingValue(
    value: root,
  );

  static atMiddle() {
    log.i("AddToChild_SameStyle_AtMiddle");

    var add = "middle";

    RichTextEditingValue oldValue = value.copyWith(
      selection: new TextSelection.collapsed(offset: (part1 + part2a).length),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
          text: part1 + part2a + add + part2b + part3 + part4 + part5),
      selection: new TextSelection.collapsed(
        offset: (part1 + part2a + add).length,
      ),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: part1,
        style: oldStyle,
        children: [
          new TextSpan(
            text: part2a + add + part2b,
            style: children[0].style,
          ),
          children[1],
          children[2],
          children[3],
        ],
      ),
      selection: newValue.selection,
    );

    expected = expected.copyWith(
      value: Extensions.copySpanWith(
        base: expected.value,
        children: RichTextEditingValueParser
            .optimiseChildren(expected.value.children),
      ),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: children[0].style,
    );

    expect(result, expected);
  }

  //If the span is not the last one atEnd doesn't exist. Make sure only at the
  //end span this is allowed, else add the new text to the next span.
  static atEndMiddleChild() {
    log.i("AddToChild_SameStyle_atEndMiddleSpan");

    var add = "end";

    RichTextEditingValue oldValue = value.copyWith(
        selection: new TextSelection.collapsed(offset: (part1 + part2).length));

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: part1 + part2 + add + part3 + part4 + part5),
      selection:
          new TextSelection.collapsed(offset: (part1 + part2 + add).length),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: part1,
        style: oldStyle,
        children: [
          new TextSpan(
            text: children[0].text + add,
            style: children[0].style,
          ),
          children[1],
          children[2],
          children[3],
        ],
      ),
      selection: newValue.selection,
    );

    expected = expected.copyWith(
      value: Extensions.copySpanWith(
        base: expected.value,
        children: RichTextEditingValueParser
            .optimiseChildren(expected.value.children),
      ),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: children[0].style,
    );

    expect(result, expected);
  }

  //If the span is not the last one atEnd doesn't exist. Make sure only at the
  //end span this is allowed, else add the new text to the next span.
  static atEndLastChild() {
    log.i("AddToChild_SameStyle_atEndLastSpan");

    var add = "end";

    RichTextEditingValue oldValue = value.copyWith(
        selection: new TextSelection.collapsed(offset: text.length));

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: text + add),
      selection: new TextSelection.collapsed(offset: (text + add).length),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: part1,
        style: oldStyle,
        children: [
          children[0],
          children[1],
          children[2],
          new TextSpan(
            text: children[3].text + add,
            style: children[3].style,
          ),
        ],
      ),
      selection: newValue.selection,
    );

    expected = expected.copyWith(
      value: Extensions.copySpanWith(
        base: expected.value,
        children: RichTextEditingValueParser
            .optimiseChildren(expected.value.children),
      ),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: children[3].style,
    );

    expect(result, expected);
  }
}

// ignore: camel_case_types
class AddToChild_DifferentStyle {
  //root
  static var part1 = "this is the root text";

  //children

  static var part2a = "aici este";
  static var part2b = " partea a doua";
  static var part2 = part2a + part2b;

  static var part3a = " esta la";
  static var part3b = " tre parte";
  static var part3 = part3a + part3b;

  static var part4 = " part4";

  static var part5a = " c'est la";
  static var part5b = " cinque parte";
  static var part5 = part5a + part5b;

  static var text = part1 + part2 + part3 + part4 + part5;

  static List<TextSpan> children = [
    new TextSpan(
      text: part2,
      style: Extensions.copyStyleWith(
        base: StyleController.material,
        fontSize: 20.0,
      ),
    ),
    new TextSpan(
      text: part3,
      style: StyleController.material,
    ),
    new TextSpan(
      text: part4,
      style: Extensions.copyStyleWith(
        base: StyleController.material,
        fontWeight: FontWeight.w700,
      ),
    ),
    new TextSpan(
      text: part5,
      style: Extensions.copyStyleWith(
        base: StyleController.material,
        color: Colors.red,
      ),
    ),
  ];

  static TextSpan root = new TextSpan(
    text: part1,
    style: oldStyle,
    children: children,
  );

  static RichTextEditingValue value = new RichTextEditingValue(
    value: root,
  );

  static atMiddle() {
    log.i("AddToChild_DifferentStyle_AtMiddle");

    var add = "middle";

    RichTextEditingValue oldValue = value.copyWith(
      selection:
          new TextSelection.collapsed(offset: (part1 + part2 + part3a).length),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
          text: part1 + part2 + part3a + add + part3b + part4 + part5),
      selection: new TextSelection.collapsed(
        offset: (part1 + part2 + part3a + add).length,
      ),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: part1,
        style: oldStyle,
        children: [
          children[0],
          new TextSpan(
            text: part3a,
            style: children[1].style,
          ),
          new TextSpan(
            text: add,
            style: newStyle,
          ),
          new TextSpan(
            text: part3b,
            style: children[1].style,
          ),
          children[2],
          children[3],
        ],
      ),
      selection: newValue.selection,
    );

    expected = expected.copyWith(
      value: Extensions.copySpanWith(
        base: expected.value,
        children: RichTextEditingValueParser
            .optimiseChildren(expected.value.children),
      ),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: newStyle,
    );

    expect(result, expected);
  }

  static atEnd() {
    log.i("AddToChild_DifferentStyle_atEnd");

    var add = "end";

    RichTextEditingValue oldValue = value.copyWith(
        selection: new TextSelection.collapsed(
            offset: (part1 + part2 + part3 + part4).length));

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: part1 + part2 + part3 + part4 + add + part5),
      selection: new TextSelection.collapsed(
          offset: (part1 + part2 + part3 + part4 + add).length),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: part1,
        style: oldStyle,
        children: [
          children[0],
          children[1],
          children[2],
          new TextSpan(
            text: add,
            style: newStyle,
          ),
          children[3],
        ],
      ),
      selection: newValue.selection,
    );

    expected = expected.copyWith(
      value: Extensions.copySpanWith(
        base: expected.value,
        children: RichTextEditingValueParser
            .optimiseChildren(expected.value.children),
      ),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
      oldValue: oldValue,
      newValue: newValue,
      style: newStyle,
    );

    expect(result, expected);
  }
}

class Delete {
  static var rootTextA = "this is the";
  static var rootTextB = " root text";

  static var rootText = rootTextA + rootTextB;
  static var secondText = " second";

  static var thirdTextA = " this is";
  static var thirdTextB = " the middle child";
  static var thirdText = thirdTextA + thirdTextB;

  static var forthText = " this is the forth text";
  static var fifthTextA = " This is the";
  static var fifthTextB = " last span.";
  static var fifthText = fifthTextA + fifthTextB;
  static var text = rootText + secondText + thirdText + forthText + fifthText;

  static deleteInRootAtStart() {
    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: [
          new TextSpan(
            text: secondText,
            style: newStyle,
          ),
        ],
      ),
      selection: new TextSelection.collapsed(offset: 1),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(text: rootText.substring(1) + secondText),
      selection: new TextSelection.collapsed(offset: 0),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText.substring(1),
        children: [
          new TextSpan(
            text: secondText,
            style: newStyle,
          ),
        ],
      ),
      selection: new TextSelection.collapsed(offset: 0),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    expect(expected, result);
  }

  static deleteInRootAtMiddle() {
    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: [
          new TextSpan(
            text: secondText,
            style: newStyle,
          ),
        ],
      ),
      selection: new TextSelection.collapsed(offset: rootTextA.length + 2),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value:
          new TextSpan(text: rootTextA + rootTextB.substring(2) + secondText),
      selection: new TextSelection.collapsed(offset: rootTextA.length),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootTextA + rootTextB.substring(2),
        children: [
          new TextSpan(
            text: secondText,
            style: newStyle,
          ),
        ],
      ),
      selection: new TextSelection.collapsed(offset: rootTextA.length),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    expect(expected, result);
  }

  static deleteInRootAtEnd() {
    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: [
          new TextSpan(
            text: secondText,
            style: newStyle,
          ),
        ],
      ),
      selection: new TextSelection.collapsed(offset: rootText.length),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
          text: rootText.substring(0, rootText.length - 3) + secondText),
      selection: new TextSelection.collapsed(offset: rootText.length - 3),
    );

    //
    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText.substring(0, rootText.length - 3),
        children: [
          new TextSpan(
            text: secondText,
            style: newStyle,
          ),
        ],
      ),
      selection: new TextSelection.collapsed(offset: rootText.length - 3),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    expect(expected, result);
  }

  static deleteLastChildAtStart() {
    List<TextSpan> children = [
      new TextSpan(
        text: secondText,
        style: newStyle,
      ),
      new TextSpan(
        text: thirdText,
        style: oldStyle,
      ),
      new TextSpan(
        text: forthText,
        style: newStyle,
      ),
    ];

    var oldList = children.toList();
    oldList.add(
      new TextSpan(
        text: fifthText,
        style: oldStyle,
      ),
    );

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: oldList,
      ),
      selection: new TextSelection.collapsed(
          offset: text.length - fifthText.length + 2),
    );

    var newText = text.substring(0, fifthText.length) + fifthText.substring(2);
    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
        text: newText,
      ),
      selection:
          new TextSelection.collapsed(offset: fifthText.substring(2).length),
    );

    //
    var expectedList = children.toList();
    expectedList.add(
      new TextSpan(
        text: fifthText.substring(2),
        style: oldStyle,
      ),
    );

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: expectedList,
      ),
      selection:
          new TextSelection.collapsed(offset: fifthText.substring(2).length),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    log.d(expected.value.toStringDeep());
    log.d(result.value.toStringDeep());

    expect(expected, result);
  }

  static deleteLastChildAtMiddle() {
    List<TextSpan> children = [
      new TextSpan(
        text: secondText,
        style: newStyle,
      ),
      new TextSpan(
        text: thirdText,
        style: oldStyle,
      ),
      new TextSpan(
        text: forthText,
        style: newStyle,
      ),
    ];

    var oldList = children.toList();
    oldList.add(
      new TextSpan(
        text: fifthText,
        style: oldStyle,
      ),
    );

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: oldList,
      ),
      selection: new TextSelection.collapsed(offset: text.length - 2),
    );

    var newText =
        text.substring(0, text.length - 4) + text.substring(text.length - 2);
    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
        text: newText,
      ),
      selection: new TextSelection.collapsed(offset: newText.length - 2),
    );

    //
    var expectedList = children.toList();
    expectedList.add(
      new TextSpan(
        text: fifthText.substring(0, fifthText.length - 4) +
            fifthText.substring(fifthText.length - 2),
        style: oldStyle,
      ),
    );

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: expectedList,
      ),
      selection: new TextSelection.collapsed(offset: newText.length - 2),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    expect(expected, result);
  }

  static deleteLastChildAtEnd() {
    List<TextSpan> children = [
      new TextSpan(
        text: secondText,
        style: newStyle,
      ),
      new TextSpan(
        text: thirdText,
        style: oldStyle,
      ),
      new TextSpan(
        text: forthText,
        style: newStyle,
      ),
    ];

    var oldList = children.toList();
    oldList.add(
      new TextSpan(
        text: fifthText,
        style: oldStyle,
      ),
    );

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: oldList,
      ),
      selection: new TextSelection.collapsed(offset: text.length),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
        text: text.substring(0, text.length - 2),
      ),
      selection: new TextSelection.collapsed(offset: text.length - 2),
    );

    //
    var expectedList = children.toList();
    expectedList.add(
      new TextSpan(
        text: fifthText.substring(0, fifthText.length - 2),
        style: oldStyle,
      ),
    );

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: expectedList,
      ),
      selection: new TextSelection.collapsed(offset: text.length - 2),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    log.d(expected.value.toStringDeep());
    log.d(result.value.toStringDeep());

    expect(expected, result);
  }

  static deleteChildAtStart() {
    List<TextSpan> children = [
      new TextSpan(
        text: thirdText,
        style: oldStyle,
      ),
      new TextSpan(
        text: forthText,
        style: newStyle,
      ),
      new TextSpan(
        text: fifthText,
        style: oldStyle,
      ),
    ];

    var oldList = children.toList();
    oldList.insert(
      0,
      new TextSpan(
        text: secondText,
        style: newStyle,
      ),
    );

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: oldList,
      ),
      selection: new TextSelection.collapsed(offset: rootText.length + 2),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText +
            secondText.substring(2) +
            thirdText +
            forthText +
            fifthText,
      ),
      selection: new TextSelection.collapsed(offset: rootText.length),
    );

    //
    var expectedList = children.toList();
    expectedList.insert(
      0,
      new TextSpan(
        text: secondText.substring(2),
        style: newStyle,
      ),
    );

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: expectedList,
      ),
      selection: new TextSelection.collapsed(offset: rootText.length),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    log.d(expected.value.toStringDeep());
    log.d(result.value.toStringDeep());

    expect(expected, result);
  }

  static deleteChildAtMiddle() {
    List<TextSpan> children = [
      new TextSpan(
        text: secondText,
        style: newStyle,
      ),
      new TextSpan(
        text: thirdText,
        style: oldStyle,
      ),
      new TextSpan(
        text: forthText,
        style: newStyle,
      ),
    ];

    var oldList = children.toList();
    oldList.add(
      new TextSpan(
        text: fifthText,
        style: oldStyle,
      ),
    );

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: oldList,
      ),
      selection: new TextSelection.collapsed(offset: text.length),
    );

    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
        text: text.substring(0, text.length - 2),
      ),
      selection: new TextSelection.collapsed(offset: text.length - 2),
    );

    //
    var expectedList = children.toList();
    expectedList.add(
      new TextSpan(
        text: fifthText.substring(0, fifthText.length - 2),
        style: oldStyle,
      ),
    );

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: expectedList,
      ),
      selection: new TextSelection.collapsed(offset: text.length - 2),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    log.d(expected.value.toStringDeep());
    log.d(result.value.toStringDeep());

    expect(expected, result);
  }

  static deleteChildAtEnd() {
    List<TextSpan> children = [
      new TextSpan(
        text: secondText,
        style: newStyle,
      ),
      new TextSpan(
        text: forthText,
        style: newStyle,
      ),
      new TextSpan(
        text: fifthText,
        style: oldStyle,
      ),
    ];

    var oldList = children.toList();
    oldList.insert(
      1,
      new TextSpan(
        text: thirdText,
        style: oldStyle,
      ),
    );

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: oldList,
      ),
      selection: new TextSelection.collapsed(
          offset: (rootText + secondText + thirdText).length),
    );

    var newText = rootText +
        secondText +
        thirdText.substring(0, thirdText.length - 2) +
        forthText +
        fifthText;
    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
        text: newText,
      ),
      selection: new TextSelection.collapsed(
          offset: (rootText +
                  secondText +
                  thirdText.substring(0, thirdText.length - 2))
              .length),
    );

    //
    var expectedList = children.toList();
    expectedList.insert(
      1,
      new TextSpan(
        text: thirdText.substring(0, thirdText.length - 2),
        style: oldStyle,
      ),
    );

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: expectedList,
      ),
      selection: new TextSelection.collapsed(
          offset: (rootText +
                  secondText +
                  thirdText.substring(0, thirdText.length - 2))
              .length),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    log.d(expected.value.toStringDeep());
    log.d(result.value.toStringDeep());

    expect(expected, result);
  }

  static deleteAllChild() {
    List<TextSpan> children = [
      new TextSpan(
        text: secondText,
        style: newStyle,
      ),
      new TextSpan(
        text: thirdText,
        style: oldStyle,
      ),
      new TextSpan(
        text: forthText,
        style: newStyle,
      ),
      new TextSpan(
        text: fifthText,
        style: oldStyle.copyWith(fontSize: 34.0),
      ),
    ];

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: children,
      ),
      selection:
          new TextSelection.collapsed(offset: text.length - fifthText.length),
    );

    var newText = rootText + secondText + thirdText + fifthText;
    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
        text: newText,
      ),
      selection: new TextSelection.collapsed(
          offset: (rootText + secondText + thirdText).length),
    );

    //
    var expectedList = children.toList();
    expectedList.removeAt(2);

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: expectedList,
      ),
      selection: new TextSelection.collapsed(
          offset: (rootText + secondText + thirdText).length),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    log.d(expected.value.toStringDeep());
    log.d(result.value.toStringDeep());

    expect(expected, result);
  }


  static deleteMultipleChildren() {
    List<TextSpan> children = [
      new TextSpan(
        text: secondText,
        style: newStyle,
      ),
      new TextSpan(
        text: thirdText,
        style: oldStyle,
      ),
      new TextSpan(
        text: forthText,
        style: newStyle,
      ),
      new TextSpan(
        text: fifthText,
        style: oldStyle.copyWith(fontSize: 34.0),
      ),
    ];

    RichTextEditingValue oldValue = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: children,
      ),
      selection:
      new TextSelection.collapsed(offset: text.length - fifthText.length),
    );

    var newText = rootText + secondText + thirdText + fifthText;
    RichTextEditingValue newValue = new RichTextEditingValue(
      value: new TextSpan(
        text: newText,
      ),
      selection: new TextSelection.collapsed(
          offset: (rootText + secondText + thirdText).length),
    );

    //
    var expectedList = children.toList();
    expectedList.removeAt(2);

    RichTextEditingValue expected = new RichTextEditingValue(
      value: new TextSpan(
        text: rootText,
        children: expectedList,
      ),
      selection: new TextSelection.collapsed(
          offset: (rootText + secondText + thirdText).length),
    );

    RichTextEditingValue result = RichTextEditingValueParser.parse(
        oldValue: oldValue, newValue: newValue, style: oldStyle);

    log.d(expected.value.toStringDeep());
    log.d(result.value.toStringDeep());

    expect(expected, result);
  }
}
