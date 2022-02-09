import Foundation

struct FileCoverageReport: Codable {
    let coveredLines: Int
    let executableLines: Int
    let functions: [FunctionCoverageReport]
    let lineCoverage: Double
    let name: String
    let path: String
}
