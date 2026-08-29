#include "FileTransferEngine.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>

namespace fs = std::filesystem;

namespace rap::file_transfer {

// Helper: Lightweight SHA-256 Implementation for standalone chunk & file verification
static std::string computeSha256(const uint8_t* data, size_t length) {
    // SHA-256 initial hash values
    uint32_t h[8] = {0x6a09e667,
                     0xbb67ae85,
                     0x3c6ef372,
                     0xa54ff53a,
                     0x510e527f,
                     0x9b05688c,
                     0x1f83d9ab,
                     0x5be0cd19};

    // K constants
    static const uint32_t k[64] = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
        0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe,
        0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
        0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
        0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
        0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
        0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116,
        0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
        0xc67178f2};

    auto rightRotate = [](uint32_t x, uint32_t n) { return (x >> n) | (x << (32 - n)); };

    std::vector<uint8_t> padded(data, data + length);
    padded.push_back(0x80);
    while ((padded.size() % 64) != 56) {
        padded.push_back(0x00);
    }

    uint64_t bitLength = length * 8;
    for (int i = 7; i >= 0; --i) {
        padded.push_back(static_cast<uint8_t>((bitLength >> (i * 8)) & 0xFF));
    }

    for (size_t chunk = 0; chunk < padded.size(); chunk += 64) {
        uint32_t w[64];
        for (int i = 0; i < 16; ++i) {
            w[i] = (padded[chunk + i * 4 + 0] << 24) | (padded[chunk + i * 4 + 1] << 16) |
                   (padded[chunk + i * 4 + 2] << 8) | (padded[chunk + i * 4 + 3]);
        }
        for (int i = 16; i < 64; ++i) {
            uint32_t s0 = rightRotate(w[i - 15], 7) ^ rightRotate(w[i - 15], 18) ^ (w[i - 15] >> 3);
            uint32_t s1 = rightRotate(w[i - 2], 17) ^ rightRotate(w[i - 2], 19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16] + s0 + w[i - 7] + s1;
        }

        uint32_t a = h[0], b = h[1], c = h[2], d = h[3];
        uint32_t e = h[4], f = h[5], g = h[6], h_val = h[7];

        for (int i = 0; i < 64; ++i) {
            uint32_t S1 = rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25);
            uint32_t ch = (e & f) ^ ((~e) & g);
            uint32_t temp1 = h_val + S1 + ch + k[i] + w[i];
            uint32_t S0 = rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22);
            uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
            uint32_t temp2 = S0 + maj;

            h_val = g;
            g = f;
            f = e;
            e = d + temp1;
            d = c;
            c = b;
            b = a;
            a = temp1 + temp2;
        }

        h[0] += a;
        h[1] += b;
        h[2] += c;
        h[3] += d;
        h[4] += e;
        h[5] += f;
        h[6] += g;
        h[7] += h_val;
    }

    std::ostringstream ss;
    for (int i = 0; i < 8; ++i) {
        ss << std::hex << std::setw(8) << std::setfill('0') << h[i];
    }
    return ss.str();
}

std::string FileTransferEngine::calculateSha256(const std::vector<uint8_t>& data) {
    return computeSha256(data.data(), data.size());
}

std::string FileTransferEngine::calculateFileSha256(const std::string& filePath) {
    std::ifstream file(filePath, std::ios::binary);
    if (!file)
        return "";
    std::vector<uint8_t> buffer((std::istreambuf_iterator<char>(file)),
                                std::istreambuf_iterator<char>());
    return computeSha256(buffer.data(), buffer.size());
}

std::vector<DirectoryItem> FileTransferEngine::listDirectory(const std::string& dirPath) {
    std::vector<DirectoryItem> items;
    fs::path targetPath = dirPath.empty() ? fs::current_path() : fs::path(dirPath);

    if (!fs::exists(targetPath) || !fs::is_directory(targetPath)) {
        return items;
    }

    for (const auto& entry : fs::directory_iterator(targetPath)) {
        DirectoryItem item;
        item.name = entry.path().filename().string();
        item.isDirectory = entry.is_directory();
        if (!item.isDirectory && entry.is_regular_file()) {
            item.size = entry.file_size();
        }
        item.modifiedTime = std::chrono::duration_cast<std::chrono::seconds>(
                                entry.last_write_time().time_since_epoch())
                                .count();
        items.push_back(item);
    }

    std::sort(items.begin(), items.end(), [](const DirectoryItem& a, const DirectoryItem& b) {
        if (a.isDirectory != b.isDirectory)
            return a.isDirectory > b.isDirectory;
        return a.name < b.name;
    });

    return items;
}

std::vector<FileChunk> FileTransferEngine::prepareFileChunks(const std::string& transferId,
                                                             const std::string& filePath,
                                                             size_t chunkSize) {
    std::vector<FileChunk> chunks;
    std::ifstream file(filePath, std::ios::binary);
    if (!file)
        return chunks;

    file.seekg(0, std::ios::end);
    uint64_t totalSize = file.tellg();
    file.seekg(0, std::ios::beg);

    uint64_t offset = 0;
    uint32_t chunkIndex = 0;

    while (offset < totalSize) {
        size_t currentChunkSize = std::min<uint64_t>(chunkSize, totalSize - offset);
        FileChunk chunk;
        chunk.transferId = transferId;
        chunk.chunkIndex = chunkIndex++;
        chunk.offset = offset;
        chunk.totalSize = totalSize;
        chunk.data.resize(currentChunkSize);

        file.read(reinterpret_cast<char*>(chunk.data.data()), currentChunkSize);
        chunk.sha256Hash = calculateSha256(chunk.data);
        offset += currentChunkSize;
        chunk.isLastChunk = (offset >= totalSize);

        chunks.push_back(chunk);
    }

    return chunks;
}

bool FileTransferEngine::writeChunkToFile(const std::string& filePath,
                                          uint64_t offset,
                                          const std::vector<uint8_t>& data) {
    std::fstream file;
    if (offset == 0) {
        file.open(filePath, std::ios::out | std::ios::binary);
    } else {
        file.open(filePath, std::ios::in | std::ios::out | std::ios::binary);
    }

    if (!file.is_open())
        return false;

    file.seekp(offset, std::ios::beg);
    file.write(reinterpret_cast<const char*>(data.data()), data.size());
    file.flush();
    return true;
}

bool FileTransferEngine::verifyIntegrity(const std::string& filePath,
                                         const std::string& expectedSha256) {
    std::string actualHash = calculateFileSha256(filePath);
    return actualHash == expectedSha256;
}

} // namespace rap::file_transfer
