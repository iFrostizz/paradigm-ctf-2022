import tree from '../src/merkledrop/public/tree.json' assert {type: 'json'}


const main = () => {
    const claims = tree["claims"];

    const maxAmount = hex_as_int(tree["tokenTotal"])

    for (const account in claims) {
        const claim = claims[account]

        const proof1 = claim["proof"][0]
        const proof2 = claim["proof"][1]

        /*const fake_proof = proof1 + proof2.substring(2)
        const trimmed_proof = fake_proof.substring(2)*/

        const fake_proof = proof1.substring(2)

        // 1 bytes = 8 bits
        // 1 hex nibble = 256 bits (2*8*8
        //              = 32 bytes

        /*const index = trimmed_proof.substring(0, 64)
        const address = trimmed_proof.substring(64, 104)
        const amount = trimmed_proof.substring(104)*/

        const address = fake_proof.substring(0, 40) // 2 hex = 1 byte
        const amount = fake_proof.substring(40)

        if (maxAmount >= hex_as_int(amount)) {
            console.log(claim["index"], fake_proof, "0x" + address, hex_as_int(amount))
        }
        // Now that we have found a correct amount, we can pad the index, can be done in solidity
    }
}

const hex_as_int = (hex) => {
    return parseInt(hex, 16)
}

main()