import FlowGotchi from "../contracts/FlowGotchi.cdc"
transaction() {
    prepare(signer: AuthAccount) {
        // Get a reference to the signer's FlowGotchiCollectionPublic or panic
        let collectionRef = signer.borrow<
            &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}
        >(
            from: FlowGotchi.CollectionStoragePath
        ) ?? panic("Could not borrow a reference to the FlowGotchi.FlowGotchiCollectionPublic resource")

        // Get the FlowGotchi in the Collection
        if let flowGotchiRef = collectionRef.borrowFlowGotchi(id: collectionRef.getIDs()[0]) {
            flowGotchiRef.pet()
        } else  {
            panic("No FlowGotchis found!")
        }
    }
}