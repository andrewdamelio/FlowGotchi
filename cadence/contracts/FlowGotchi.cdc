/*
*
  _____ _                ____       _       _     _
 |  ___| | _____      __/ ___| ___ | |_ ___| |__ (_)
 | |_  | |/ _ \ \ /\ / / |  _ / _ \| __/ __| '_ \| |
 |  _| | | (_) \ V  V /| |_| | (_) | || (__| | | | |
 |_|   |_|\___/ \_/\_/  \____|\___/ \__\___|_| |_|_|

*
*/

import NonFungibleToken from "./shared/NonFungibleToken.cdc"
import MetadataViews from "./shared/MetadataViews.cdc"
import FungibleToken from "./shared/FungibleToken.cdc"
import FlowToken from "./shared/FlowToken.cdc"

pub contract FlowGotchi: NonFungibleToken {
    pub var nextGotchi: UInt8
    pub var totalSupply: UInt64
    pub var gotchiOwners: {Address: Bool}

    pub event ContractInitialized()
    pub event Debug(log: String)
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub struct Traits {
        // TODO how does this go down / up?
        pub var health: UInt64
        // Goes up by 1 every time you PET, maybe it goes down every day if you don't PET
        pub var friendship: UInt64
        // TODO how does this get set?
        pub var mood: UInt64
        // Blockheight is the age
        pub var age: UInt64
        // Feeding FlowGotchi will reset this to 0, should increaes with every FlowGotchi interaction
        pub var hunger: UInt64

        init(
            health: UInt64,
            friendship: UInt64,
            mood: UInt64,
            age: UInt64,
            hunger: UInt64
        ) {
            self.health = health
            self.friendship = friendship
            self.mood = mood
            self.age = age
            self.hunger = hunger
        }

    }

    pub enum QuestStatus: UInt8 {
        pub case Incomplete
        pub case Completed
        pub case Claimed
    }

    pub struct Actions {
        pub let canPet: UInt64                // TODO Can only PET every HOUR
        pub let canFeed: UInt64               // TODO Can only FEED every 3 HOUR

        init(
            canPet: UInt64,
            canFeed: UInt64,
        ) {
            self.canPet = canPet
            self.canFeed = canFeed
        }
    }

    pub struct Quests {
        access(account) var status: QuestStatus
        pub var name: String
        pub var description: String


        init(
            status: QuestStatus,
            name: String,
            description: String,
        ) {
            self.status = status
            self.name = name
            self.description = description
        }

        pub fun updateStatus(status: QuestStatus) {
            self.status = status
        }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: String

        // Quest Status (TODO move to another contract)
        access(self) let quests: {UInt64: AnyStruct}

        // FlowGotchi actions block amount cooldowns
        pub let canPetCoolDown: UInt64
        pub let canFeedCoolDown: UInt64

        // FlowGotchi action states
        pub(set) var canPet: UInt64
        pub(set) var canFeed: UInt64

        // Items
        pub let items: [AnyStruct]

        // FlowGotchi Stats
        pub(set) var health: UInt64                          // 0 - 100
        pub(set) var friendship: UInt64                      // 0 - No Limit
        pub(set) var mood: UInt64                            // 0 - 100
        pub(set) var age: UInt64                             // 0 - No Limit
        pub(set) var hunger: UInt64                          // 0 - 100

        access(self) let royalties: [MetadataViews.Royalty]
        pub(set) var metadata: {String: AnyStruct}

        init(
            id: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.royalties = royalties
            self.metadata = metadata
            self.items = []
            self.quests = {
                0: Quests(
                    status: FlowGotchi.QuestStatus.Incomplete,
                    name: "Flow Rookie",
                    description: "Have at least 10 FLOW tokens in your Dapper Wallet"
                ),
                1: Quests(
                    status: FlowGotchi.QuestStatus.Incomplete,
                    name: "Flow Veteran",
                    description: "Have at least 50 FLOW tokens in your Dapper Wallet"
                ),
                2: Quests(
                    status: FlowGotchi.QuestStatus.Incomplete,
                    name: "Flow All Star",
                    description: "Have at least 1,000 FLOW tokens in your Dapper Wallet"
                )
            }

            // Inital Stats
            self.canPetCoolDown = 1                        // TODO update with the amount of blocks required for a COOL down of 1 hour
            self.canFeedCoolDown = 1                       // TODO update with the amount of blocks required for a COOL down of 3 hours
            self.canPet = getCurrentBlock().height
            self.canFeed = getCurrentBlock().height
            self.health = 100
            self.friendship = 0
            self.mood = 0
            self.age = getCurrentBlock().height
            self.hunger = 0
        }

        pub fun completeQuest(questId: UInt64) {
            let vaultRef = getAccount(self.owner!.address!)
                .getCapability(/public/flowTokenBalance)
                .borrow<&FlowToken.Vault{FungibleToken.Balance}>()
                ?? panic("Could not borrow Balance reference to the Vault")

            if (!self.quests.containsKey(questId)) {
                panic("Could not find Quest ID")
            }

            if (questId == 0) { // Flow Balance Quests FLOW > 0.1
                if let quest = self.quests[questId] as! FlowGotchi.Quests? {
                    if (quest.status == FlowGotchi.QuestStatus.Completed) {
                        panic("Quest already completed")
                    }

                    if (vaultRef.balance > 0.1) {
                        emit Debug(log: "Quest 1: Completed")
                        quest.updateStatus(status: FlowGotchi.QuestStatus.Completed)
                        // quest.status = FlowGotchi.QuestStatus.Completed
                        self.quests[questId] = quest
                    }
                }
            }
            else if (questId == 1) { // Flow Balance Quests FLOW > 1
                if let quest = self.quests[questId] as! FlowGotchi.Quests? {
                    if (quest.status == FlowGotchi.QuestStatus.Completed) {
                        panic("Quest already completed")
                    }

                    if (vaultRef.balance > 1.0) {
                        emit Debug(log: "Quest 2: Completed")
                        quest.updateStatus(status: FlowGotchi.QuestStatus.Completed)
                        self.quests[questId] = quest
                    }
                }
            }
            else if (questId == 2) { // Flow Balance Quests FLOW > 10
                if let quest = self.quests[questId] as! FlowGotchi.Quests? {
                    if (quest.status == FlowGotchi.QuestStatus.Completed) {
                        panic("Quest already completed")
                    }

                    if (vaultRef.balance > 10.0) {
                        emit Debug(log: "Quest 3: Completed")
                        quest.updateStatus(status: FlowGotchi.QuestStatus.Completed)
                        self.quests[questId] = quest
                    }
                }
            }
        }

        pub fun getCanPet(): Bool {
            return getCurrentBlock().height - self.canPet > 0      // TODO wire up to Petting Cooldown
        }

        pub fun getCanFeed(): Bool {
            return getCurrentBlock().height - self.canFeed > 0    // TODO wire up to Feeding Cooldown
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<FlowGotchi.Actions>(),
                Type<FlowGotchi.Traits>(),
                Type<FlowGotchi.Quests>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<FlowGotchi.Traits>():
                    return FlowGotchi.Traits(
                        health: self.health,
                        friendship: self.friendship,
                        mood: self.mood,
                        age: self.age,
                        hunger: self.hunger
                    )
                case Type<FlowGotchi.Actions>():
                    return FlowGotchi.Actions(
                        canPet: self.canPet,
                        canPetCoolDown: self.canPetCoolDown,
                    )
                case Type<FlowGotchi.Quests>():
                    var quests: [FlowGotchi.Quests] = []
                    let keys = self.quests.keys
                    for key in keys {
                        if let quest = self.quests[key] as! FlowGotchi.Quests? {
                            quests.append(
                                FlowGotchi.Quests(
                                    status: quest.status,
                                    name: quest.name,
                                    description: quest.description
                                )
                            )
                        }
                    }
                    return quests
            }
            return nil
        }
    }

    pub resource interface FlowGotchiCollectionPublic {
        pub fun mintFlowGotchi()
        pub fun pet(): Bool
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun mintAndDeposit(token: @NonFungibleToken.NFT, blockHeight: UInt64)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFlowGotchi(id: UInt64): &FlowGotchi.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow FlowGotchi reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: FlowGotchiCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var birthday: UInt64
        pub var flowGotchiMinted: Bool
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
            self.birthday = 0
            self.flowGotchiMinted = false
        }

        // TODO
        // Add function fed, this will Fed the FlowGotchi (decreasing its hunger level to 0 and increasing its mood by 1)
        // If the user is feeding a FlowGotchi who has let the hunger level of 100, its mood should reduce back to 0 after the feeding
        // pub fun pet(): Bool {
        // }

        // Anyone, any service can Pet your FlowGotchi as long as its within the block limit
        // TODO petting should increase the Hunger level (max 100)
        pub fun pet(): Bool {
            if self.ownedNFTs[0] != nil {
                let ref = (&self.ownedNFTs[0] as auth &NonFungibleToken.NFT?)!
                let flowGotchi = ref as! &FlowGotchi.NFT
                if (flowGotchi.getCanPet()) {
                    flowGotchi.canPet = getCurrentBlock().height
                    flowGotchi.friendship = flowGotchi.friendship + 1
                    flowGotchi.mood = flowGotchi.mood + 1
                    return true
                }
               return false;
            }
            return false
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @FlowGotchi.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun mintAndDeposit(token: @NonFungibleToken.NFT, blockHeight: UInt64) {
            let token <- token as! @FlowGotchi.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            self.birthday = blockHeight
            if (self.flowGotchiMinted) {
                panic("a FlowGotchi already exists for this account")
            }

            self.flowGotchiMinted = true;

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowFlowGotchi(id: UInt64): &FlowGotchi.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &FlowGotchi.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let FlowGotchi = nft as! &FlowGotchi.NFT
            return FlowGotchi as &AnyResource{MetadataViews.Resolver}
        }

        pub fun mintFlowGotchi() {
            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = self.owner!.address

            metadata["age"] = 0
            metadata["friendship"] = 0
            metadata["mood"] = 0
            metadata["health"] = 0
            metadata["hunger"] = 0
            metadata["items"] = []

            // create a FlowGotchi NFT
            var flowGotchi <- create NFT(
                id: FlowGotchi.totalSupply,
                name: FlowGotchi.getNames()[FlowGotchi.nextGotchi],
                description: FlowGotchi.getOrigins()[FlowGotchi.nextGotchi],
                thumbnail: FlowGotchi.getAvatars()[FlowGotchi.nextGotchi],
                royalties: [],
                metadata: metadata,
            )

            if (FlowGotchi.hasFlowGotchi(flowAddress: self.owner!.address)) {
                panic("You already have an active Gotchi, please take care of it first")
            }

            self.mintAndDeposit(token: <-flowGotchi, blockHeight: currentBlock.height)

            FlowGotchi.totalSupply = FlowGotchi.totalSupply + UInt64(1)

            FlowGotchi.nextGotchi = FlowGotchi.nextGotchi + UInt8(1)

            if (FlowGotchi.nextGotchi >= 10) {
                FlowGotchi.nextGotchi = 0;
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun getAvatars(): [String] {
        return [
            "https://i.imgur.com/hN0Mo7H.png",
            "https://i.imgur.com/bbgWXrQ.png",
            "https://i.imgur.com/gOyvaaQ.png",
            "https://i.imgur.com/7H8mtuR.png",
            "https://i.imgur.com/NErCjiO.png",
            "https://i.imgur.com/lcLOT0m.png",
            "https://i.imgur.com/aLxIEgH.png",
            "https://i.imgur.com/Y5kKAcl.png",
            "https://i.imgur.com/BWh0ySS.png",
            "https://i.imgur.com/FZkc2oA.png",
            "https://i.imgur.com/rVHoLRb.png",
            "https://i.imgur.com/iQYYbS8.png",
            "https://i.imgur.com/dUh0t8U.png",
            "https://i.imgur.com/4U6OwTX.png",
            "https://i.imgur.com/T7nhyhI.png",
            "https://i.imgur.com/QYQNkuY.png",
            "https://i.imgur.com/PBkuVz9.png",
            "https://i.imgur.com/aPeK2Uz.png",
            "https://i.imgur.com/1lNqsly.png",
            "https://i.imgur.com/4Pnn55o.png",
            "https://i.imgur.com/fLF26yv.png",
            "https://i.imgur.com/MJEIxIi.png"
        ]
    }

    pub fun getNames(): [String] {
        return [
            "Gizmo",
            "Pixel",
            "Digi",
            "Robo",
            "Cutey",
            "Fuzzy",
            "Boo",
            "Zippy",
            "Sprout",
            "Munchkin"
        ]
    }

    pub fun getOrigins(): [String] {
        return [
            "Gizmo was created in a laboratory by a team of scientists who wanted to study the behaviors of a virtual pet.",
            "Pixel was found as a stray on the streets, but was taken in and raised by a loving family.",
            "Digi was created by a group of programmers as a way to test new artificial intelligence algorithms.",
            "Robo was built by a group of engineers who wanted to create the ultimate virtual pet.",
            "Cutey was discovered by a young girl who found the abandoned egg while exploring the woods.",
            "Fuzzy was created by a group of artists who wanted to bring a sense of whimsy and fun to the world of virtual pets.",
            "Boo was created by a group of mystics who believed that the creature would bring good luck and prosperity to its owner.",
            "Zippy was discovered by a group of adventurers who found the egg while exploring a mysterious cave.",
            "Sprout was created by a group of farmers who wanted to bring the joys of gardening to the world of virtual pets.",
            "Munchkin was created by a group of bakers who wanted to bring a touch of sweetness and fun to the world of virtual pets."
        ]
    }

    pub fun hasFlowGotchi(flowAddress: Address): Bool {
        if (FlowGotchi.gotchiOwners[flowAddress] == true ) {
            return true;
        }
        return false;
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0
        self.nextGotchi = 0
        self.gotchiOwners = {}

        // Set the named paths
        self.CollectionStoragePath = /storage/flowGotchiCollection
        self.CollectionPublicPath = /public/flowGotchiCollection

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&FlowGotchi.Collection{NonFungibleToken.CollectionPublic, FlowGotchi.FlowGotchiCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )
        emit ContractInitialized()
    }
}
