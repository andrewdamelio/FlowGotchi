import FlowToken from "../../contracts/shared/FlowToken.cdc"
import FungibleToken from "../../contracts/shared/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/shared/NonFungibleToken.cdc"
import FlowGotchi from "../../contracts/shared/FlowGotchi.cdc"
import MetadataViews from "../../contracts/shared/MetadataViews.cdc"

transaction() {
    let user: &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}

    prepare(signer: AuthAccount) {
        self.user = signer.borrow<&AnyResource{FlowGotchi.FlowGotchiCollectionPublic}>(from: FlowGotchi.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the FlowGotchi.FlowGotchiCollectionPublic resource")
    }

    execute {
        self.user.mintFlowGotchi()
    }
}
