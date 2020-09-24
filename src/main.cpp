#include <QApplication>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQmlApplicationEngine>
#include <QSettings>

#include "Backend.h"
#include "EventListModel.h"
#include "AdbController.h"

int main(int argc, char *argv[]) {
	QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
	QQuickStyle::setStyle("Fusion");

	QApplication app(argc, argv);
	app.setOrganizationDomain("simpleLoc.de");
	app.setOrganizationName("simpleLoc");
	app.setApplicationName("SensorReadout Editor");

	Backend backend(&app);
	SensorType sensorType;
	qmlRegisterSingletonInstance<SensorType>("SensorReadout", 1, 0, "SensorType", &sensorType);
	qmlRegisterType<EventListModel>("SensorReadout", 1, 0, "EventListModel");
	qmlRegisterType<AdbController>("SensorReadout", 1, 0, "AdbController");

	QQmlApplicationEngine engine;
	const QUrl url(QStringLiteral("qrc:/ui/main.qml"));
	QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
					 &app, [url](QObject *obj, const QUrl &objUrl) {
		if (!obj && url == objUrl)
			QCoreApplication::exit(-1);
	}, Qt::QueuedConnection);
	engine.rootContext()->setContextProperty("backend", &backend);
	engine.load(url);

	return app.exec();
}
