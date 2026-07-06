//
//  SocketService.swift
//  ServiceMapCustomer
//

import Foundation
import Starscream

class SocketService: ObservableObject {
    static let shared = SocketService()
    
    private var socket: WebSocket?
    private let baseURL: String
    
    @Published var isConnected = false
    @Published var messages: [Message] = []
    
    init(baseURL: String = ProcessInfo.processInfo.environment["WS_BASE_URL"] ?? "ws://localhost:3000") {
        self.baseURL = baseURL
    }
    
    func connect(token: String) {
        guard let url = URL(string: "\(baseURL)?token=\(token)") else { return }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        
        socket?.onEvent = { [weak self] event in
            switch event {
            case .connected(_):
                DispatchQueue.main.async {
                    self?.isConnected = true
                }
                print("✅ WebSocket connected")
                
            case .disconnected(_, _):
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
                print("❌ WebSocket disconnected")
                
            case .text(let string):
                self?.handleMessage(string)
                
            case .binary(let data):
                print("Received binary data: \(data.count) bytes")
                
            case .ping(_):
                break
                
            case .pong(_):
                break
                
            case .error(let error):
                print("WebSocket error: \(error?.localizedDescription ?? "Unknown")")
                
            case .viabilityChanged(_):
                break
                
            case .reconnectSuggested(_):
                break
                
            case .peerClosed:
                print("Peer closed connection")
                
            @unknown default:
                break
            }
        }
        
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        isConnected = false
    }
    
    func joinBookingRoom(bookingId: String) {
        send(event: "join-booking", data: ["bookingId": bookingId])
    }
    
    func updateLocation(bookingId: String, latitude: Double, longitude: Double) {
        send(event: "provider-location", data: [
            "bookingId": bookingId,
            "latitude": latitude,
            "longitude": longitude
        ])
    }
    
    func updateBookingStatus(bookingId: String, status: String) {
        send(event: "booking-status-update", data: [
            "bookingId": bookingId,
            "status": status
        ])
    }
    
    func sendMessage(receiverId: String, content: String, bookingId: String? = nil) {
        var data: [String: Any] = [
            "receiverId": receiverId,
            "content": content
        ]
        
        if let bookingId = bookingId {
            data["bookingId"] = bookingId
        }
        
        send(event: "send-message", data: data)
    }
    
    private func send(event: String, data: [String: Any]) {
        guard isConnected else {
            print("⚠️ Cannot send: WebSocket not connected")
            return
        }
        
        do {
            let payload: [String: Any] = ["event": event, "data": data]
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                socket?.write(string: jsonString)
            }
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    private func handleMessage(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let event = json["event"] as? String {
                
                switch event {
                case "location-update":
                    handleLocationUpdate(json)
                    
                case "status-update":
                    handleStatusUpdate(json)
                    
                case "message-sent":
                    handleMessageSent(json)
                    
                case "new-message":
                    handleNewMessage(json)
                    
                default:
                    print("Unknown event: \(event)")
                }
            }
        } catch {
            print("Error parsing message: \(error)")
        }
    }
    
    private func handleLocationUpdate(_ json: [String: Any]) {
        // Notify view models about location update
        NotificationCenter.default.post(
            name: NSNotification.Name("ProviderLocationUpdated"),
            object: nil,
            userInfo: json
        )
    }
    
    private func handleStatusUpdate(_ json: [String: Any]) {
        // Notify view models about status update
        NotificationCenter.default.post(
            name: NSNotification.Name("BookingStatusUpdated"),
            object: nil,
            userInfo: json
        )
    }
    
    private func handleMessageSent(_ json: [String: Any]) {
        // Message sent confirmation
    }
    
    private func handleNewMessage(_ json: [String: Any]) {
        // New message received
        NotificationCenter.default.post(
            name: NSNotification.Name("NewMessageReceived"),
            object: nil,
            userInfo: json
        )
    }
}
