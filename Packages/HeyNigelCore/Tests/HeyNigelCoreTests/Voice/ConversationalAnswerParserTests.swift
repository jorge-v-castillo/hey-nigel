import Testing
@testable import HeyNigelCore

@Suite("ConversationalAnswerParser")
struct ConversationalAnswerParserTests {
    let parser = ConversationalAnswerParser()

    @Test("recognizes an affirmative response")
    func yesResponse() {
        let result = parser.parse("yeah that's right", expecting: .yesNo)
        #expect(result == .yesNo(true))
    }

    @Test("recognizes a negative response")
    func noResponse() {
        let result = parser.parse("no that's wrong", expecting: .yesNo)
        #expect(result == .yesNo(false))
    }

    @Test("unclear yes/no response is unrecognized")
    func unclearYesNo() {
        let result = parser.parse("maybe I think so", expecting: .yesNo)
        #expect(result == .unrecognized(rawTranscript: "maybe I think so"))
    }

    @Test("parses a plain digit transcript")
    func digitNumber() {
        let result = parser.parse("230", expecting: .number(range: nil))
        #expect(result == .number(230))
    }

    @Test("parses digits with trailing units")
    func digitsWithUnits() {
        let result = parser.parse("about 230 yards", expecting: .number(range: nil))
        #expect(result == .number(230))
    }

    @Test("parses a spelled-out number")
    func spelledOutNumber() {
        let result = parser.parse("eighteen", expecting: .number(range: nil))
        #expect(result == .number(18))
    }

    @Test("parses a compound spelled-out number")
    func compoundSpelledOutNumber() {
        let result = parser.parse("two hundred thirty", expecting: .number(range: nil))
        #expect(result == .number(230))
    }

    @Test("number outside the expected range is unrecognized")
    func numberOutOfRange() {
        let result = parser.parse("25", expecting: .number(range: 1...18))
        #expect(result == .unrecognized(rawTranscript: "25"))
    }

    @Test("number inside the expected range is accepted")
    func numberInRange() {
        let result = parser.parse("9", expecting: .number(range: 1...18))
        #expect(result == .number(9))
    }

    @Test("matches a choice by substring")
    func choiceMatch() {
        let result = parser.parse("let's go with the white tees", expecting: .choice(options: ["White", "Black", "Red"]))
        #expect(result == .choice(index: 0, matched: "White"))
    }

    @Test("no matching choice is unrecognized")
    func choiceNoMatch() {
        let result = parser.parse("the blue ones", expecting: .choice(options: ["White", "Black", "Red"]))
        #expect(result == .unrecognized(rawTranscript: "the blue ones"))
    }

    @Test("free text below the minimum word count is unrecognized")
    func freeTextTooShort() {
        let result = parser.parse("uh", expecting: .freeText(minWords: 2))
        #expect(result == .unrecognized(rawTranscript: "uh"))
    }

    @Test("free text meeting the minimum word count is accepted")
    func freeTextAccepted() {
        let result = parser.parse("Jorge Castillo", expecting: .freeText(minWords: 2))
        #expect(result == .text("Jorge Castillo"))
    }

    @Test("empty transcript is unrecognized regardless of expected type")
    func emptyTranscript() {
        let result = parser.parse("   ", expecting: .yesNo)
        #expect(result == .unrecognized(rawTranscript: "   "))
    }

    @Test("skip phrase is recognized for a number question")
    func skipNumberQuestion() {
        let result = parser.parse("I don't have one", expecting: .number(range: nil))
        #expect(result == .skipped)
    }

    @Test("skip phrase is recognized regardless of expected type")
    func skipAnyQuestionType() {
        let result = parser.parse("skip", expecting: .choice(options: ["White", "Black"]))
        #expect(result == .skipped)
    }
}
