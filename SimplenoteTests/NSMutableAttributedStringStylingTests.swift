import XCTest
@testable import Simplenote


// MARK: - NSMutableAttributedString Styling Tests
//
class NSMutableAttributedStringStylingTests: XCTestCase {

    /// Verifies that `NSRegularExpression.regexForChecklists` will not match checklists that are in the middle of a string
    ///
    func testRegexForChecklistsWillNotMatchChecklistsLocatedAtTheMiddleOfTheString() {
        let string = "This is a badly formed todo - [ ] Buy avocados - []"
        let regex = NSRegularExpression.regexForChecklists
        let matches = regex.matches(in: string, options: [], range: string.rangeOfEntireString)
        
        XCTAssertTrue(matches.isEmpty)
    }

    /// Verifies that `NSRegularExpression.regexForChecklistsEmbeddedAnywhere` matches multiple checklists in the same line
    ///
    func testRegexForChecklistsEmbeddedAnywhereWillMatchChecklistsLocatedAtTheMiddleOfTheString() {
        let string = "The second regex should consider this as a valid checklist - [ ] Buy avocados - []"
        let regex = NSRegularExpression.regexForChecklistsEmbeddedAnywhere
        let matches = regex.matches(in: string, options: [], range: string.rangeOfEntireString)

        XCTAssertEqual(matches.count, 2)
    }

    /// Verifies that `NSRegularExpression.regexForChecklists` matches multiple spacing prefixes
    ///
    func testRegexForChecklistsProperlyMatchesMultipleWhitespacePrefixes() {
        let string = "           - [ ] Buy avocados - [ ]"
        let regex = NSRegularExpression.regexForChecklists
        let matches = regex.matches(in: string, options: [], range: string.rangeOfEntireString)

        XCTAssertEqual(matches.count, 1)
    }

    /// Verifies that `NSRegularExpression.regexForChecklistsEmbeddedAnywhere` matches multiple spacing prefixes
    ///
    func testRegexForChecklistsEverywhereProperlyMatchesMultipleWhitespacePrefixes() {
        let string = "           - [ ] Buy avocados - [ ]"
        let regex = NSRegularExpression.regexForChecklistsEmbeddedAnywhere
        let matches = regex.matches(in: string, options: [], range: string.rangeOfEntireString)

        XCTAssertEqual(matches.count, 2)
    }

    /// Verifies that `NSRegularExpression.regexForChecklists` only matches corretly formed strings
    ///
    func testRegexForChecklistsMatchProperlyFormattedChecklists() {
        let string = "ToDo\n\n- [ ] Buy avocados\n- [ ] Ship it\n- [x ] Malformed!\n- [x] Correct."
        let regex = NSRegularExpression.regexForChecklists
        let matches = regex.matches(in: string, options: [], range: string.rangeOfEntireString)
        
        XCTAssertEqual(matches.count, 3)
    }

    /// Verifies that `NSRegularExpression.regexForChecklists` will not match malformed strings
    ///
    func testRegexForChecklistsWillNotMatchMalformedChecklists() {
        let string = "- [x ] Malformed!"
        let regex = NSRegularExpression.regexForChecklists
        let matches = regex.matches(in: string, options: [], range: string.rangeOfEntireString)

        XCTAssertTrue(matches.isEmpty)
    }

    /// Verifies that `NSRegularExpression.regexForChecklistsEverywhere` will not match malformed strings
    ///
    func testRegexForChecklistsEverywhereWillNotMatchMalformedChecklists() {
        let string = "- [x ] Malformed!"
        let regex = NSRegularExpression.regexForChecklistsEmbeddedAnywhere
        let matches = regex.matches(in: string, options: [], range: string.rangeOfEntireString)

        XCTAssertTrue(matches.isEmpty)
    }

    /// Verifies that `NSRegularExpression.regexForChecklists` will match checklists with no spaces between brackets
    ///
    func testRegexForChecklistsWillMatchChecklistsWithNoInternalSpaces() {
        let string = "- [] Item"
        let regex = NSRegularExpression.regexForChecklists
        let matches = regex.matches(in: string, options: [], range: string.rangeOfEntireString)

        XCTAssertEqual(matches.count, 1)
    }

    /// Verifies that `NSRegularExpression.regexForChecklistsEmbeddedAnywhere` will match checklists with no spaces between brackets
    ///
    func testRegexForChecklistsEverywhereWillMatchChecklistsWithNoInternalSpaces() {
        let string = "- [] Item"
        let regex = NSRegularExpression.regexForChecklistsEmbeddedAnywhere
        let matches = regex.matches(in: string, options: [], range: string.rangeOfEntireString)

        XCTAssertEqual(matches.count, 1)
    }
}
