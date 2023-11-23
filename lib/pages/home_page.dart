import 'package:cp_habit_tracker/components/habit_tile.dart';
import 'package:cp_habit_tracker/components/month_summary.dart';
import 'package:cp_habit_tracker/components/my_alert_box.dart';
import 'package:cp_habit_tracker/components/my_fab.dart';
import 'package:cp_habit_tracker/data/habit_database.dart';
import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HabitDatabase db = HabitDatabase();
  final _myBox = Hive.box("Habit_Database");

  @override
  void initState() {
    // if there is no current habit list, then it is the 1st time ever opening the app
    // then create default data
    if (_myBox.get("CURRENT_HABIT_LIST") == null) {
      db.createDefaultData();
    }

    // there already exists data, this is not the first time
    else {
      db.loadData();
    }

    // update the database
    db.updateDatabase();

    super.initState();
  }

  // checkbox was tapped
  void checkBoxTapped(bool? value, int index) {
    setState(() {
      db.todaysHabitList[index][1] = value;
    });
    db.updateDatabase();
  }

  // create a new habit
  final _newHabitNameController = TextEditingController();
  void createNewHabit() {
    // show alert dialog for user to enter the new habit details
    showDialog(
      context: context,
      builder: (context) {
        return MyAlertBox(
          controller: _newHabitNameController,
          hintText: 'Enter habit name..',
          onSave: saveNewHabit,
          onCancel: cancelDialogBox,
        );
      },
    );
  }

  // save new habit
  void saveNewHabit() {
    // add new habit to todays habit list
    setState(() {
      db.todaysHabitList.add([_newHabitNameController.text, false]);
    });

    // clear textfield
    _newHabitNameController.clear();
    // pop dialog box
    Navigator.of(context).pop();
    db.updateDatabase();
  }

  // cancel new habit
  void cancelDialogBox() {
    // clear textfield
    _newHabitNameController.clear();

    // pop dialog box
    Navigator.of(context).pop();
  }

  // open habit settings to edit
  void openHabitSettings(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return MyAlertBox(
          controller: _newHabitNameController,
          hintText: db.todaysHabitList[index][0],
          onSave: () => saveExistingHabit(index),
          onCancel: cancelDialogBox,
        );
      },
    );
  }

  // save existing habit with a new name
  void saveExistingHabit(int index) {
    setState(() {
      db.todaysHabitList[index][0] = _newHabitNameController.text;
    });
    _newHabitNameController.clear();
    Navigator.pop(context);
    db.updateDatabase();
  }

  // delete habit
  void deleteHabit(int index) {
    setState(() {
      db.todaysHabitList.removeAt(index);
    });
    db.updateDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: IconButton(
              onPressed: createNewHabit,
              tooltip: "Add New Habit",
              icon: const Icon(
                Icons.add_task,
                size: 29,
              ),
            ),
          )
        ],
        leading: const Icon(
          Icons.published_with_changes,
          size: 31,
        ),
        centerTitle: true,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 23,
            ),
            children: <TextSpan>[
              TextSpan(
                text: 'CP ',
                style: TextStyle(
                  letterSpacing: 2,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Habit Tracker',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[300],
      floatingActionButton: MyFloatingActionButton(onPressed: createNewHabit),
      body: ListView(
        children: [
          // Check if todaysHabitList is empty
          if (db.todaysHabitList.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.85),
                child: const Text(
                  'Your Habit list is Empty!',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          if (db.todaysHabitList.isNotEmpty)

            // monthly summary heat map
            MonthlySummary(
              datasets: db.heatMapDataSet,
              startDate: _myBox.get("START_DATE"),
            ),

          // list of habits
          ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: db.todaysHabitList.length,
            itemBuilder: (context, index) {
              final reversedIndex = db.todaysHabitList.length - index - 1;

              return HabitTile(
                habitName: db.todaysHabitList[reversedIndex][0],
                habitCompleted: db.todaysHabitList[reversedIndex][1],
                onChanged: (value) => checkBoxTapped(value, reversedIndex),
                settingsTapped: (context) => openHabitSettings(reversedIndex),
                deleteTapped: (context) => deleteHabit(reversedIndex),
              );
            },
          )
        ],
      ),
    );
  }
}
