#include "JsonLogger.h"

#include <QDateTime>
#include <QDebug>
#include <QJsonDocument>
#include <QTextStream>

#include <iostream>

namespace rap::common::logging {

JsonLogger& JsonLogger::instance() {
    static JsonLogger inst;
    return inst;
}

JsonLogger::~JsonLogger() {
    if (logFile_.isOpen()) {
        logFile_.close();
    }
}

void JsonLogger::initialize(const QString& logFilePath) {
    QMutexLocker locker(&mutex_);
    if (initialized_) {
        return;
    }

    if (!logFilePath.isEmpty()) {
        logFile_.setFileName(logFilePath);
        logFile_.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text);
    }
    initialized_ = true;
}

void JsonLogger::install() {
    QMutexLocker locker(&mutex_);
    if (!installed_) {
        qInstallMessageHandler(JsonLogger::qtMessageHandler);
        installed_ = true;
    }
}

void JsonLogger::uninstall() {
    QMutexLocker locker(&mutex_);
    if (installed_) {
        qInstallMessageHandler(nullptr);
        installed_ = false;
    }
}

QJsonObject JsonLogger::formatJsonObject(QtMsgType type,
                                         const QMessageLogContext& context,
                                         const QString& msg) const {
    QJsonObject obj;

    obj["timestamp"] = QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs);

    switch (type) {
    case QtDebugMsg:
        obj["level"] = "DEBUG";
        break;
    case QtInfoMsg:
        obj["level"] = "INFO";
        break;
    case QtWarningMsg:
        obj["level"] = "WARNING";
        break;
    case QtCriticalMsg:
        obj["level"] = "CRITICAL";
        break;
    case QtFatalMsg:
        obj["level"] = "FATAL";
        break;
    }

    obj["category"] = context.category ? QString(context.category) : "default";
    obj["file"] = context.file ? QString(context.file) : "";
    obj["line"] = context.line;
    obj["function"] = context.function ? QString(context.function) : "";
    obj["message"] = msg;

    return obj;
}

void JsonLogger::qtMessageHandler(QtMsgType type,
                                  const QMessageLogContext& context,
                                  const QString& msg) {
    QJsonObject json = instance().formatJsonObject(type, context, msg);
    QJsonDocument doc(json);
    QString line = QString::fromUtf8(doc.toJson(QJsonDocument::Compact));

    instance().writeLog(line);
}

void JsonLogger::writeLog(const QString& jsonLine) {
    QMutexLocker locker(&mutex_);

    std::cout << jsonLine.toStdString() << std::endl;

    if (logFile_.isOpen()) {
        QTextStream stream(&logFile_);
        stream << jsonLine << "\n";
        stream.flush();
    }
}

} // namespace rap::common::logging
