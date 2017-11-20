import 'package:flutter/material.dart';
import 'package:rich_editor/src/extensions.dart';
import 'package:test/test.dart';

void main() {
  test('isEmpty  test', () => isEmptyTest());
  test('length  test', () => lengthTest());
  test('getOffsetInParent  test', () => getOffsetInParentTest());
  test('maxFontSize  test', () => maxFontSizeTest());
  test('copySpanWith  test', () => copySpanWithTest());
  test('copyStyleWith  test', () => copyStyleWithTest());
  test('deepMerge  test', () => deepMergeTest());
  test('getDifferenceStyle  test', () => getDifferenceStyleTest());
}

void isEmptyTest() {
  expect(
      Extensions.isEmpty(
        new TextSpan(text: null),
      ),
      true);
  expect(
      Extensions.isEmpty(
        new TextSpan(text: ""),
      ),
      true);
  expect(
      Extensions.isEmpty(
        new TextSpan(
          text: "ss",
        ),
      ),
      false);
  expect(
      Extensions.isEmpty(
        new TextSpan(
          text: "",
          children: [new TextSpan(text: "")],
        ),
      ),
      true);
  expect(
      Extensions.isEmpty(
        new TextSpan(
          text: "a",
          children: [new TextSpan(text: "")],
        ),
      ),
      false);
  expect(
      Extensions.isEmpty(
        new TextSpan(
          text: "",
          children: [new TextSpan(text: "a")],
        ),
      ),
      false);
}

void lengthTest() {
  expect(
      Extensions.length(
        new TextSpan(text: null),
      ),
      0);
  expect(
      Extensions.length(
        new TextSpan(text: ""),
      ),
      0);
  expect(
      Extensions.length(
        new TextSpan(
          text: "ss",
        ),
      ),
      2);
  expect(
      Extensions.length(
        new TextSpan(
          text: "",
          children: [new TextSpan(text: "")],
        ),
      ),
      0);
  expect(
      Extensions.length(
        new TextSpan(
          text: "ae",
          children: [new TextSpan(text: "")],
        ),
      ),
      2);
  expect(
      Extensions.length(
        new TextSpan(
          text: "",
          children: [
            new TextSpan(text: "a"),
            new TextSpan(text: "as"),
            new TextSpan(text: "aa")
          ],
        ),
      ),
      5);
}

void getOffsetInParentTest() {
  //
  expect(Extensions.getOffsetInParent(new TextSpan(text: ""), null), -1);

  //
  expect(
      Extensions.getOffsetInParent(
        new TextSpan(text: ""),
        new TextSpan(text: ""),
      ),
      -1);

  //
  TextSpan child = new TextSpan(text: "");
  TextSpan parent = new TextSpan(text: "", children: [child]);

  expect(Extensions.getOffsetInParent(parent, child), 0);

  //
  child = new TextSpan(text: "a");
  parent = new TextSpan(text: "ssasa", children: [child]);

  expect(Extensions.getOffsetInParent(parent, child), 5);

  //
  child = new TextSpan(text: "a");
  parent = new TextSpan(text: "ssasa", children: [
    new TextSpan(text: "ar t"),
    child,
  ]);

  expect(Extensions.getOffsetInParent(parent, child), 9);

  //
  child = new TextSpan(text: "a");
  parent = new TextSpan(text: "ssasa", children: [
    new TextSpan(text: "ar t"),
    child,
    new TextSpan(text: "ar t"),
  ]);

  expect(Extensions.getOffsetInParent(parent, child), 9);
}

maxFontSizeTest() {
  TextSpan root = new TextSpan(
    text: "",
    style: new TextStyle(fontSize: 15.0),
    children: [
      new TextSpan(text: "", style: new TextStyle(fontSize: 16.0)),
      new TextSpan(text: "", style: new TextStyle(fontSize: 18.0)),
      new TextSpan(text: "", style: new TextStyle(fontSize: 13.0)),
      new TextSpan(text: "", style: new TextStyle(fontSize: 23.0)),
    ],
  );

  expect(Extensions.maxFontSize(root), 23.0);
}

copySpanWithTest() {
  TextSpan root = new TextSpan(
    text: "",
    style: new TextStyle(fontSize: 15.0),
    children: [new TextSpan(text: " children ")],
  );

  var test = "test";

  TextSpan newSpan = Extensions.copySpanWith(base: root, text: test);

  expect(
    newSpan,
    new TextSpan(
      text: test,
      style: new TextStyle(fontSize: 15.0),
      children: [
        new TextSpan(text: " children "),
      ],
    ),
  );
}

copyStyleWithTest() {
  TextStyle root = new TextStyle(fontSize: 12.0, color: Colors.orange);

  TextStyle newStyle = Extensions.copyStyleWith(base: root, color: Colors.red);
  expect(newStyle.color, Colors.red);
}

deepMergeTest() {
  TextStyle root = new TextStyle(
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.overline,
  );

  TextStyle newStyle = Extensions.deepMerge(
      root,
      new TextStyle(
        decoration: TextDecoration.lineThrough,
      ));

  expect(
    newStyle.decoration,
    new TextDecoration.combine(
      [
        TextDecoration.overline,
        TextDecoration.lineThrough,
      ],
    ),
  );

  newStyle = Extensions.deepMerge(
      root,
      new TextStyle(
        decoration: TextDecoration.none,
      ));

  expect(
    newStyle.decoration,
    new TextDecoration.combine(
      [
        TextDecoration.none,
      ],
    ),
  );
}

getDifferenceStyleTest() {
  TextStyle original = new TextStyle(
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.overline,
  );
  TextStyle copy = Extensions.copyStyleWith(base: original, fontSize: 12.0);
  TextStyle differenceStyle = Extensions.getDifferenceStyle(original, copy);

  expect(differenceStyle, new TextStyle(fontSize: 12.0));
}
