import ReplayKit

class ReplayKitHostExtension: RPBroadcastSampleHandler {
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        print("[RAPHostAgent] iOS ReplayKit Broadcast Extension Session Started")
    }
    
    override func broadcastPaused() {
        print("[RAPHostAgent] iOS ReplayKit Session Paused")
    }
    
    override func broadcastResumed() {
        print("[RAPHostAgent] iOS ReplayKit Session Resumed")
    }
    
    override func broadcastFinished() {
        print("[RAPHostAgent] iOS ReplayKit Session Finished")
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            // Process live iOS screen video sample buffer
            break
        case .audioApp, .audioMic:
            break
        @unknown default:
            break
        }
    }
}
