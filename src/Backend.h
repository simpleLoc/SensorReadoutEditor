#pragma once

#include <vector>
#include <fstream>
#include <iostream>

#include <QObject>
#include <QString>

#include <sensorreadout/SensorReadoutParser.h>
#include "UiModels.h"

namespace srp = SensorReadoutParser;

class Backend : public QObject {
	Q_OBJECT
	Q_PROPERTY(EventList* events READ events NOTIFY eventsChanged)

private: // data
	srp::AggregatingParser::AggregatedParseResult m_data;
	EventList* m_events;

public:
	explicit Backend(QObject* parent = nullptr) : QObject(parent) {
		m_events = new EventList(this);
		emit eventsChanged();
	}
	virtual ~Backend(){}

public: // Properties
	EventList* events() const { return m_events; }

public: // UI interface
	Q_INVOKABLE void openFile(const QString& filePath) {
		std::fstream fileStream(filePath.toStdString());
		if(!fileStream.is_open()) {
			emit onError(QString("Failed to open file"));
			return;
		}
		srp::AggregatingParser parser(fileStream);
		try {
			m_data = parser.parse();
		} catch (std::runtime_error& e) {
			emit onError(QString::fromStdString(e.what()));
		}
		m_events->setEvents(m_data);
	};

signals:
	void eventsChanged();

	void onError(const QString& message);

};
