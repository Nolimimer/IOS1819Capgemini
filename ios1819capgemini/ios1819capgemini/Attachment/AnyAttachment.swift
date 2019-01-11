//
//  AnyAttachments.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 10.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import Foundation

class AnyAttachment: Codable {
    var attachment: Attachment
    
    init(_ attachment: Attachment) {
        self.attachment = attachment
    }
    
     required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(AttachmentType.self, forKey: .type)
        self.attachment = try type.metatype.init(from: container.superDecoder(forKey: .attachment))
    }
    
    private enum CodingKeys : CodingKey {
        case type, attachment
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type(of: attachment).type, forKey: .type)
        try attachment.encode(to: encoder)
    }
    
    
}

public enum AttachmentType : String, Codable {
    
    // be careful not to rename these – the encoding/decoding relies on the string
    // values of the cases. If you want the decoding to be reliant on case
    // position rather than name, then you can change to enum TagType : Int.
    // (the advantage of the String rawValue is that the JSON is more readable)
    case photo, video, audio, textDocument
    
    var metatype: Attachment.Type {
        switch self {
        case .photo:
            return Photo.self
        case .video:
            return Video.self
        case .audio:
            return Audio.self
        case .textDocument:
            return TextDocument.self
        }
    }
}
