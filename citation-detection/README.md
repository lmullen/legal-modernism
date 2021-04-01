# Setup

Prerequisites: NodeJS v 12.18.x or higher; npm

Recommended editor/IDE: Visual Studio code with Typescript and ES6+ related extensions. The `jsconfig.json` will include some common settings used to launch and debug.

1. Install the Knex CLI: `sudo npm install knex -g`.
2. Install app dependencies by running `npm install`. 
3. Create a `.env` file in the `citation-detection` directory. 

# Running the Code

1. To compile the code, navigate to the `citation-detection` directory, and run `npm run build`. 
2. As the code currently stands, then run `node ./build/extraction.js` to execute whatever code is in the `main` function of that file.