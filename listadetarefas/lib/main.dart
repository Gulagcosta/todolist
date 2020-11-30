import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main(){
  runApp(MaterialApp(
    home: Home(),
  ));
}
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoCtrl = TextEditingController();

  List _toDolist = [];
  Map<String, dynamic> _lastRemoved;
  int _lastremovedPos;


  @override
  void initState() {
    super.initState();
    
    _readData().then((data){
      setState(() {
        _toDolist = json.decode(data);
      });
    });
  }

  void _addTodo(){
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _toDoCtrl.text;
      _toDoCtrl.text = "";
      newTodo["ok"] = false;
      _toDolist.add(newTodo);
      _saveData();
    });
  }

  Future<Null> _atualizar() async{
    await Future.delayed(Duration(seconds:1));
    setState(() {
      _toDolist.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                      controller: _toDoCtrl,
                      decoration: InputDecoration(
                          labelText: "Nova tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent)
                      ),
                    ),
                ),
                RaisedButton(
                    color: Colors.blueAccent,
                    child: Text("ADD"),
                    textColor: Colors.white,
                    onPressed: _addTodo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(onRefresh: _atualizar,
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10.0),
                      itemCount: _toDolist.length,
                      itemBuilder: buildItem),
              )
          )
        ],
      )
    );
  }

  Widget buildItem(context, index){
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.redAccent,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDolist[index]["title"]),
        value: _toDolist [index] ["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDolist [index]["ok"] ? Icons.check_circle : Icons.error),
        ),
        onChanged: (c){
          setState(() {
            _toDolist[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){
        setState(() {
          _lastRemoved = Map.from(_toDolist[index]);
          _lastremovedPos = index;
          _toDolist.removeAt(index);
          _saveData();
          final snack = SnackBar(
              content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
              action: SnackBarAction(
                label: "Desfazer",
                onPressed: (){
                  setState(() {
                    _toDolist.insert(_lastremovedPos, _lastRemoved);
                    _saveData();
                  });
                },
              ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File("${diretorio.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDolist);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
        return null;
    }
  }
}
