const axios = require('axios')
const { ethers } = require("ethers")
const fs = require('fs')

const provider = new ethers.InfuraProvider()
let addressArray = []
const fidSeen = new Map()

const yo = async () => {
    let res = await axios.get('http://127.0.0.1:2281/v1/castsByParent?fid=2757&hash=0x793eb1289bd927de5aeac37cee7795a042ed87c6')
    for (message of res.data.messages) {
        let {fid, castAddBody} = message.data

        let {text, parentCastId} = castAddBody
        if (parentCastId.hash != '0x793eb1289bd927de5aeac37cee7795a042ed87c6') continue
        let address
        if(text.includes('.eth')) {
            let ens = text.match(/[a-zA-Z0-9]+\.eth/gm)
            if (ens == null) continue
            address = await provider.resolveName(ens[0])
        } else {
            address = text.match(/0x[a-zA-Z0-9]+/gm)
            if (address == null) continue
            address = address[0]
        }
        if (address) {
            addressArray.push(ethers.getAddress(address))
        }
    }
    let uniqueArray = [...new Set(addressArray)]
    fs.writeFileSync('./whitelist/data/addresses.json', JSON.stringify(uniqueArray))
}

yo()