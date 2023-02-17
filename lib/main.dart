import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class Promise {
  String title;
  DateTime date;
  bool fulfilled;

  Promise({required this.title, required this.date, this.fulfilled = false});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date.toIso8601String(),
      'fulfilled': fulfilled ? 1 : 0,
    };
  }

  factory Promise.fromMap(Map<String, dynamic> map) {
    return Promise(
      title: map['title'],
      date: DateTime.parse(map['date']),
      fulfilled: map['fulfilled'] == 1,
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Promises',
      home: MyHomePage(title: 'Promises'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<Promise> _promises = [];

  @override
  void initState() {
    super.initState();
    _loadPromises();
  }

  void _loadPromises() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> promiseStrings = prefs.getStringList('promises') ?? [];
    setState(() {
      _promises = promiseStrings.map((promiseJson) {
        return Promise.fromMap(
            Map<String, dynamic>.from(json.decode(promiseJson)));
      }).toList();
    });
  }

  void _savePromises() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> promiseStrings = _promises.map((promise) {
      return json.encode(promise.toMap());
    }).toList();
    await prefs.setStringList('promises', promiseStrings);
  }

  void _addPromise() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _promises.add(Promise(
          title: _titleController.text,
          date: _selectedDate,
        ));
        _savePromises();
      });
      _titleController.clear();
      _selectedDate = DateTime.now();
    }
  }

  void _deletePromise(int index) {
    setState(() {
      _promises.removeAt(index);
      _savePromises();
    });
  }

  void _togglePromiseFulfilled(int index) {
    setState(() {
      _promises[index].fulfilled = !_promises[index].fulfilled;
      _savePromises();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Promise',
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a promise';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Text('Date:'),
                      SizedBox(width: 16),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child:
                            Text(DateFormat('dd/MM/yy').format(_selectedDate)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _promises.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: _promises[index].fulfilled,
                      onChanged: (value) => _togglePromiseFulfilled(index),
                    ),
                    title: Text(_promises[index].title),
                    subtitle: Text(
                        DateFormat('dd/MM/yy').format(_promises[index].date)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deletePromise(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPromise,
        tooltip: 'Add Promise',
        child: Icon(Icons.add),
      ),
    );
  }
}
