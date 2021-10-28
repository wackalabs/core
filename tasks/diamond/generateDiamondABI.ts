import fs from "fs";
import { AbiCoder } from "@ethersproject/abi";
import { task } from "hardhat/config";

const basePath = "contracts/Enepti/facets/";
// const libraryBasePath = "contracts/Enepti/libraries/";
const sharedLibraryBasePath = "contracts/shared/libraries/";

task("diamondABI", "Generates ABI file for diamond, includes all ABIs of facets").setAction(async () => {
  let files = fs.readdirSync("./" + basePath);
  const abi: AbiCoder[] = [];
  for (const file of files) {
    const jsonFile = file.replace("sol", "json");
    const json = JSON.parse(fs.readFileSync(`./artifacts/${basePath}${file}/${jsonFile}`).toString());
    abi.push(...json.abi);
  }
  // files = fs.readdirSync("./" + libraryBasePath);
  // for (const file of files) {
  //   const jsonFile = file.replace("sol", "json");
  //   const json = JSON.parse(fs.readFileSync(`./artifacts/${libraryBasePath}${file}/${jsonFile}`).toString());
  //   abi.push(...json.abi);
  // }
  files = fs.readdirSync("./" + sharedLibraryBasePath);
  for (const file of files) {
    const jsonFile = file.replace("sol", "json");
    const json = JSON.parse(fs.readFileSync(`./artifacts/${sharedLibraryBasePath}${file}/${jsonFile}`).toString());
    abi.push(...json.abi);
  }
  const finalAbi = JSON.stringify(abi, null, 2);
  fs.writeFileSync("./diamondABI/diamond.json", finalAbi);
  console.log("ABI written to diamondABI/diamond.json");
});
