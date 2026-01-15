//
//  OCRTextRecognizer.swift
//  Cart Calc
//
//  Created by 이다은 on 1/15/26.
//


import UIKit
import Vision

struct OCRTextRecognizer {
    /// Recognizes Korean product name and price from image.
    /// Calls completion(name, price) on main queue.
    static func recognizeText(from image: UIImage, completion: @escaping (String?, Int?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil, nil)
            return
        }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                completion(nil, nil)
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil, nil)
                return
            }
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = recognizedStrings.joined(separator: " ")
            var foundName = ""
            var foundPriceString = ""
            var foundPrice = 0
            let parts = fullText.components(separatedBy: .whitespaces)
            var priceStarted = false
            for part in parts {
                if priceStarted {
                    foundPriceString += part
                } else {
                    if part.rangeOfCharacter(from: .decimalDigits) != nil {
                        priceStarted = true
                        foundPriceString += part
                    } else {
                        if !foundName.isEmpty {
                            foundName += " "
                        }
                        foundName += part
                    }
                }
            }
            let digits = foundPriceString.filter { $0.isNumber }
            if let priceInt = Int(digits) {
                foundPrice = priceInt
            }
            DispatchQueue.main.async {
                completion(foundName.isEmpty ? nil : foundName, foundPrice > 0 ? foundPrice : nil)
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
            }
        }
    }
}