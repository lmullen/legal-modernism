import * as xregex from "xregexp";
import * as _ from "lodash";

import * as testTexts from "./testText";
import reporterList from './reporters/reporters';
import { getReporterByID } from "./reporters";

let standardRegex: RegExp = /[\d]{1,3}\s[a-zA-Z\.\s]+\s[\d]{1,4}}/gi;
let standardAppellateRegex: RegExp = /[\d]{1,3}\s[a-zA-Z\.\s]+\sApp\.\s[\d]{1,4}}/gi;

export async function extractMatches(text: string, regex?: RegExp): Promise<string[]> {
    let res = [];
    let match;

    // It's stupid, but this is how one must find all matches in a text to a regex in JS.
    while ((match = regex.exec(text)) !== null) {
        res.push(match[0]);
    }

    // res = Array.from(text.matchAll(regex));

    return res;
}

async function seriatim() {
    let reportersWithRegexes = _.filter(reporterList, (r) => { return r.regEx != null });

    // reportersWithRegexes.forEach((r) => {
    //     let res = await extractMatches(testTexts.treatiseTest0, r.regEx);
    // });

    let allMatches: string[] = [];

    for (let r of reportersWithRegexes) {
        // console.log(r.regEx);
        let reporterRes = await extractMatches(testTexts.treatiseTest0, r.regEx);
        allMatches = allMatches.concat(reporterRes);
        // console.log(allMatches);
    }

    console.log(allMatches);

}

async function main() {
    // let reporter = await getReporterByID(414);
    // console.log(reporter.name);

    // let res = await extractMatches(testTexts.treatiseTest0, reporter.regEx);
    // console.log(res);
    
    // await seriatim();

    let res = await extractMatches(testTexts.treatiseTest0, standardRegex);
    let res2 = await extractMatches(testTexts.treatiseTest0, standardAppellateRegex);

    res = res.concat(res2);

    console.log(res);
}

main();

