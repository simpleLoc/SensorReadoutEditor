#pragma once

#include <string>

#include <QObject>
#include <QProcess>

#include "AppSettings.h"
#include "AdbInterface.h"

class ReadoutFileInfo {
	Q_GADGET
	Q_PROPERTY(QString filePath READ filePath)
	Q_PROPERTY(QString fileName READ fileName)
	Q_PROPERTY(quint64 fileSize READ fileSize)
	Q_PROPERTY(QString fileDate READ fileDate)

private:
	QString m_filePath;
	QString m_fileName;
	quint64 m_fileSize;
	QString m_fileDate;

public:
	ReadoutFileInfo() {}
	ReadoutFileInfo(const std::string& filePath, size_t fileSize, const std::string& fileDate)
			: m_filePath(QString::fromStdString(filePath)), m_fileSize(fileSize), m_fileDate(QString::fromStdString(fileDate)) {
		auto fileNameSepIdx = m_filePath.lastIndexOf('/');
		if(fileNameSepIdx == -1) { throw std::runtime_error("Invalid filename"); }
		m_fileName = m_filePath.mid(fileNameSepIdx + 1);
	}

	QString filePath() const { return m_filePath; }
	QString fileName() const { return m_fileName; }
	quint64 fileSize() const { return m_fileSize; }
	QString fileDate() const { return m_fileDate; }
};
Q_DECLARE_METATYPE(ReadoutFileInfo)


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

public slots:

	QList<QString> deviceList() {
		QList<QString> result;
		auto deviceList = AdbInterface::getDevices(m_settings->adbExecutable().toStdString());
		if(deviceList) {
			for(const auto& device : deviceList.value()) {
				result.push_back(QString::fromStdString(device));
			}
		}
		return result;
	}

	QVariantList listFiles(const QString& pattern) {
		QVariantList result;
		auto fileList = AdbInterface::listFiles(
			m_settings->adbExecutable().toStdString(),
			m_device.toStdString(),
			pattern.toStdString());
		if(fileList) {
			for(const auto& fileInfo : fileList.value()) {
				result.push_back(
					QVariant::fromValue(ReadoutFileInfo(fileInfo.filePath, fileInfo.size, fileInfo.fileDate))
				);
			}
		}
		return result;
	}

	void deleteFile(const QString& filePath) {
		try {
			AdbInterface::deleteFile(
				m_settings->adbExecutable().toStdString(),
				m_device.toStdString(),
				filePath.toStdString());
		} catch (std::runtime_error& e) {
			//TODO: handle error (send to gui?)
		}
	}

signals:
	void settingsChanged();
	void deviceChanged();

};
