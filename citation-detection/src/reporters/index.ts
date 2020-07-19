import * as _ from "lodash";

import { lastItem, camelCase } from "../utils";
import requester from "../caseDotLaw/requester";

type reporter = {
    id: number,
    url: string,
    fullName: string,
    shortName: string,
    startYear: number,
    endYear: number,
    jurisdictions: any[]
};

function reporterInRange(r: reporter) {
    if (r.startYear > 1900) {
        return false;
    }

    if (r.endYear < 1800) {
        return false;
    }

    return true;
}

async function main() {
    let res = await requester.get("/reporters");
    console.log(res.data);
    // console.log(res.data.results.length);
    // console.log(lastItem(res.data.results));

    res.data.results.forEach((r) => {
        r = camelCase(r);
    });

    let inRange: reporter[] = _.filter(res.data.results, reporterInRange);

    console.log(inRange);

}

main();