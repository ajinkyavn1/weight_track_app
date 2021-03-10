import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weight_track_app/logic/exercise_calc/exercise_format.dart';
import 'package:weight_track_app/logic/storage/database_filtered_data.dart';
import 'package:weight_track_app/logic/storage/database_unfiltered_data.dart';
import 'package:weight_track_app/models/exercise.dart';
import 'package:weight_track_app/models/exercise_instance.dart';

import 'exercise_selection_manager.dart';

class ExerciseListWidget extends StatefulWidget {
  final int _idOfDay;

  ExerciseListWidget(this._idOfDay);

  @override
  _ExerciseListWidgetState createState() => _ExerciseListWidgetState(_idOfDay);
}

class _ExerciseListWidgetState extends State<ExerciseListWidget> {

  final int _idOfDay;
  _ExerciseListWidgetState(this._idOfDay);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DatabaseDataUnfiltered.getExercisesOfDay(_idOfDay),
      builder: (BuildContext context, AsyncSnapshot<List<Exercise>> snapshot){
        if (snapshot.data == null)
          return Text('loading...');
        else {
          // TODO: somehow update the name of the exercise after the selected exercise has been loaded
          ExerciseSelectionManager.updateExercises(snapshot.data, _idOfDay);
          ExerciseSelectionManager.setLastSelectedUpdater(() => setState((){}), _idOfDay);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(
                          (snapshot.data.length / 2).floor(), (int index) {
                        if (snapshot.data[index] == null) {
                          return Text('loading');
                        }
                        return ExerciseListItem(snapshot.data[index], index, _idOfDay);
                      }),
                    ),
                  ),
                ),
                SizedBox(
                  width: 20.0,
                ),
                Expanded(
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate((snapshot.data.length / 2).ceil(),
                          (int index) {
                        if (snapshot.data[
                                index + (snapshot.data.length / 2).floor()] ==
                            null) {
                          return Text('Loading');
                        }
                        return ExerciseListItem(
                            snapshot.data[
                                index + (snapshot.data.length / 2).floor()],
                            index + (snapshot.data.length / 2).floor(),
                          _idOfDay
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class ExerciseListItem extends StatefulWidget {
  final Exercise _exercise;
  final int _indexOfItem;
  final int _idOfDay;

  ExerciseListItem(this._exercise, this._indexOfItem, this._idOfDay);

  @override
  _ExerciseListItemState createState() => _ExerciseListItemState(_exercise, _indexOfItem, _idOfDay);
}

class _ExerciseListItemState extends State<ExerciseListItem> {
  final Exercise _exercise;
  final int _indexOfItem;
  final int _idOfDay;

  _ExerciseListItemState(this._exercise, this._indexOfItem, this._idOfDay);

  @override
  Widget build(BuildContext context) {
    bool _selected = ExerciseSelectionManager.checkIfSelected(_indexOfItem, _idOfDay);
    TextStyle _subtitleStyle = TextStyle(
      fontFamily: GoogleFonts.roboto().fontFamily,
      fontWeight: _selected?FontWeight.w600:FontWeight.w300,
      fontSize: 18.0,
      color: _selected?Colors.white:Colors.black,
    );
    TextStyle _contentStyle = TextStyle(
      fontFamily: GoogleFonts.roboto().fontFamily,
      fontWeight: FontWeight.w200,
      fontSize: 18.0,
      color: _selected?Colors.white:Colors.black,
    );
    // TODO make AnimatedContainer work, to animate the expansion of a tile
    // TODO possible fix is to move the AnimatedContainer up to the List as a whole
    return AnimatedContainer(
      duration: Duration(seconds: 100),
      child: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 22.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomLeft,
                  colors: [
                    // has to change when not selected
                    _selected?Color.fromRGBO(0xA9, 0xD5, 0x87, 1):Color.fromRGBO(0xF0, 0xF0, 0xF0, 1),
                    _selected?Color.fromRGBO(0x51, 0xC2, 0xA4, 1):Color.fromRGBO(0xF0, 0xF0, 0xF0, 1),
                  ]
              )
            ),
            // TODO remove selection animation
            child: FlatButton(
              padding: const EdgeInsets.all(0),
              onPressed: (){
                ExerciseSelectionManager.updateSelectedIndexes(_indexOfItem, _idOfDay);
                ExerciseSelectionManager.updateListeners(_idOfDay);
                ExerciseSelectionManager.callLastSelectedUpdater(_idOfDay);
                ExerciseSelectionManager.setLastSelectedUpdater(() => setState((){print("Updating..");}), _idOfDay);
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 21),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _exercise.name,
                      style: TextStyle(
                        fontFamily: GoogleFonts.raleway().fontFamily,
                        fontSize: 24.0,
                        color: _selected?Colors.white:Colors.black
                      ),
                    ),
                    Divider(
                      thickness: 1.0,
                      color: _selected?Colors.white:Colors.black,
                    ),
                    SizedBox(
                      height: _selected?10.0:5.0,
                    ),
                    Text(
                      "Average",
                      style: _subtitleStyle,
                    ),
                    FutureBuilder(
                      future: DatabaseDataFiltered.getRecentAverage(_exercise),
                      builder: (BuildContext context, AsyncSnapshot<ExerciseInstance> snapshot){
                        if (snapshot.data == null)
                          return Text('0x0kg', style: _contentStyle);
                        else
                          return Text(ExerciseFormat.instanceToString(snapshot.data), style: _contentStyle);
                      },
                    ),
                    !_selected?Container():Text(
                      "Maximum",
                      style: _subtitleStyle,
                    ),
                    !_selected?Container():FutureBuilder(
                      future: DatabaseDataFiltered.getBestInstanceOfExercise(_exercise),
                      builder: (BuildContext context, AsyncSnapshot<ExerciseInstance> snapshot){
                        if (snapshot.data == null)
                          return Text('0x0kg', style: _contentStyle);
                        else
                          return Text(ExerciseFormat.instanceToString(snapshot.data), style: _contentStyle);
                      },
                    ),
                    SizedBox(
                      height: _selected?10.0:5.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}