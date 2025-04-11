import 'geometry_object.dart';
import 'point.dart';

class Line extends GeometryObject {
  final Point start;
  final Point end;

  Line(this.start, this.end);
}
