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
import { getOrInsertCase, insertCase } from "./cases";
import { clearTreatiseCitations, createOrUpdateTreatiseEntry, getAllTreatises, incrementCitation } from "./treatises";
import { Case } from './cases/data/models';
import { PageOCRText } from './treatises/data/models';

let standardRegex: RegExp = /[\d]{1,3}\s[a-zA-Z\.\s]+\s[\d]{1,4}/gi;
let standardAppellateRegex: RegExp = /[\d]{1,3}\s[a-zA-Z\.\s]+\sApp\.\s[\d]{1,4}}/gi;

async function gatherRegexes(): Promise<RegExp[]> {
    let r = [standardRegex, standardAppellateRegex];

    //so there are these two catchall regexes above, and also specific regexes for each reporter CAP lists as having been active during the relevant time period. that list is incomplete. I think it would be best if finished; relying on the catchall regexes is not ideal, IMO
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

//extracts case guids from a given block of text
export async function extractCases(text: string) {
    let regexes = await gatherRegexes();

    let res = [];

    for (let reg of regexes) {
        let _res = await parseCases(text, reg);
        res = res.concat(_res);
    }

    return res;
}

//puts the resulting extracted cases in a place where other parts of the code can use them
export async function processText(text: string, matchObject) {
    let matchRes = await extractCases(text);
    matchObject.cases = matchObject.cases.concat(matchRes);
    //so, we pass this matchObject around. it's not the best software design, admittedly, a lot of the parts of this entire process started out as quick tests that just stuck
}

//once we have all the case guids from a given treatise, we record that these cases were cited in the treatise
export async function updateCitationCounts(matchObject) {
    console.log(`${matchObject.cases.length} possible cases`);
    for (let c of matchObject.cases) {
        try {
            let caseEntry: Case = await getOrInsertCase(c);
            if (caseEntry.existsOnCap) {
                console.log("found a case!");
                await incrementCitation(caseEntry.guid, matchObject.treatiseId);
            }
            else {
                console.log("not a case");
            }
        }
        catch (e) {
            // throw (e);
            console.log(`case entry error, guid: ${c}`);
            console.error(e);
        }

    }
}

//sort of the "master" function. Pre-processing of treatise; extraction of cases; post-processing of treatise, including actually recording the citations in our db
export async function processTreatise(treatiseId: string) {
    console.log(`hello, I am starting this treatise: ${treatiseId}`);
    await createOrUpdateTreatiseEntry(treatiseId);
    await clearTreatiseCitations(treatiseId);
    console.log(`treatise record located/created; citations cleared`);
    let pages = await OcrRepo.getOCRTextByTreatiseID(treatiseId);
    console.log(`pages: ${pages.length}`);

    let matchObject = {
        treatiseId: treatiseId,
        cases: []
    };

    for (let p of pages) {
        console.log(`processing page ${p.pageid}`);
        try {
            await processText(p.ocrtext, matchObject);
        }
        catch (e) {
            console.log("page process error");
            console.error(e);
        }
    }

    await updateCitationCounts(matchObject);
    await TreatiseRepo.updateTreatiseLastRun(treatiseId);
    await TreatiseRepo.setTreatiseProcessed(true, treatiseId);
    console.log(`hello, I am finished with this treatise: ${treatiseId}`);
}

async function singleTreatiseTest() {
    // const problemTreatise = "19004016900";
    const problemTreatise = "19004016900";
    await processTreatise(problemTreatise);
}

async function textTest(text: string) {
    let matchObject = {
        treatiseId: 0,
        cases: []
    };


    await processText(text, matchObject);

    // console.log(matchObject.cases);

}

async function properRun() {
    let ts = await getAllTreatises();
    ts = ts.slice(0, 15); //this how I was setting it to like only do 20 this day, or w/e
    for (let t of ts) {
        try {
            await processTreatise(t.psmid);
        }
        catch (e) {
            console.log(`something went wrong for ${t.psmid}!!`);
            console.error(e);
        }
    }
}

async function main() {
    await properRun();
    process.exit(1);
}

main();

