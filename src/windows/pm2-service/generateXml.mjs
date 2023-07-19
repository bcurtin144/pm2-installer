import process from "node:process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import xml from "xml";

import { PM2_HOME, PM2_SERVICE_DIRECTORY } from "./env.js";


let [ directory, user ] = process.argv.slice(2);

const workingdirectory = directory ?? PM2_SERVICE_DIRECTORY;
user ??= "NT AUTHORITY\\LOCAL SERVICE";

let serviceaccount;
const userTokens = user.split("\\");
if ( userTokens.length > 1 ) {
	serviceaccount = [
		{ domain: userTokens[0] },
		{ user: userTokens[1] },
	];
}
else {
	serviceaccount = [
		{ user }
	];
}

const configWinSW = {
	service: [
		{ id: "pm2" },
		{ name: "PM2 (using WinSW)" },
		{ description: "Node Process Manager" },

		{ executable: process.execPath },
		{ argument: path.join( workingdirectory, "index.js" ) },
		{ workingdirectory },

		{ env: { _attr: { name: "PM2_HOME", value: PM2_HOME }} },

		{ serviceaccount },
		{ stoptimeout: "20sec" },

		{ logmode: "roll" },
	],
}

const data = xml( configWinSW, { indent: '\t' } ).replace( /\n/g,'\r\n' );

const __dirname = path.dirname( fileURLToPath(import.meta.url) );
const target = path.join( __dirname, 'daemon' );

if (!fs.existsSync(target)){
    fs.mkdirSync(target);
}

fs.writeFileSync( path.resolve( target, 'pm2.xml' ), data, { encoding: "utf8" });
