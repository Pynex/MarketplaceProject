import { HardhatUserConfig} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as path from 'path';
import "hardhat-abi-exporter";
import 'solidity-coverage';
import './Tasks/Sample.task';


const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    hardhat: {},
  },
  paths: {
    artifacts: './artifacts',
    cache: './cache',
    sources: './contracts',
    tests: './test',
  },
  abiExporter: {
    path: path.join(__dirname, 'abi'),
    runOnCompile: true,
    clear: true,
    flat: true,
    only: [],
    spacing: 2,
    format: "json",
  }, 
};

export default config;