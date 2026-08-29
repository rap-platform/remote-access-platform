#include "VideoFrameProvider.h"

#include <QMutexLocker>

namespace rap::client {

VideoFrameProvider::VideoFrameProvider() : QQuickImageProvider(QQuickImageProvider::Image) {
    // Default placeholder frame
    currentFrame_ = QImage(1280, 720, QImage::Format_RGB32);
    currentFrame_.fill(QColor(30, 30, 46));
}

QImage
VideoFrameProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize) {
    Q_UNUSED(id)
    QMutexLocker locker(&mutex_);

    if (size) {
        *size = currentFrame_.size();
    }

    if (requestedSize.width() > 0 && requestedSize.height() > 0) {
        return currentFrame_.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }

    return currentFrame_;
}

void VideoFrameProvider::updateFrame(const QImage& image) {
    {
        QMutexLocker locker(&mutex_);
        currentFrame_ = image;
    }
    emit frameReady();
}

} // namespace rap::client
