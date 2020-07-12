import * as testTexts from "./test_text";

let catchallRegex : RegExp = /[\d]{1,3}\s[a-zA-Z0-9\.]+\s[\d]{1,4}/;

// let res = catchallRegex.exec(testTexts.manyCitations0);
let res = testTexts.manyCitations0.matchAll(catchallRegex);

console.log(res);
// for(var x in res){
//     console.log(x);
// }