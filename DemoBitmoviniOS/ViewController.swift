//
//  ViewController.swift
//  BitmovinDemo
//
//  Created by José Alberto González Gordillo on 5/15/19.
//  Copyright © 2019 José Alberto González Gordillo. All rights reserved.
//

import UIKit
import BitmovinPlayer
import Alamofire

enum BitmovinErrors: Error {
    case unableToConfigure
    case unableToCreateDRMConfig
    case unableToCreateHLSSource
}

final class ViewController: UIViewController {

    var player: BitmovinPlayer?
    var testView: UIView!
    let certificateURL = "https://lic.drmtoday.com/license-server-fairplay/cert/cinepolis"
    let licenseURL = "https://lic.drmtoday.com/license-server-fairplay/"


    deinit {
        player?.destroy()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black

        //select type content.
        self.playKlicContent()
    }

}

//KLIC
extension ViewController {

    func playKlicContent() {
        let config = PlayerConfiguration()
        config.styleConfiguration.userInterfaceType = .bitmovin
        do {
            let fpsConfig = try self.createPlayerConfig(licenseURL: licenseURL,
                                                        certificateURL: certificateURL)
            let base64 = self.prepareHeaderKlic()
            fpsConfig.licenseRequestHeaders = ["x-dt-custom-data": base64]
            let hlsSource = try self.createHLSSource(url: "https://hlscf.cinepolisklic.com/usp-s3-storage/clear/peter-rabbit-conejos-en-fuga/peter-rabbit-conejos-en-fuga_fp.ism/.m3u8")

            let sourceItem = SourceItem(hlsSource: hlsSource)
            let drmConfig = try self.createDRMConfiguration(licenseURL: licenseURL)
            fpsConfig.prepareContentId = { (contentId: String) -> String in
                print("contentId: \(contentId)")
                let pattern = "skd://drmtoday?"
                let contentId = String(contentId[pattern.endIndex...])
                print("contentId: \(contentId)")
                return contentId
            }


            fpsConfig.prepareMessage = { (data: Data, contentId: String) -> Data in
                let base64String = data.base64EncodedString()
                guard let uriEncodedMessage =
                    base64String.addingPercentEncoding(withAllowedCharacters:
                        CharacterSet.alphanumerics) else { return Data() }
                let message = "spc=\(uriEncodedMessage)&\(contentId)"
                if let dataMessage = message.data(using: String.Encoding.utf8) {
                    return dataMessage
                } else {
                    return Data()
                }
            }
            config.playbackConfiguration.isAutoplayEnabled = true
            sourceItem.add(drmConfiguration: drmConfig)
            sourceItem.add(drmConfiguration: fpsConfig)
            //sourceItem.itemTitle = "Prueba"
            config.sourceItem = sourceItem
            self.createPlayer(config: config)
        } catch {
            print(error)
        }
    }

    func prepareHeaderKlic() -> String  {
        let userData = #"{"sessionId":"EFIPBo7VDf","userId":"11514946","merchant":"cinepolis"}"#
        let data = (userData).data(using: String.Encoding.utf8)
        if let userData = data {
            return userData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        } else {
            return ""
        }
    }

    func createPlayerConfig(licenseURL:String, certificateURL:String) throws -> FairplayConfiguration {
        guard let certificateUrl = URL(string: certificateURL),
            let licenseUrl = URL(string: licenseURL) else { throw  BitmovinErrors.unableToConfigure}
        return FairplayConfiguration(license: licenseUrl, certificateURL: certificateUrl)
    }

    func createHLSSource(url:String) throws -> HLSSource {
        guard let fairplayStreamUrl = URL(string: url) else { throw BitmovinErrors.unableToCreateHLSSource }
        return HLSSource(url: fairplayStreamUrl)
    }

    func createDRMConfiguration(licenseURL :String) throws -> DRMConfiguration {
        guard let licenseUrl = URL(string: licenseURL) else { throw  BitmovinErrors.unableToCreateDRMConfig}
        return DRMConfiguration(license: licenseUrl, uuid: UUID())
    }

    func createPlayer(config: PlayerConfiguration) {
        let player = BitmovinPlayer(configuration: config)
        let playerView = BMPBitmovinPlayerView(player: player, frame: .zero)
        player.add(listener: self)
        playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        playerView.frame = view.bounds
        view.addSubview(playerView)
        view.bringSubviewToFront(playerView)
        self.player = player
    }

    func configureStyle( config: inout PlayerConfiguration) {
          config.styleConfiguration.isUiEnabled = false
          config.styleConfiguration.userInterfaceType = .subtitle
      }
}

// MARK: - PlayerListener
extension ViewController: PlayerListener {

    func onPlay(_ event: PlayEvent) {
        print("onPlay \(event.time)")
    }

    func onPaused(_ event: PausedEvent) {
        print("onPaused \(event.time)")
    }

    func onTimeChanged(_ event: TimeChangedEvent) {
        print("onTimeChanged \(event.currentTime)")
    }

    func onDurationChanged(_ event: DurationChangedEvent) {
        print("onDurationChanged \(event.duration)")
    }

    func onError(_ event: ErrorEvent) {
        print("onError \(event.message)")
    }
}
