#pragma once

#include <QObject>
#include <QString>
#include <QSettings>

#include "AdbInterface.h"

class AppSettings : public QObject {
	Q_OBJECT
	Q_PROPERTY(QString adbExecutable READ adbExecutable WRITE setAdbExecutable NOTIFY adbExecutableChanged)
	Q_PROPERTY(bool isConfigured READ isConfigured NOTIFY isConfiguredChanged)

private:
	QSettings m_settings;
	bool m_isConfigured;

	void updateIsConfigured() {
		bool result = true;

		// validate adb executable setting
		if(!AdbInterface::getVersion(adbExecutable().toStdString())) {
			result = false;
		}

		if(result != m_isConfigured) {
			m_isConfigured = result;
			emit isConfiguredChanged();
		}
	}

public:
	AppSettings(QObject* parent = nullptr) : QObject(parent) {
		updateIsConfigured();
	}

	QString adbExecutable() const { return m_settings.value("adb/executable", QString("")).toString(); }
	void setAdbExecutable(const QString& newAdbExecutable) {
		m_settings.setValue("adb/executable", newAdbExecutable);
		emit adbExecutableChanged();
		updateIsConfigured();
	}

	bool isConfigured() const { return m_isConfigured; }

signals:
	void adbExecutableChanged();
	void isConfiguredChanged();

};
