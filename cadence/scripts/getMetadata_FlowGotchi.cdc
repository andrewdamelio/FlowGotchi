import FlowGotchi from "../../contracts/shared/FlowGotchi.cdc"
import MetadataViews from "../../contracts/shared/MetadataViews.cdc"

/// This script gets all the view-based metadata associated with the specified NFT
/// and returns it as a single struct
pub struct NFT {
    pub let name: String
    pub let description: String
    pub let thumbnail: String
    pub let owner: Address
    pub let traits: AnyStruct?
    pub let actions: AnyStruct?
    pub let quests: AnyStruct?

    init(
        name: String,
        description: String,
        thumbnail: String,
        owner: Address,
        traits: AnyStruct?,
        actions: AnyStruct?,
        quests: AnyStruct?
    ) {
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.owner = owner

        self.traits = traits
        self.actions = actions
        self.quests = quests
    }
}

pub fun main(address: Address): NFT {
    let account = getAccount(address)

    let collection = account
        .getCapability(FlowGotchi.CollectionPublicPath)
        .borrow<&{FlowGotchi.FlowGotchiCollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection")


    let nft = collection.borrowFlowGotchi(id: collection.getIDs()[0])!

    // Get the basic display information for this NFT
    let display = MetadataViews.getDisplay(nft)!

    let owner: Address = nft.owner!.address!
    let actions = nft.resolveView(Type<FlowGotchi.Actions>())
    let traits = nft.resolveView(Type<FlowGotchi.Traits>())
    let quests = nft.resolveView(Type<FlowGotchi.Quests>())

    return NFT(
        name: display.name,
        description: display.description,
        thumbnail: display.thumbnail.uri(),
        owner: owner,
        traits: traits,
        actions: actions,
        quests: quests,
    )
}