import * as xregex from "xregexp";

import * as testTexts from "./testText";
import reporterList from './reporters/reporters';

let catchallRegex: RegExp = /[\d]{1,3}\s[a-zA-Z\.]+([0=9]+)?(\s[a-zA-z]+\.\s)?,?\s[\d]{1,4}/gi; //@TODO: still doesn't catch multi-word reporters 
// let actualMagic: RegExp = /[a-zA-Z0-9\.,\s]+\sv\.\s[a-zA-Z0-9\.,\s]+/g; //Capable of getting party names, but over-inclusive. Gets basically everything to the left of the "v."

// let omni: RegExp = new RegExp("(" + catchallRegex.source + ")");
let omniPattern: string = "(" + catchallRegex.source + ")";

reporterList.forEach((r) => {
    let reporterPattern = r.regEx;

    if (reporterPattern) {
        omniPattern += "|(" + reporterPattern + ")";
    }
});

let omniRegex: RegExp = new RegExp(omniPattern, "gi");

export async function extractMatches(text: string, regex?: RegExp): Promise<string[]> {
    // regex = (regex) ? regex : catchallRegex;
    regex = omniRegex;
    let res = [];
    let match;

    // It's stupid, but this is how one must find all matches in a text to a regex in JS.
    while ((match = regex.exec(text)) !== null) {
        res.push(match[0]);
    }

    return res;
}

async function main() {
    // console.log(omniRegex);
    let res = await extractMatches(testTexts.testText2);
    console.log(res);
}

main();

