//
//  ContentView.swift
//  adbconnect
//
//  Created by Naman Dwivedi on 10/03/21.
//

import AppKit
import SwiftUI

struct ContentView: View {
    let adb = AdbHelper()

    @State private var devices: [Device] = []

    @State private var statusMessage: String = ""

    var body: some View {
        DispatchQueue.global(qos: .background).async {
            devices = adb.getDevices()
        }
        return VStack {
            ScrollView(.vertical) {
                if devices.isEmpty {
                    NoDevicesView()
                } else {
                    ForEach(devices, id: \.id) { device in
                        DeviceActionsView(adb: adb, device: device, statusMessaage: $statusMessage, devices: $devices)
                    }
                }
            }.padding(.leading, 15).padding(.trailing, 5).padding(.top, 15)
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 15)
                    .font(.subheadline)
            }
        }.padding(.bottom, statusMessage.isEmpty ? 0 : 10)
    }
}

struct DeviceActionsView: View {
    var adb: AdbHelper
    var device: Device

    @Binding var statusMessaage: String
    @Binding var devices: [Device]

    @State private var deeplink: String = ""
    @State private var showAdvanced: Bool = false
    @State private var isRecordingScreen: Bool = false

    private func isTcpConnected() -> Bool {
        // if already connected over tcp, name would contain the port on which we connected
        return device.id.contains("5555")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // device info
            HStack(alignment: .top) {
                Text(device.name)
                Text("-")
                Text(device.id)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 5)

            // tcp connection
            HStack(alignment: .top) {
                Image("WifiIcon").resizable().frame(width: 18.0, height: 18.0)
                isTcpConnected()
                    ? Text("Disconnect remote connection")
                    : Text("Establish remote connection")
            }.contentShape(Rectangle())
                .onTapGesture {
                    if isTcpConnected() {
                        statusMessaage = "Disconnected remoted connection"
                        adb.disconnectTCPConnection(deviceId: device.id)
                    } else {
                        statusMessaage = "Connected to adb remotely"
                        adb.makeTCPConnection(deviceId: device.id)
                    }
                    // refresh device list
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        devices = adb.getDevices()
                    }
                }

            // screenshot
            HStack(alignment: .top) {
                Image("ScreenshotIcon").resizable().frame(width: 18.0, height: 18.0)
                Text("Take screenshot")
            }.contentShape(Rectangle())
                .onTapGesture {
                    statusMessaage = "Screenshot will be saved in Desktop"
                    adb.takeScreenshot(deviceId: device.id)
                }

            // screenshot
            HStack(alignment: .top) {
                Image("PasteIcon").resizable().frame(width: 18.0, height: 18.0)
                Text("Copy screenshot in your clipboard")
            }.contentShape(Rectangle())
                .onTapGesture {
                    statusMessaage = "Screenshot will be copied in your clipboard"
                    // Copying image data from paste board
                    adb.takeScreenshotAndCopyIt(deviceId: device.id)
                }

            // record screen
            HStack(alignment: .top) {
                Image("RecordIcon").resizable().frame(width: 18.0, height: 18.0)
                Text(isRecordingScreen ? "Recording screen... Click to stop and save recording" : "Record screen")
            }.contentShape(Rectangle())
                .onTapGesture {
                    if isRecordingScreen {
                        statusMessaage = "Recording will be saved in Desktop"
                        adb.stopScreenRecording(deviceId: device.id)
                        isRecordingScreen = false
                    } else {
                        statusMessaage = "Started recording screen.."
                        adb.recordScreen(deviceId: device.id)
                        isRecordingScreen = true
                    }
                }

            // advanced options
            HStack(alignment: .top) {
                Image("SettingsIcon").resizable().frame(width: 18.0, height: 18.0)
                Text(showAdvanced ? "Hide more options" : "Show more options")
                    .font(showAdvanced ? Font.body.bold() : Font.body)
            }.contentShape(Rectangle())
                .onTapGesture {
                    showAdvanced = !showAdvanced
                }
            if showAdvanced {
                // open deeplink
                HStack(alignment: .top) {
                    Image("DeeplinkIcon").resizable().frame(width: 18.0, height: 18.0)
                    TextField("deeplink", text: $deeplink).padding(.leading, 5)
                    Button(action: {
                        statusMessaage = "Opening deeplink.."
                        adb.openDeeplink(deviceId: device.id, deeplink: deeplink)
                    }, label: {
                        Text("Open")
                    })
                }.padding(.leading, 20)

                // capture bugreport
                HStack(alignment: .top) {
                    Image("BugreportIcon").resizable().frame(width: 18.0, height: 18.0)
                    Text("Capture logcat")
                }.contentShape(Rectangle()).padding(.leading, 20)
                    .onTapGesture {
                        statusMessaage = "Logcat saved in Desktop"
                        adb.captureBugReport(deviceId: device.id)
                    }
            }

        }.padding(.bottom, 15)
    }
}

struct NoDevicesView: View {
    var body: some View {
        VStack {
            Text("No devices connected").frame(maxWidth: .infinity, alignment: .center).padding(.top, 20)
            Image("UsbOffIcon").resizable().frame(width: 54.0, height: 54.0, alignment: .center).padding(.top, 15)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
