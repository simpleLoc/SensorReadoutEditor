#pragma once

#include <string>

#include <QObject>
#include <QProcess>

#include "AppSettings.h"
#include "AdbInterface.h"

class AdbController : public QObject {
	Q_OBJECT
	Q_PROPERTY(AppSettings* settings READ settings WRITE setSettings NOTIFY settingsChanged)
	Q_PROPERTY(QString device READ device WRITE setDevice NOTIFY deviceChanged)

private:
	AppSettings* m_settings;
	QString m_device;

public:
	AdbController(QObject* parent = nullptr) : QObject(parent) {}

	AppSettings* settings() const { return m_settings; }
	void setSettings(AppSettings* settings) {
		m_settings = settings;
		emit settingsChanged();
	}

	QString device() const { return m_device; }
	void setDevice(const QString& device) {
		m_device = device;
		emit deviceChanged();
	}

	Q_INVOKABLE QList<QString> deviceList() {
		QList<QString> result;
		auto deviceList = AdbInterface::getDevices(m_settings->adbExecutable().toStdString());
		if(deviceList) {
			for(const auto& device : deviceList.value()) {
				result.push_back(QString::fromStdString(device));
			}
		}
		return result;
	}

	Q_INVOKABLE QList<QString> listFiles(const QString& pattern) {
		QList<QString> result;
		auto fileList = AdbInterface::listFiles(
			m_settings->adbExecutable().toStdString(),
			m_device.toStdString(),
			pattern.toStdString());
		if(fileList) {
			for(const auto& file : fileList.value()) {
				result.push_back(QString::fromStdString(file));
			}
		}
		return result;
	}

signals:
	void settingsChanged();
	void deviceChanged();

};
