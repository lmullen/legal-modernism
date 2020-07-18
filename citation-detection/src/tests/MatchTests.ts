import { Expect, AsyncTest, TestCase } from "alsatian";

import { extractMatches } from "../extraction";
import { manyCitations0, testText1, testText2 } from "../testText";

export class MatchTests {

   @AsyncTest()
    async testSimple() {
        let res = await extractMatches(testText1);
        Expect(res.length).toEqual(1);
        Expect(res[0]).toEqual("3 Comst. 547");
    }

    @AsyncTest()
    async testTwo(){
        let res = await extractMatches(testText2);
        Expect(res.length).toEqual(3);
        Expect(res[0]).toEqual("sp. t.");
        Expect(res[1]).toEqual("12 How. 289");
        Expect(res[2]).toEqual("4 Paige, 92");
    }

    @AsyncTest()
    async testMany() {
        let res = await extractMatches(manyCitations0);
        Expect(res.length).toEqual(10);
    }
}