import axios from "axios";

import config from "../config";

const API_ROOT = "https://api.case.law/v1/";

const requester = axios.create({
    baseURL: API_ROOT,
    headers: { 'Token': config.caseDotLaw.APIKey }
});

export default requester;


