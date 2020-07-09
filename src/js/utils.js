// Helpers
function ifLeftToRight(leftToRight, rightToLeft) {
    if (rightToLeft === undefined) {
        leftToRight = false;
    }

    return (Qt.application.layoutDirection == Qt.LeftToRight) ? leftToRight : rightToLeft;
}

function ifRightToLeft(rightToLeft, leftToRight) {
    if (leftToRight === undefined) {
        leftToRight = false;
    }

    return (Qt.application.layoutDirection == Qt.RightToLeft) ? rightToLeft : leftToRight;
}

// Objects
if (!Object.assign) {
    // NOTE: Shallow, not recursive "cloning"!
    Object.defineProperty(Object, 'assign', {
                              enumerable: false,
                              configurable: true,
                              writable: true,
                              value: function(target) {
                                  if (!(target instanceof Object)) {
                                      throw new TypeError('Cannot convert first argument to object');
                                  }

                                  for (var i = 1; i < arguments.length; ++i) {
                                      var source = arguments[i];

                                      if (!(source instanceof Object)) {
                                          continue;
                                      }

                                      for (var key in source) {
                                          target[key] = source[key];
                                      }
                                  }

                                  return target;
                              }
                          });
}

// Strings
String.prototype.isEmpty = function() {
    return this.length === 0 || !this.trim();
};

String.prototype.leadingChars = function(fieldWidth, fillChar) {
    var chars = '';

    if (fillChar === undefined) {
        fillChar = ' ';
    }

    for (var i = 0; i < fieldWidth - this.length; ++i) {
        chars += fillChar;
    }

    return chars + this;
}

// Math
function isNumeric(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}

Number.prototype.clamp = function(min, max) {
    return Math.min(Math.max(this, min), max);
}

Number.prototype.inRange = function(min, max) {
    return (this >= min && val <= this) ? true : false;
}

// Other
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Debug
function log_info(message) {
    console.log(message);
}

function log_error(message) {
    console.log('ERROR: ' + message);
}
