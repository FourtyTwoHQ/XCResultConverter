import ArgumentParser
import Foundation

struct XCResultConverterCommand: ParsableCommand {

    static var configuration: CommandConfiguration {
        .init(commandName: "xcrc")
    }

    @Option(name: [.customShort("p"), .long])
    var excludedPackages: [String] = []

    @Option(name: [.customShort("t"), .long])
    var excludedTargets: [String] = []

    @Option(name: [.short, .long])
    var output: String?

    @Argument(help: "The path to the json file")
    var path: String

    mutating func run() throws {
        let json = try String(contentsOfFile: path, encoding: .utf8)
        guard let data = json.data(using: .utf8) else { throw "💥 Unable to convert JSON to Data" }

        let report = try JSONDecoder().decode(CoverageReport.self, from: data)


        let manager: FileManager = .default
        let pwd = manager.currentDirectoryPath

        let url = "https://raw.githubusercontent.com/cobertura/cobertura/master/cobertura/src/site/htdocs/xml/coverage-04.dtd"
        let dtd = try XMLDTD(contentsOf: URL(string: url)!)
        dtd.name = "coverage"
        dtd.systemID = url

        let root = XMLElement(name: "coverage")
        root.addAttribute(XMLNode.attribute(withName: "line-rate", stringValue: "\(report.lineCoverage)") as! XMLNode)
        root.addAttribute(XMLNode.attribute(withName: "branch-rate", stringValue: "1.0") as! XMLNode)
        root.addAttribute(XMLNode.attribute(withName: "lines-covered", stringValue: "\(report.coveredLines)") as! XMLNode)
        root.addAttribute(XMLNode.attribute(withName: "lines-valid", stringValue: "\(report.executableLines)") as! XMLNode)
        root.addAttribute(XMLNode.attribute(withName: "timestamp", stringValue: "\(Date().timeIntervalSince1970)") as! XMLNode)
        root.addAttribute(XMLNode.attribute(withName: "version", stringValue: "diff_coverage 0.1") as! XMLNode)
        root.addAttribute(XMLNode.attribute(withName: "complexity", stringValue: "0.0") as! XMLNode)
        root.addAttribute(XMLNode.attribute(withName: "branches-valid", stringValue: "1.0") as! XMLNode)
        root.addAttribute(XMLNode.attribute(withName: "branches-covered", stringValue: "1.0") as! XMLNode)

        let doc = XMLDocument(rootElement: root)
        doc.version = "1.0"
        doc.dtd = dtd
        doc.documentContentKind = .xml

        let sourceElement = XMLElement(name: "sources")
        root.addChild(sourceElement)
        sourceElement.addChild(XMLElement(name: "source", stringValue: pwd))

        let packagesElement = XMLElement(name: "packages")
        root.addChild(packagesElement)

        var allFiles: [FileCoverageReport] = []
        for targetCoverageReport in report.targets {
            // Filter out targets
            guard targetCoverageReport.name.contains(elementOfArray: excludedTargets) == false else { continue }

            // Filter out files by package
            let files = targetCoverageReport.files.filter { $0.path.contains(elementOfArray: excludedPackages) == false }
            allFiles.append(contentsOf: files)
        }

        // Sort files to avoid duplicated packages
        allFiles = allFiles.sorted { $0.path > $1.path }

        var currentPackage = ""
        var currentPackageElement: XMLElement!
        var isNewPackage = false

        for fileCoverageReport in allFiles {
            // Define file path relative to source!
            let filePath = fileCoverageReport.path.replacingOccurrences(of: pwd + "/", with: "")
            let pathComponents = filePath.split(separator: "/")
            let packageName = pathComponents[0..<pathComponents.count - 1].joined(separator: ".")

            isNewPackage = currentPackage != packageName

            if isNewPackage {
                currentPackageElement = XMLElement(name: "package")
                packagesElement.addChild(currentPackageElement)
            }

            currentPackage = packageName

            if isNewPackage {
                currentPackageElement.addAttribute(XMLNode.attribute(withName: "name", stringValue: packageName) as! XMLNode)
                currentPackageElement.addAttribute(XMLNode.attribute(withName: "line-rate", stringValue: "\(fileCoverageReport.lineCoverage)") as! XMLNode)
                currentPackageElement.addAttribute(XMLNode.attribute(withName: "branch-rate", stringValue: "1.0") as! XMLNode)
                currentPackageElement.addAttribute(XMLNode.attribute(withName: "complexity", stringValue: "0.0") as! XMLNode)
            }

            let classElement = XMLElement(name: "class")
            classElement.addAttribute(XMLNode.attribute(withName: "name", stringValue: "\(packageName).\((fileCoverageReport.name as NSString).deletingPathExtension)") as! XMLNode)
            classElement.addAttribute(XMLNode.attribute(withName: "filename", stringValue: "\(filePath)") as! XMLNode)
            classElement.addAttribute(XMLNode.attribute(withName: "line-rate", stringValue: "\(fileCoverageReport.lineCoverage)") as! XMLNode)
            classElement.addAttribute(XMLNode.attribute(withName: "branch-rate", stringValue: "1.0") as! XMLNode)
            classElement.addAttribute(XMLNode.attribute(withName: "complexity", stringValue: "0.0") as! XMLNode)
            currentPackageElement.addChild(classElement)

            let linesElement = XMLElement(name: "lines")
            classElement.addChild(linesElement)

            for functionCoverageReport in fileCoverageReport.functions {
                for index in 0..<functionCoverageReport.executableLines {
                    // Function coverage report won't be 100% reliable without parsing it by file (would need to use xccov view --file filePath currentDirectory + Build/Logs/Test/*.xccovarchive)
                    let lineElement = XMLElement(kind: .element, options: .nodeCompactEmptyElement)
                    lineElement.name = "line"
                    lineElement.addAttribute(XMLNode.attribute(withName: "number", stringValue: "\(functionCoverageReport.lineNumber + index)") as! XMLNode)
                    lineElement.addAttribute(XMLNode.attribute(withName: "branch", stringValue: "false") as! XMLNode)

                    let lineHits: Int
                    if index < functionCoverageReport.coveredLines {
                        lineHits = functionCoverageReport.executionCount
                    } else {
                        lineHits = 0
                    }

                    lineElement.addAttribute(XMLNode.attribute(withName: "hits", stringValue: "\(lineHits)") as! XMLNode)
                    linesElement.addChild(lineElement)
                }
            }
        }

        let string = doc.xmlString(options: [.nodePrettyPrint])
        switch output {
        case .some(let path):
            let url = URL(fileURLWithPath: path)
            try string.write(to: url, atomically: true, encoding: .utf8)

        case .none:
            print(string)
        }
    }
}

XCResultConverterCommand.main()
