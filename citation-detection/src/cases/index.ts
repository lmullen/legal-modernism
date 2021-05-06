import requester from '../caseDotLaw/requester';
import { Case } from "./data/models";
import CaseRepo from "./data/caseRepo";

//gets numerical year from CAP "decision_date" string
function _stripYear(d: string) {
    let split = d.split("-");
    let stringYear = split[0];
    let numYear = parseInt(stringYear);
    return numYear;
}

//not sure how much unescaping the strings matters rn
// export async function getCase(guid: string) {
//     let c: Case = await CaseRepo.getBy("guid", guid);
//     c.fullName = unescape(c.fullName);

// }

//I think 'case' is some sort of reserved keyword in Typescript, or maybe just VS Code
export async function getOrInsertCase(guid: string) {
    let c = await CaseRepo.getBy("guid", guid);

    if (!c) {
        c = await locateCase(guid);

        if (!c) {
            c = new Case();
            c.guid = guid;
            c.existsOnCap = false;
            return c;
        }

    }

    await insertCase(c);

    return c;
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

    let c = _mapCase(res, guid);
    c.existsOnCap = true;
    return c;

}

function _mapCase(res, guid) {
    let c = new Case();
    c.caseDotLawId = res.id;
    console.log(res.name);
    console.log(res.name_abbreviation);
    c.fullName = escape(res.name);
    c.shortName = escape(res.name_abbreviation);
    c.year = _stripYear(res.decision_date);
    c.guid = guid;

    return c;
}

export async function insertCase(c: Case) {
    await CaseRepo.insertCase(c);
}