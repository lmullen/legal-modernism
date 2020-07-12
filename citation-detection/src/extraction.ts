import * as _regex from "xregexp";

import * as testTexts from "./test_text";

let catchallRegex: RegExp = /[\d]{1,3}\s[a-zA-Z0-9\.]+\s[\d]{1,4}/g;

export async function extractMatches(text: string, regex: RegExp): Promise<string[]> {
    let res = [];
    let match;

    while ((match = regex.exec(text)) !== null) {
        // console.log(match[0]);
        res.push(match[0]);
    }

    return res;
}

async function main() {
    let _res = await extractMatches(testTexts.manyCitations0, catchallRegex);
    console.log(_res);
}

main();

