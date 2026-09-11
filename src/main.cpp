#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "diarystore.h"

int main(int argc, char *argv[])
{
    QGuiApplication application(argc, argv);
    QGuiApplication::setApplicationDisplayName(QStringLiteral("Udaet"));
    QGuiApplication::setApplicationName(QStringLiteral("udaet"));
    QGuiApplication::setApplicationVersion(QStringLiteral("0.1.0"));
    QGuiApplication::setOrganizationDomain(QStringLiteral("udaet.org"));

    DiaryStore diaryStore;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("diaryStore"), &diaryStore);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &application,
        [] { QCoreApplication::exit(EXIT_FAILURE); },
        Qt::QueuedConnection);
    engine.loadFromModule(QStringLiteral("org.udaet"), QStringLiteral("Main"));

    return application.exec();
}
