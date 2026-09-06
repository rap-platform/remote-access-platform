#ifndef RAP_CLIENT_HOT_RELOAD_MANAGER_H
#define RAP_CLIENT_HOT_RELOAD_MANAGER_H

#include <QFileSystemWatcher>
#include <QObject>
#include <QQmlEngine>
#include <QStringList>

namespace rap::client::dev {

class HotReloadManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ isActive NOTIFY activeChanged)

public:
    explicit HotReloadManager(QQmlEngine* engine, QObject* parent = nullptr);

    void watchDirectory(const QString& dirPath);
    bool isActive() const { return watcher_.directories().count() > 0; }

signals:
    void activeChanged();
    void qmlReloaded();

private slots:
    void onFileOrDirectoryChanged(const QString& path);

private:
    QQmlEngine* engine_{nullptr};
    QFileSystemWatcher watcher_;
};

} // namespace rap::client::dev

#endif // RAP_CLIENT_HOT_RELOAD_MANAGER_H
