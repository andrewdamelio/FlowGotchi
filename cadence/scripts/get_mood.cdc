import FlowGotchi from "../contracts/FlowGotchi.cdc"

/// Script to get the mood of the FlowGotchi at the address
///
pub fun main(address: Address): String? {

    // Get a reference to the signer's FlowGotchiCollectionPublic or panic
    if let collectionRef = getAccount(address).getCapability<
        &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}
    >(
        FlowGotchi.CollectionPublicPath
    ).borrow() {
        // Get the FlowGotchi in the Collection
        if let flowGotchiRef = collectionRef.borrowFlowGotchi(id: 0) {
            // Return its mood
            return flowGotchiRef.getMood()
        }
    }
    // Nothing found return nil
    return nil
}
