import requester from '../caseDotLaw/requester';
import { Case } from "./data/models";
import CaseRepo from "./data/caseRepo";

//gets numerical year from CAP "decision_date" string
function stripYear(d: string) {
    let split = d.split("-");
    let stringYear = split[0];
    let numYear = parseInt(stringYear);
    return numYear;
}

//I think 'case' is some sort of reserved keyword in Typescript, or maybe just VS Code
export async function getOrInsertCase(guid: string) {
    // let cases: any[] = await CaseRepo.fetchCase(guid);
    let c = await CaseRepo.getBy("full_name", "test");

    // if (!c) {
    //     c = await locateCase(guid);
    //     CaseRepo.insertCase(c);
    // }

    // return c;
}


async function locateCase(guid: string): Promise<Case> {
    let requestURL: string = `/cases/?cite=${guid}`;
    let data = await requester.get(requestURL);
    let numRes = data.data.count;

    if (numRes == 0) {
        return null;
    }

    if (numRes > 1) {
        //do something in the unlikely event more than one case matches the guid
        return null;
    }

    let res = data.data.results[0];

    // let caseYear = stripYear(res.decision_date);

    let c = new Case();
    c.caseDotLawId = res.id;
    c.fullName = res.name;
    c.shortName = res.name_abbreviation;
    c.year = stripYear(res.decision_date);
    c.guid = guid;

    console.log(c);
    return c;
}