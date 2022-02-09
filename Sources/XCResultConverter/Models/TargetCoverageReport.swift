import Foundation

struct TargetCoverageReport: Codable {
    let buildProductPath: String
    let coveredLines: Int
    let executableLines: Int
    let files: [FileCoverageReport]
    let lineCoverage: Double
    let name: String
}
