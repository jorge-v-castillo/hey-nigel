import Foundation
import HeyNigelCore

/// Bundled fixture courses so the app is developable and testable end-to-end
/// before a real course-data vendor is contracted. Swapping in
/// `RemoteCourseDataProvider` later requires no changes anywhere else, since
/// both conform to `CourseDataProvider`.
public struct MockCourseDataProvider: CourseDataProvider {
    private let courses: [Course]

    public init() {
        let decoder = JSONDecoder()
        let names = ["sunridge-fixture", "cactus-wren-fixture"]
        self.courses = names.compactMap { name in
            guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"),
                  let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(Course.self, from: data)
        }
    }

    /// Testing/preview convenience — bypasses bundle resource loading.
    public init(courses: [Course]) {
        self.courses = courses
    }

    public func searchCourses(query: String) async throws -> [CourseSummary] {
        guard !query.isEmpty else {
            return courses.map { CourseSummary(id: $0.id, name: $0.name, location: $0.location) }
        }
        let lowered = query.lowercased()
        return courses
            .filter { $0.name.lowercased().contains(lowered) || $0.location.lowercased().contains(lowered) }
            .map { CourseSummary(id: $0.id, name: $0.name, location: $0.location) }
    }

    public func fetchCourseDetail(id: String) async throws -> Course {
        guard let course = courses.first(where: { $0.id == id }) else {
            throw CourseDataError.courseNotFound(id)
        }
        return course
    }
}
