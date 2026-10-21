package citations

import "regexp"

var reVolume = regexp.MustCompile(`^\d+`)
var rePage = regexp.MustCompile(`\d+$`)

// var reAbbr = regexp.MustCompile(`\s*[\w\.]+\s*`)

// Multiple spaces in a row
var reSpace = regexp.MustCompile(`\s+`)

// Any letter. abbrChar admits whitespace, periods, commas, ampersands and
// parentheses as well as letters, so a match can consist entirely of the leader
// dots between two numbers in a table of contents; reHasLetter is how Detect
// rejects those (issue #283).
var reHasLetter = regexp.MustCompile(`\p{L}`)

// Multiple periods in a row
var reMultiplePeriodsSpace = regexp.MustCompile(`\.+\s`)
var reMultiplePeriodsNoSpace = regexp.MustCompile(`\.+`)

// reCaseName matches, in a whitespace-normalized match, the words that mark a
// case name or a citation signal rather than a reporter: "v" or "v." between
// the parties, "vs", "In re", "Ex parte", "Ex rel", and the signals "See",
// "Cf.", "citing", "quoting", "aff'd" and "denied" that the generic detector
// otherwise reads as an abbreviation between two numbers ("345 See 2"). The
// list is eyecite's STOP_WORDS. Case matters: "V. & B." is Vesey and Beames,
// and must not be refused on "V." (issue #373). Each word is bounded by
// whitespace or the ends of the match rather than \b, which would not hold
// between the period of "Cf." and the space after it.
var reCaseName = regexp.MustCompile(`(?:^|\s)(?:v|vs|See|see|Cf|cf|citing|quoting|aff'd|denied|[Ii]n re|[Ee]x parte|[Ee]x rel)\.?[,;]?(?:\s|$)`)
