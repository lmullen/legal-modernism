import * as xregex from "xregexp";
import * as _ from "lodash";
import * as fs from "fs";

import * as testTexts from "./testText";
import reporterList from './reporters/reporters';
import { getReporterByID } from "./reporters";
import { rawQuery } from "./infrastructure/data/dataTest";
import TreatiseRepo from "./treatises/data/treatiseRepo";
import CitationRepo from "./treatises/data/CitationRepo";
import OcrRepo from "./treatises/data/ocrRepo";
import { getOrInsertCase } from "./cases";
import { incrementCitation } from "./treatises";
import { Case } from './cases/data/models';
import { PageOCRText } from './treatises/data/models';

let standardRegex: RegExp = /[\d]{1,3}\s[a-zA-Z\.\s]+\s[\d]{1,4}/gi;
let standardAppellateRegex: RegExp = /[\d]{1,3}\s[a-zA-Z\.\s]+\sApp\.\s[\d]{1,4}}/gi;

async function gatherRegexes(): Promise<RegExp[]> {
    let r = [standardRegex, standardAppellateRegex];

    let reportersWithSpecial = _.filter(reporterList, (r) => { return r.useSpecial });
    let specialRegexes = reportersWithSpecial.map((r) => { return r.regEx; });

    r = r.concat(specialRegexes);
    return r;
}

export async function parseCases(text: string, regex?: RegExp): Promise<string[]> {
    let res = [];
    let match;
    // It's stupid, but this is how one must find all matches in a text to a regex in JS.
    while ((match = regex.exec(text)) !== null) {
        res.push(match[0]);
    }

    return res;
}

export async function extractCases(text: string) {
    let regexes = await gatherRegexes();

    let res = [];

    for (let reg of regexes) {
        let _res = await parseCases(text, reg);
        res = res.concat(_res);
    }

    return res;
}

export async function processText(text: string, matchObject) {
    let matchRes = await extractCases(text);
    matchObject.cases = matchObject.cases.concat(matchRes);
    // return matchObject;
}

export async function updateCitationCounts(matchObject) {
    // console.log(matchObject);
    for (let c of matchObject.cases) {
        let caseEntry = await getOrInsertCase(c);

        if (caseEntry) {
            console.log("a case");
            // console.log(caseEntry);
            await incrementCitation(caseEntry.guid, matchObject.treatiseId);
        }
        else {
            console.log("not a case");
        }
    }
}

export async function processTreatise(treatiseId: string) {
    let pages = await OcrRepo.getOCRTextByTreatiseID(treatiseId);
    console.log(pages.length);

    let matchObject = {
        treatiseId: treatiseId,
        cases: []
    };

    for (let p of pages) {
        // console.log(p);
        await processText(p.ocrtext, matchObject);
    }

    console.log(matchObject.cases);

    await updateCitationCounts(matchObject);
}

async function main() {
    await processTreatise("19007469900");
    process.exit(1);
}

main();

