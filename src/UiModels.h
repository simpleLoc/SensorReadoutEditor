#pragma once

#include <variant>

#include <QObject>
#include <QVariant>
#include <QVector>
#include <QAbstractTableModel>

#include <sensorreadout/SensorReadoutParser.h>

namespace srp = SensorReadoutParser;

namespace SensorReadout {
	Q_NAMESPACE
	enum SensorType {
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
	Q_ENUM_NS(SensorType)
}

class XYZSensorEventUiModel {
	Q_GADGET
	Q_PROPERTY(qreal x READ x WRITE setX)
	Q_PROPERTY(qreal y READ y WRITE setY)
	Q_PROPERTY(qreal z READ z WRITE setZ)
	srp::XYZSensorEventBase evt;
public:
	XYZSensorEventUiModel() {}
	XYZSensorEventUiModel(const srp::XYZSensorEventBase& evt) : evt(evt) {}
	qreal x() const { return evt.x; }
	qreal y() const { return evt.y; }
	qreal z() const { return evt.z; }
	void setX(qreal x) { evt.x = x; }
	void setY(qreal y) { evt.y = y; }
	void setZ(qreal z) { evt.z = z; }
};
Q_DECLARE_METATYPE(XYZSensorEventUiModel);

class SingleValueSensorEventUiModel {
	Q_GADGET
	Q_PROPERTY(qreal value READ value WRITE setValue)
	srp::NumericSensorEventBase<1> evt;
public:
	SingleValueSensorEventUiModel() {}
	SingleValueSensorEventUiModel(const srp::NumericSensorEventBase<1>& evt) : evt(evt) {}
	qreal value() const { return evt.getValue<0>(); }
	void setValue(qreal value) { evt.getValue<0>() = value; }
};
Q_DECLARE_METATYPE(SingleValueSensorEventUiModel);




class EventUiModel {
	Q_GADGET
	Q_PROPERTY(SensorReadout::SensorType type READ type)
	Q_PROPERTY(quint64 timestamp READ timestamp)
	Q_PROPERTY(QVariant data READ data)

private: // data
	SensorReadout::SensorType m_type;
	quint64 m_timestamp;
	QVariant m_data;

public:
	EventUiModel(){}
	EventUiModel(const srp::SensorEvent& sensorEvent) {
		m_type = static_cast<SensorReadout::SensorType>(sensorEvent.eventType);
		m_timestamp = sensorEvent.timestamp;

		#define SENSOREVT_TO_UIMODEL(_sensorEvent, _EventDataUiModelType) \
			case srp::EventType::_sensorEvent:\
				m_data = QVariant::fromValue(_EventDataUiModelType( std::get<srp::_sensorEvent ## Event>(sensorEvent.data) )); \
				break;

		switch(sensorEvent.eventType) {
			SENSOREVT_TO_UIMODEL(Accelerometer, XYZSensorEventUiModel)
			SENSOREVT_TO_UIMODEL(Gravity, XYZSensorEventUiModel)
			SENSOREVT_TO_UIMODEL(LinearAcceleration, XYZSensorEventUiModel)
			SENSOREVT_TO_UIMODEL(Gyroscope, XYZSensorEventUiModel)
			SENSOREVT_TO_UIMODEL(MagneticField, XYZSensorEventUiModel)
			SENSOREVT_TO_UIMODEL(Orientation, XYZSensorEventUiModel)
			SENSOREVT_TO_UIMODEL(OrientationOld, XYZSensorEventUiModel)
			SENSOREVT_TO_UIMODEL(GameRotationVector, XYZSensorEventUiModel)
			//TODO: implement
			case srp::EventType::Pressure:
			case srp::EventType::RotationMatrix:
			case srp::EventType::Wifi:
			case srp::EventType::BLE:
			case srp::EventType::RelativeHumidity:
			case srp::EventType::RotationVector:
			case srp::EventType::Light:
			case srp::EventType::AmbientTemperature:
			case srp::EventType::HeartRate:
			case srp::EventType::GPS:
			case srp::EventType::WifiRTT:
			case srp::EventType::PedestrianActivity:
			case srp::EventType::GroundTruth:
			case srp::EventType::GroundTruthPath:
			case srp::EventType::FileMetadata:
				break;
		}
	}

	SensorReadout::SensorType type() const { return m_type; }
	quint64 timestamp() const { return m_timestamp; }
	QVariant data() const { return m_data; }

	srp::SensorEvent toSensorEvent() const {
		srp::SensorEvent evt;
		evt.eventType = static_cast<srp::EventType>(m_type);
		evt.timestamp = m_timestamp;
		//TODO: evt.data =
		return evt;
	}
};
Q_DECLARE_METATYPE(EventUiModel);



class EventList : public QObject {
	Q_OBJECT

private:
	std::vector<srp::SensorEvent> m_events;

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
	void setEvents(const std::vector<srp::SensorEvent>& events) {
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













//class EventTableModel : public QAbstractTableModel {
//	Q_OBJECT

//	srp::AggregatingParser::AggregatedParseResult eventData;

//public:
//	EventTableModel(QObject* parent = nullptr) : QAbstractTableModel(parent) {}

//	int rowCount(const QModelIndex &parent) const override {
//		return eventData.size();
//	}
//	int columnCount(const QModelIndex &parent) const override {
//		return 3;
//	}
//	QVariant data(const QModelIndex &index, int role) const override {
//		if(role == Qt::DisplayRole) {
//			switch(index.column()) {
//				case 0:
//					return static_cast<SensorReadout::SensorType>(eventData[index.row()].eventType);
//				case 1:
//					return QString("%1").arg(eventData[index.row()].timestamp);
//				case 2:
//					return QString("Data");
//			}
//		} else if(role == Qt::UserRole) {
//			if(index.column() == 2) {
//				return QVariant::fromValue(EventUiDataModel(eventData[index.row()]));
//			}
//		}
//		return QVariant();
//	}

//	QHash<int, QByteArray> roleNames() const override {
//		return {
//			{Qt::DisplayRole,	"display"},
//			{Qt::UserRole,		"data"}
//		};
//	}

//	QVariant headerData(int section, Qt::Orientation orientation, int role) const override {
//		if(role == Qt::DisplayRole) {
//			switch(section) {
//				case 0: return QString("EventType");
//				case 1: return QString("Timestamp");
//				case 2: return QString("Data");
//			}
//		}
//		return QVariant();
//	}

//	Qt::ItemFlags flags(const QModelIndex &index) const override {
//		return (Qt::ItemIsEnabled | Qt::ItemIsSelectable);
//	}

//public: // Update api
//	void update(const srp::AggregatingParser::AggregatedParseResult& parseResult) {
//		beginResetModel();
//		eventData = parseResult;
//		endResetModel();
//	}
//};
