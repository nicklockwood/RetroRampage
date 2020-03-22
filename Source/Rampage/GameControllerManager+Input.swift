//
//  GameControllerManager+Input.swift
//  Rampage
//
//  Created by PJ COOK on 23/03/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Engine
import Foundation

extension GameControllerManager {
    func input(turningSpeed: Double, worldTimeStep: Double) -> Input? {
        guard let controller = gameController?.extendedGamepad else { return nil }

        let leftInput = controller.leftThumbstick
        let rightInput = controller.rightThumbstick
        let rotation = Double(rightInput.xAxis.value) * turningSpeed * worldTimeStep
        let isFiring = controller.rightTrigger.isPressed

        /*
         If you implement the dual stick touch control PR then use the following for "speed"
         Vector(x: Double(leftInput.xAxis.value), y: Double(leftInput.yAxis.value))

         Implementing the 2 stick approach allows you to strafe, which is awesome!
         */
        return Input(
            speed: Double(leftInput.yAxis.value),
            rotation: Rotation(sine: sin(rotation), cosine: cos(rotation)),
            isFiring: isFiring
        )
    }
}
