@testable import OSAT_VideoCompositor
import XCTest
import AVFoundation

class AVPlayerTests: XCTestCase {
    var videoPlayer: MoviePlayer!
    var url: URL!
    var playerLayer: AVPlayerView!
    
    override func setUp() {
        super.setUp()
        url = URL(string: "https://jplayer.org/video/m4v/Big_Buck_Bunny_Trailer.m4v")!
        playerLayer = AVPlayerView(frame: .zero, url: url)
        videoPlayer = MoviePlayer(customPlayerView: playerLayer)
    }
    
    func testVideoPlayerPlayAndPauseAction() throws {
        let player = try XCTUnwrap(playerLayer.getPlayer())
        
        XCTAssertNotNil(player.currentItem)
        
        videoPlayer.play()
        XCTAssertTrue(playerLayer.isVideoPlaying)
        videoPlayer.pause()
        XCTAssertFalse(playerLayer.isVideoPlaying)
    }
    
    func testMemoryLeak() {
        var customPlayerLayer: AVPlayerView? = AVPlayerView(frame: .zero, url: url)
        customPlayerLayer?.play()
        
        // this holds weak reference and doesn't increase ARC count
        weak var customSecondLayer = customPlayerLayer
        
        // making the instance nil
        customPlayerLayer = nil
        
        XCTAssertNil(customSecondLayer)
    }
    
    func testReplaceItemTest() throws {
        let currentItem = try XCTUnwrap(playerLayer.avPlayerItem)
        let player = try XCTUnwrap(playerLayer.player)
        
        videoPlayer.play()
        videoPlayer.set(url: URL(string: "https://jplayer.org/video/m4v/Big_Buck_Bunny_Trailer.m4v")!)
        let newItem = try XCTUnwrap(playerLayer.avPlayerItem)
        let newPlayer = try XCTUnwrap(playerLayer.player)
        
        XCTAssertNotIdentical(currentItem, newItem)
        XCTAssertIdentical(player, newPlayer)
    }
    
    func testSeekApi() throws {
        let fakeDelegate = FakeAVPlayerCustomViewDelegate()
        playerLayer.delegate = fakeDelegate
        playerLayer.registerTimeIntervalForObservingPlayer(1)
        playerLayer.play()
        playerLayer.seek(to: CMTime(seconds: 1, preferredTimescale: 1000))
        XCTAssertTrue(fakeDelegate.isSuccessFul)
    }
    
    func testDurationOfVideo() async throws {
        let duration = try await playerLayer.getDuration()
        XCTAssertNotNil(duration)
    }
}

class FakeAVPlayerCustomViewDelegate: AVPlayerCustomViewDelegate {
    var isSuccessFul = false
    func avPlayerCustomView(_ avPlayerView: OSAT_VideoCompositor.AVPlayerCustomView, didSeek isSuccess: Bool) {
        isSuccessFul = isSuccess
    }
    
    var didReceiveTime = false
    func avPlayerCustomView(_ avPlayerView: OSAT_VideoCompositor.AVPlayerCustomView, didReceivePlayBack time: CMTime) {
        didReceiveTime = true
    }
}
