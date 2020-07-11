let catchallRegex: RegExp = new RegExp('([\d]{1,3}\s[a-zA-Z0-9\.]+\s[\d]{1,4})');

let res = catchallRegex.test("The District Court found that the States were likely to succeed on the merits of at least one of their claims and entered a \
   nationwide preliminary injunction barring implementation of both DAPA and the DACA expansion. See Texas v. United States, 86 F. Supp. 3d 591, 677–678 (2015)");

console.log(res);