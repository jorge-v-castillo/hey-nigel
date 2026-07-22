import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case introOne
    case introTwo
    case permissions
    case name
    case nickname
    case clubs
    case ready

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
}
