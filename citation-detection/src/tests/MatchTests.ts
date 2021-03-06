import { Expect, AsyncTest, TestCase, FocusTest } from "alsatian";

import { parseCases } from "../extraction";
import { manyCitations0, testText1, testText2, testText5, treatiseTest0 } from "../testText";
// import { reporter } from '../reporters/types/index';
import reporterList from '../reporters/reporters';
import { getReporterByID } from "../reporters";

export class MatchTests {

    @AsyncTest()
    @TestCase(testText1, "3 Comst. 547")
    async testSimple(text: string, expected: string) {
        let res = await parseCases(testText1);
        Expect(res.length).toEqual(1);
        Expect(res[0]).toEqual(expected);
    }

    @AsyncTest()
    async testTwo() {
        let res = await parseCases(testText5);
        Expect(res.length).toEqual(2);
        Expect(res[0]).toEqual("7 East, 405");
        Expect(res[1]).toEqual("4 Taunt. 557");
    }

    @AsyncTest()
    async testThree() {
        let res = await parseCases(testText2);
        Expect(res.length).toEqual(2);
        // Expect(res[0]).toEqual("sp. t.");
        Expect(res[0]).toEqual("12 How. 289");
        Expect(res[1]).toEqual("4 Paige, 92");
    }

    // @AsyncTest()
    // async testMany() {
    //     let res = await extractMatches(treatiseTest0);
    //     Expect(res.length).toEqual(10);
    // }
    @FocusTest
    @AsyncTest()
    async testSpacing() {
        let reporter = await getReporterByID(20); 
        let regex = reporter.regEx;

        let res = await parseCases(treatiseTest0, regex);
        Expect(res.length).toEqual(2);
        Expect(res[0]).toEqual("36 N. Y. 613");
    }
}