import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class TodoItem {
  int id;
  String task;
  DateTime date;

  TodoItem({required this.id, required this.task, required this.date});

  TodoItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        task = json['task'],
        date = DateTime.parse(json['date']);
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final String apiUrl = 'https://10.0.2.2:7080/api/User/ToDo';

  DateTime? selectedDate;
  TextEditingController taskController = TextEditingController();
  List<TodoItem> todoList = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> fetchData() async {
    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<TodoItem> fetchedList =
            data.map((item) => TodoItem.fromJson(item)).toList();

        setState(() {
          todoList = fetchedList;
        });
      } else {
        print('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      var response = await http.delete(
        Uri.parse('$apiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        print('Deleted Successfully');
        fetchData();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateTodo(int id, String updatedTask) async {
    try {
      var response = await http.put(
        Uri.parse('$apiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task': updatedTask}),
      );

      if (response.statusCode == 200) {
        setState(() {
          int index = todoList.indexWhere((element) => element.id == id);
          if (index != -1) {
            todoList[index].task = updatedTask;
            taskController.clear();
          }
        });
        print('Updated Successfully');
      }
    } catch (e) {
      print(e);
    }
  }

  void addTodo() async {
    if (taskController.text.isNotEmpty && selectedDate != null) {
      try {
        var response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'task': taskController.text,
            'date': selectedDate!.toIso8601String(),
          }),
        );

        if (response.statusCode == 200) {
          print('Data sent successfully');
          fetchData();
        }
      } catch (e) {
        print('Error: $e');
      }

      setState(() {
        taskController.clear();
        selectedDate = null;
      });
    }
  }

  void editTodo(int index) async {
    TextEditingController taskController = TextEditingController(
      text: todoList[index].task,
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Todo'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(
              hintText: 'Edit Todo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                updateTodo(
                  todoList[index].id,
                  taskController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            title: Text(
              'Selected Date: ${selectedDate != null ? DateFormat('dd-MM-yyyy').format(selectedDate!) : "Select a Date"}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: taskController,
              decoration: InputDecoration(
                hintText: 'Enter Task',
                suffixIcon: IconButton(
                  onPressed: addTodo,
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: todoList.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(todoList[index].task),
                  subtitle: Text(
                    'Date: ${DateFormat('dd-MM-yyyy').format(todoList[index].date)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          editTodo(index);
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 30.0,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          deleteTodo(todoList[index].id);
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 30.0,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }
}
