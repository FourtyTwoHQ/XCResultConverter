import Foundation

extension String: Error { }

extension String {
    func contains(elementOfArray: [String]) -> Bool {
        for element in elementOfArray {
            if self.contains(element) {
                return true
            }
        }

        return false
    }
}
