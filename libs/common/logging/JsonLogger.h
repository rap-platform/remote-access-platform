#ifndef RAP_COMMON_JSON_LOGGER_H
#define RAP_COMMON_JSON_LOGGER_H

#include <QFile>
#include <QJsonObject>
#include <QLoggingCategory>
#include <QMutex>
#include <QString>

namespace rap::common::logging {

class JsonLogger {
public:
    static JsonLogger& instance();

    void initialize(const QString& logFilePath = QString());
    void install();
    void uninstall();

    static void
    qtMessageHandler(QtMsgType type, const QMessageLogContext& context, const QString& msg);

    QJsonObject
    formatJsonObject(QtMsgType type, const QMessageLogContext& context, const QString& msg) const;

private:
    JsonLogger() = default;
    ~JsonLogger();

    JsonLogger(const JsonLogger&) = delete;
    JsonLogger& operator=(const JsonLogger&) = delete;

    void writeLog(const QString& jsonLine);

    QMutex mutex_;
    QFile logFile_;
    bool initialized_{false};
    bool installed_{false};
};

} // namespace rap::common::logging

#endif // RAP_COMMON_JSON_LOGGER_H
