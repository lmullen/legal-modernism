import * as xregex from "xregexp";
import * as _ from "lodash";

import * as testTexts from "./testText";
import reporterList from './reporters/reporters';
import { getReporterByID } from "./reporters";
import { rawQuery } from "./infrastructure/dataTest";

let standardRegex: RegExp = /[\d]{1,3}\s[a-zA-Z\.\s]+\s[\d]{1,4}/gi;
let standardAppellateRegex: RegExp = /[\d]{1,3}\s[a-zA-Z\.\s]+\sApp\.\s[\d]{1,4}}/gi;

async function gatherRegexes(): Promise<RegExp[]> {
    let r = [standardRegex, standardAppellateRegex];

    let reportersWithSpecial = _.filter(reporterList, (r) => { return r.useSpecial });
    let specialRegexes = reportersWithSpecial.map((r) => { return r.regEx; });

    r = r.concat(specialRegexes);
    return r;
}

export async function extractMatches(text: string, regex?: RegExp): Promise<string[]> {
    let res = [];
    let match;
    // console.log(regex);
    // It's stupid, but this is how one must find all matches in a text to a regex in JS.
    while ((match = regex.exec(text)) !== null) {
        res.push(match[0]);
    }

    // res = Array.from(text.matchAll(regex));

    // console.log(res);

    return res;
}

export async function processText(text: string) {
    // let res = await extractMatches(text, standardRegex);
    // let res2 = await extractMatches(text, standardAppellateRegex);

    let regexes = await gatherRegexes();

    // console.log(regexes);

    let res = [];

    for (let reg of regexes) {
        let _res = await extractMatches(text, reg);
        res = res.concat(_res);
    }

    return res;
}

// async function seriatim() {
//     let reportersWithRegexes = _.filter(reporterList, (r) => { return r.regEx != null });

//     // reportersWithRegexes.forEach((r) => {
//     //     let res = await extractMatches(testTexts.treatiseTest0, r.regEx);
//     // });

//     let allMatches: string[] = [];

//     for (let r of reportersWithRegexes) {
//         // console.log(r.regEx);
//         let reporterRes = await extractMatches(testTexts.treatiseTest0, r.regEx);
//         allMatches = allMatches.concat(reporterRes);
//         // console.log(allMatches);
//     }

//     console.log(allMatches);

// }

async function main() {
    //    let res =  await processText(testTexts.treatiseTest0);
    //    console.log(res);

    let res = await rawQuery("select * from moml.book_info limit 1");
    console.log(res);
}

main();

