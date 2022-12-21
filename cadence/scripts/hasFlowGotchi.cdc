import FlowGotchi from "../contracts/FlowGotchi.cdc"

/// Script to tell if an address has a FlowGotchi Collection with an NFT in it
///
pub fun main(address: Address): Bool {
    if let collectionRef = getAccount(address)
        .getCapability<
            &{FlowGotchi.FlowGotchiCollectionPublic}
        >(
            FlowGotchi.CollectionPublicPath
        ).borrow() {
        return collectionRef.getIDs().length > 0
    }
    return false
}