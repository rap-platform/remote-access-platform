#ifndef RAP_CLIENT_SESSION_CLIENT_H
#define RAP_CLIENT_SESSION_CLIENT_H

#include <QByteArray>
#include <QClipboard>
#include <QGuiApplication>
#include <QHostAddress>
#include <QImage>
#include <QObject>
#include <QTcpSocket>
#include "VideoFrameProvider.h"

namespace rap::client {

class SessionClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStateChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)

public:
    explicit SessionClient(VideoFrameProvider *frameProvider, QObject *parent = nullptr);
    ~SessionClient() override;

    bool isConnected() const { return isConnected_; }
    QString statusText() const { return statusText_; }

    Q_INVOKABLE void sendInputEvent(uint16_t type, int32_t x, int32_t y, uint32_t button, int32_t delta, uint32_t keycode, uint32_t modifiers);
    Q_INVOKABLE void sendClipboardText(const QString &text);

public slots:
    void connectToHost(const QString &host, uint16_t port);
    void disconnectFromHost();

signals:
    void connectionStateChanged(bool connected);
    void statusTextChanged(const QString &status);
    void clipboardTextReceived(const QString &text);

private slots:
    void onReadyRead();
    void onConnected();
    void onDisconnected();
    void onErrorOccurred(QAbstractSocket::SocketError socketError);
    void onClipboardChanged();

private:
    void setStatus(const QString &status);

    QTcpSocket socket_;
    VideoFrameProvider *frameProvider_{nullptr};
    QByteArray receiveBuffer_;
    bool isConnected_{false};
    QString statusText_{"Disconnected"};
    uint64_t receivedFrames_{0};
    uint64_t inputSequence_{0};
    QString lastClipboardText_;
};

} // namespace rap::client

#endif // RAP_CLIENT_SESSION_CLIENT_H
