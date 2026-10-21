package citations

import "unicode"

// RemoveShadows drops every citation that is a second reading of a citation
// another detector found on the same page, and returns the rest in their
// original order. Three kinds of reading are shadows:
//
// A volume-less citation whose span lies strictly inside another citation's
// span. The single-volume detectors match an abbreviation with no regard for
// what precedes it, so they re-detect the tail of any longer citation that ends
// in that abbreviation: "Cal. 185" inside the generic detector's "123 Cal. 185",
// "Raym. 45" inside "5 Ld. Raym. 45", or "Cas. 45" inside another single-volume
// detector's "Ch. Cas. 45". Each such shadow was a separate row in
// citations_unlinked, where it either failed to link (a volume-less cite to a
// multi-volume reporter can never match) or, worse, linked to the single-volume
// reporter that a citation to California or Lord Raymond never meant (issue
// #267). Only volume-less citations are candidates here, because only the
// single-volume detectors produce them; the containing citation may come from
// any detector.
//
// Any citation whose span lies strictly inside a citation that carries a year.
// A YearDetector match begins at the year, so the generic detector's reading of
// the same citation without it -- "2 K. B. 1" inside "[1905] 2 K. B. 1" -- is
// inside its span. For a reporter cited by year that reading names no case in
// particular, and keeping both would write the same citation twice, once
// usefully and once not.
//
// A volume-less citation that begins before a volumed citation and runs into
// it. The single-volume detectors also match with no regard for what follows
// the number, so in the ordinary "Smith v. Jones, 12 Mass. 345" a detector for
// a reporter spelled "Jones" finds "Jones, 12", whose page is the volume of the
// citation that follows (issue #367). The spellings of the single-volume
// reporters include a great many bare surnames -- Andrews, Davis, King, Taylor
// -- so the reading is a party name far more often than it is a citation
// without its separator, and it links wherever that reporter has the page.
// The number the two readings share can only be the second citation's
// volume, so the first is dropped. Two readings are exempt. A citation that
// carries a year is never a name: its volume may be absent ("[1899] K.B. 1"),
// but the year is what the detector matched on. And the volumed citation
// must look like one, which here means a capital letter in its abbreviation:
// the generic detector also reads the prose between two numbers as a
// citation, "45 and 2" in "Hob. 45 and 2 Pick. 12", and that reading, which
// no whitelist row will ever admit, must not take the real citation ahead of
// it with it.
//
// Containment must be strict: two single-volume detectors whose abbreviations
// are prefixes of one another ("Toth" and "Tothill") produce identical spans for
// the same text, and those are the same citation, not a shadow -- the unique
// index on citations_unlinked collapses them at save time.
//
// The comparison is quadratic in the number of citations on the page, which is
// at most a few hundred.
func RemoveShadows(cites []*Citation) []*Citation {
	kept := make([]*Citation, 0, len(cites))
	for _, c := range cites {
		if shadowed(c, cites) {
			continue
		}
		kept = append(kept, c)
	}
	return kept
}

// shadowed reports whether c's span lies strictly inside the span of another
// citation in cites that it is a lesser reading of: any other citation when c
// carries no volume, or a citation that carries a year. A volume-less,
// year-less citation is also a shadow when it begins before a volumed citation
// and runs into it (issue #367): "Smith v. Jones, 12 Mass. 345" yields "Jones,
// 12" from the single-volume spelling "Jones" beside "12 Mass. 345", and the
// number the two readings share is the second citation's volume, so the first
// is a defendant's surname, never a reporter. The volumed citation must carry
// a capital letter in its abbreviation: the generic detector also reads the
// prose between two numbers as a citation ("45 and 2" in "Hob. 45 and 2 Pick.
// 12"), and that reading must not take the real "Hob. 45" with it. A
// volume-less span that contains a volumed one is not that case and is left
// alone, as it always was.
func shadowed(c *Citation, cites []*Citation) bool {
	for _, o := range cites {
		if o == c {
			continue
		}
		contains := o.Start <= c.Start && c.End <= o.End
		strict := o.Start < c.Start || c.End < o.End
		if contains && strict && (c.Volume == nil || o.Year != nil) {
			return true
		}
		runsInto := c.Start < o.Start && o.Start < c.End && c.End < o.End
		if runsInto && c.Volume == nil && c.Year == nil && o.Volume != nil && hasUpper(o.ReporterAbbr) {
			return true
		}
	}
	return false
}

// hasUpper reports whether s contains an upper-case letter, which every
// reporter abbreviation does and the generic detector's readings of prose
// between two numbers ("and", "feet long and") do not.
func hasUpper(s string) bool {
	for _, r := range s {
		if unicode.IsUpper(r) {
			return true
		}
	}
	return false
}
