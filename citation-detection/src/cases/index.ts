import requester from '../caseDotLaw/requester';


export async function locateCase(guid: string) {
    let requestURL: string = `/cases/?cite=${guid}`;
    let data = await requester.get(requestURL);
    let numRes = data.data.count; 
    // console.log(numRes);
    // console.log(data.data);

    if (numRes == 0) {
        return null;
    }

    if (numRes > 1) {
        //do something in the unlikely event more than one case matches the guid
    }

    // if()
}