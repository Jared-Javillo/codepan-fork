import 'package:codepan/database/entities/field.dart';
import 'package:codepan/database/entities/sqlite_entity.dart';
import 'package:codepan/database/sqlite_statement.dart';

enum Operator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterThanOrEquals,
  lessThanOrEquals,
  between,
  isNull,
  notNull,
  isEmpty,
  notEmpty,
  like,
}
enum Scan {
  start,
  end,
  between,
}

class Condition extends SQLiteEntity {
  dynamic _value, _start, _end;
  List<Condition> orList;
  Operator _operator;
  Scan _scan;

  String get start => _getValue(_start);

  String get end => _getValue(_end);

  Operator get operator => _operator;

  bool get hasOrList => orList?.isNotEmpty ?? false;

  String get value {
    if (_value != null) {
      if (_value is bool) {
        return _value
            ? SQLiteStatement.TRUE.toString()
            : SQLiteStatement.FALSE.toString();
      } else if (_value is String) {
        final text = _value as String;
        if (_operator == Operator.like && _scan != null) {
          switch (_scan) {
            case Scan.start:
              return '\'%$text\'';
              break;
            case Scan.end:
              return '\'$text%\'';
              break;
            case Scan.between:
              return '\'%$text%\'';
              break;
          }
        }
        return '\'$text\'';
      } else if (_value is Field) {
        final field = _value as Field;
        return field.field;
      } else {
        return _value.toString();
      }
    }
    return SQLiteStatement.NULL;
  }

  List<Operator> get _noValueOperators {
    return [
      Operator.between,
      Operator.isNull,
      Operator.notNull,
      Operator.isEmpty,
      Operator.notEmpty,
    ];
  }

  bool get _isNoValueOperator {
    return _operator != null && _noValueOperators.contains(_operator);
  }

  bool get hasValue => _value != null;

  bool get isValid => hasValue || _isNoValueOperator;

  Condition(
    String _field,
    this._value, {
    dynamic start,
    dynamic end,
    Operator operator = Operator.equals,
    Scan scan = Scan.between,
  }) : super(_field) {
    this._start = start;
    this._end = end;
    if (_value is Operator) {
      this._operator = _value;
    } else {
      this._operator = operator;
    }
    if (operator == Operator.like) {
      this._scan = scan;
    }
  }

  Condition.or(this.orList) : super(null);

  factory Condition.notEquals(
    String field,
    dynamic value,
  ) {
    return Condition(
      field,
      value,
      operator: Operator.notEquals,
    );
  }

  factory Condition.greaterThan(
    String field,
    dynamic value,
  ) {
    return Condition(
      field,
      value,
      operator: Operator.greaterThan,
    );
  }

  factory Condition.lessThan(
    String field,
    dynamic value,
  ) {
    return Condition(
      field,
      value,
      operator: Operator.lessThan,
    );
  }

  factory Condition.greaterThanOrEquals(
    String field,
    dynamic value,
  ) {
    return Condition(
      field,
      value,
      operator: Operator.greaterThanOrEquals,
    );
  }

  factory Condition.lessThanOrEquals(
    String field,
    dynamic value,
  ) {
    return Condition(
      field,
      value,
      operator: Operator.lessThanOrEquals,
    );
  }

  factory Condition.between(
    String field,
    dynamic start,
    dynamic end,
  ) {
    return Condition(
      field,
      null,
      start: start,
      end: end,
      operator: Operator.between,
    );
  }

  factory Condition.isNull(String field) {
    return Condition(
      field,
      null,
      operator: Operator.isNull,
    );
  }

  factory Condition.notNull(String field) {
    return Condition(
      field,
      null,
      operator: Operator.notNull,
    );
  }

  factory Condition.isEmpty(String field) {
    return Condition(
      field,
      null,
      operator: Operator.isEmpty,
    );
  }

  factory Condition.notEmpty(String field) {
    return Condition(
      field,
      null,
      operator: Operator.notEmpty,
    );
  }

  factory Condition.like(
    String field,
    String value, {
    Scan scan = Scan.between,
  }) {
    return Condition(
      field,
      value,
      operator: Operator.like,
      scan: scan,
    );
  }

  String asString() {
    final type = hasValue && _value is Operator ? _value : operator;
    switch (type) {
      case Operator.equals:
        return "$field = $value";
        break;
      case Operator.notEquals:
        return "$field != $value";
        break;
      case Operator.greaterThan:
        return "$field > $value";
        break;
      case Operator.lessThan:
        return "$field < $value";
        break;
      case Operator.greaterThanOrEquals:
        return "$field >= $value";
        break;
      case Operator.lessThanOrEquals:
        return "$field <= $value";
        break;
      case Operator.between:
        return "$field BETWEEN $start AND $end";
        break;
      case Operator.isNull:
        return "$field IS NULL";
        break;
      case Operator.notNull:
        return "$field NOT NULL";
        break;
      case Operator.isEmpty:
        return "$field = ''";
        break;
      case Operator.notEmpty:
        return "$field != ''";
        break;
      case Operator.like:
        return "$field LIKE $value";
        break;
    }
    return null;
  }

  String _getValue(dynamic input) {
    if (input != null) {
      if (input is String) {
        return '\'${input.toString()}\'';
      }
    }
    return input.toString();
  }
}
