.pragma library
.import SensorReadout 1.0 as SensorReadout

function _param(parameterType, parameterName) {
    return {
        type: parameterName,
        name: parameterName
    };
}
function _fparam(name) { return _param("float", name); }
function _iparam(name) { return _param("integer", name); }
function _sparam(name) { return _param("string", name); }

class FixedParameterParser {
    constructor(mapArray) {
        this.mapArray = mapArray;
    }
    parse(parameterString) {
        var args = parameterString.split(';');
        var resultMap = [];
        for(var i in this.mapArray) {
            var parameter = this.mapArray[i];
            resultMap.push({ type: parameter.type, name: parameter.name, value: args[i] })
        }
        return {type: "fixedParameter", value: resultMap};
    }
    serialize(parameterMap) {
        console.assert(parameterMap.type === "fixedParameter");
        var args = parameterMap.value.map(function(parameter) {
            return parameter.value;
        });
        return args.join(';');
    }
}

var __PARSE_DEFINITIONS = {};
__PARSE_DEFINITIONS[SensorReadout.SensorType.Accelerometer] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Gravity] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.LinearAcceleration] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Gyroscope] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.MagneticField] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Pressure] = new FixedParameterParser([_fparam("pressure")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Orientation] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.RotationMatrix] = {}; //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.Wifi] = {}; //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.BLE] = {}; //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.RelativeHumidity] = new FixedParameterParser([_fparam("relativeHumidity")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.OrientationOld] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.RotationVector] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z"), _fparam("w")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Light] = new FixedParameterParser([_fparam("light")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.AmbientTemperature] = new FixedParameterParser([_fparam("temperature")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.HeartRate] = new FixedParameterParser([_fparam("heartRate")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.GPS] = {}; //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.WifiRTT] = {}; //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.GameRotationVector] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.PedestrianActivity] = new FixedParameterParser([_fparam("activityName"), _fparam("activityId")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.GroundTruth] = new FixedParameterParser([_iparam("groundTruth")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.GroundTruthPath] = new FixedParameterParser([_iparam("pathId"), _iparam("groundTruthPointCnt")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.FileMetadata] = new FixedParameterParser([_sparam("date"), _sparam("person"), _sparam("comment")]);

class SensorEvent {
    constructor(rawSensorEvent) {
        // rawSensorEvent is a c++ model. manually copy into native JavaScript what we need
        this.type = rawSensorEvent.type;
        this.dataRaw = rawSensorEvent.dataRaw;
    }
    get() {
        return __PARSE_DEFINITIONS[this.type].parse(this.dataRaw);
    }
    set(parsedObj) {
        this.dataRaw = __PARSE_DEFINITIONS[this.type].serialize(parsedObj);
    }
    toRawData() {
        return this.dataRaw;
    }
}
