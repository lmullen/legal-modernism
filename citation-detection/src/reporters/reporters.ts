import { reporter } from "./types";

let reporterList = [
    {
        name: "Abbot's Court of Appeals Decisions",
        caseDotLawID: 137,
        regEx: /[\d]{1,3}\sAbb\.\sCt.\sApp\.\s[\d]{1,4}/g
    },
    {
        name: "Abbot's New Cases",
        caseDotLawID: 23,
        regEx: /[\d]{1,3}\sAbb\.N\.\sCas\.\s[\d]{1,4}}/g
    },
    {
        name: "Abbot's Practice Reports",
        caseDotLawID: 29,
        alternateIDs: [989],
        regEx: /[\d]{1,3}\sAbb\.\sPr\.\s(R\.\s)?(\(n\.s\.\)\s)?[\d]{1,4}/g
    },
    {
        name: "Dallam",
        caseDotLawID: 929,
        regEx: null
    },
    {
        name: "Aikens",
        caseDotLawID: 661,
        regEx: null
    },
    {
        name: "Alabama Reports",
        caseDotLawID: 296,
        regEx: /[\d]{1,3}\sAla\.\s[\d]{1,4}/g
    },
    {
        name: "Alaska Reports",
        caseDotLawID: 596,
        regEx: null
    },
    {
        name: "Alaska Federal Reports",
        caseDotLawID: 597,
        regEx: null
    },
    {
        name: "American Somoa Reports",
        caseDotLawID: 951,
        regEx: null
    },
    {
        name: "Anthon's Nisi Prius Cases",
        caseDotLawID: 119,
        regEx: null
    },
    {
        name: "Appellate Division Reports",
        caseDotLawID: 107,
        regEx: null
    },
    {
        name: "Arizona Reports",
        caseDotLawID: 291,
        regEx: null
    },
    {
        name: "Arkansas Reports",
        caseDotLawID: 368,
        regEx: null
    },
    {
        name: "Armstrong's Contested Election Cases in New York",
        caseDotLawID: 135,
        regEx: null
    },
    {
        name: "Baltimore City Reports",
        caseDotLawID: 735,
        regEx: null
    },
    {
        name: "Barbour's Chancery Reports",
        caseDotLawID: 2,
        regEx: /[\d]{1,3}\sBarb\.\sCh\.\s[\d]{1,4}/g
    },
    {
        name: "Barbour's Supreme Court Reports",
        caseDotLawID: 112,
        regEx: /[\d]{1,3}\sBarb\.\s[\d]{1,4}/g
    },
    {
        name: "Blackford",
        caseDotLawID: 643,
        regEx: null
    },
    {
        name: "Bosworth",
        caseDotLawID: 175,
        regEx: null
    },
    {
        name: "Bradford's Reports",
        caseDotLawID: 131,
        regEx: null
    },
    {
        name: "Brayton",
        caseDotLawID: 663,
        regEx: null
    },
    {
        name: "Burnett",
        caseDotLawID: 656,
        regEx: null
    },
    {
        name: "Decisions of the Hon. John Cadwalader",
        caseDotLawID: 788,
        regEx: null
    },
    {
        name: "Caines' Cases", //sic
        caseDotLawID: 124,
        alternateIDs: [123],
        regEx: /[\d]{1,3}\sCai\.\s[\d]{1,4}/g
    },
    {
        name: "California Appellate Reports",
        caseDotLawID: 327,
        regEx: null
    },
    {
        name: "California Appellate Reports, Second Series",
        caseDotLawID: 329,
        regEx: null
    },
    {
        name: "California Reports",
        caseDotLawID: 414,
        regEx: /[\d]{1,3}\sCal\.\s[\d]{1,4}/g
    },
    {
        name: "California Unreported Cases",
        caseDotLawID: 565,
        regEx: /[\d]{1,3}\sCal\.\sUnrep\.\s(R\.\s)?[\d]{1,4}/g
    },
    {
        name: "Cases decided in the Courts of common pleas, in the Fifth circuit of the state of Ohio [1816-1819] (Tappan)",
        caseDotLawID: 773,
        regEx: null
    },
    {
        name: "Ohio Supreme Court special session",
        caseDotLawID: 781,
        regEx: null
    },
    {
        name: "Ohio State", //@TODO Go through ToA and put unrepresented reporters in here.
        caseDotLawID: 781,
        regEx: /[\d]{1,3}\sOhio\sSt\.\s[\d]{1,4}/g
    },
    {
        name: "Supreme Court of Pennsylvania -- Monaghan",
        caseDotLawID: 790,
        regEx: null
    },
    {
        name: "Supreme Court of Pennsylvania -- Unreported (Sadler)",
        caseDotLawID: 803,
        regEx: null
    },
    {
        name: "Chandler",
        caseDotLawID: 654,
        regEx: null
    },
    {
        name: "Charlton's Reports",
        caseDotLawID: 180,
        regEx: null
    },
    {
        name: "Chipman, D",
        caseDotLawID: 662,
        regEx: null
    },
    {
        name: "New York City Court Reports",
        caseDotLawID: 169,
        regEx: null
    },
    {
        name: "Clarke's Chancery Reports",
        caseDotLawID: 6,
        regEx: null
    },
    {
        name: "Coleman & Caines' Cases",
        caseDotLawID: 125,
        regEx: null
    },
    {
        name: "Coleman's Cases",
        caseDotLawID: 127,
        regEx: null
    },
    {
        name: "Colorado Court of Appeals Reports",
        caseDotLawID: 600,
        regEx: null
    },
    {
        name: "Colorado Law Reporter",
        caseDotLawID: 675,
        regEx: null
    },
    {
        name: "Colorado Reports",
        caseDotLawID: 344,
        regEx: null
    },
    {
        name: "Colorado Nisi Prius Decisions",
        caseDotLawID: 681,
        regEx: null
    },
    {
        name: "Condensed Reports of Decisions in Civil Causes in the Court of Appeals (Willson)",
        caseDotLawID: 1073,
        regEx: null
    },
    {
        name: "Condensed Reports of Decisions in Civil Causes in the Court of Appeals (White & Wilson)",
        caseDotLawID: 591,
        regEx: null
    },
    {
        name: "Connecticut Reports",
        caseDotLawID: 178,
        regEx: /[\d]{1,3}\sConn\.\s[\d]{1,4}/g
    },
    {
        name: "Connoly's Surrogate's Reports",
        caseDotLawID: 148,
        regEx: null
    },
    {
        name: "Court of Claims Reports",
        caseDotLawID: 415,
        regEx: null
    },
    {
        name: "Cowen's Reports",
        caseDotLawID: 121,
        regEx: /[\d]{1,3}\sCow\.\s[\d]{1,4}/g
    },
    {
        name: "Dakota Reports",
        caseDotLawID: 668,
        regEx: null
    },
    {
        name: "Daly's Common Pleas Reports",
        caseDotLawID: 166,
        regEx: null
    },
    {
        name: "Day's Reports",
        caseDotLawID: 177,
        regEx: null
    },
    {
        name: "Decisions of the Honorable John J. Pearson, judge of the twelvth judicial district", //sic
        caseDotLawID: 808,
        regEx: null
    },
    {
        name: "New Hampshire Supreme Court",
        caseDotLawID: 671,
        regEx: null
    },
    {
        name: "Decisions of the Superior Courts of the State of Georgia",
        caseDotLawID: 181,
        regEx: null
    },
    {
        name: "Delaware Cases",
        caseDotLawID: 199,
        regEx: null
    },
    {
        name: "Delaware Chancery Reports",
        caseDotLawID: 200,
        regEx: null
    },
    {
        name: "Delaware Reports",
        caseDotLawID: 198,
        regEx: null
    },
    {
        name: "Demarent's Surrogate's Reports",
        caseDotLawID: 147,
        regEx: null
    },
    {
        name: "Denio's Reports",
        caseDotLawID: 114,
        regEx: /[\d]{1,3}\sDenio(,)?(\.)?\s[\d]{1,4}/g
    },
    {
        name: "Dudley's Georgia Reports",
        caseDotLawID: 179,
        regEx: null
    },
    {
        name: "Duer's Superior Court Reports",
        caseDotLawID: 176,
        regEx: /[\d]{1,3}\sDuer(,)?(\.)?\s[\d]{1,4}/g
    },
    {
        name: "Edmond's Select Cases",
        caseDotLawID: 117,
        regEx: null
    },
    {
        name: "E.D. Smith's Common Pleas Reports",
        caseDotLawID: 167,
        regEx: /[\d]{1,3}\sE\.(\s)?D\.\sSmith(,)?(\.)?\s[\d]{1,4}/g
    },
    {
        name: "Edward's Chancery Reports",
        caseDotLawID: 1,
        regEx: /[\d]{1,3}\sEdw\.\s[\d]{1,4}/g
    },
    {
        name: "Puerto Rico Supreme Court",
        caseDotLawID: 786,
        regEx: null
    },
    {
        name: "Federal Cases",
        caseDotLawID: 942,
        regEx: null
    },
    {
        name: "Federal Reporter",
        caseDotLawID: 943,
        regEx: null
    },
    {
        name: "Federal Rules Decisions",
        caseDotLawID: 981,
        regEx: null
    },
    {
        name: "Federal Supplement",
        caseDotLawID: 982,
        regEx: null
    },
    {
        name: "Florida Reports",
        caseDotLawID: 391,
        regEx: /[\d]{1,3}\sFla\.\s[\d]{1,4}/g
    },
    {
        name: "Georgia Law Reporter",
        caseDotLawID: 639,
        regEx: null
    },
    {
        name: "Georgia Reports",
        caseDotLawID: 360,
        regEx: null
    },
    {
        name: "Gibbon's Surrogate's Reports",
        caseDotLawID: 149,
        regEx: null
    },
    {
        name: "Hall's Superior Court Reports",
        caseDotLawID: 170,
        regEx: null
    },
    {
        name: "Harris and Gill",
        caseDotLawID: 729,
        regEx: null
    },
    {
        name: "Hawaii Reports",
        caseDotLawID: 423,
        regEx: null
    },
    {
        name: "Hill and Denio Supplement (Labor)",
        caseDotLawID: 115,
        regEx: null
    },
    {
        name: "Hill's Reports",
        caseDotLawID: 116,
        regEx: /[\d]{1,3}\sHill(,)?\s[\d]{1,4}/g
    },
    {
        name: "Hilton's Common Pleas Reports",
        caseDotLawID: 168,
        regEx: /[\d]{1,3}\sHilt(,)?(\.)?\s[\d]{1,4}/g
    },
    {
        name: "Hoffman's Chancery Reports",
        caseDotLawID: 7,
        regEx: null
    },
    {
        name: "Hopkin's Chancery Reports",
        caseDotLawID: 8,
        regEx: null
    },
    {
        name: "Howard's Appeal Cases",
        caseDotLawID: 136,
        regEx: null
    },
    {
        name: "Howard's Practice Reports",
        caseDotLawID: 35,
        alternateIDs: [991],
        regEx: /[\d]{1,3}\sHow\.\sPr\.\s(R\.\s)?(n\.s\.)?[\d]{1,4}/g
    },
    {
        name: "Idaho Reports",
        caseDotLawID: 306,
        regEx: null
    },
    {
        name: "Illinois Appellate Court Reports",
        caseDotLawID: 315,
        regEx: null
    },
    {
        name: "Illinois Appellate Court Reports, Third Series",
        caseDotLawID: 322,
        regEx: null
    },
    {
        name: "Illinois Circuit Court Reports",
        caseDotLawID: 652,
        regEx: null
    },
    {
        name: "Illinois Court of Claims Reports",
        caseDotLawID: 532,
        regEx: null
    },
    {
        name: "Illinois Reports",
        caseDotLawID: 528,
        regEx: /[\d]{1,3}\sIll(,)?(\.)?\s[\d]{1,4}/
    },
    {
        name: "Indiana Court of Appeals Reports",
        caseDotLawID: 436,
        regEx: null
    },
    {
        name: "Indiana Law Reporter",
        caseDotLawID: 646,
        regEx: null
    },
    {
        name: "Indiana Reports",
        caseDotLawID: 272,
        regEx: /[\d]{1,3}\sInd(,)?(\.)?\s[\d]{1,4}/
    },
    {
        name: "Indian Territory Reports",
        caseDotLawID: 1069,
        regEx: null
    },
    {
        name: "Iowa Reports",
        caseDotLawID: 474,
        regEx: /[\d]{1,3}\sIowa(,)?(\.)?\s[\d]{1,4}/
    },
    {
        name: "Johnson's Cases",
        caseDotLawID: 126,
        regEx: /[\d]{1,3}\sJohns\.\sCas\.\s[\d]{1,4}/
    },
    {
        name: "Johnson's Chancery Reports",
        caseDotLawID: 10,
        regEx: /[\d]{1,3}\sJohns\.\sCh\.\s[\d]{1,4}/
    },
    {
        name: "Johnson's Reports",
        caseDotLawID: 122,
        regEx: /[\d]{1,3}\sJohns\.\s[\d]{1,4}/
    },
    {
        name: "Jones and Spencer's Superior Court Reports",
        caseDotLawID: 172,
        regEx: null
    },
    {
        name: "Kansas Reports",
        caseDotLawID: 476,
        regEx: null
    },
    {
        name: "Kentucky Opinions, containing the unreported opinions of the Court of Appeals",
        caseDotLawID: 713,
        regEx: null
    },
    {
        name: "Kentucky Reports",
        caseDotLawID: 305,
        regEx: null
    },
    {
        name: "Keyes' Reports",
        caseDotLawID: 139,
        regEx: /[\d]{1,3}\sKeyes(,)?(\.)?\s[\d]{1,4}/
    },
    {
        name: "Lansing's Chancery Reports",
        caseDotLawID: 9,
        regEx: null
    },
    {
        name: "Lansing's Reports",
        caseDotLawID: 111,
        regEx: null
    },
    {
        name: "Law Times (New Series)",
        caseDotLawID: 956,
        regEx: null
    },
    {
        name: "Legal Chronicle reports of Cases decided in the Supreme Court of Pennsylvania (Foster)",
        caseDotLawID: 955,
        regEx: null
    },
    {
        name: "Legal points decided by the Second circuit court of Louisiana (Gunby's Reports)",
        caseDotLawID: 725,
        regEx: null
    },
];

export default reporterList;
