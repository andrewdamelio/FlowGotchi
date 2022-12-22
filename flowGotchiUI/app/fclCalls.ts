import * as fcl from "@onflow/fcl"

// Script to get TopShot Moment
export const getTopShotMoments = async (user) => {
  return await fcl.query({
    cadence: `
      import TopShot from 0x877931736ee77cff
      pub fun main(account: Address): [UInt64] {
        let acct = getAccount(account)
        let collectionRef = acct.getCapability(/public/MomentCollection).borrow<&{TopShot.MomentCollectionPublic}>()!
        return collectionRef.getIDs()
      }
    `,
    args: (arg, t) => [arg(user, t.Address)]
  });
}

// Script to get NFL AllDay Moments
export const getAllDayMoments = async (user) => {
  return await fcl.query({
    cadence: `
      import AllDay from 0x4dfd62c88d1b6462
      pub fun main(account: Address): [UInt64] {
        let acct = getAccount(account)
        let collectionRef = acct.getCapability(AllDay.CollectionPublicPath).borrow<&{AllDay.MomentNFTCollectionPublic}>()!
        return collectionRef.getIDs()
      }
    `,
    args: (arg, t) => [arg(user, t.Address)]
  });
}

// Script to get FlowGotchi MetaData
export const getMetaData = async (user) => {
  return await fcl.query({
    cadence: `
    import FlowGotchi from 0x3a9134be2cb28add
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
        import FlowGotchi from 0x3a9134be2cb28add
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

// TX to feed a FlowGotchi
export const feedFlowGotchi = async () => {
  const transactionId = await fcl.mutate({
    cadence: `
    import FlowGotchi from 0x3a9134be2cb28add
    transaction() {
        prepare(signer: AuthAccount) {
            let collectionRef = signer.borrow<
                &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}
            >(
                from: FlowGotchi.CollectionStoragePath
            ) ?? panic("Could not borrow a reference to the FlowGotchi.FlowGotchiCollectionPublic resource")
            if let flowGotchiRef = collectionRef.borrowFlowGotchi(id: collectionRef.getIDs()[0]) {
                flowGotchiRef.feed()
            } else  {
                panic("No FlowGotchis found!")
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

// TX to pet a FlowGotchi
export const petFlowGotchi = async () => {
  const transactionId = await fcl.mutate({
    cadence: `
    import FlowGotchi from 0x3a9134be2cb28add
    transaction() {
        prepare(signer: AuthAccount) {
            let collectionRef = signer.borrow<
                &AnyResource{FlowGotchi.FlowGotchiCollectionPublic}
            >(
                from: FlowGotchi.CollectionStoragePath
            ) ?? panic("Could not borrow a reference to the FlowGotchi.FlowGotchiCollectionPublic resource")
            if let flowGotchiRef = collectionRef.borrowFlowGotchi(id: collectionRef.getIDs()[0]) {
                flowGotchiRef.pet()
            } else  {
                panic("No FlowGotchis found!")
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

// TX to setup a FlowGotchi
export const setupFlowGotchi = async () => {
  const transactionId = await fcl.mutate({
    cadence: `
      import FlowGotchi from 0x3a9134be2cb28add
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
      import FlowGotchi from 0x3a9134be2cb28add
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