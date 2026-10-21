package citations

// The pieces shared by the generic detectors' abbreviation patterns.
//
// abbrChar is the character class of everything that can appear in a reporter
// abbreviation. abbrOCRDigit is a digit with a letter on either side, which in
// this corpus is always an OCR misreading of a letter rather than a real part of
// an abbreviation -- "Fed." scanned as "F1ed.", "Ill." as "I1l.", "Mass." as
// "Ma5ss." Requiring a letter on both sides is what keeps the abbreviation from
// swallowing the volume and page numbers, which are always separated from it by
// whitespace; a bare \d in the character class would let a single match run
// across several adjacent citations.
const (
	abbrChar     = `[\p{L}\s\.,&\(\)]`
	abbrOCRDigit = `\p{L}\d\p{L}`
)

// abbrUnit is one position in a corrupted abbreviation: an ordinary character,
// or a misread letter together with the letters flanking it.
const abbrUnit = `(?:` + abbrChar + `|` + abbrOCRDigit + `)`

// edition is the optional edition suffix, e.g. "Leach, 4th ed. 484".
const edition = `((1st|2nd|3rd|\dth)\sed.)??`

// abbrMaxLen is the longest abbreviation GenericDetector matches, in
// characters. A spelling longer than this is not truncated; it is lost, because
// the page has to follow the abbreviation and nothing shorter than the whole
// spelling is followed by one: at the old cap of 16, "12 N. Y. Sup. Ct. Rep.
// 345" and "12 Smedes & Marshall 345" were not detected at all, and a
// whitelist row for such a spelling could never be fed (issue #369). The
// treatises use spellings up to about 21 characters ("Am. & Eng. R. R. Cas.",
// "N. Y. Civ. Proc. Rep.", "Am. Law Reg. (N. S.)"), so 24 covers them with a
// little room. The cost is more prose between two numbers read as an
// abbreviation; those rows go to the not-whitelisted pool, where the whitelist
// has always sorted them. The number is a parameter to tune once the junk it
// adds has been measured on a sample.
const abbrMaxLen = "24"

// GenericDetector is a generic detector with a regular expression that looks for all
// citations. Its abbreviation is alphabetic and admits no digits.
var GenericDetector = NewDetector("Generic", abbrChar+`{3,`+abbrMaxLen+`}`+edition)

// GenericOCRDigitDetector finds the citations GenericDetector cannot, the ones
// whose abbreviation the OCR corrupted by reading a letter as a digit. The
// pattern is anchored on an abbrOCRDigit so it only ever fires on an
// abbreviation that actually contains one; that also keeps the effective
// minimum abbreviation length at three characters, matching GenericDetector,
// since abbrOCRDigit is itself three characters wide.
//
// This is deliberately a second detector rather than a widened GenericDetector.
// Detect keeps only one match per starting place, so folding the corrupted
// branch into GenericDetector lets a newly matchable corrupt span displace the
// clean citation that starting place would otherwise have yielded -- measured at
// 16 lost detections per 26k pages, several of them real citations, against 235
// gained. That measurement was taken when a starting place was a 25-character
// window rather than an anchored match (issue #281); the displacement it
// describes is a property of keeping one match per starting place, which has not
// changed, but the numbers are worth re-taking after the next full run.
// Running it separately makes the yield purely additive: the two detectors scan
// independently and SaveCitation's ON CONFLICT DO NOTHING collapses any citation
// they both produce.
//
// As everywhere else, the ReporterAbbr saved is the spelling that actually
// appeared in the OCR -- "F1ed.", not "Fed." -- and legalhist.whitelist decides
// what it means. These citations therefore link only once the whitelist carries
// their spellings; TestOCRDigitWhitelistSuggestions compiles the candidates.
var GenericOCRDigitDetector = NewDetector("Generic OCR digit",
	abbrUnit+`{0,15}`+abbrOCRDigit+abbrUnit+`{0,15}`+edition)
