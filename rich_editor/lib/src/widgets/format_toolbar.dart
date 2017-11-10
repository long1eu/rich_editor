import 'package:flutter/material.dart';
import 'package:flutter_logger/flutter_logger.dart';
import 'package:rich_editor/src/widgets/rich_editable_text.dart';

const double _defaultFontSize = 16.0;

class FormatToolbar extends StatefulWidget {
  FormatToolbar(this.styleController);

  final StyleController styleController;

  @override
  State<StatefulWidget> createState() => new _FormatToolbarState();
}

class _FormatToolbarState extends State<FormatToolbar> {
  final Log log = new Log("_FormatToolbarState");
  final GlobalKey<_FontSizeWidgetState> _fontSizeState =
      new GlobalKey<_FontSizeWidgetState>();

  StyleController _styleController;
  TextStyle _lastKnownStyle;

  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  bool _lineThrough = false;
  bool _overline = false;
  double _size = _defaultFontSize;

  @override
  void initState() {
    super.initState();
    _styleController = widget.styleController;
    _styleController.addListener(_onStyleChanged);

    _lastKnownStyle = _styleController.value;
    _size = widget.styleController.value.fontSize;
  }

  @override
  void didUpdateWidget(FormatToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.styleController != oldWidget.styleController) {
      oldWidget.styleController.removeListener(_onStyleChanged);
      widget.styleController.addListener(_onStyleChanged);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _styleController.removeListener(_onStyleChanged);
  }

  void _setFontSize(double size) {
    _styleController.value = _styleController.value.copyWith(fontSize: size);
    setState(() => _size = size);
  }

  void _setBold() {
    var fontWeight = _lastKnownStyle.fontWeight == FontWeight.bold
        ? FontWeight.normal
        : FontWeight.bold;

    _styleController.value =
        _styleController.value.copyWith(fontWeight: fontWeight);

    setState(() {
      _bold = fontWeight == FontWeight.bold;
    });
  }

  void _setItalic() {
    var fontStyle = _lastKnownStyle.fontStyle == FontStyle.italic
        ? FontStyle.normal
        : FontStyle.italic;

    _styleController.value =
        _styleController.value.copyWith(fontStyle: fontStyle);

    setState(() {
      _italic = fontStyle == FontStyle.italic;
    });
  }

  void _setUnderlined() {
    var underlineDecoration;
    var lineThroughDecoration;
    var overlineDecoration;

    if (_lastKnownStyle.decoration != null) {
      underlineDecoration =
          _lastKnownStyle.decoration.contains(TextDecoration.underline)
              ? TextDecoration.none
              : TextDecoration.underline;

      lineThroughDecoration =
          _lastKnownStyle.decoration.contains(TextDecoration.lineThrough)
              ? TextDecoration.lineThrough
              : TextDecoration.none;

      overlineDecoration =
          _lastKnownStyle.decoration.contains(TextDecoration.overline)
              ? TextDecoration.overline
              : TextDecoration.none;
    } else {
      underlineDecoration = TextDecoration.underline;
      lineThroughDecoration = TextDecoration.none;
      overlineDecoration = TextDecoration.none;
    }

    var textDecoration = new TextDecoration.combine(
      [underlineDecoration, lineThroughDecoration, overlineDecoration],
    );

    _styleController.value =
        _styleController.value.copyWith(decoration: textDecoration);

    setState(() {
      _underline = textDecoration.contains(TextDecoration.underline);
    });
  }

  void _setLineThrough() {
    var underlineDecoration;
    var lineThroughDecoration;
    var overlineDecoration;

    if (_lastKnownStyle.decoration != null) {
      underlineDecoration =
          _lastKnownStyle.decoration.contains(TextDecoration.underline)
              ? TextDecoration.underline
              : TextDecoration.none;

      lineThroughDecoration =
          _lastKnownStyle.decoration.contains(TextDecoration.lineThrough)
              ? TextDecoration.none
              : TextDecoration.lineThrough;

      overlineDecoration =
          _lastKnownStyle.decoration.contains(TextDecoration.overline)
              ? TextDecoration.overline
              : TextDecoration.none;
    } else {
      underlineDecoration = TextDecoration.none;
      lineThroughDecoration = TextDecoration.lineThrough;
      overlineDecoration = TextDecoration.none;
    }

    var textDecoration = new TextDecoration.combine(
      [underlineDecoration, lineThroughDecoration, overlineDecoration],
    );

    _styleController.value =
        _styleController.value.copyWith(decoration: textDecoration);

    setState(() {
      _lineThrough = textDecoration.contains(TextDecoration.lineThrough);
    });
  }

