import * as xregex from "xregexp";

import * as testTexts from "./testText";

let catchallRegex: RegExp = /[\d]{1,3}\s[a-zA-Z0-9\.]+,?\s[\d]{1,4}/g;
let oldNY: RegExp = /[\d]{1,3}\sN.\sY.+,?\s[\d]{1,4}/g
// let actualMagic: RegExp = /[a-zA-Z0-9\.,\s]+\sv\.\s[a-zA-Z0-9\.,\s]+/g; //Capable of getting party names, but over-inclusive. Gets basically everything to the left of the "v."

export async function extractMatches(text: string, regex?: RegExp): Promise<string[]> {
    regex = (regex) ? regex : catchallRegex;
    let res = [];
    let match;

    // It's stupid, but this is how one must find all matches in a text to a regex in JS.
    while ((match = regex.exec(text)) !== null) {
        res.push(match[0]);
    }

    return res;
}

async function main() {
    let _res = await extractMatches(testTexts.testText2, catchallRegex);
    console.log(_res);
}

main();

