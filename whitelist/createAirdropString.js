const fs = require('fs')
const addresses = JSON.parse(fs.readFileSync('./whitelist/data/addresses.json'))

let text = `address[] memory players = new address[](${addresses.length});\n`
let index = 0
for (addy of addresses) {
    text += `       players[${index++}] = ${addy};\n`
}
fs.writeFileSync('./whitelist/data/airdrop.sol', text)