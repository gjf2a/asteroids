import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'math2d.dart';

const double speedIncrement = 0.5;

class Game {
  double _width = 100, _height = 100;
  List<FlyingCircle> _missiles;
  List<Asteroid> _asteroids;
  Ship _ship;
  bool _live;
  double asteroidSpeed = 0;

  Game() {
    restart();
  }

  void restart() {
    _live = true;
    _asteroids = List();
    _missiles = List();
    _setupShip();
    _setupAsteroids();
  }

  void setBoundaries(double width, double height) {
    if (width != _width || height != _height) {
      _width = width;
      _height = height;
      _setupShip();
      _setupAsteroids();
    }
  }

  void _setupShip() {
    _ship = Ship(Point(_width/2, _height/2), Polar(0, 0), _height/20, _width/20);
  }

  void _setupAsteroids() {
    asteroidSpeed += speedIncrement;
    _asteroids = List();
    for (int i = 0; i < 12; i++) {
      _asteroids.add(Asteroid(Point(0, 0), Polar(asteroidSpeed, i * pi/6), (_height+_width)/20));
    }
  }

  Ship get ship => _ship;

  bool get live => _live;

  void paint(Canvas canvas) {
    _asteroids.forEach((element) {element.paint(canvas);});
    _missiles.forEach((element) {element.paint(canvas);});
    if (_live) {
      _ship.paint(canvas);
    }
  }

  void fire() {
    _missiles.add(_ship.fire());
  }

  void rotateShip(Point touched) {
    _ship.setHeading(_ship._location.directionTo(touched));
  }

  void tick() {
    if (_asteroids.length == 0) {
      _setupAsteroids();
    }

    _moveEverything();
    _resolveCollisions();
  }

  void _moveEverything() {
    for (FlyingCircle asteroid in _asteroids) {
      asteroid.wrapMove(_width, _height);
    }

    for (FlyingCircle missile in _missiles) {
      missile.move();
    }
  }

  void _resolveCollisions() {
    List<FlyingCircle> survivingAsteroids = _findSurvivingAsteroids();
    List<FlyingCircle> survivingMissiles = _findSurvivingMissiles();
    _asteroids = survivingAsteroids;
    _missiles = survivingMissiles;
  }

  List<Asteroid> _findSurvivingAsteroids() {
    List<Asteroid> survivingAsteroids = List();
    for (Asteroid asteroid in _asteroids) {
      if (_live && _ship.collidesWith(asteroid)) {
        _live = false;
        asteroidSpeed = speedIncrement;
      } else {
        if (asteroid.collidesWithAny(_missiles)) {
          asteroid.addSplitsTo(survivingAsteroids);
        } else {
          survivingAsteroids.add(asteroid);
        }
      }
    }
    return survivingAsteroids;
  }

  List<FlyingCircle> _findSurvivingMissiles() {
    List<FlyingCircle> survivingMissiles = List();
    for (FlyingCircle missile in _missiles) {
      if (!missile.collidesWithAny(_asteroids) && missile.location.within(_width, _height)) {
        survivingMissiles.add(missile);
      }
    }
    return survivingMissiles;
  }
}

abstract class FlyingObject {
  Point _location;
  Polar _velocity;

  FlyingObject(this._location, this._velocity);

  double distance(FlyingObject other) =>
      this._location.distance(other._location);

  bool collidesWith(FlyingCircle other);

  void paint(Canvas canvas);

  bool collidesWithAny(List<FlyingCircle> others) =>
      others.any((FlyingCircle element) => this.collidesWith(element));

  Point get location => _location;
  Polar get velocity => _velocity;
}

class FlyingCircle extends FlyingObject {
  double _radius;

  FlyingCircle(Point location, Polar velocity, this._radius) : super(location, velocity);

  bool collidesWith(FlyingCircle other) =>
      distance(other) <= _radius + other._radius;

  bool contains(Point p) => _location.distance(p) <= _radius;

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
    canvas.drawCircle(Offset(_location.x, _location.y), _radius, p);
  }
}

class Ship extends FlyingObject {
  double _height, _width;

  Ship(Point location, Polar velocity, this._height, this._width) : super(location, velocity);

  void setHeading(double heading) {
    _velocity = Polar(0, heading);
  }

  Point get tip => offset(_height, 0);
  Point get left => offset(_width/2, -pi/2);
  Point get right => offset(_width/2, pi/2);

  Point offset(double distance, double headingOffset) =>
    _location + Polar(distance, _velocity.theta + headingOffset).toPoint();

  bool collidesWith(FlyingCircle other) =>
      other.contains(tip) || other.contains(left) || other.contains(right);

  FlyingCircle fire() => FlyingCircle(_location, Polar(10, _velocity.theta), 2);

  @override
  void paint(Canvas canvas) {
    Paint p = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.deepPurple;
    Path path = Path()
      ..moveTo(tip.x, tip.y)
      ..lineTo(left.x, left.y)
      ..lineTo(right.x, right.y)
      ..lineTo(tip.x, tip.y)
      ..close();
    canvas.drawPath(path, p);
  }
}

class Asteroid extends FlyingCircle {
  int _livesLeft = 2;

  Asteroid(Point location, Polar velocity, double radius) : super(location, velocity, radius);

  void addSplitsTo(List<Asteroid> asteroids) {
    if (_livesLeft > 0) {
      asteroids.add(_getSplit(pi / 2));
      asteroids.add(_getSplit(-pi / 2));
    }
  }

  Asteroid _getSplit(double headingOffset) {
    Asteroid split = Asteroid(_location, _velocity + Polar(_velocity.r, headingOffset), _radius / 2);
    split._livesLeft = _livesLeft - 1;
    return split;
  }

  int get livesLeft => _livesLeft;
}