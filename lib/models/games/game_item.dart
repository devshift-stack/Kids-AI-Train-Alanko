import 'package:flutter/material.dart';

class GameItem {
  final String id;
  final String value;
  final String displayText;
  final String audioText;
  final Color color;
  final IconData? icon;

  const GameItem({
    required this.id,
    required this.value,
    required this.displayText,
    required this.audioText,
    required this.color,
    this.icon,
  });
}

class GameResult {
  final int totalQuestions;
  final int correctAnswers;
  final Duration timeTaken;
  final DateTime completedAt;

  const GameResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeTaken,
    required this.completedAt,
  });

  double get accuracy => totalQuestions > 0
      ? (correctAnswers / totalQuestions) * 100
      : 0;

  bool get isPerfect => correctAnswers == totalQuestions;
}

// Letters data for ABC game
class LettersData {
  static const List<GameItem> bosnianAlphabet = [
    GameItem(id: 'a', value: 'A', displayText: 'A', audioText: 'A', color: Colors.red),
    GameItem(id: 'b', value: 'B', displayText: 'B', audioText: 'B', color: Colors.blue),
    GameItem(id: 'c', value: 'C', displayText: 'C', audioText: 'C', color: Colors.green),
    GameItem(id: 'č', value: 'Č', displayText: 'Č', audioText: 'Č', color: Colors.orange),
    GameItem(id: 'ć', value: 'Ć', displayText: 'Ć', audioText: 'Ć', color: Colors.purple),
    GameItem(id: 'd', value: 'D', displayText: 'D', audioText: 'D', color: Colors.teal),
    GameItem(id: 'dž', value: 'DŽ', displayText: 'DŽ', audioText: 'DŽ', color: Colors.pink),
    GameItem(id: 'đ', value: 'Đ', displayText: 'Đ', audioText: 'Đ', color: Colors.indigo),
    GameItem(id: 'e', value: 'E', displayText: 'E', audioText: 'E', color: Colors.amber),
    GameItem(id: 'f', value: 'F', displayText: 'F', audioText: 'F', color: Colors.cyan),
    GameItem(id: 'g', value: 'G', displayText: 'G', audioText: 'G', color: Colors.lime),
    GameItem(id: 'h', value: 'H', displayText: 'H', audioText: 'H', color: Colors.deepOrange),
    GameItem(id: 'i', value: 'I', displayText: 'I', audioText: 'I', color: Colors.lightBlue),
    GameItem(id: 'j', value: 'J', displayText: 'J', audioText: 'J', color: Colors.deepPurple),
    GameItem(id: 'k', value: 'K', displayText: 'K', audioText: 'K', color: Colors.brown),
    GameItem(id: 'l', value: 'L', displayText: 'L', audioText: 'L', color: Colors.red),
    GameItem(id: 'lj', value: 'LJ', displayText: 'LJ', audioText: 'LJ', color: Colors.blue),
    GameItem(id: 'm', value: 'M', displayText: 'M', audioText: 'M', color: Colors.green),
    GameItem(id: 'n', value: 'N', displayText: 'N', audioText: 'N', color: Colors.orange),
    GameItem(id: 'nj', value: 'NJ', displayText: 'NJ', audioText: 'NJ', color: Colors.purple),
    GameItem(id: 'o', value: 'O', displayText: 'O', audioText: 'O', color: Colors.teal),
    GameItem(id: 'p', value: 'P', displayText: 'P', audioText: 'P', color: Colors.pink),
    GameItem(id: 'r', value: 'R', displayText: 'R', audioText: 'R', color: Colors.indigo),
    GameItem(id: 's', value: 'S', displayText: 'S', audioText: 'S', color: Colors.amber),
    GameItem(id: 'š', value: 'Š', displayText: 'Š', audioText: 'Š', color: Colors.cyan),
    GameItem(id: 't', value: 'T', displayText: 'T', audioText: 'T', color: Colors.lime),
    GameItem(id: 'u', value: 'U', displayText: 'U', audioText: 'U', color: Colors.deepOrange),
    GameItem(id: 'v', value: 'V', displayText: 'V', audioText: 'V', color: Colors.lightBlue),
    GameItem(id: 'z', value: 'Z', displayText: 'Z', audioText: 'Z', color: Colors.deepPurple),
    GameItem(id: 'ž', value: 'Ž', displayText: 'Ž', audioText: 'Ž', color: Colors.brown),
  ];
}

