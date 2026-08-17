import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: securityKeysView
    color: themePalette.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingLg
        spacing: Metrics.spacingMd

        Label {
            text: "Security Architecture & Cryptographic Keys"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontHeader
            font.weight: Typography.weightBold
            color: themePalette.textPrimary
            Accessible.role: Accessible.Heading
            Accessible.name: "Security & Keys Title"
        }

        Label {
            text: "Real-time state for ChaCha20-Poly1305 AEAD cipher, X25519 ECDH key exchange, and STUN/ICE NAT connection mode."
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontBody
            color: themePalette.textSecondary
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            color: themePalette.surface
            radius: Metrics.radiusSm
            border.color: themePalette.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingMd
                spacing: Metrics.spacingSm

                Label { text: "Encryption Cipher: ChaCha20-Poly1305 AEAD (256-bit key)"; font.weight: Typography.weightBold; color: themePalette.success }
                Label { text: "Key Agreement: X25519 ECDH Key Exchange"; color: themePalette.textPrimary }
                Label { text: "Protocol Magic: RAP0 (0x52415030)"; color: themePalette.textSecondary }
                Label { text: "Replay & Tamper Protection: Active (12-byte monotonic IV + 16-byte Poly1305 Tag)"; color: themePalette.textSecondary }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: themePalette.surface
            radius: Metrics.radiusSm
            border.color: themePalette.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingMd
                spacing: Metrics.spacingSm

                Label { text: "NAT Traversal & ICE Connection Mode"; font.weight: Typography.weightBold; color: themePalette.textPrimary }
                Label { text: "Active Mode: Direct Local / STUN UDP Hole Punching (Fallback to Stateless Relay)"; color: themePalette.textSecondary }
                Label { text: "STUN Server: stun.l.google.com:19302 / RFC 5389 Binding Client"; color: themePalette.textSecondary }
                Label { text: "Stateless Relay Endpoint: 127.0.0.1:18445 (Zero-Decryption E2E Preserved)"; color: themePalette.textSecondary }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
