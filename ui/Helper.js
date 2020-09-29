.pragma library

function padDigits(number, digits) {
    return Array(Math.max(digits - String(number).length + 1, 0)).join(0) + number;
}

function nsTimestampToTimeString(timestamp) {
    var minutes = timestamp / 60000000000;
    var fullMinutes = Math.trunc(minutes);
    var seconds = (minutes - fullMinutes) * 60;
    var fullSeconds = Math.trunc(seconds);
    var fullMilliseconds = Math.trunc((seconds - fullSeconds) * 1000);
    return padDigits(fullMinutes, 2) + ":" + padDigits(fullSeconds, 2) + "." + padDigits(fullMilliseconds, 4);
}

var __fileSizeUnits = ["B", "KiB", "MiB", "GiB", "TiB", "EiB"];
function bytesToSizeString(byteSize) {
    var order = parseInt(Math.floor(Math.log(byteSize) / Math.log(1024)));
    var value = byteSize / Math.pow(1024, order);
    return value.toFixed(2) + " " + __fileSizeUnits[order];
}
