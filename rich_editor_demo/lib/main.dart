import 'package:flutter/material.dart';
import 'package:rich_editor/rich_editor.dart';


void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'RichField Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StyleController _styleController;

  @override
  Widget build(BuildContext context) {
    TextStyle baseStyle = Theme.of(context).textTheme.subhead;
    _styleController = new StyleController(style: baseStyle);

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Container(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new Expanded(
              child: new Container(
                decoration: new BoxDecoration(
                    border:
                    new Border.all(color: Theme.of(context).primaryColor)),
                child: new RichTextField(
                  maxLines: null,
                  decoration: null,
                  styleController: _styleController,
                  style: baseStyle,
                ),
              ),
            ),
            new FormatToolbar(_styleController)
          ],
        ),
      ),
    );
  }
}
