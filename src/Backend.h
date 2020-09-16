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
	srp::AggregatingParser::AggregatedRawParseResult m_data;
	EventList* m_events;
	std::optional<std::string> currentFile;

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
		currentFile = filePath.toStdString();
		std::fstream fileStream(currentFile.value());
		if(!fileStream.is_open()) {
			currentFile = {};
			m_events->clear();
			emit onError(QString("Failed to open source file."));
			return;
		}
		srp::AggregatingParser parser(fileStream);
		try {
			m_data = parser.parseRaw();
		} catch (std::runtime_error& e) {
			emit onError(QString::fromStdString(e.what()));
		}
		m_events->setEvents(m_data);
	};

	Q_INVOKABLE bool saveFile() {
		if(currentFile) {
			return saveFile(QString::fromStdString(currentFile.value()));
		}
		return false;
	}

	Q_INVOKABLE bool saveFile(const QString& filePath) {
		std::ofstream fileStream(filePath.toStdString());
		if(!fileStream.is_open()) {
			emit onError(QString("Failed to open destination file."));
			return false;
		}
		srp::Serializer serializer(fileStream);
		try {
			for(const auto& event : m_events->getEvents()) {
				serializer.write(event);
			}
		} catch (std::runtime_error& e) {
			emit onError(QString::fromStdString(e.what()));
			return false;
		}
		// only change currentFile if saving was successful
		currentFile = filePath.toStdString();
		return true;
	}

signals:
	void eventsChanged();

	void onError(const QString& message);

};
