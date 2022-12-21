import FlowGotchi from "../contracts/FlowGotchi.cdc"

/// Transaction to pet the FlowGotchi NFT in the signer's Collection.
/// Panics if there is no Collection configured with a FlowGotchiCollectionPublic Capability
/// configured at the expected path or if there is no FlowGotchi contained in the Collection
///
transaction() {

    prepare(signer: AuthAccount) {
        // Get a reference to the signer's FlowGotchiCollectionPublic or panic
        let collectionRef = signer.borrow<
            &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}
        >(
            from: FlowGotchi.CollectionStoragePath
        ) ?? panic("Could not borrow a reference to the FlowGotchi.FlowGotchiCollectionPublic resource")
        
        // Get the FlowGotchi in the Collection
        if let flowGotchiRef = collectionRef.borrowFlowGotchi(id: 0) {            
            flowGotchiRef.pet()
        } else  {
            panic("No FlowGotchis found!")
        }
    }
}