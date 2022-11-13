import OSAT_VideoCompositor
import XCTest

class VideoPlayerTests: XCTestCase {
    var videoPlayer: VideoPlayer!
    var url: URL!
    override func setUp() {
        super.setUp()
        url = Bundle.main.url(forResource: "Demo", withExtension: "mp4")!
        videoPlayer = VideoPlayer(frame: .zero, url: url)
    }
    
    func testVideoPlayerPlayAndPauseAction() throws {
        let player = try XCTUnwrap(videoPlayer.getPlayer())
        let playButton = videoPlayer.getPlayButton()
        
        XCTAssertNotNil(player.currentItem)
        XCTAssertFalse(playButton.isSelected)
        
        videoPlayer.play()
        
        // for pause icon - state should be false
        XCTAssertFalse(playButton.isSelected)
        
        // for play icon - state should be true
        videoPlayer.pause()
        XCTAssertTrue(playButton.isSelected)
    }
}
