import * as fcl from "@onflow/fcl"

// Script
export const getMetaData = async (user) => {
  return await fcl.query({
    cadence: `
    import FlowGotchi from 0xf3429b0ff26fcb0f
    import MetadataViews from 0x631e88ae7f1d7c20
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
        let actions = nft.resolveView(Type<FlowGotchi.ActionStatus>())
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
    `,
    args: (arg, t) => [arg(user, t.Address)]
  });
}

// Script to check if the User has a FlowGotchi setup
export const hasFlowGotchi = async (user) => {
  return await fcl.query({
    cadence: `
        import FlowGotchi from 0xf3429b0ff26fcb0f
        pub fun main(address: Address): Bool {
          if let collectionRef = getAccount(address)
              .getCapability<
                  &{FlowGotchi.FlowGotchiCollectionPublic}
              >(
                  FlowGotchi.CollectionPublicPath
              ).borrow() {
              return collectionRef.getIDs().length > 0
          }
          return false
      }
    `,
    args: (arg, t) => [arg(user, t.Address)]
  });
}

// TX to setup a FlowGotchi
export const setupFlowGotchi = async () => {
  const transactionId = await fcl.mutate({
    cadence: `
      import FlowGotchi from 0xf3429b0ff26fcb0f
      import NonFungibleToken from 0x631e88ae7f1d7c20
      transaction {
        prepare(acct: AuthAccount) {
          if acct.borrow<&FlowGotchi.Collection>(from: FlowGotchi.CollectionStoragePath) == nil {
            let collection <- FlowGotchi.createEmptyCollection()
            acct.save(<-collection, to: FlowGotchi.CollectionStoragePath)
            acct.link<&FlowGotchi.Collection{FlowGotchi.FlowGotchiCollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(FlowGotchi.CollectionPublicPath, target: FlowGotchi.CollectionStoragePath)
          }
        }
      }
    `,
    payer: fcl.authz,
    proposer: fcl.authz,
    authorizations: [fcl.authz],
    limit: 9999
  });
  const transaction = await fcl.tx(transactionId).onceSealed()
  console.log(transaction)
}

// TX to mint a FlowGotchi
export const mintFlowGotchi = async () => {
  const transactionId = await fcl.mutate({
    cadence: `
      import FlowGotchi from 0xf3429b0ff26fcb0f
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
    `,
    payer: fcl.authz,
    proposer: fcl.authz,
    authorizations: [fcl.authz],
    limit: 9999
  });
  const transaction = await fcl.tx(transactionId).onceSealed()
  console.log(transaction)
}