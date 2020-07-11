let catchallRegex : RegExp = /[\d]{1,3}\s[a-zA-Z0-9\.]+\s[\d]{1,4}/;

let res = catchallRegex.test(" The Act restructures federal regulation by insisting that a person wishing to discharge any pollution into navigable waters first obtain EPA’s permission to do so. \
See id., at 203–205; Milwaukee v. Illinois, 451 U.S. 304, 310–311 (1981).");

console.log(res);