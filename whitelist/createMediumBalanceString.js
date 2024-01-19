const fs = require('fs')
const addresses = JSON.parse(fs.readFileSync('./whitelist/data/addresses.json'))
let text = ''

for (addy of addresses) {
    text += `       sum += degen.balanceOf(${addy});\n`
    text += `       count++;\n`

}
fs.writeFileSync('./whitelist/data/mediumBalance.sol', text)