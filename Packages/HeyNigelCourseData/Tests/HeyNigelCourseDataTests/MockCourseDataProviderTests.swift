import Testing
import HeyNigelCore
@testable import HeyNigelCourseData

@Suite("MockCourseDataProvider")
struct MockCourseDataProviderTests {
    @Test("loads bundled fixture courses")
    func loadsFixtures() async throws {
        let provider = MockCourseDataProvider()
        let results = try await provider.searchCourses(query: "")
        #expect(results.count == 2)
        #expect(results.contains { $0.name == "Sunridge Fixture Golf Club" })
        #expect(results.contains { $0.name == "Cactus Wren Fixture Links" })
    }

    @Test("search matches by name substring, case-insensitive")
    func searchByName() async throws {
        let provider = MockCourseDataProvider()
        let results = try await provider.searchCourses(query: "sunridge")
        #expect(results.count == 1)
        #expect(results.first?.id == "fixture-sunridge")
    }

    @Test("search matches by location substring")
    func searchByLocation() async throws {
        let provider = MockCourseDataProvider()
        let results = try await provider.searchCourses(query: "smoke test")
        #expect(results.count == 1)
        #expect(results.first?.id == "fixture-cactus-wren")
    }

    @Test("fetchCourseDetail returns full hole data for a known id")
    func fetchDetail() async throws {
        let provider = MockCourseDataProvider()
        let course = try await provider.fetchCourseDetail(id: "fixture-sunridge")
        #expect(course.holes.count == 9)
        #expect(course.hole(number: 7)?.yardageByTee["White"] == 145)
    }

    @Test("fetchCourseDetail throws for an unknown id")
    func fetchDetailUnknown() async throws {
        let provider = MockCourseDataProvider()
        await #expect(throws: CourseDataError.self) {
            _ = try await provider.fetchCourseDetail(id: "does-not-exist")
        }
    }
}
