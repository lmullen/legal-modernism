import * as _regex from "xregexp";

import * as testTexts from "./test_text";

let catchallRegex : RegExp = /[\d]{1,3}\s[a-zA-Z0-9\.]+\s[\d]{1,4}/g;

// testTexts.manyCitations0.matchAll(catchallRegex).forEach((x) => {
//     console.log(x);
// });
let res;
let match;
let result;

while ((result = catchallRegex.exec(testTexts.manyCitations0)) !== null) {
    console.log(result[0]);
}