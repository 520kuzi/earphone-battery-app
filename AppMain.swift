import SwiftUI

@main
struct EarphoneBatteryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var bt = BatteryManager()
    
    var body: some View {
        NavigationView {
            List {
                Section("当前耳机状态") {
                    HStack {
                        Text("连接状态")
                        Spacer()
                        Text(bt.isConnected ? "已连接" : "搜索耳机中...")
                            .foregroundColor(bt.isConnected ? .green : .secondary)
                    }
                    HStack {
                        Text("实时电量")
                        Spacer()
                        Text(bt.currentBattery >= 0 ? "\(bt.currentBattery)%" : "--")
                            .font(.title3)
                            .bold()
                            .foregroundColor(bt.currentBattery > 20 ? .blue : .red)
                    }
                    if let session = bt.activeSession {
                        HStack {
                            Text("起始电量")
                            Spacer()
                            Text("\(session.startBattery)%")
                        }
                    }
                }
                
                Section("历史续航与耗电统计") {
                    if bt.sessions.isEmpty {
                        Text("暂无数据，断开连接后自动保存")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(bt.sessions) { session in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(session.startTime, style: .time) + Text(" - ") + Text(session.endTime ?? Date(), style: .time)
                                    Spacer()
                                    Text("\(session.durationMinutes) 分钟")
                                        .bold()
                                }
                                HStack {
                                    Text("电量变化: \(session.startBattery)% -> \(session.endBattery ?? 0)%")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("耗电: \(session.consumedBattery)%")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("耳机续航管家")
        }
    }
}