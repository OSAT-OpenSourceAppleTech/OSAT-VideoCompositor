@testable import OSAT_VideoCompositor
import XCTest

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
    }
}
