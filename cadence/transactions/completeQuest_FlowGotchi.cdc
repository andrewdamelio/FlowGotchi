import FlowToken from "../contracts/shared/FlowToken.cdc"
import FungibleToken from "../contracts/shared/FungibleToken.cdc"
import NonFungibleToken from "../contracts/shared/NonFungibleToken.cdc"
import FlowGotchi from "../contracts/FlowGotchi.cdc"
import MetadataViews from "../contracts/shared/MetadataViews.cdc"

transaction(questId: UInt64) {
    let collection: &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}

    prepare(signer: AuthAccount) {
        self.collection = signer.borrow<&AnyResource{FlowGotchi.FlowGotchiCollectionPublic}>(from: FlowGotchi.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the FlowGotchi.FlowGotchiCollectionPublic resource")
    }

    execute {
        let nft = self.collection.borrowFlowGotchi(id: self.collection.getIDs()[0])!

        nft.completeQuest(questIdentifier: questId)
    }
}