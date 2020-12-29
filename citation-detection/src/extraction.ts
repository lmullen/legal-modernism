import * as xregex from "xregexp";
import * as _ from "lodash";
import * as fs from "fs";

import * as testTexts from "./testText";
import reporterList from './reporters/reporters';
import { getReporterByID } from "./reporters";
import { rawQuery } from "./infrastructure/data/dataTest";
import TreatiseRepo from "./treatises/data/treatiseRepo";
import OcrRepo from "./treatises/data/ocrRepo";

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
    // It's stupid, but this is how one must find all matches in a text to a regex in JS.
    while ((match = regex.exec(text)) !== null) {
        res.push(match[0]);
    }


    return res;
}

export async function processText(text: string) {
    let regexes = await gatherRegexes();

    let res = [];

    for (let reg of regexes) {
        let _res = await extractMatches(text, reg);
        res = res.concat(_res);
    }

    return res;
}

export async function processTreatise(treatiseId: string) {

    // console.log(`psmid: ${treatiseId}`);
    let pages = await OcrRepo.getOCRTextByTreatiseID(treatiseId);
    // console.log(pages.length);

    let matchObject = {
        treatiseId: treatiseId,
        cases: []
    };

    for (let p of pages) {
        let matchRes = await processText(p.ocrtext);
        matchObject.cases = matchObject.cases.concat(matchRes);
    }

    console.log(matchObject);
}

async function main() {
    // await processTreatise("19005095000");
    // let res = await processText();

    // let testTreatises = await TreatiseRepo.getSampleTreatises();
    // console.log(testTreatises);

    let text = fs.readFileSync("../sample-treatises/Pomeroy, Remedies, 1976.txt", 'utf8');
    // console.log(text);
    let res = await processText(text);
    console.log(res);

    // for(let t of testTreatises) {
    //     // console.log(t.psmid);
    //     await processTreatise(t.psmid);
    // }

}

main();

