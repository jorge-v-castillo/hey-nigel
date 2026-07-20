import Foundation
import HeyNigelCore
import HeyNigelCourseData
import HeyNigelWeather

/// Composition root. Picks Mock vs. Remote providers in one place so no
/// other layer needs to know which vendor is behind `CourseDataProvider` /
/// `WeatherProvider` — swapping either in later is a one-line change here.
@MainActor
final class AppDependencies {
    let courseDataProvider: CourseDataProvider
    let weatherProvider: WeatherProvider
    let caddyBrain: CaddyBrain
    let responsePhraser: ResponsePhraser

    static let shared = AppDependencies()

    init(
        courseDataProvider: CourseDataProvider = MockCourseDataProvider(),
        weatherProvider: WeatherProvider = MockWeatherProvider(),
        caddyBrain: CaddyBrain = DefaultCaddyBrain(),
        responsePhraser: ResponsePhraser = ResponsePhraser()
    ) {
        self.courseDataProvider = courseDataProvider
        self.weatherProvider = weatherProvider
        self.caddyBrain = caddyBrain
        self.responsePhraser = responsePhraser
    }
}
