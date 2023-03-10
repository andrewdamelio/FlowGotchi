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
import FlowGotchiQuests from "./FlowGotchiQuests.cdc"

pub contract FlowGotchi: NonFungibleToken {

    /// Counter of the next FlowGotchi to be created. Access(contract) to make it more difficult to snoop
    access(contract) var nextGotchi: UInt64
    /// Total number of FlowGotchis created
    pub var totalSupply: UInt64
    /// Mapping of names and their origin stories
    pub let gotchisAndOrigins: {String: String}
    /// URLs of all possible avatars
    pub let avatarURLs: [String]
    /// All moods of a FlowGotchi in order from saddest to happiest
    pub let moods: [String]

    /* Canonical paths */
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath

    /* Contract Events */
    pub event ContractInitialized()
    pub event Debug(log: String)
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event NewQuestStarted(flowGotchiID: UInt64, owner: Address, questIdentifer: UInt64)
    pub event QuestCompleted(flowGotchiID: UInt64, owner: Address, questIdentifier: UInt64, completedQuestID: UInt64, questName: String)

    /// Struct representing FlowGotchi traits - used as a MetadataView
    ///
    pub struct Traits {
        /// Measure of how close the creature feels to its owner based on interactions
        pub var friendship: UInt64
        /// Mood of the FlowGotchi
        pub var mood: UInt64
        /// Time since birthdate timestamp is the age in seconds (Unix timestamp)
        pub var age: UFix64
        /// Feeding FlowGotchi will reset this to 0, should increase with every FlowGotchi interaction
        pub var hunger: UInt64

        init(
            friendship: UInt64,
            mood: UInt64,
            age: UFix64,
            hunger: UInt64
        ) {
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

    /// Struct representing the status of Actions (pet & feed for the moment)
    ///
    pub struct ActionStatus {
        /// Last time the Gotchi was pet
        pub let lastPet: UFix64
        /// Last time the Gotchi was fed
        pub let lastFed: UFix64
        /// The next time the Gotchi can be pet
        pub let nextPettingTime: UFix64
        /// The next time the Gotchi can be fed
        pub let nextFeedingTime: UFix64
        /// Whether Gotchi can be pet
        pub let canPet: Bool
        /// Whether Gotchi can be pet
        pub let canFeed: Bool

        init(
            lastPet: UFix64,
            lastFed: UFix64,
            nextPettingTime: UFix64,
            nextFeedingTime: UFix64,
            canPet: Bool,
            canFeed: Bool,
        ) {
            self.lastPet = lastPet
            self.lastFed = lastFed
            self.nextPettingTime = nextPettingTime
            self.nextFeedingTime = nextFeedingTime
            self.canPet = canPet
            self.canFeed = canFeed
        }
    }

    /// This NFT defines a FlowGotchi creature, designed to belong to a Flow Address and accompany them on
    /// their journey through Flow
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let name: String
        /// The owner of the FlowGotchi
        pub let homeAddress: Address
        pub let description: String
        pub let thumbnail: String

        /// Creation block height
        pub let birthblock: UInt64
        /// Creation block timestamp
        pub let birthdate: UFix64

        /* FlowGotchi actions block amount cooldowns */
        /// Amount of seconds before Gotchi can be pet again
        pub let canPetCoolDown: UFix64
        /// Amount of seconds before Gotchi can be fed again
        pub let canFeedCoolDown: UFix64

        /// Last time the Gotchi was pet
        pub var lastPet: UFix64
        /// Last time the Gotchi was fed
        pub var lastFed: UFix64
        /// The next time the Gotchi can be pet
        pub var nextPettingTime: UFix64
        /// The next time the Gotchi can be fed
        pub var nextFeedingTime: UFix64
        /// Whether Gotchi can be pet
        pub var canPet: Bool
        /// Whether Gotchi can be fed
        pub var canFeed: Bool

        /// Items that belong to the FlowGotchi - not implemented at the moment
        pub let items: [AnyStruct]

        /// Mapping of quest identifier to Quest resourrce
        /// Note that quest identifiers are defined in FlowGotchiQuests contract
        /// TODO: Update to index on Type?
        pub let quests: @{UInt64: FlowGotchiQuests.Quest}

        // FlowGotchi Stats
        // 0 - No Limit
        pub var friendship: UInt64
        // 0 - 100
        pub var mood: UInt64
        // 0 - 100
        pub var hunger: UInt64

        access(self) let royalties: [MetadataViews.Royalty]
        pub let metadata: {String: AnyStruct}

        init(
            id: UInt64,
            name: String,
            homeAddress: Address,
            description: String,
            thumbnail: String,
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
        ) {
            self.id = id
            self.name = name
            self.homeAddress = homeAddress
            self.description = description
            self.thumbnail = thumbnail
            self.royalties = royalties
            self.metadata = metadata
            self.items = []
            self.quests <-{
                0: <-FlowGotchiQuests.startQuest(questIdentifier: 0),
                1: <-FlowGotchiQuests.startQuest(questIdentifier: 1),
                2: <-FlowGotchiQuests.startQuest(questIdentifier: 2),
                3: <-FlowGotchiQuests.startQuest(questIdentifier: 3),
                4: <-FlowGotchiQuests.startQuest(questIdentifier: 4)
            }

            // Set birth stats
            let currentBlock = getCurrentBlock()
            self.birthblock = currentBlock.height
            self.birthdate = currentBlock.timestamp

            // Inital Stats
            self.canPetCoolDown = 3600.0
            self.canFeedCoolDown = 10800.0
            self.canPet = true
            self.canFeed = true
            self.friendship = (metadata["friendship"]! as! UInt64)
            self.mood = (metadata["mood"]! as! UInt64)
            self.hunger = (metadata["hunger"]! as! UInt64)

            self.lastPet = self.birthdate - self.canPetCoolDown
            self.lastFed = self.birthdate - self.canFeedCoolDown
            self.nextPettingTime = self.birthdate
            self.nextFeedingTime = self.birthdate
        }

        /** Getters for FlowGotchi's attributes */

        pub fun getAgeInSeconds(): UFix64 {
            return getCurrentBlock().timestamp - self.birthdate
        }

        pub fun getAgeInBlocks(): UInt64 {
            return getCurrentBlock().height - self.birthblock
        }

        pub fun getQuestRef(questIdentifier: UInt64): &FlowGotchiQuests.Quest? {
            return &self.quests[questIdentifier] as &FlowGotchiQuests.Quest?
        }

        pub fun getCanPet(): Bool {
            self.updateStats()
            return self.canPet
        }

        pub fun getCanFeed(): Bool {
            self.updateStats()
            return self.canFeed
        }

        /// Returns the mood of the FlowGotchi based on its current mood stat
        pub fun getMood(): String {
            self.updateStats()
            // Since the moods array is initialized in order of increasingly good mood, the
            // lower the mood value, the lower the mood
            return FlowGotchi.moods[self.mood / 10]
        }

        /** Interactions */

        /// Anyone, any service can Pet your FlowGotchi as long as its within the block limit
        ///
        pub fun pet(): Bool {
            // Update stats based on time since last actions
            self.updateStats()
            if self.canPet {
                // Track when petting happend
                self.lastPet = getCurrentBlock().timestamp

                // Increment stats if below max values
                self.friendship = self.friendship + 4
                if self.mood + 4 <= 100 {
                    self.mood = self.mood + 4
                }
                if self.hunger + 1 <= 100 {
                    self.hunger = self.hunger + 1
                }

                // Identify the next time Gotchi can be pet
                self.nextPettingTime = self.lastPet + self.canPetCoolDown

                // Confirm petting
                return true
            }
            // Confirm petting did not occur
            return false
        }

        // Add function fed, this will Fed the FlowGotchi (decreasing its hunger level to 0 and increasing its mood by 1)
        // If the user is feeding a FlowGotchi who has let the hunger level of 100, its mood should reduce back to 0 after the feeding
        pub fun feed(): Bool {
            // Update stats based on time since last actions
            self.updateStats()
            if self.canFeed {
                // Track when petting happend
                self.lastFed = getCurrentBlock().timestamp

                // Increment stats if below max values
                self.friendship = self.friendship + 8
                if self.mood + 8 <= 100 {
                    self.mood = self.mood + 8
                } else {
                    self.mood = 100
                }
                if self.hunger - 50 >= 0 {
                    self.hunger = self.hunger - 50
                } else {
                    self.hunger = 0
                }

                // Identify the next time Gotchi can be pet
                self.nextFeedingTime = self.lastFed + self.canFeedCoolDown

                // Confirm Feeding
                return true
            }
            // Confirm Feeding did not occur
            return false
        }

        /** Attribute Updater */

        /// Update FlowGotchi's attributes based on current block
        ///
        pub fun updateStats() {
            // Update petting & feeding times
            let currentTimestamp = getCurrentBlock().timestamp
            self.canPet = currentTimestamp >= self.nextPettingTime
            self.canFeed = currentTimestamp >= self.nextFeedingTime

            // Calculate Pet cooldowns since last feeding
            let petPeriodsPassed = UInt64((currentTimestamp - self.lastPet) / self.canPetCoolDown)
            // Calculate Fed cooldowns since last feeding
            let fedPeriodsPassed = UInt64((currentTimestamp - self.lastFed) / self.canFeedCoolDown)

            // Calculate friendship decay
            let petFriendshipDecay = petPeriodsPassed * 1
            let fedFriendshipDecay = fedPeriodsPassed * 2
            if self.friendship >= (petFriendshipDecay + fedFriendshipDecay) {
                self.friendship = self.friendship - (petFriendshipDecay + fedFriendshipDecay)
            } else {
                self.friendship = 0
            }

            // Calculate mood decay
            let petMoodDecay = petPeriodsPassed * 1
            let fedMoodDecay = fedPeriodsPassed * 2
            if self.mood >= (petMoodDecay + fedMoodDecay) {
                self.mood = self.mood - (petMoodDecay + fedMoodDecay)
            } else {
                self.mood = 0
            }

            // Calculate hunger increase
            let fedHungerIncrease = fedPeriodsPassed * 10
            // Check
            if self.hunger + fedHungerIncrease <= 100 {
                self.hunger = self.hunger + fedHungerIncrease
            } else {
                self.hunger = 100
            }
        }

        /** Quest sign up & completion */

        pub fun embarkOnQuest(questIdentifier: UInt64) {
            pre {
                !self.quests.containsKey(questIdentifier):
                    "You've already embarked on this quest!"
            }
            self.quests[questIdentifier] <-! FlowGotchiQuests.startQuest(questIdentifier: questIdentifier)
            emit NewQuestStarted(flowGotchiID: self.id, owner: self.homeAddress, questIdentifer: questIdentifier)
        }

        pub fun completeQuest(questIdentifier: UInt64): Bool {
            pre {
                self.quests.containsKey(questIdentifier)
            }
            let questRef = self.getQuestRef(questIdentifier: questIdentifier)!
            if questRef.complete() {
                emit QuestCompleted(
                    flowGotchiID: self.id,
                    owner: self.homeAddress,
                    questIdentifier: questIdentifier,
                    completedQuestID: questRef.id,
                    questName: String
                )
                return true
            }
            return false
        }

        pub fun removeQuest(questIdentifier: UInt64) {
            let quest <-self.quests.remove(key: questIdentifier)
            destroy quest
        }

        /** MetadataViews.Resolver */

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<ActionStatus>(),
                Type<Traits>(),
                Type<FlowGotchiQuests.QuestsView>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            // Update stats before returning a view
            self.updateStats()
            // Return the specified view
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
                        friendship: self.friendship,
                        mood: self.mood,
                        age: self.getAgeInSeconds(),
                        hunger: self.hunger
                    )
                case Type<FlowGotchi.ActionStatus>():
                    self.updateStats()
                    return FlowGotchi.ActionStatus(
                        lastPet: self.lastPet,
                        lastFed: self.lastFed,
                        nextPettingTime: self.nextPettingTime,
                        nextFeedingTime: self.nextFeedingTime,
                        canPet: self.canPet,
                        canFeed: self.canFeed,
                    )
                case Type<FlowGotchiQuests.QuestsView>():
                    let quests: [FlowGotchiQuests.Quests] = []
                    for questID in self.quests.keys {
                        let questRef = self.getQuestRef(questIdentifier: questID)!
                        let overview = FlowGotchiQuests.Quests(
                            status: questRef.status,
                            name: questRef.verifier.name,
                            description: questRef.verifier.description
                        )
                        quests.append(overview)
                    }
                    return quests
            }
            return nil
        }

        destroy() {
            pre {
                self.quests.length == 0: "FlowGotchi still has quests!"
            }
            destroy self.quests
        }
    }

    pub resource interface FlowGotchiCollectionPublic {
        pub fun mintFlowGotchi()
        pub fun deposit(token: @NonFungibleToken.NFT)
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
        pub var flowGotchiHatched: Bool
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
            self.flowGotchiHatched = false
        }

        /// Currently, only 1 FlowGotchi allowed per account (or Collection really)
        pub fun deposit(token: @NonFungibleToken.NFT) {
            pre {
                // Prevent storing more than one FlowGotchi
                self.ownedNFTs.length == 0:
                    "Collection is already home to a FlowGotchi!"
            }

            let token <- token as! @FlowGotchi.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // TODO: If we're really going to map FlowGotchis 1:1 per account, we want to reconsider how we handle withdrawals
        // or reconsider the 1:1 allowance. Alternatively, could we just let accounts have as many as they want?
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

        /// Each Collection contains within it a FlowGotchi that belongs to the owner that mints it - like a FlowGotchi egg! 
        pub fun mintFlowGotchi() {
            pre {
                !self.flowGotchiHatched:
                    "This account's FlowGotchi has already hatched!"
            }
            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = self.owner!.address
            // Initialize traits
            metadata["friendship"] = UInt64(0)
            metadata["mood"] = UInt64(50)
            metadata["hunger"] = UInt64(50)
            metadata["items"] = []

            // create a FlowGotchi NFT & grab its id
            let flowGotchi <-FlowGotchi.mintGotchi(metadata: metadata, residence: self.owner!.address)
            let id: UInt64 = flowGotchi.id

            // Cast to NonFungibleToken.NFT & deposit to this Colection
            let nft <-flowGotchi as! @NonFungibleToken.NFT
            self.deposit(token: <-nft)

            // Label as hatched
            self.flowGotchiHatched = true
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun getAvatars(): [String] {
        return self.avatarURLs
    }

    pub fun getNames(): [String] {
        return self.gotchisAndOrigins.keys
    }

    pub fun getOrigins(): [String] {
        return self.gotchisAndOrigins.values
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    access(contract) fun mintGotchi(metadata: {String: AnyStruct}, residence: Address): @FlowGotchi.NFT {
        // Create a new FlowGotchi NFT
        let flowGotchi <-create NFT(
                id: self.totalSupply,
                name: self.getNames()[FlowGotchi.nextGotchi],
                homeAddress: residence,
                description: self.getOrigins()[self.nextGotchi],
                thumbnail: self.getAvatars()[self.nextGotchi],
                royalties: [],
                metadata: metadata,
            )
        // Increment tracking values
        self.totalSupply = self.totalSupply + UInt64(1)
        self.nextGotchi = self.totalSupply % UInt64(self.gotchisAndOrigins.length)
        // Return
        return <-flowGotchi
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0
        self.nextGotchi = 0
        self.gotchisAndOrigins = {
            "Gizmo": "Gizmo was created in a laboratory by a team of scientists who wanted to study the behaviors of a virtual pet.",
            "Pixel": "Pixel was found as a stray on the streets, but was taken in and raised by a loving family.",
            "Digi": "Digi was created by a group of programmers as a way to test new artificial intelligence algorithms.",
            "Robo": "Robo was built by a group of engineers who wanted to create the ultimate virtual pet.",
            "Cutey": "Cutey was discovered by a young girl who found the abandoned egg while exploring the woods.",
            "Fuzzy": "Fuzzy was created by a group of artists who wanted to bring a sense of whimsy and fun to the world of virtual pets.",
            "Boo": "Boo was created by a group of mystics who believed that the creature would bring good luck and prosperity to its owner.",
            "Zippy": "Zippy was discovered by a group of adventurers who found the egg while exploring a mysterious cave.",
            "Sprout": "Sprout was created by a group of farmers who wanted to bring the joys of gardening to the world of virtual pets.",
            "Munchkin": "Munchkin was created by a group of bakers who wanted to bring a touch of sweetness and fun to the world of virtual pets.",
            "Blockbeard": "The scruffy Blockbeard was created by a group of pirates who wanted a pet to keep them company on their long voyages at sea.",
            "HashHippo": "This rotund FlowGotchi was created by a group of programmers who were looking for a way to bring their love of math and cryptography to life.",
            "LedgerLlama": "This fluffy creature was created by a group of accountants who wanted a pet that could help them keep track of all their financial records.",
            "Minty": "Minty, was created by a group of candy makers who wanted a pet that could help them come up with new and exciting flavors. "
        }
        self.avatarURLs = [
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
        self.moods = [
            "Disconsolate",
            "Lonely",
            "Glum",
            "Anxious",
            "Blah",
            "Content",
            "Happy",
            "Playful",
            "Energized",
            "Joyful",
            "Ecstatic"
        ]

        // Set the named paths
        self.CollectionStoragePath = /storage/flowGotchiCollectionV1
        self.CollectionPublicPath = /public/flowGotchiCollectionV1
        self.CollectionPrivatePath = /private/flowGotchiCollectionV1

        emit ContractInitialized()
    }
}
 