// Numbers data for 123 game
class NumbersData {
  static List<GameItem> getNumbers(int max) {
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
      Colors.amber, Colors.cyan,
    ];

    return List.generate(max + 1, (i) => GameItem(
      id: i.toString(),
      value: i.toString(),
      displayText: i.toString(),
      audioText: i.toString(),
      color: colors[i % colors.length],
    ));
  }
}

// Colors data
class ColorsData {
  static const Map<String, List<GameItem>> colorsByLanguage = {
    'bs': [
      GameItem(id: 'red', value: 'red', displayText: 'Crvena', audioText: 'Crvena', color: Colors.red),
      GameItem(id: 'blue', value: 'blue', displayText: 'Plava', audioText: 'Plava', color: Colors.blue),
      GameItem(id: 'green', value: 'green', displayText: 'Zelena', audioText: 'Zelena', color: Colors.green),
      GameItem(id: 'yellow', value: 'yellow', displayText: 'Žuta', audioText: 'Žuta', color: Colors.yellow),
      GameItem(id: 'orange', value: 'orange', displayText: 'Narandžasta', audioText: 'Narandžasta', color: Colors.orange),
      GameItem(id: 'purple', value: 'purple', displayText: 'Ljubičasta', audioText: 'Ljubičasta', color: Colors.purple),
      GameItem(id: 'pink', value: 'pink', displayText: 'Roza', audioText: 'Roza', color: Colors.pink),
      GameItem(id: 'brown', value: 'brown', displayText: 'Smeđa', audioText: 'Smeđa', color: Colors.brown),
      GameItem(id: 'black', value: 'black', displayText: 'Crna', audioText: 'Crna', color: Colors.black),
      GameItem(id: 'white', value: 'white', displayText: 'Bijela', audioText: 'Bijela', color: Colors.white),
    ],
    'en': [
      GameItem(id: 'red', value: 'red', displayText: 'Red', audioText: 'Red', color: Colors.red),
      GameItem(id: 'blue', value: 'blue', displayText: 'Blue', audioText: 'Blue', color: Colors.blue),
      GameItem(id: 'green', value: 'green', displayText: 'Green', audioText: 'Green', color: Colors.green),
      GameItem(id: 'yellow', value: 'yellow', displayText: 'Yellow', audioText: 'Yellow', color: Colors.yellow),
      GameItem(id: 'orange', value: 'orange', displayText: 'Orange', audioText: 'Orange', color: Colors.orange),
      GameItem(id: 'purple', value: 'purple', displayText: 'Purple', audioText: 'Purple', color: Colors.purple),
      GameItem(id: 'pink', value: 'pink', displayText: 'Pink', audioText: 'Pink', color: Colors.pink),
      GameItem(id: 'brown', value: 'brown', displayText: 'Brown', audioText: 'Brown', color: Colors.brown),
      GameItem(id: 'black', value: 'black', displayText: 'Black', audioText: 'Black', color: Colors.black),
      GameItem(id: 'white', value: 'white', displayText: 'White', audioText: 'White', color: Colors.white),
    ],
    'de': [
      GameItem(id: 'red', value: 'red', displayText: 'Rot', audioText: 'Rot', color: Colors.red),
      GameItem(id: 'blue', value: 'blue', displayText: 'Blau', audioText: 'Blau', color: Colors.blue),
      GameItem(id: 'green', value: 'green', displayText: 'Grün', audioText: 'Grün', color: Colors.green),
      GameItem(id: 'yellow', value: 'yellow', displayText: 'Gelb', audioText: 'Gelb', color: Colors.yellow),
      GameItem(id: 'orange', value: 'orange', displayText: 'Orange', audioText: 'Orange', color: Colors.orange),
      GameItem(id: 'purple', value: 'purple', displayText: 'Lila', audioText: 'Lila', color: Colors.purple),
      GameItem(id: 'pink', value: 'pink', displayText: 'Rosa', audioText: 'Rosa', color: Colors.pink),
      GameItem(id: 'brown', value: 'brown', displayText: 'Braun', audioText: 'Braun', color: Colors.brown),
      GameItem(id: 'black', value: 'black', displayText: 'Schwarz', audioText: 'Schwarz', color: Colors.black),
      GameItem(id: 'white', value: 'white', displayText: 'Weiß', audioText: 'Weiß', color: Colors.white),
    ],
  };

  static List<GameItem> getColors(String languageCode) {
    return colorsByLanguage[languageCode] ?? colorsByLanguage['bs']!;
  }
}
