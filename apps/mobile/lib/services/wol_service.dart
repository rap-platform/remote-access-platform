import 'dart:io';

class WakeOnLanService {
  static Future<bool> sendMagicPacket(String macAddress) async {
    try {
      String cleanMac = macAddress.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
      if (cleanMac.length != 12) return false;

      List<int> macBytes = [];
      for (int i = 0; i < 12; i += 2) {
        macBytes.add(int.parse(cleanMac.substring(i, i + 2), radix: 16));
      }

      List<int> magicPacket = List.filled(6, 0xFF);
      for (int i = 0; i < 16; i++) {
        magicPacket.addAll(macBytes);
      }

      RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(magicPacket, InternetAddress("255.255.255.255"), 9);
      socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
