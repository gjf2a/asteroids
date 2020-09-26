import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class Game {
  double _width = 100, _height = 100;
  List<FlyingCircle> _asteroids, _missiles;
  Ship _ship;
  bool _live;

  Game() {
    _live = true;
    _asteroids = List();
    _missiles = List();
    _setupShipAndAsteroids();
  }

  void setBoundaries(double width, double height) {
    if (width != _width || height != _height) {
      _width = width;
      _height = height;
      _setupShipAndAsteroids();
    }
  }

  void _setupShipAndAsteroids() {
    _ship = Ship(Point(_width/2, _height/2), Polar(0, 0), _height/20, _width/20);

    for (int i = 0; i < 12; i++) {
      _asteroids.add(FlyingCircle(Point(0, 0), Polar(1, i * pi/12), (_height+_width)/20));
    }
  }

  void paint(Canvas canvas) {
    _asteroids.forEach((element) {element.paint(canvas);});
    _missiles.forEach((element) {element.paint(canvas);});
    _ship.paint(canvas);
  }

  void fire() {
    _missiles.add(_ship.fire());
  }

  void rotateShip(Point touched) {
    _ship.setHeading(_ship._location.directionTo(touched));
  }

  void tick() {
    for (FlyingCircle asteroid in _asteroids) {
      asteroid.wrapMove(_width, _height);
    }

    for (FlyingCircle missile in _missiles) {
      missile.move();
    }

    List<FlyingCircle> survivors = List();
    for (FlyingCircle asteroid in _asteroids) {
      if (!asteroid.collidesWithAny(_missiles) && !_ship.collidesWith(asteroid)) {
        survivors.add(asteroid);
      }
    }
    _asteroids = survivors;

    _live = !_ship.collidesWithAny(_asteroids);
  }

  Ship get ship => _ship;
}

class Point {
  double _x, _y;

  Point(this._x, this._y);

  double distance(Point other) {
    return sqrt(pow(_x - other._x, 2) + pow(_y - other._y, 2));
  }

  Point operator+(Point other) {
    return Point(_x + other._x, _y + other._y);
  }

  Point operator-(Point other) {
    return Point(_x - other._x, _y - other._y);
  }

  double directionTo(Point other) {
    Point difference = other - this;
    return atan2(difference._y, difference._x);
  }

  bool operator==(Object other) {
    return other is Point && _x == other._x && _y == other._y;
  }

  Point wrapped(double width, double height) {
    return Point(_wrap(_x, width), _wrap(_y, height));
  }

  String toString() => "Point($_x,$_y)";

  @override
  int get hashCode => toString().hashCode;
}

double _wrap(double v, double bound) {
  if (v < 0) {
    return v + bound;
  } else if (v > bound) {
    return v - bound;
  } else {
    return v;
  }
}

class Polar {
  double _r, _theta;

  Polar(this._r, this._theta) {
    while (_theta < 0) {_theta += 2*pi;}
    while (_theta >= 2 * pi) {_theta -= 2*pi;}
  }

  bool operator==(Object other) {
    return other is Polar && _r == other._r && _theta == other._theta;
  }

  Polar operator+(Polar other) {
    return Polar(_r + other._r, _theta + other._theta);
  }

  Point toPoint() {
    return Point(_r * cos(_theta), _r * sin(_theta));
  }

  String toString() => "Polar($_r,$_theta)";

  @override
  int get hashCode => toString().hashCode;
}

abstract class FlyingObject {
  Point _location;
  Polar _velocity;

  FlyingObject(this._location, this._velocity);

  double distance(FlyingObject other) {
    return this._location.distance(other._location);
  }

  bool collidesWith(FlyingCircle other);

  void paint(Canvas canvas);

  bool collidesWithAny(List<FlyingCircle> others) {
    return others.any((FlyingCircle element) => this.collidesWith(element));
  }

  Point get location => _location;
  Polar get velocity => _velocity;
}

class FlyingCircle extends FlyingObject {
  double _radius;

  FlyingCircle(Point location, Polar velocity, this._radius) : super(location, velocity);

  bool collidesWith(FlyingCircle other) {
    return distance(other) <= _radius + other._radius;
  }

  bool contains(Point p) {
    return _location.distance(p) <= _radius;
  }

  void move() {
    _location += _velocity.toPoint();
  }

  void wrapMove(double width, double height) {
    move();
    _location = _location.wrapped(width, height);
  }

  @override
  void paint(Canvas canvas) {
    Paint p = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.blue;
    canvas.drawCircle(Offset(_location._x, _location._y), _radius, p);
  }
}

class Ship extends FlyingObject {
  double _height, _width;

  Ship(Point location, Polar velocity, this._height, this._width) : super(location, velocity);

  void setHeading(double heading) {
    _velocity = Polar(0, heading);
  }

  Point tip() {
    return _location + Polar(_height, _velocity._theta).toPoint();
  }

  Point left() {
    return _location + Polar(_width/2, _velocity._theta - pi/2).toPoint();
  }

  Point right() {
    return _location + Polar(_width/2, _velocity._theta + pi/2).toPoint();
  }

  bool collidesWith(FlyingCircle other) {
    return other.contains(tip()) || other.contains(left()) || other.contains(right());
  }

  FlyingCircle fire() {
    return FlyingCircle(_location, Polar(10, _velocity._theta), 2);
  }

  @override
  void paint(Canvas canvas) {
    Paint p = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.deepPurple;
    Path path = Path()
      ..moveTo(tip()._x, tip()._y)
      ..lineTo(left()._x, left()._y)
      ..lineTo(right()._x, right()._y)
      ..lineTo(tip()._x, tip()._y)
      ..close();
    canvas.drawPath(path, p);
  }
}