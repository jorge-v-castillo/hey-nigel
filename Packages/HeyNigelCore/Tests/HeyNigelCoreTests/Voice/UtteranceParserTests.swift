import Testing
@testable import HeyNigelCore

@Suite("UtteranceParser")
struct UtteranceParserTests {
    let parser = UtteranceParser()

    @Test("extracts hole number from natural phrasing")
    func holeNumber() {
        let query = parser.parse("I'm on hole 7, what's my distance?")
        #expect(query.holeOverride == 7)
    }

    @Test("no hole number mentioned leaves holeOverride nil")
    func noHoleNumber() {
        let query = parser.parse("what club should I hit?")
        #expect(query.holeOverride == nil)
    }

    @Test("defaults target to center when front/back aren't mentioned")
    func defaultTarget() {
        let query = parser.parse("what's my distance to the hole")
        #expect(query.target == .center)
    }

    @Test("recognizes front of the green")
    func frontTarget() {
        let query = parser.parse("what's the distance to the front of the green")
        #expect(query.target == .front)
    }

    @Test("recognizes back of the green")
    func backTarget() {
        let query = parser.parse("how far to the back")
        #expect(query.target == .back)
    }

    @Test("distance-only phrasing maps to distance query type")
    func distanceOnly() {
        let query = parser.parse("what's my distance to the hole")
        #expect(query.queryType == .distance)
    }

    @Test("club-only phrasing maps to club query type")
    func clubOnly() {
        let query = parser.parse("what club should I hit")
        #expect(query.queryType == .club)
    }

    @Test("mentioning both distance and club maps to both")
    func bothMentioned() {
        let query = parser.parse("what's my distance and what club do you recommend")
        #expect(query.queryType == .both)
    }

    @Test("ambiguous phrasing with neither keyword defaults to both")
    func neitherMentioned() {
        let query = parser.parse("help me out here Nigel")
        #expect(query.queryType == .both)
    }

    @Test("full natural sentence parses hole, target default, and both query type together")
    func fullSentence() {
        let query = parser.parse("I'm on hole 12 and need to know my distance and what club you'd recommend")
        #expect(query.holeOverride == 12)
        #expect(query.target == .center)
        #expect(query.queryType == .both)
    }
}
