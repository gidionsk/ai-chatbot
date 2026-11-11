//
//  TanyaAIChatService+LiveAgent.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 10/11/26.
//

import Foundation

/// `--live-agent`: pertanyaan pertama diserahkan bot ke agen. Agen bergabung setelah jeda, menyapa, menjawab
/// pertanyaan berikutnya, lalu menutup percakapan. "Batalkan proses ini" selama antre mengembalikan ke bot.
extension TanyaAIChatService {
    func acceptForLiveAgent(_ text: String, clientMessageID: String) -> Data {
        let ack = frames.ack()
        let question = frames.newMessage(
            direction: SandboxWireMessage.user, text: text, clientMessageID: clientMessageID
        )
        schedule(after: SandboxOptions.echoDelay) { $0.emit($0.frames.frame(question)) }
        // Selama antre atau dengan agen tidak ada turn, jadi tidak ada `turn_end`.
        guard conversationState == SandboxGatewayFrames.assistantActive else {
            if conversationState == SandboxGatewayFrames.agentActive {
                scheduleAgentMessage(SandboxGatewayFrames.agentReply, isClosing: true)
            }
            return ack
        }
        pendingQuestion = question
        scheduleHandover()
        return ack
    }

    /// Respons `leave-agent`: hanya berlaku selama antre; agen yang dijadwalkan bergabung dibatalkan.
    func leaveQueue() -> Data {
        guard conversationState == SandboxGatewayFrames.agentQueued else {
            return SandboxGatewayFrames.notInAgentQueue
        }
        pendingWork.forEach { $0.cancel() }
        pendingWork = []
        DispatchQueue.main.async { [weak self] in
            self?.moveAgent(to: SandboxGatewayFrames.assistantActive, notice: SandboxGatewayFrames.queueCanceled)
        }
        return SandboxGatewayFrames.leftAgentQueue
    }
}

// MARK: - Skenario

private extension TanyaAIChatService {
    /// Bot menjawab bahwa nasabah dihubungkan ke agen, masuk antrean, lalu agen bergabung setelah jeda.
    func scheduleHandover() {
        schedule(after: SandboxOptions.echoDelay + SandboxOptions.replyDelay) { service in
            service.emit(
                service.frames.message(
                    direction: SandboxWireMessage.assistant, text: SandboxGatewayFrames.handoverReply)
            )
            service.moveAgent(to: SandboxGatewayFrames.agentQueued, notice: SandboxGatewayFrames.agentConnecting)
            service.finishTurn()
            service.schedule(after: SandboxOptions.agentJoinDelay) { service in
                service.moveAgent(to: SandboxGatewayFrames.agentActive, notice: SandboxGatewayFrames.agentJoined)
                service.scheduleAgentMessage(SandboxGatewayFrames.agentGreeting, isClosing: false)
            }
        }
    }

    /// Agen mengetik sebentar lalu mengirim pesan; `isClosing` = agen menutup percakapan setelah jeda.
    func scheduleAgentMessage(_ text: String, isClosing: Bool) {
        schedule(after: SandboxOptions.echoDelay) { $0.emit($0.frames.typing(isTyping: true)) }
        schedule(after: SandboxOptions.echoDelay + SandboxOptions.agentTypingDelay) { service in
            service.emit(service.frames.message(direction: SandboxWireMessage.agent, text: text))
            guard isClosing else { return }
            service.schedule(after: SandboxOptions.agentJoinDelay) { service in
                service.emit(service.frames.system(SandboxGatewayFrames.agentEnded))
                service.moveAgent(
                    to: SandboxGatewayFrames.assistantActive, notice: SandboxGatewayFrames.backToAssistant)
            }
        }
    }

    /// Perpindahan state selalu berpasangan dengan event `system` (contract §10.6).
    func moveAgent(to state: String, notice: String) {
        let previous = conversationState
        conversationState = state
        emit(frames.system(notice))
        emit(frames.state(state, previous: previous))
    }
}
