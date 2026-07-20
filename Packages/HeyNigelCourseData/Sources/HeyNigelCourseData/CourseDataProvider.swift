import Foundation
import HeyNigelCore

public enum CourseDataError: Error, Sendable {
    case courseNotFound(String)
}

/// Vendor-agnostic access to course/hole GPS data. `MockCourseDataProvider`
/// backs development and tests today; a `RemoteCourseDataProvider` talking to
/// a contracted course-data API is a drop-in replacement behind this same
/// protocol — no other layer needs to change when a vendor is picked.
public protocol CourseDataProvider: Sendable {
    func searchCourses(query: String) async throws -> [CourseSummary]
    func fetchCourseDetail(id: String) async throws -> Course
}
