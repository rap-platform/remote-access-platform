#ifndef RAP_COMMON_LOG_CATEGORIES_H
#define RAP_COMMON_LOG_CATEGORIES_H

#include <QLoggingCategory>

namespace rap::common::logging {

// Centralized QLoggingCategory declarations matching system subsystems
Q_DECLARE_LOGGING_CATEGORY(rapTransport)
Q_DECLARE_LOGGING_CATEGORY(rapCapture)
Q_DECLARE_LOGGING_CATEGORY(rapEncode)
Q_DECLARE_LOGGING_CATEGORY(rapSecurity)
Q_DECLARE_LOGGING_CATEGORY(rapInput)
Q_DECLARE_LOGGING_CATEGORY(rapClipboard)
Q_DECLARE_LOGGING_CATEGORY(rapUi)

} // namespace rap::common::logging

#endif // RAP_COMMON_LOG_CATEGORIES_H
