//
//  AdbHelper.swift
//  adbconnect
//
//  Created by Naman Dwivedi on 11/03/21.
//

import AppKit
import Foundation

class AdbHelper {
    let adb = Bundle.main.url(forResource: "adb", withExtension: nil)

    func getDevices() -> [Device] {
        let command = "devices -l | awk 'NR>1 {print $1}'"
        let devicesResult = runAdbCommand(command)
        return devicesResult
            .components(separatedBy: .newlines)
            .filter { id -> Bool in
                !id.isEmpty
            }
            .map { id -> Device in
                Device(id: id, name: getDeviceName(deviceId: id))
            }
    }

    func getDeviceName(deviceId: String) -> String {
        let command = "-s " + deviceId + " shell getprop ro.product.model"
        return runAdbCommand(command)
    }

    func takeScreenshot(deviceId: String) {
        let time = formattedTime()
        _ = runAdbCommand("-s " + deviceId + " shell screencap -p /sdcard/screencap_adbtool.png")
        _ = runAdbCommand("-s " + deviceId + " pull /sdcard/screencap_adbtool.png ~/Desktop/screen" + time + ".png")
    }

    func takeScreenshotAndCopyIt(deviceId: String) {
        let time = formattedTime()
        let path = "~/Desktop/screen" + time + ".png"
        _ = runAdbCommand("-s " + deviceId + " shell screencap -p /sdcard/screencap_adbtool.png")
        _ = runAdbCommand("-s " + deviceId + " pull /sdcard/screencap_adbtool.png \(path)")

        let absolutePath = NSString(string: path).expandingTildeInPath
        do {
            try copyToPastboard(data: Data(contentsOf: URL(fileURLWithPath: "\(absolutePath)")))
            try FileManager.default.removeItem(atPath: "\(absolutePath)")
        } catch {
            print("Error opening file: \(error)")
        }
    }

    func recordScreen(deviceId: String) {
        let command = "-s " + deviceId + " shell screenrecord /sdcard/screenrecord_adbtool.mp4"

        // run record screen in background
        DispatchQueue.global(qos: .background).async {
            _ = self.runAdbCommand(command)
        }
    }

    func stopScreenRecording(deviceId: String) {
        let time = formattedTime()

        // kill already running screenrecord process to stop recording
        _ = runAdbCommand("-s " + deviceId + " shell pkill -INT screenrecord")

        // after killing the screenrecord process,we have to for some time
        // before pulling the file else file stays corrupted
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            _ = self.runAdbCommand("-s " + deviceId +
                " pull /sdcard/screenrecord_adbtool.mp4 ~/Desktop/record" + time + ".mp4")
        }
    }

    func makeTCPConnection(deviceId: String) {
        DispatchQueue.global(qos: .background).async {
            let deviceIp = self.getDeviceIp(deviceId: deviceId)
            let tcpCommand = "-s " + deviceId + " tcpip 5555"
            _ = self.runAdbCommand(tcpCommand)
            let connectCommand = "-s " + deviceId + " connect " + deviceIp + ":5555"
            _ = self.runAdbCommand(connectCommand)
        }
    }

    func disconnectTCPConnection(deviceId: String) {
        DispatchQueue.global(qos: .background).async {
            _ = self.runAdbCommand("-s " + deviceId + " disconnect")
        }
    }

    func getDeviceIp(deviceId: String) -> String {
        let command = "-s " + deviceId + " shell ip route | awk '{print $9}'"
        return runAdbCommand(command)
    }

    func openDeeplink(deviceId: String, deeplink: String) {
        let command = "-s " + deviceId + " shell am start -a android.intent.action.VIEW -d '" + deeplink + "'"
        _ = runAdbCommand(command)
    }

    func captureBugReport(deviceId: String) {
        let time = formattedTime()
        DispatchQueue.global(qos: .background).async {
            _ = self.runAdbCommand("-s " + deviceId + " logcat -d > ~/Desktop/logcat" + time + ".txt")
        }
    }

    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm"
        let time = formatter.string(from: Date())
        return time
    }

    private func runAdbCommand(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", adb!.path + " " + command]
        task.launchPath = "/bin/sh"
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
        return output
    }

    func copyToPastboard(data: Data) {
        let pastboard = NSPasteboard.general
        pastboard.declareTypes([.png], owner: nil)

        pastboard.setData(data, forType: NSPasteboard.PasteboardType.png)
    }
}
