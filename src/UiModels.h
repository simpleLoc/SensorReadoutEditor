#pragma once

#include <variant>

#include <QObject>
#include <QVariant>
#include <QVector>
#include <QMetaEnum>
#include <QAbstractTableModel>

#include <sensorreadout/SensorReadoutParser.h>

namespace srp = SensorReadoutParser;

class SensorType : public QObject {
	Q_OBJECT
	Q_PROPERTY(QVector<int> values READ values NOTIFY valuesChanged)

public:
	enum Value {
		Accelerometer = srp::EVENTID_ACCELEROMETER,
		Gravity = srp::EVENTID_GRAVITY,
		LinearAcceleration = srp::EVENTID_LINEAR_ACCELERATION,
		Gyroscope = srp::EVENTID_GYROSCOPE,
		MagneticField = srp::EVENTID_MAGNETIC_FIELD,
		Pressure = srp::EVENTID_PRESSURE,
		Orientation = srp::EVENTID_ORIENTATION_NEW,
		RotationMatrix = srp::EVENTID_ROTATION_MATRIX,
		Wifi = srp::EVENTID_WIFI,
		BLE = srp::EVENTID_IBEACON,
		RelativeHumidity = srp::EVENTID_RELATIVE_HUMIDITY,
		OrientationOld = srp::EVENTID_ORIENTATION_OLD,
		RotationVector = srp::EVENTID_ROTATION_VECTOR,
		Light = srp::EVENTID_LIGHT,
		AmbientTemperature = srp::EVENTID_AMBIENT_TEMPERATURE,
		HeartRate = srp::EVENTID_HEART_RATE,
		GPS = srp::EVENTID_GPS,
		WifiRTT = srp::EVENTID_WIFIRTT,
		GameRotationVector = srp::EVENTID_GAME_ROTATION_VECTOR,
		PedestrianActivity = srp::EVENTID_PEDESTRIAN_ACTIVITY,
		GroundTruth = srp::EVENTID_GROUND_TRUTH,
		GroundTruthPath = srp::EVENTID_GROUND_TRUTH_PATH,
		FileMetadata = srp::EVENTID_FILE_METADATA
	};
	Q_ENUM(Value);

	explicit SensorType(QObject* parent = nullptr) : QObject(parent) {
		auto metaEnum = QMetaEnum::fromType<Value>();
		for(size_t i = 0; i < metaEnum.keyCount(); ++i) {
			m_values.push_back(metaEnum.value(i));
		}
	}

	Q_INVOKABLE QString toName(Value value) const {
		return QMetaEnum::fromType<Value>().valueToKey(value);
	}

	QVector<int> values() const { return m_values; }

signals:
	void valuesChanged();

private:
	QVector<int> m_values;
};



class EventUiModel {
	Q_GADGET
	Q_PROPERTY(SensorType::Value type READ type WRITE setType)
	Q_PROPERTY(quint64 timestamp READ timestamp WRITE setTimestamp)
	Q_PROPERTY(QString dataRaw READ dataRaw WRITE setDataRaw)

private: // data
	SensorType::Value m_type;
	quint64 m_timestamp;
	QString m_dataRaw;

public:
	EventUiModel(){}
	EventUiModel(const srp::RawSensorEvent& sensorEvent) {
		m_type = static_cast<SensorType::Value>(sensorEvent.eventId);
		m_timestamp = sensorEvent.timestamp;
		m_dataRaw = QString::fromStdString(sensorEvent.parameterString);
	}

	SensorType::Value type() const { return m_type; }
	quint64 timestamp() const { return m_timestamp; }
	QString dataRaw() const { return m_dataRaw; }

	void setType(SensorType::Value type) { m_type = type; }
	void setTimestamp(quint64 timestamp) { m_timestamp = timestamp; }
	void setDataRaw(const QString& dataRaw) { m_dataRaw = dataRaw; }

	srp::RawSensorEvent toSensorEvent() const {
		srp::RawSensorEvent evt;
		evt.eventId = static_cast<srp::EventId>(m_type);
		evt.timestamp = m_timestamp;
		evt.parameterString = m_dataRaw.toStdString();
		return evt;
	}

	Q_INVOKABLE EventUiModel clone() {
		return EventUiModel(*this);
	}
};
Q_DECLARE_METATYPE(EventUiModel);



class EventList : public QObject {
	Q_OBJECT

private:
	std::vector<srp::RawSensorEvent> m_events;

	bool indexIsValidItem(int index) const {
		return (index >= 0 && index < m_events.size());
	}

public:
	explicit EventList(QObject* parent = nullptr) : QObject(parent) {}

	int len() const { return m_events.size(); }

	EventUiModel getEventAt(int index) const {
		if(!indexIsValidItem(index)) { throw std::runtime_error("Invalid index"); }
		return EventUiModel(m_events[index]);
	}
	void setEvents(const std::vector<srp::RawSensorEvent>& events) {
		emit preReset();
		m_events = events;
		emit postReset();
	}

signals:
	void preReset();
	void postReset();
	void preEventInserted(int index);
	void postEventInserted();
	void preEventRemoved(int index);
	void postEventRemoved();
	void preEventChange(int index);
	void postEventChange(int index);

public slots:
	bool setEventAt(int index, const EventUiModel& event) {
		if(!indexIsValidItem(index)) { return false; }
		emit preEventChange(index);
		m_events[index] = event.toSensorEvent();
		emit postEventChange(index);
		return true;
	}
	bool insertEvent(int index, const EventUiModel& event) {
		if(indexIsValidItem(index)) {
			emit preEventInserted(index);
			m_events.insert(m_events.begin() + index, event.toSensorEvent());
		} else if(index == m_events.size()) {
			emit preEventInserted(index);
			m_events.push_back(event.toSensorEvent());
		} else { return false; }

		emit postEventInserted();
		return true;
	}
	void removeEvent(int index) {
		if(indexIsValidItem(index)) {
			emit preEventRemoved(index);
			m_events.erase(m_events.begin() + index);
			emit postEventRemoved();
		}
	}

};
