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
    Q_PROPERTY(QString p2pId READ p2pId NOTIFY p2pIdChanged)
    Q_PROPERTY(bool hostAgentRunning READ isHostAgentRunning NOTIFY hostAgentStateChanged)
    Q_PROPERTY(double transferProgress READ transferProgress NOTIFY transferProgressChanged)
    Q_PROPERTY(QString transferStatus READ transferStatus NOTIFY transferStatusChanged)
    Q_PROPERTY(QString transferSpeed READ transferSpeed NOTIFY transferSpeedChanged)
    Q_PROPERTY(QVariantList directoryList READ directoryList NOTIFY directoryListChanged)
    Q_PROPERTY(QString currentRemotePath READ currentRemotePath NOTIFY currentRemotePathChanged)
    Q_PROPERTY(QVariantList localDirectoryList READ localDirectoryList NOTIFY localDirectoryListChanged)
    Q_PROPERTY(QString currentLocalPath READ currentLocalPath NOTIFY currentLocalPathChanged)

public:
    explicit SessionClient(VideoFrameProvider *frameProvider, QObject *parent = nullptr);
    ~SessionClient() override;

    bool isConnected() const { return isConnected_; }
    QString statusText() const { return statusText_; }
    QString p2pId() const { return p2pId_; }
    bool isHostAgentRunning() const { return hostAgentRunning_; }
    double transferProgress() const { return transferProgress_; }
    QString transferStatus() const { return transferStatus_; }
    QString transferSpeed() const { return transferSpeed_; }
    QVariantList directoryList() const { return directoryList_; }
    QString currentRemotePath() const { return currentRemotePath_; }
    QVariantList localDirectoryList() const { return localDirectoryList_; }
    QString currentLocalPath() const { return currentLocalPath_; }

    Q_INVOKABLE void connectByP2PId(const QString &p2pId);
    Q_INVOKABLE void sendInputEvent(uint16_t type, int32_t x, int32_t y, uint32_t button, int32_t delta, uint32_t keycode, uint32_t modifiers);
    Q_INVOKABLE void sendClipboardText(const QString &text);
    Q_INVOKABLE void requestDirectoryListing(const QString &path);
    Q_INVOKABLE void requestLocalDirectoryListing(const QString &path);
    Q_INVOKABLE void deleteLocalFile(const QString &path);
    Q_INVOKABLE void deleteRemoteFile(const QString &path);
    Q_INVOKABLE void startFileUpload(const QString &localPath, const QString &remotePath);
    Q_INVOKABLE void startFileDownload(const QString &remotePath, const QString &localPath);
    Q_INVOKABLE void pauseFileTransfer();
    Q_INVOKABLE void resumeFileTransfer();
    Q_INVOKABLE void cancelFileTransfer();

public slots:
    void connectToHost(const QString &host, uint16_t port);
    void disconnectFromHost();

signals:
    void connectionStateChanged(bool connected);
    void statusTextChanged(const QString &status);
    void p2pIdChanged(const QString &p2pId);
    void hostAgentStateChanged(bool running);
    void clipboardTextReceived(const QString &text);
    void transferProgressChanged(double progress);
    void transferStatusChanged(const QString &status);
    void transferSpeedChanged(const QString &speed);
    void directoryListChanged(const QVariantList &items);
    void currentRemotePathChanged(const QString &path);
    void localDirectoryListChanged(const QVariantList &items);
    void currentLocalPathChanged(const QString &path);

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
    QString p2pId_{"482 915 307"};
    QString lastConnectedTarget_;
    bool hostAgentRunning_{true};
    uint64_t receivedFrames_{0};
    uint64_t inputSequence_{0};
    QString lastClipboardText_;

    double transferProgress_{0.0};
    QString transferStatus_{"Idle"};
    QString transferSpeed_{"0 KB/s"};
    QVariantList directoryList_;
    QString currentRemotePath_{"."};
    QVariantList localDirectoryList_;
    QString currentLocalPath_{"."};
    bool isTransferPaused_{false};
    uint64_t currentTransferBytes_{0};
    uint64_t totalTransferBytes_{0};
};

} // namespace rap::client

#endif // RAP_CLIENT_SESSION_CLIENT_H
