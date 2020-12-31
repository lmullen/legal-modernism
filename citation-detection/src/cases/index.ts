import requester from '../caseDotLaw/requester';


export async function locateCase(guid: string) {
    let requestURL: string = `/cases/?cite=${guid}`;
    let data = await requester.get(requestURL);
    let numRes = data.data.count; 
    console.log(numRes);
    console.log(data.data);
}