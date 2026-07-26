import 'package:chess/chess.dart'; 
void main() { 
  var game = Chess(); 
  var m = game.moves({'verbose': true});
  print((m.first as Map).keys);
  print((m.first as Map)['from']);
  print((m.first as Map)['to']);
}
