#ifndef RAP_AGENT_CLIPBOARD_MANAGER_H
#define RAP_AGENT_CLIPBOARD_MANAGER_H

#include <QClipboard>
#include <QGuiApplication>
#include <QObject>
#include <QString>

namespace rap::agent {

class ClipboardManager : public QObject {
    Q_OBJECT
public:
    explicit ClipboardManager(QObject* parent = nullptr) : QObject(parent) {}

    static QString getSystemClipboardText() {
        QClipboard* cb = QGuiApplication::clipboard();
        return cb ? cb->text() : QString();
    }

    static void setSystemClipboardText(const QString& text) {
        QClipboard* cb = QGuiApplication::clipboard();
        if (cb) {
            cb->setText(text);
        }
    }
};

} // namespace rap::agent

#endif // RAP_AGENT_CLIPBOARD_MANAGER_H
