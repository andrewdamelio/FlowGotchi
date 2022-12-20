import FungibleToken from "../../contracts/shared/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/shared/NonFungibleToken.cdc"
import FlowGotchi from "../../contracts/shared/FlowGotchi.cdc"
import MetadataViews from "../../contracts/shared/MetadataViews.cdc"

/// Transaction to pet the FlowGotchi NFT in the signer's Collection.
/// Panics if there is no Collection configured with a FlowGotchiCollectionPublic Capability
/// configured at the expected path or if there is no FlowGotchi contained in the Collection
///
transaction() {
    
    let flowGotchi: &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}

    prepare(signer: AuthAccount) {
        // Get a reference to the signer's FlowGotchiCollectionPublic or panic
        let collectionRef = signer.borrow<
            &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}
        >(
            from: FlowGotchi.CollectionStoragePath
        ) ?? panic("Could not borrow a reference to the FlowGotchi.FlowGotchiCollectionPublic resource")
        
        // Get the FlowGotchi in the Collection
        if let flowGotchiRef = collectionRef.getIDs()[0] {
            self.flowGotchi = flowGotchiRef
        } ?? panic("No FlowGotchis found!")
    }

    execute {
        self.flowGotchi.pet()
    }
}