#include "ThemeManager.h"

namespace rap::client {

ThemeManager::ThemeManager(QObject *parent) : QObject(parent) {
    setTheme(0);
}

void ThemeManager::setTheme(int mode) {
    currentTheme_ = mode;
    if (mode == 1) {
        currentThemeName_ = "Tokyo Night";
        background_ = QColor("#1a1b26"); surface_ = QColor("#24283b"); surfaceVariant_ = QColor("#414868");
        border_ = QColor("#565f89"); primary_ = QColor("#7aa2f7"); accent_ = QColor("#bb9af7");
        textPrimary_ = QColor("#c0caf5"); textSecondary_ = QColor("#9aa5ce");
        error_ = QColor("#f7768e"); success_ = QColor("#9ece6a"); warning_ = QColor("#e0af68");
    } else if (mode == 2) {
        currentThemeName_ = "Nordic Frost";
        background_ = QColor("#2e3440"); surface_ = QColor("#3b4252"); surfaceVariant_ = QColor("#434c5e");
        border_ = QColor("#4c566a"); primary_ = QColor("#88c0d0"); accent_ = QColor("#81a1c1");
        textPrimary_ = QColor("#eceff4"); textSecondary_ = QColor("#d8dee9");
        error_ = QColor("#bf616a"); success_ = QColor("#a3be8c"); warning_ = QColor("#ebcb8b");
    } else if (mode == 3) {
        currentThemeName_ = "GitHub Dark";
        background_ = QColor("#0d1117"); surface_ = QColor("#161b22"); surfaceVariant_ = QColor("#21262d");
        border_ = QColor("#30363d"); primary_ = QColor("#58a6ff"); accent_ = QColor("#bc8cff");
        textPrimary_ = QColor("#c9d1d9"); textSecondary_ = QColor("#8b949e");
        error_ = QColor("#f85149"); success_ = QColor("#3fb950"); warning_ = QColor("#d29922");
    } else if (mode == 4) {
        currentThemeName_ = "Enterprise Light";
        background_ = QColor("#f8f9fa"); surface_ = QColor("#ffffff"); surfaceVariant_ = QColor("#e9ecef");
        border_ = QColor("#ced4da"); primary_ = QColor("#0d6efd"); accent_ = QColor("#6f42c1");
        textPrimary_ = QColor("#212529"); textSecondary_ = QColor("#6c757d");
        error_ = QColor("#dc3545"); success_ = QColor("#198754"); warning_ = QColor("#ffc107");
    } else {
        currentThemeName_ = "Catppuccin Dark";
        background_ = QColor("#181825"); surface_ = QColor("#1e1e2e"); surfaceVariant_ = QColor("#313244");
        border_ = QColor("#45475a"); primary_ = QColor("#89b4fa"); accent_ = QColor("#cba6f7");
        textPrimary_ = QColor("#cdd6f4"); textSecondary_ = QColor("#a6adc8");
        error_ = QColor("#f38ba8"); success_ = QColor("#a6e3a1"); warning_ = QColor("#f9e2af");
    }
    emit themeChanged();
}

} // namespace rap::client
