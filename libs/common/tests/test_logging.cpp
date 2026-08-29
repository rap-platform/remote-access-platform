#include <QCoreApplication>
#include <QTest>

#include "../logging/LogCategories.h"

class TestLogging : public QObject {
    Q_OBJECT

private slots:
    void testCategoryNames() {
        QCOMPARE(QString(rap::common::logging::rapTransport().categoryName()),
                 QString("rap.transport"));
        QCOMPARE(QString(rap::common::logging::rapSecurity().categoryName()),
                 QString("rap.security"));
        QCOMPARE(QString(rap::common::logging::rapCapture().categoryName()),
                 QString("rap.capture"));
    }
};

QTEST_MAIN(TestLogging)
#include "test_logging.moc"
