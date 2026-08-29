#ifndef RAP_CLIENT_THEME_MANAGER_H
#define RAP_CLIENT_THEME_MANAGER_H

#include <QColor>
#include <QObject>
#include <QString>

namespace rap::client {

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(int currentTheme READ currentTheme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString currentThemeName READ currentThemeName NOTIFY themeChanged)
    Q_PROPERTY(QColor background READ background NOTIFY themeChanged)
    Q_PROPERTY(QColor surface READ surface NOTIFY themeChanged)
    Q_PROPERTY(QColor surfaceVariant READ surfaceVariant NOTIFY themeChanged)
    Q_PROPERTY(QColor border READ border NOTIFY themeChanged)
    Q_PROPERTY(QColor primary READ primary NOTIFY themeChanged)
    Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
    Q_PROPERTY(QColor textPrimary READ textPrimary NOTIFY themeChanged)
    Q_PROPERTY(QColor textSecondary READ textSecondary NOTIFY themeChanged)
    Q_PROPERTY(QColor error READ error NOTIFY themeChanged)
    Q_PROPERTY(QColor success READ success NOTIFY themeChanged)
    Q_PROPERTY(QColor warning READ warning NOTIFY themeChanged)
    Q_PROPERTY(QColor transparent READ transparent CONSTANT)

public:
    explicit ThemeManager(QObject* parent = nullptr);

    int currentTheme() const { return currentTheme_; }
    QString currentThemeName() const { return currentThemeName_; }

    QColor background() const { return background_; }
    QColor surface() const { return surface_; }
    QColor surfaceVariant() const { return surfaceVariant_; }
    QColor border() const { return border_; }
    QColor primary() const { return primary_; }
    QColor accent() const { return accent_; }
    QColor textPrimary() const { return textPrimary_; }
    QColor textSecondary() const { return textSecondary_; }
    QColor error() const { return error_; }
    QColor success() const { return success_; }
    QColor warning() const { return warning_; }
    QColor transparent() const { return QColor(0, 0, 0, 0); }

    Q_INVOKABLE void setTheme(int mode);

signals:
    void themeChanged();

private:
    int currentTheme_{0};
    QString currentThemeName_{"Catppuccin Dark"};

    QColor background_{"#181825"};
    QColor surface_{"#1e1e2e"};
    QColor surfaceVariant_{"#313244"};
    QColor border_{"#45475a"};
    QColor primary_{"#89b4fa"};
    QColor accent_{"#cba6f7"};
    QColor textPrimary_{"#cdd6f4"};
    QColor textSecondary_{"#a6adc8"};
    QColor error_{"#f38ba8"};
    QColor success_{"#a6e3a1"};
    QColor warning_{"#f9e2af"};
};

} // namespace rap::client

#endif // RAP_CLIENT_THEME_MANAGER_H
