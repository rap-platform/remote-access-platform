#ifndef RAP_AGENT_MULTI_USER_SESSION_MANAGER_H
#define RAP_AGENT_MULTI_USER_SESSION_MANAGER_H

#include <algorithm>
#include <iostream>
#include <mutex>
#include <string>
#include <vector>

namespace rap::agent {

struct SessionObserver {
    std::string observerId;
    std::string ipAddress;
    bool isController{false};
};

class MultiUserSessionManager {
public:
    MultiUserSessionManager() = default;

    void addObserver(const std::string& observerId,
                     const std::string& ipAddress,
                     bool isController = false) {
        std::lock_guard<std::mutex> lock(mutex_);
        observers_.push_back({observerId, ipAddress, isController});
        std::cout << "[Agent MultiUser] Observer connected: " << observerId << " (" << ipAddress
                  << ")" << std::endl;
    }

    void removeObserver(const std::string& observerId) {
        std::lock_guard<std::mutex> lock(mutex_);
        observers_.erase(std::remove_if(observers_.begin(),
                                        observers_.end(),
                                        [&](const SessionObserver& obs) {
                                            return obs.observerId == observerId;
                                        }),
                         observers_.end());
    }

    size_t observerCount() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return observers_.size();
    }

private:
    std::vector<SessionObserver> observers_;
    mutable std::mutex mutex_;
};

} // namespace rap::agent

#endif // RAP_AGENT_MULTI_USER_SESSION_MANAGER_H
