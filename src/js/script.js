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
function leadingChars(str, fieldWidth, fillChar) {
    var chars = '';

    if (fillChar === undefined) {
        fillChar = ' ';
    }

    for (var i = 0; i < fieldWidth - String(str).length; ++i) {
        chars += fillChar;
    }

    return chars + str;
}

// Math
function isNumeric(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}

function clamp(val, min, max) {
    return Math.min(Math.max(val, min), max);
}

function inRange(val, min, max) {
    return (val >= min && val <= max) ? true : false;
}

// Debug
function log_info(message) {
    console.log(message);
}

function log_error(message) {
    console.log('ERROR: ' + message);
}
