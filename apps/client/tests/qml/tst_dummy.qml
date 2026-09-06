import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "QMLSkeletonTest"

    function test_trivial_pass() {
        verify(true, "QML testing skeleton is operational")
        compare(1 + 1, 2, "Math holds true in QML harness")
    }
}
