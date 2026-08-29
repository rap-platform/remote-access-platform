#ifndef RAP_FILE_TRANSFER_ENGINE_H
#define RAP_FILE_TRANSFER_ENGINE_H

#include <cstdint>
#include <string>
#include <vector>

namespace rap::file_transfer {

struct DirectoryItem {
    std::string name;
    uint64_t size{0};
    bool isDirectory{false};
    uint64_t modifiedTime{0};
};

struct FileChunk {
    std::string transferId;
    uint32_t chunkIndex{0};
    uint64_t offset{0};
    uint64_t totalSize{0};
    std::vector<uint8_t> data;
    std::string sha256Hash;
    bool isLastChunk{false};
};

enum class TransferControlAction { Pause = 1, Resume = 2, Cancel = 3 };

class FileTransferEngine {
public:
    static std::string calculateSha256(const std::vector<uint8_t>& data);
    static std::string calculateFileSha256(const std::string& filePath);

    static std::vector<DirectoryItem> listDirectory(const std::string& dirPath);

    static std::vector<FileChunk> prepareFileChunks(const std::string& transferId,
                                                    const std::string& filePath,
                                                    size_t chunkSize = 65536);

    static bool writeChunkToFile(const std::string& filePath,
                                 uint64_t offset,
                                 const std::vector<uint8_t>& data);

    static bool verifyIntegrity(const std::string& filePath, const std::string& expectedSha256);
};

} // namespace rap::file_transfer

#endif // RAP_FILE_TRANSFER_ENGINE_H
