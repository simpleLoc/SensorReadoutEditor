.pragma library
.import SensorReadout 1.0 as SensorReadout

class Parameter {
    constructor(parameterType, parameterName, parameterArgs) {
        this.type = parameterType;
        this.name = parameterName;
        this.args = parameterArgs;
    }
    addTo(dstMap, values, idx) { console.assert(false); }
    serializeTo(dstArr, param) { console.assert(false); }
}
class SingleValueParameter extends Parameter {
    constructor(parameterType, parameterName, parameterArgs) { super(parameterType, parameterName, parameterArgs); }
    addTo(dstMap, values, idx) {
        dstMap.push({ type: this.type, name: this.name, value: values[idx] });
        return (idx + 1);
    }
    serializeTo(dstArr, param) { dstArr.push(param.value); }
}
class FParameter extends SingleValueParameter { constructor(parameterName) { super("float", parameterName, null); } }
class IParameter extends SingleValueParameter { constructor(parameterName) { super("integer", parameterName, null); } }
class SParameter extends SingleValueParameter { constructor(parameterName) { super("string", parameterName, null); } }
class TableParameter extends Parameter {
    constructor(parameterName, columnParameters) { super("table", parameterName, columnParameters); }
    addTo(dstMap, values, idx) {
        let param = { type: this.type, name: this.name, columns: [], value: [] };
        param.columns = this.args.map((a) => a.name);
        while(idx < values.length) {
            console.assert(values.length - idx >= this.args.length);
            let valueRow = [];
            for(let pidx = 0; pidx < this.args.length; ++pidx) {
                idx = this.args[pidx].addTo(valueRow, values, idx);
            }
            param.value.push(valueRow);
        }
        dstMap.push(param);
        return values.length;
    }
    serializeTo(dstArr, param) {
        for(let r = 0; r < param.value.length; ++r) {
            for(let c = 0; c < this.args.length; ++c) {
                this.args[c].serializeTo(dstArr, param.value[r][c]);
            }
        }
    }
}


function _fparam(name) { return new FParameter(name); }
function _iparam(name) { return new IParameter(name); }
function _sparam(name) { return new SParameter(name); }
function _tableparam(name, fieldArray) { return new TableParameter(name, fieldArray); }

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
        let argIdx = 0;
        for(var parameter of this.mapArray) {
            argIdx = parameter.addTo(resultMap, args, argIdx);
        }
        return {type: "fixedParameter", value: resultMap};
    }
    serialize(parameterMap) {
        console.assert(parameterMap.type === "fixedParameter");
        let args = [];
        for(let i = 0; i < this.mapArray.length; ++i) {
            this.mapArray[i].serializeTo(args, parameterMap.value[i]);
        }
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
__PARSE_DEFINITIONS[SensorReadout.SensorType.EddystoneUID] = new NotImplementedParameterParser(); //TODO: implement
__PARSE_DEFINITIONS[SensorReadout.SensorType.DecawaveUWB] = new FixedParameterParser([
    _fparam("x"), _fparam("y"), _fparam("z"), _iparam("quality"),
    _tableparam("ranges", [_iparam("anchorId"), _iparam("distanceMM"), _iparam("quality")])
]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.StepDetector] = new FixedParameterParser([_fparam("probability")]);
__PARSE_DEFINITIONS[SensorReadout.SensorType.HeadingChange] = new FixedParameterParser([_fparam("headingChangeRad")]);

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
