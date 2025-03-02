//
//  PostProcessor.swift
//  
//
//  Created by Pedro Cuenca on 17/7/23.
//

import Foundation
import Hub

public protocol PostProcessor {
    func postProcess(tokens: [String], tokensPair: [String]?, addSpecialTokens: Bool) -> [String]
    func callAsFunction(tokens: [String], tokensPair: [String]?, addSpecialTokens: Bool) -> [String]

    init(config: Config)
}

extension PostProcessor {
    func callAsFunction(tokens: [String], tokensPair: [String]? = nil, addSpecialTokens: Bool = true) -> [String] {
        return postProcess(tokens: tokens, tokensPair: tokensPair, addSpecialTokens: addSpecialTokens)
    }
}
enum PostProcessorType: String {
    case TemplateProcessing
    case ByteLevel
    case RobertaProcessing
    case BertProcessing
    case Sequence
}

struct PostProcessorFactory {
    static func fromConfig(config: Config?) -> PostProcessor? {
        guard let config = config else { return nil }
        guard var typeName = config.type?.stringValue else { return nil }
        if typeName.hasSuffix("Processing") {
            typeName = String(typeName.dropLast("Processing".count))
        }

        let type = PostProcessorType(rawValue: typeName)
        switch type {
            case .TemplateProcessing : return TemplateProcessing(config: config)
            case .ByteLevel          : return ByteLevelPostProcessor(config: config)
            case .RobertaProcessing  : return RobertaProcessing(config: config)
            case .BertProcessing     : return BertProcessing(config: config)
            case .Sequence           : return SequenceProcessing(config: config)
            default                  : fatalError("Unsupported PostProcessor type: \(typeName)")
        }
    }
}

// Keep the new BertProcessing and SequenceProcessing implementations from main
class BertProcessing: PostProcessor {
    private let sep: (UInt, String)
    private let cls: (UInt, String)

    required public init(config: Config) {
        guard let sep = config.sep?.tokenValue else { fatalError("Missing `sep` processor configuration") }
        guard let cls = config.cls?.tokenValue else { fatalError("Missing `cls` processor configuration") }
        self.sep = sep
        self.cls = cls
    }

    func postProcess(tokens: [String], tokensPair: [String]?, addSpecialTokens: Bool = true) -> [String] {
        guard addSpecialTokens else { return tokens + (tokensPair ?? []) }

        var outTokens = [self.cls.1] + tokens + [self.sep.1]
        if let tokensPair = tokensPair, !tokensPair.isEmpty {
            outTokens += tokensPair + [self.sep.1]
        }

        return outTokens
    }
}

class SequenceProcessing: PostProcessor {
    private let processors: [PostProcessor]

    required public init(config: Config) {
        guard let processorConfigs = config.processors?.arrayValue else {
            fatalError("Missing `processors` configuration")
        }

        self.processors = processorConfigs.compactMap { PostProcessorFactory.fromConfig(config: $0) }
    }

    func postProcess(tokens: [String], tokensPair: [String]?, addSpecialTokens: Bool = true) -> [String] {
        var currentTokens = tokens
        var currentTokensPair = tokensPair

        for processor in processors {
            let processed = processor.postProcess(tokens: currentTokens, tokensPair: currentTokensPair, addSpecialTokens: addSpecialTokens)
            currentTokens = processed
            currentTokensPair = nil  // After the first processor, we no longer have a separate pair
        }

        return currentTokens
    }
}
class TemplateProcessing: PostProcessor {
    let single: [Config]
    let pair: [Config]
    
    required public init(config: Config) {
        guard let single = config.single?.arrayValue else { fatalError("Missing `single` processor configuration") }
        guard let pair = config.pair?.arrayValue else { fatalError("Missing `pair` processor configuration") }
        
        self.single = single
        self.pair = pair
    }
    
    func postProcess(tokens: [String], tokensPair: [String]? = nil, addSpecialTokens: Bool = true) -> [String] {
        let config = tokensPair == nil ? single : pair
        
        var toReturn: [String] = []
        for item in config {
            if let specialToken = item.SpecialToken {
                if addSpecialTokens {
                    toReturn.append(specialToken.id!.stringValue!)
                }
            } else if let sequence = item.Sequence {
                if sequence.id?.stringValue == "A" {
                    toReturn += tokens
                } else if sequence.id?.stringValue == "B" {
                    toReturn += tokensPair!
                }
            }
        }
        return toReturn
    }
}
class ByteLevelPostProcessor: PostProcessor {
    required public init(config: Config) {}
    func postProcess(tokens: [String], tokensPair: [String]? = nil, addSpecialTokens: Bool = true) -> [String] { tokens }
}

class RobertaProcessing: BertProcessing { }
=======
class BertProcessing: PostProcessor {
    private let sep: (UInt, String)
    private let cls: (UInt, String)

    required public init(config: Config) {
        guard let sep = config.sep?.tokenValue else { fatalError("Missing `sep` processor configuration") }
        guard let cls = config.cls?.tokenValue else { fatalError("Missing `cls` processor configuration") }
        self.sep = sep
        self.cls = cls
    }

    func postProcess(tokens: [String], tokensPair: [String]?, addSpecialTokens: Bool = true) -> [String] {
        guard addSpecialTokens else { return tokens + (tokensPair ?? []) }

        var outTokens = [self.cls.1] + tokens + [self.sep.1]
        if let tokensPair = tokensPair, !tokensPair.isEmpty {
            outTokens += tokensPair + [self.sep.1]
        }

        return outTokens
    }
}
