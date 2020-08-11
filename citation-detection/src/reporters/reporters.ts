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
        name: "Howard's Practice Reports",
        caseDotLawID: 35,
        regEx: /[\d]{1,3}\sHow\.\sPr\.\s(R\.\s)?[\d]{1,4}/g
    },

    // [\d]{1,3}\sAbb\.\sPr\.(\sR\.\s)?(\s\(n\.s\.\))?\s[\d]{1,4}


];

export default reporterList;

// [\d]{1,3}\sHow\.\sPr\.\sR\.\s[\d]{1,4}