  void _setOverline() {
    var underlineDecoration;
    var lineThroughDecoration;
    var overlineDecoration;

    if (_lastKnownStyle.decoration != null) {
      underlineDecoration =
          _lastKnownStyle.decoration.contains(TextDecoration.underline)
              ? TextDecoration.underline
              : TextDecoration.none;

      lineThroughDecoration =
          _lastKnownStyle.decoration.contains(TextDecoration.lineThrough)
              ? TextDecoration.lineThrough
              : TextDecoration.none;

      overlineDecoration =
          _lastKnownStyle.decoration.contains(TextDecoration.overline)
              ? TextDecoration.none
              : TextDecoration.overline;
    } else {
      underlineDecoration = TextDecoration.none;
      lineThroughDecoration = TextDecoration.none;
      overlineDecoration = TextDecoration.overline;
    }

    var textDecoration = new TextDecoration.combine(
      [underlineDecoration, lineThroughDecoration, overlineDecoration],
    );

    _styleController.value =
        _styleController.value.copyWith(decoration: textDecoration);

    setState(() {
      _overline = textDecoration.contains(TextDecoration.overline);
    });
  }

  void _onStyleChanged() {
    log.d("_FormatToolbarState: $_lastKnownStyle");
    log.d("_FormatToolbarState: ${_styleController.value}");
    _lastKnownStyle = _styleController.value;

    setState(() {
      _bold = _isBold();
      _italic = _isItalic();
      _underline = _isUnderlined();
      _lineThrough = _isLineThrough();
      _overline = _isOverlined();
      _size = _lastKnownStyle.fontSize;
      _fontSizeState.currentState.setSize(_lastKnownStyle.fontSize);
    });
  }

  bool _isBold() {
    if (_lastKnownStyle.fontWeight == FontWeight.bold)
      return true;
    else
      return false;
  }

  bool _isItalic() {
    if (_lastKnownStyle.fontStyle == FontStyle.italic)
      return true;
    else
      return false;
  }

  bool _isUnderlined() {
    if (_lastKnownStyle.decoration == null) return false;
    if (_lastKnownStyle.decoration.contains(TextDecoration.underline))
      return true;
    else
      return false;
  }

  bool _isLineThrough() {
    if (_lastKnownStyle.decoration == null) return false;
    if (_lastKnownStyle.decoration.contains(TextDecoration.lineThrough))
      return true;
    else
      return false;
  }

  bool _isOverlined() {
    if (_lastKnownStyle.decoration == null) return false;
    if (_lastKnownStyle.decoration.contains(TextDecoration.overline))
      return true;
    else
      return false;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> childrenList = <Widget>[
      new FontSizeWidget(
        key: _fontSizeState,
        size: _size,
        onChange: _setFontSize,
      ),
      new Container(
        height: 24.0,
        width: 1.5,
        color: Theme.of(context).dividerColor,
      ),
      new IconButton(
        onPressed: _setBold,
        icon: new Icon(
          Icons.format_bold,
        ),
        color: _bold ? Theme.of(context).primaryColor : null,
      ),
      new IconButton(
        onPressed: _setItalic,
        icon: new Icon(
          Icons.format_italic,
        ),
        color: _italic ? Theme.of(context).primaryColor : null,
      ),
      new IconButton(
        onPressed: _setUnderlined,
        icon: new Icon(
          Icons.format_underlined,
        ),
        color: _underline ? Theme.of(context).primaryColor : null,
      ),
      new IconButton(
        onPressed: _setLineThrough,
        icon: new Icon(
          Icons.format_strikethrough,
        ),
        color: _lineThrough ? Theme.of(context).primaryColor : null,
      ),
      new IconButton(
        onPressed: _setOverline,
        icon: new ImageIcon(new AssetImage("res/images/format_overline.png")),
        color: _overline ? Theme.of(context).primaryColor : null,
      ),
    ];

    return new Container(
      alignment: Alignment.bottomCenter,
      height: 48.0,
      color: new Color(0xFFE8E8E8),
      child: new ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => childrenList[index],
        itemCount: childrenList.length,
      ),
    );
  }
}

class FontSizeWidget extends StatefulWidget {
  const FontSizeWidget({Key key, this.size, this.onChange}) : super(key: key);

  final double size;

  final ValueChanged<double> onChange;

  @override
  _FontSizeWidgetState createState() => new _FontSizeWidgetState();
}

class _FontSizeWidgetState extends State<FontSizeWidget> {
  double _size;

  @override
  void initState() {
    super.initState();
    _size = widget.size ?? _defaultFontSize;
  }

  void setSize(double size) {
    setState(() => _size = size ?? _defaultFontSize);
  }

  @override
  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new IconButton(
          onPressed: () {
            setState(() {
              if (_size != 8.0) {
                _size--;
                widget.onChange(_size);
              }
            });
          },
          icon: new Icon(
            Icons.keyboard_arrow_down,
          ),
        ),
        new Text(_size.toInt().toString()),
        new IconButton(
          onPressed: () {
            setState(() {
              if (_size != 96.0) {
                _size++;
                widget.onChange(_size);
              }
            });
          },
          icon: new Icon(
            Icons.keyboard_arrow_up,
          ),
        ),
      ],
    );
  }
}
