import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case courseSearch
    case teeSelection
    case holeCount
    case clubYardages
    case permissions
    case ready

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }
}
