import * as _ from "lodash";
import * as fs from "fs";

import { lastItem, camelCase, promise } from "../utils";
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

export function reporterInRange(r: reporter) {
    if (r.startYear > 1900) {
        return false;
    }

    if (r.endYear < 1800) {
        return false;
    }

    return true;
}

function makeNextUrl(next: string) {
    if (!next) {
        return null;
    }

    let split = next.split("?");

    return "/reporters?" + split[1];
}

async function main() {
    let next = "something";
    let res = await requester.get("/reporters/?cursor=cD1Db25uZWN0aWN1dCtDaXJjdWl0K0NvdXJ0K1JlcG9ydHMmbz0y");
    let actualResp = res.data;
    next = makeNextUrl(actualResp.next);
    // console.log(next);
    let list: reporter[] = [];

    while (next) {
        res = await requester.get(next);
        let actualResp = res.data;
        let formatted = [];

        for (let r of res.data.results) {
            formatted.push(camelCase(r));
        }

        let inRange: reporter[] = _.filter(formatted, reporterInRange);
        list = list.concat(inRange);

        next = makeNextUrl(actualResp.next);
        console.log(next);
    }

    console.log(list);

    let listAsJSON = JSON.stringify(list);
    await promise(fs.writeFile.bind(fs, "myjsonfile.json", listAsJSON, "utf8")); 
}

main();