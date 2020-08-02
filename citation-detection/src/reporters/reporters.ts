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
        name: "Howard's Practice Reports",
        caseDotLawID: 35,
        regEx: /[\d]{1,3}\sHow\.\sPr\.\s(R\.\s)?[\d]{1,4}/g
    },

    // [\d]{1,3}\sAbb\.\sPr\.(\sR\.\s)?(\s\(n\.s\.\))?\s[\d]{1,4}


];

export default reporterList;

// [\d]{1,3}\sHow\.\sPr\.\sR\.\s[\d]{1,4}