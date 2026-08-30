#ifndef RAP_CLIENT_UPDATE_CHECKER_H
#define RAP_CLIENT_UPDATE_CHECKER_H

#include <QObject>
#include <QString>

namespace rap::client {

class UpdateChecker : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool updateAvailable READ isUpdateAvailable NOTIFY updateCheckFinished)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY updateCheckFinished)
    Q_PROPERTY(QString releaseNotes READ releaseNotes NOTIFY updateCheckFinished)

public:
    explicit UpdateChecker(QObject* parent = nullptr) : QObject(parent) {}

    bool isUpdateAvailable() const { return updateAvailable_; }
    QString latestVersion() const { return latestVersion_; }
    QString releaseNotes() const { return releaseNotes_; }

    Q_INVOKABLE void checkForUpdates() {
        // Simulated asynchronous update check against GitHub releases API
        updateAvailable_ = false;
        latestVersion_ = "0.3.0";
        releaseNotes_ = "Current version 0.3.0 is up to date.";
        emit updateCheckFinished(updateAvailable_, latestVersion_);
    }

signals:
    void updateCheckFinished(bool updateAvailable, const QString& latestVersion);

private:
    bool updateAvailable_{false};
    QString latestVersion_{"0.3.0"};
    QString releaseNotes_;
};

} // namespace rap::client

#endif // RAP_CLIENT_UPDATE_CHECKER_H
