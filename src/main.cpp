#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlApplicationEngine>

#include "Backend.h"
#include "EventListModel.h"

int main(int argc, char *argv[]) {
	QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

	QGuiApplication app(argc, argv);
	app.setOrganizationDomain("simpleLoc.de");
	app.setOrganizationName("simpleLoc");
	app.setApplicationName("SensorReadout Editor");

	Backend backend(&app);
	SensorType sensorType;
	qmlRegisterSingletonInstance<SensorType>("SensorReadout", 1, 0, "SensorType", &sensorType);
	qmlRegisterType<EventListModel>("SensorReadout", 1, 0, "EventListModel");

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
