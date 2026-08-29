#include "FileTransferEngine.h"
#include <cassert>
#include <fstream>
#include <iostream>
#include <filesystem>

namespace fs = std::filesystem;

void testSha256Calculation() {
    std::cout << "[+] Test 1: SHA-256 Digest Calculation..." << std::endl;
    std::string testString = "Remote Access Platform File Transfer Test";
    std::vector<uint8_t> data(testString.begin(), testString.end());
    std::string hash = rap::file_transfer::FileTransferEngine::calculateSha256(data);
    assert(!hash.empty());
    assert(hash.length() == 64);
    std::cout << "    SHA-256 Digest: " << hash << " [PASSED]" << std::endl;
}

void testDirectoryListing() {
    std::cout << "[+] Test 2: Directory Listing..." << std::endl;
    auto items = rap::file_transfer::FileTransferEngine::listDirectory(".");
    assert(!items.empty());
    std::cout << "    Found " << items.size() << " items in workspace directory [PASSED]" << std::endl;
}

void testFileChunkingAndAssembly() {
    std::cout << "[+] Test 3: File Chunking & Assembly..." << std::endl;
    std::string tempSource = "test_file_transfer_source.tmp";
    std::string tempDest = "test_file_transfer_dest.tmp";

    // Create 128KB dummy payload
    std::vector<uint8_t> testData(128 * 1024);
    for (size_t i = 0; i < testData.size(); ++i) {
        testData[i] = static_cast<uint8_t>(i % 256);
    }

    {
        std::ofstream file(tempSource, std::ios::binary);
        file.write(reinterpret_cast<const char *>(testData.data()), testData.size());
    }

    std::string sourceHash = rap::file_transfer::FileTransferEngine::calculateFileSha256(tempSource);
    auto chunks = rap::file_transfer::FileTransferEngine::prepareFileChunks("tx-001", tempSource, 32 * 1024);
    assert(chunks.size() == 4);

    for (const auto &chunk : chunks) {
        bool ok = rap::file_transfer::FileTransferEngine::writeChunkToFile(tempDest, chunk.offset, chunk.data);
        assert(ok);
        (void)ok;
    }

    bool verified = rap::file_transfer::FileTransferEngine::verifyIntegrity(tempDest, sourceHash);
    assert(verified);
    (void)verified;

    fs::remove(tempSource);
    fs::remove(tempDest);
    std::cout << "    4 chunks of 32KB assembled and SHA-256 verified successfully [PASSED]" << std::endl;
}

int main() {
    std::cout << "=== Running File Transfer Unit Tests ===" << std::endl;
    testSha256Calculation();
    testDirectoryListing();
    testFileChunkingAndAssembly();
    std::cout << "=== All File Transfer Unit Tests Passed! ===" << std::endl;
    return 0;
}
