import FungibleToken from "../contracts/shared/FungibleToken.cdc"
import NonFungibleToken from "../contracts/shared/NonFungibleToken.cdc"
import MetadataViews from "../contracts/shared/MetadataViews.cdc"
import FlowGotchi from "../contracts/FlowGotchi.cdc"

/// Transaction to mint a FlowGotchi.NFT using the `mintFlowGotchi()` method
/// defined in the Collection. The NFT is minted directly to the Collection
/// which can only contain one FlowGotchi
///
transaction() {

    let collection: &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}

    prepare(signer: AuthAccount) {
        self.collection = signer.borrow<
            &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}
        >(
            from: FlowGotchi.CollectionStoragePath
        ) ?? panic("Could not borrow a reference to the FlowGotchi.FlowGotchiCollectionPublic resource")
    }

    execute {
        self.collection.mintFlowGotchi()
    }
}
