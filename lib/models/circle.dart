import 'geometry_object.dart';
import 'point.dart';

class Circle extends GeometryObject {
  final Point center;
  final double radius;

  Circle(this.center, this.radius);
}
