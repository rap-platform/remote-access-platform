#include <QtTest/QtTest>

#include "IInputBackend.h"

using namespace rap::input;

class TestInputBackend : public QObject {
    Q_OBJECT

private slots:
    void testBackendInitialization();
    void testMouseMoveInjection();
    void testMouseButtonInjection();
    void testMouseWheelInjection();
    void testKeyboardInjection();
};

void TestInputBackend::testBackendInitialization() {
    auto backend = InputBackendFactory::createDefaultBackend();
    QVERIFY(backend != nullptr);
    QVERIFY(backend->initialize());
    QVERIFY(!backend->backendName().empty());
}

void TestInputBackend::testMouseMoveInjection() {
    auto backend = InputBackendFactory::createDefaultBackend();
    backend->initialize();

    InputEvent event;
    event.type = InputEventType::MouseMove;
    event.x = 500;
    event.y = 300;

    QVERIFY(backend->injectEvent(event));
}

void TestInputBackend::testMouseButtonInjection() {
    auto backend = InputBackendFactory::createDefaultBackend();
    backend->initialize();

    InputEvent press;
    press.type = InputEventType::MouseDown;
    press.x = 100;
    press.y = 200;
    press.button = 1; // Left click

    InputEvent release;
    release.type = InputEventType::MouseUp;
    release.x = 100;
    release.y = 200;
    release.button = 1;

    QVERIFY(backend->injectEvent(press));
    QVERIFY(backend->injectEvent(release));
}

void TestInputBackend::testMouseWheelInjection() {
    auto backend = InputBackendFactory::createDefaultBackend();
    backend->initialize();

    InputEvent wheel;
    wheel.type = InputEventType::MouseWheel;
    wheel.delta = 120; // Scroll up

    QVERIFY(backend->injectEvent(wheel));
}

void TestInputBackend::testKeyboardInjection() {
    auto backend = InputBackendFactory::createDefaultBackend();
    backend->initialize();

    InputEvent key;
    key.type = InputEventType::KeyDown;
    key.keycode = 0; // Test safe event dispatch without injecting physical keys into X11 display

    QVERIFY(backend->injectEvent(key));
}

QTEST_MAIN(TestInputBackend)
#include "test_input.moc"
