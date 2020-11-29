import devConfig from "./development";

const env = process.env.NODE_ENV || "development";

const baseConfig = {
    caseDotLaw: {
        APIKey: "09c734eea1cd0bffaf5f27f9ed4d11c289aa4b9f"
    }
};

let envConfig;

switch(env) {
    case "development":
        envConfig = devConfig;
        break;
    default:
        throw new Error(process.env.NODE_ENV);
}

const config = Object.assign(baseConfig, envConfig);
export default config;