package citations

// GenericDetector is a generic detector with a regular expression that looks for all
// citations
var GenericDetector = NewDetector("Generic", `[\p{L}\s\.,&\(\)]{3,15}((1st|2nd|3rd|\dth)\sed.)??`)
