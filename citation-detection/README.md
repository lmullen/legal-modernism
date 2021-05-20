# Setup

Prerequisites: NodeJS v 12.18.x or higher; npm

Recommended editor/IDE: Visual Studio code with Typescript and ES6+ related extensions. The `jsconfig.json` will include some common settings used to launch and debug.

1. Install the Knex CLI: `sudo npm install knex -g`.
2. Install app dependencies by running `npm install` from the `citation-detection` directory. 
3. Create a `.env` file in the `citation-detection` directory. 

# Running the Code

1. To compile the code, navigate to the `citation-detection` directory, and run `npm run build`. 
2. As the code currently stands, then run `node ./build/extraction.js` to execute whatever code is in the `main` function of that file.

# Outstanding Issues or Areas of Uncertainty

1. The code can't parse tables of contents and tables of cases properly. It gets very confused; if it sees "burn v wash, 541 U.S. 785 (2019)...71 beavis v. butthead, 56 F. Supp. 3d 76 (1999)...87", it might do "burn v. wash" correctly and parse out "541 U.S. 785", but it will also give you "71 beavis v. butthead 56" as another case identifier and not give the actual guid for that case. This is kind of okay; the code still goes through and manually count and parse all instances of the guid "56 F. Supp. 3d 76". 
2. I am not sure how good the code is at catching short cites, but also, I am not sure how consistent the short-citing is in older legal writings anyways. Nowadays it's very standard; "Girl v. The World, 761 U.S. 89 (2003)" would be subsequently cited as, e.g., "Girl, 761 U.S. at 91" (to cite to page 91). But I think the 19th century American treatises often use the British way of saying, for prominent cases, e.g., "Girl's case". 
3. Case names are put into the db escaped, and are not totally readable. May want to look into this.