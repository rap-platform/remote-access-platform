#ifndef RAP_CLIENT_SESSION_CLIENT_H
#define RAP_CLIENT_SESSION_CLIENT_H

#include <QByteArray>
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
    ~SessionClient() override = default;

    bool isConnected() const { return isConnected_; }
    QString statusText() const { return statusText_; }

public slots:
    void connectToHost(const QString &host, uint16_t port);
    void disconnectFromHost();

signals:
    void connectionStateChanged(bool connected);
    void statusTextChanged(const QString &status);

private slots:
    void onReadyRead();
    void onConnected();
    void onDisconnected();
    void onErrorOccurred(QAbstractSocket::SocketError socketError);

private:
    void setStatus(const QString &status);

    QTcpSocket socket_;
    VideoFrameProvider *frameProvider_{nullptr};
    QByteArray receiveBuffer_;
    bool isConnected_{false};
    QString statusText_{"Disconnected"};
    uint64_t receivedFrames_{0};
};

} // namespace rap::client

#endif // RAP_CLIENT_SESSION_CLIENT_H
