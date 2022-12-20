import FlowGotchi from "../../contracts/shared/FlowGotchi.cdc"
import MetadataViews from "../../contracts/shared/MetadataViews.cdc"

/// This script gets all the view-based metadata associated with the specified NFT
/// and returns it as a single struct
pub struct NFT {
    pub let name: String
    pub let description: String
    pub let thumbnail: String
    pub let owner: Address
    // pub let type: String
    // pub let royalties: [MetadataViews.Royalty]
    // pub let externalURL: String
    // pub let serialNumber: UInt64
    // pub let collectionPublicPath: PublicPath
    // pub let collectionStoragePath: StoragePath
    // pub let collectionProviderPath: PrivatePath
    // pub let collectionPublic: String
    // pub let collectionPublicLinkedType: String
    // pub let collectionProviderLinkedType: String
    // pub let collectionName: String
    // pub let collectionDescription: String
    // pub let collectionExternalURL: String
    // pub let collectionSquareImage: String
    // pub let collectionBannerImage: String
    // pub let collectionSocials: {String: String}
    // pub let edition: MetadataViews.Edition
    pub let traits: AnyStruct?
    pub let actions: AnyStruct?

	// 	pub let medias: MetadataViews.Medias?
	// 	pub let license: MetadataViews.License?

/*
        nftType: String,
        royalties: [MetadataViews.Royalty],
        externalURL: String,
        serialNumber: UInt64,
        collectionPublicPath: PublicPath,
        collectionStoragePath: StoragePath,
        collectionProviderPath: PrivatePath,
        collectionPublic: String,
        collectionPublicLinkedType: String,
        collectionProviderLinkedType: String,
        collectionName: String,
        collectionDescription: String,
        collectionExternalURL: String,
        collectionSquareImage: String,
        collectionBannerImage: String,
        collectionSocials: {String: String},
        edition: MetadataViews.Edition,
        traits: AnyStruct?,
				medias:MetadataViews.Medias?,
				license:MetadataViews.License?
                */
    init(
        name: String,
        description: String,
        thumbnail: String,
        owner: Address,
        traits: AnyStruct?,
        actions: AnyStruct?
    ) {
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.owner = owner
        // self.type = nftType
        // self.royalties = royalties
        // self.externalURL = externalURL
        // self.serialNumber = serialNumber
        // self.collectionPublicPath = collectionPublicPath
        // self.collectionStoragePath = collectionStoragePath
        // self.collectionProviderPath = collectionProviderPath
        // self.collectionPublic = collectionPublic
        // self.collectionPublicLinkedType = collectionPublicLinkedType
        // self.collectionProviderLinkedType = collectionProviderLinkedType
        // self.collectionName = collectionName
        // self.collectionDescription = collectionDescription
        // self.collectionExternalURL = collectionExternalURL
        // self.collectionSquareImage = collectionSquareImage
        // self.collectionBannerImage = collectionBannerImage
        // self.collectionSocials = collectionSocials
        // self.edition = edition
        self.traits = traits
        self.actions = actions
		// 		self.medias=medias
		// 		self.license=license
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

    // // Get the royalty information for the given NFT
    // let royaltyView = MetadataViews.getRoyalties(nft)!

    // let externalURL = MetadataViews.getExternalURL(nft)!

    // let collectionDisplay = MetadataViews.getNFTCollectionDisplay(nft)!
    // let nftCollectionView = MetadataViews.getNFTCollectionData(nft)!

    // let nftEditionView = MetadataViews.getEditions(nft)!
    // let serialNumberView = MetadataViews.getSerial(nft)!

    let owner: Address = nft.owner!.address!
    // let nftType = nft.getType()
    let actions = nft.resolveView(Type<FlowGotchi.Actions>())

    let traits = nft.resolveView(Type<FlowGotchi.Traits>())

    // let collectionSocials: {String: String} = {}
    // for key in collectionDisplay.socials.keys {
    //     collectionSocials[key] = collectionDisplay.socials[key]!.url
    // }

    // let traits = MetadataViews.getTraits(nft)!

	// 	let medias=MetadataViews.getMedias(nft)
	// 	let license=MetadataViews.getLicense(nft)

    return NFT(
        name: display.name,
        description: display.description,
        thumbnail: display.thumbnail.uri(),
        owner: owner,
        traits: traits,
        actions: actions,
    )
}