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

    /// Placeholder nearest-course logic: straight-line distance to each
    /// course's hole-1 tee. Both bundled fixtures are in Scottsdale, AZ, so
    /// this only resolves sensibly near there — a real vendor would run an
    /// actual geospatial "courses near me" query.
    public func nearestCourse(to coordinate: Coordinate) async throws -> CourseSummary? {
        let distances: [(course: Course, distance: Double)] = courses.compactMap { course in
            guard let teeCoordinate = course.holes.first(where: { $0.number == 1 })?.teeBoxes.first?.coordinate else {
                return nil
            }
            return (course, Geodesy.distanceYards(coordinate, teeCoordinate))
        }
        guard let nearest = distances.min(by: { $0.distance < $1.distance }) else { return nil }
        return CourseSummary(id: nearest.course.id, name: nearest.course.name, location: nearest.course.location)
    }
}
