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

/**
  * Fixed parameter parser, for events with a fixed amount and type of parameters
 */
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
class MatrixParameterParser {
    constructor(width, height, rowMajor) {
        this.width = width;
        this.height = height;
        this.rowMajor = rowMajor;
    }
    convertMajorness(values, height, width) {
        var result = [];
        for(var y = 0; y < height; ++y) {
            for(var x = 0; x < width; ++x) {
            result.push(values[x * height + y]);
          }
        }
        return result;
    }
    parse(parameterString) {
        var values = parameterString.split(';');
        for(var i = values.length; i < (this.width * this.height); ++i) {
            values.push(0); // fill with 0 if required
        }
        if(!this.rowMajor) { // convert to rowMajor
            values = this.convertMajorness(values, this.height, this.width);
        }
        return {
            type: "matrixParameter",
            value: { width: this.width, height: this.height, values: values }
        };
    }
    serialize(parameterMap) {
        console.assert(parameterMap.type === "matrixParameter");
        var values = parameterMap.value.values;
        if(!this.rowMajor) { // convert back to column-major
            values = this.convertMajorness(values, this.height, this.width);
        }
        return values.join(';');
    }
}
class NotImplementedParameterParser {
    constructor(){}
    parse(parameterString) {return null;}
    serialize(parameterMap) {return null;}
}


var __PARSE_DEFINITIONS = {};
__PARSE_DEFINITIONS[SensorReadout.SensorType.Accelerometer] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Gravity] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.LinearAcceleration] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Gyroscope] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.MagneticField] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Pressure] = new FixedParameterParser([_fparam("pressure")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Orientation] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.RotationMatrix] = new MatrixParameterParser(3, 3, true); //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.Wifi] = new NotImplementedParameterParser(); //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.BLE] = new NotImplementedParameterParser(); //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.RelativeHumidity] = new FixedParameterParser([_fparam("relativeHumidity")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.OrientationOld] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.RotationVector] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z"), _fparam("w")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.Light] = new FixedParameterParser([_fparam("light")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.AmbientTemperature] = new FixedParameterParser([_fparam("temperature")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.HeartRate] = new FixedParameterParser([_fparam("heartRate")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.GPS] = new NotImplementedParameterParser(); //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.WifiRTT] = new NotImplementedParameterParser(); //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.GameRotationVector] = new FixedParameterParser([_fparam("x"), _fparam("y"), _fparam("z")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.PedestrianActivity] = new FixedParameterParser([_fparam("activityName"), _fparam("activityId")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.GroundTruth] = new FixedParameterParser([_iparam("groundTruth")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.GroundTruthPath] = new FixedParameterParser([_iparam("pathId"), _iparam("groundTruthPointCnt")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.FileMetadata] = new FixedParameterParser([_sparam("date"), _sparam("person"), _sparam("comment")]);

class SensorEvent {
    constructor(rawSensorEvent) {
        // rawSensorEvent is a c++ model. manually copy into native JavaScript what we need
        this.type = (rawSensorEvent) ? rawSensorEvent.type : SensorReadout.SensorType.UNKNOWN;
        this.dataRaw = (rawSensorEvent) ? rawSensorEvent.dataRaw : "";
    }
    get() {
        if(!(this.type in __PARSE_DEFINITIONS)) { return null; }
        return __PARSE_DEFINITIONS[this.type].parse(this.dataRaw);
    }
    set(parsedObj) {
        this.dataRaw = __PARSE_DEFINITIONS[this.type].serialize(parsedObj);
    }
    toRawData() {
        return this.dataRaw;
    }
}
