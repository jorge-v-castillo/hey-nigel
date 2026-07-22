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

    /// Best-guess course for the player's current GPS position, used to open
    /// round-setup with "Are we playing X today?" instead of a blind search.
    /// Returns nil if no course is known nearby. A real vendor would run a
    /// proper geospatial query here; `MockCourseDataProvider`'s straight-line
    /// approximation is a placeholder until one is contracted.
    func nearestCourse(to coordinate: Coordinate) async throws -> CourseSummary?
}
