#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageLogContext>
#include <QTest>

#include "../logging/JsonLogger.h"
#include "../logging/LogCategories.h"

class TestJsonLogger : public QObject {
    Q_OBJECT

private slots:
    void testFormatJsonObject() {
        QMessageLogContext ctx("test_file.cpp", 42, "testFunc", "rap.transport");
        QJsonObject json =
            rap::common::logging::JsonLogger::instance().formatJsonObject(QtInfoMsg,
                                                                          ctx,
                                                                          "Connection established");

        QCOMPARE(json["level"].toString(), QString("INFO"));
        QCOMPARE(json["category"].toString(), QString("rap.transport"));
        QCOMPARE(json["file"].toString(), QString("test_file.cpp"));
        QCOMPARE(json["line"].toInt(), 42);
        QCOMPARE(json["function"].toString(), QString("testFunc"));
        QCOMPARE(json["message"].toString(), QString("Connection established"));
        QVERIFY(!json["timestamp"].toString().isEmpty());
    }

    void testLogFileOutput() {
        QString tempPath = QDir::temp().filePath("test_rap_log.jsonlog");
        QFile::remove(tempPath);

        rap::common::logging::JsonLogger::instance().initialize(tempPath);
        rap::common::logging::JsonLogger::instance().install();

        qCDebug(rap::common::logging::rapTransport) << "Test transport message";

        rap::common::logging::JsonLogger::instance().uninstall();

        QFile file(tempPath);
        QVERIFY(file.open(QIODevice::ReadOnly | QIODevice::Text));
        QString content = QString::fromUtf8(file.readAll());
        file.close();
        QFile::remove(tempPath);

        QVERIFY(content.contains("Test transport message"));
        QVERIFY(content.contains("rap.transport"));
    }
};

QTEST_MAIN(TestJsonLogger)
#include "test_json_logger.moc"
