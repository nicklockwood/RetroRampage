//
//  GameControllerManager.swift
//  Rampage
//
//  Created by PJ COOK on 23/03/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import GameController

class GameControllerManager {
    var gameController: GCController?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(controllerConnected), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDisconnected), name: .GCControllerDidDisconnect, object: nil)
        GCController.startWirelessControllerDiscovery()
    }
}

extension GameControllerManager {
    @objc private func controllerConnected(_ note: Notification) {
        GCController.stopWirelessControllerDiscovery()
        gameController = note.object as? GCController
    }

    @objc private func controllerDisconnected(_ note: Notification) {
        GCController.startWirelessControllerDiscovery()
        gameController = nil
    }
}
