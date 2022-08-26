use ethers::abi::{AbiEncode, Tokenizable};
use ethers::core::k256::sha2::Digest;
use ethers::{
    abi::{encode, HumanReadableParser, Token},
    core::{k256::sha2::Sha256, rand::thread_rng},
    prelude::*,
    types::{Bytes, Selector, H256},
    utils::{hex, keccak256},
};
use rayon::prelude::*;
use std::str::FromStr;

// We need to encode selector + MAGIC and loop over random bytes to find a clashing sig
fn main() {
    let func = HumanReadableParser::parse_function("isValidSignature(bytes32,bytes)").unwrap();

    let selector = hex::encode(func.short_signature());

    dbg!(&selector);

    let magic: H256 = keccak256("CHALLENGE_MAGIC".to_string().as_bytes()).into();

    std::iter::repeat_with(move || H256::random_using(&mut thread_rng()))
        .enumerate()
        .par_bridge()
        .for_each(|(idx, sig)| {
            // dbg!(&magic.into_token(), &sig.into_token());
            let sig_bytes = sig.clone().as_bytes().to_vec();
            let bytes: Vec<u8> = sig_bytes;
            let calldata = func
                .encode_input(&[magic.into_token(), Token::Bytes(bytes)])
                .unwrap();

            let mut hasher = Sha256::new();
            hasher.update(calldata);
            let result = hasher.finalize();

            let calldata = hex::encode(result);

            // dbg!(&calldata);

            if calldata.starts_with("1626ba7") {
                println!("not yet: {:#?}", &calldata);
            } else if calldata.starts_with("1626ba7e") {
                println!("not yet: {:#?}", &calldata);
                dbg!("4");
            }

            if calldata.starts_with(&selector) {
                println!("{:#?}", &calldata);
                println!("sig found: {:#?}", &sig);
            }

            if idx % 10000000 == 0 {
                println!("{}", idx);
            }
        })
}
