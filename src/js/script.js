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

// Debug
function log_info(message) {
    console.log(message);
}

function log_error(message) {
    console.log('ERROR: ' + message);
}
