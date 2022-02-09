import Foundation

struct FunctionCoverageReport: Codable {
    var coveredLines: Int
    var executableLines: Int
    var executionCount: Int
    var lineCoverage: Double
    var lineNumber: Int
    var name: String
}
