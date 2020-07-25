import { Expect, AsyncTest, TestCase } from "alsatian";

import { reporterInRange } from "../reporters";

export class ReporterTests {

    // Tests whether a reporter pulled from case.law was active during the 19th century.
    @AsyncTest()
    @TestCase(1764, 1890, true)
    @TestCase(1899, 1900, true)
    @TestCase(1791, 2050, true)
    @TestCase(1901, 2011, false)
    async testReporterInRange(startDate: number, endDate: number, expectedRes: boolean) {
        let x = {
            startYear: startDate,
            endYear: endDate,
            id: 0,
            fullName: "test reporter",
            shortName: "testrep",
            jurisdictions: [],
            url: "ffff.com"
        };

        let res = reporterInRange(x);
        Expect(res).toEqual(expectedRes);
    }
}