import Foundation

struct CoverageReport: Codable {
    let executableLines: Int
    let targets: [TargetCoverageReport]
    let lineCoverage: Double
    let coveredLines: Int
}
