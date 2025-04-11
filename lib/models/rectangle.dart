import 'geometry_object.dart';
import 'point.dart';

class Rectangle extends GeometryObject {
  final Point topLeft;
  final Point bottomRight;

  Rectangle(this.topLeft, this.bottomRight);
}
