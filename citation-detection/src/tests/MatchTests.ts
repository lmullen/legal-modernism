import { Expect, AsyncTest, TestCase } from "alsatian";

import { extractMatches } from "../extraction";
import { manyCitations0 } from "../test_text";

export class MatchTests {
    @AsyncTest()
    async testTest() {
        let res = await extractMatches(manyCitations0);
        Expect(res.length).toEqual(10);
    }
}