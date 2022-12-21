import FlowGotchi from "../contracts/FlowGotchi.cdc"
import NonFungibleToken from "../contracts/shared/NonFungibleToken.cdc"

/// This transaction configures an account to hold FlowGotchi
///
transaction {

    prepare(acct: AuthAccount) {
        // create a new empty collection
        let collection <- FlowGotchi.createEmptyCollection()

        // save it to the account
        acct.save(<-collection, to: FlowGotchi.CollectionStoragePath)

        // create a public capability for the collection
        acct.link<&FlowGotchi.Collection{FlowGotchi.FlowGotchiCollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(FlowGotchi.CollectionPublicPath, target: FlowGotchi.CollectionStoragePath)
    }
}
