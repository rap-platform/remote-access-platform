#ifndef RAP_CLIENT_VIDEO_FRAME_PROVIDER_H
#define RAP_CLIENT_VIDEO_FRAME_PROVIDER_H

#include <QImage>
#include <QMutex>
#include <QQuickImageProvider>

namespace rap::client {

class VideoFrameProvider : public QQuickImageProvider {
    Q_OBJECT

public:
    VideoFrameProvider();

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;
    QImage currentFrame() const;

public slots:
    void updateFrame(const QImage& image);

signals:
    void frameReady();

private:
    QImage currentFrame_;
    mutable QMutex mutex_;
};

} // namespace rap::client

#endif // RAP_CLIENT_VIDEO_FRAME_PROVIDER_H
