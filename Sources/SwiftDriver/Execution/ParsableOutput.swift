import TSCBasic

import Foundation

public struct ParsableMessage {
  public enum Kind {
    case began(BeganMessage)
    case finished(FinishedMessage)
    case signalled
    case skipped
  }

  public let name: String
  public let kind: Kind

  public static func beganMessage(
    name: String,
    msg: BeganMessage
  ) -> ParsableMessage {
    return ParsableMessage(name: name, kind: .began(msg))
  }

  public static func finishedMessage(
    name: String,
    msg: FinishedMessage
  ) -> ParsableMessage {
    return ParsableMessage(name: name, kind: .finished(msg))
  }

  public func toJSON() throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(self)
  }
}

public struct BeganMessage: Encodable {
  public struct Output: Encodable {
    public let type: String
    public let path: String

    public init(path: String, type: String) {
      self.path = path
      self.type = type
    }
  }

  public let pid: Int
  public let inputs: [String]
  public let outputs: [Output]
  public let commandExecutable: String
  public let commandArguments: [String]

  public init(
    pid: Int,
    inputs: [String],
    outputs: [Output],
    commandExecutable: String,
    commandArguments: [String]
  ) {
    self.pid = pid
    self.inputs = inputs
    self.outputs = outputs
    self.commandExecutable = commandExecutable
    self.commandArguments = commandArguments
  }

  private enum CodingKeys: String, CodingKey {
    case pid
    case inputs
    case outputs
    case commandExecutable = "command-executable"
    case commandArguments = "command-arguments"
  }
}

public struct FinishedMessage: Encodable {
  let exitStatus: Int
  let pid: Int
  let output: String?

  // proc-info

  public init(
    exitStatus: Int,
    pid: Int,
    output: String?
  ) {
    self.exitStatus = exitStatus
    self.pid = pid
    self.output = output
  }

  private enum CodingKeys: String, CodingKey {
    case pid
    case output
    case exitStatus = "exit-status"
  }
}

extension ParsableMessage: Encodable {
  enum CodingKeys: CodingKey {
    case name
    case kind
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)

    switch kind {
    case .began(let msg):
      try container.encode("began", forKey: .kind)
      try msg.encode(to: encoder)
    case .finished(let msg):
      try container.encode("finished", forKey: .kind)
      try msg.encode(to: encoder)
    case .signalled:
      break
    case .skipped:
      break
    }
  }
}
