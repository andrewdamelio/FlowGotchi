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

/**

QUESTIONS:
    - Is there a reason why we're using block height instead of timestamp to define birthdays and cooldowns? Seems like timestamp would be easier client-side
    - What determines the Gotchi's health? mood? age?
    - How do we plan on updating the values that change over time on-chain? Things like friendship or mood can't change value without someone submitting a transaction, and it would have
        to be done by the user since they have the resource with attributes that need to be altered. Will this just be represented off-chain client-side?
    - What about the custody model? Will a user have to sign every time they interact with their FlowGotchi?
    - Are we planning on adding names & back stories? We could have ChatGPT do this us pretty quickly
    - Why do we need to know the FlowGotchi owners?
    - The variables in the NFT are pub(set), this allows anyone to change the values via Collection.borrowFlowGotchi() - is that desirable?
    - Is the idea for a FlowGotchi to be 1:1 per Flow account? Judging by mintAndDeposit(), it looks like that's the case, but what if a user just transfers the Collection to another account? 
        It also looks like a user can withdraw their FlowGotchi. If they withdraw, and lose the resource, they won't be able to mint another one. Is this desired behavior?

RESPONSE
    - We should just use timestamp I agree
    - Heath -> TBD, maybe we ditch it to simplify MVP
    - Mood -> Was thinking of just making this a random think whenever we call a getMood function, like cycles through a few moods a day
    - Age -> its birthday is consider the bock it was minted on. So we store its birthday block and will determine its age by Current Block - Mint Block
    - I was thinking about connecting this into the quest interactions. I think we could have a method that updates these values onchain based off of other factors (last time feed, last time pet?). And this function, call it recalcuateStats would get called in the pre/post condition of all the contract/nft functions.
    - Ya i was thinking a user would just sign every time
    - I'm super open to ditching the onchain way I did it with something more GPT dynamic
    - I don't think we do -- that could be cleaned up RE FlwoGotchi owners
    - yeah not at all,I could use some help fixing that up, was running into issues trying to make that contract only
    - Yeah a Flow account should only have 1 flow gotchi. Yeah i haven't consider these edge cases... is it possible for us to make these soul bound?

MY RESPONSE
    Thanks for clarifying, so my takeaways as requirements for the contract are:
    - Refactor to use timestamps with the exception of birthday (maybe rename "birthblock"), which I'll leave as block height and add a timestamp value for the gotchi's birth as UNIX
    - Ditch Health to keep things simple
    - Randomize Mood on `getMood()`
    - Calculate age on birthblock and/or birthday
    - Expose a method that we can use in quests to update traits based on when they were last updated (e.g. recalculateStats()) and include a script to demo its use
    - Remove the contract mapping of owners in Cadence
    - Make this a Soulbound token. I've had the idea to self-destruct a souldbound resource if it ever detects that it exists in an account is wasn't designed for. E.g. I transfer my Collection to another account and call withdraw() or some other method which would destroy the Gotchi. Not sure if that would be something we'd want to implement here, but we'd also need to get rid of the withdraw method
 */

pub contract FlowGotchi: NonFungibleToken {
    
    /// Contract Variables
    //
    access(contract) var nextGotchi: UInt64
    pub var totalSupply: UInt64
    pub let gotchisAndOrigins: {String: String}
    pub let avatarURLs: [String]
    pub let moods: [String]

    /// Canonical paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath
    
    /// Contract Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub enum Actions: UInt8 {
        pub case pet
        pub case feed
    }

    pub struct Traits {
        // Goes up by 1 every time you PET, maybe it goes down every day if you don't PET
        pub var friendship: UInt64
        // TODO how does this get set?
        pub var mood: UInt64
        /// Time since birthdate timestampe is the age in seconds (Unix timestampe)
        pub var age: UFix64
        /// Feeding FlowGotchi will reset this to 0, should increaes with every FlowGotchi interaction
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

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let name: String
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
        /// Whether Gotchi can be pet
        pub var canFeed: Bool

        // Items
        pub let items: [AnyStruct]

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

            // Set birth stats
            let currentBlock = getCurrentBlock() 
            self.birthblock = currentBlock.height
            self.birthdate = currentBlock.timestamp

            // Inital Stats
            self.canPetCoolDown = 3600.0
            self.canFeedCoolDown = 10800.0
            self.canPet = true
            self.canFeed = true
            self.friendship = 0
            self.mood = 0
            self.hunger = 0

            self.lastPet = 0.0
            self.lastFed = 0.0
            self.nextPettingTime = 0.0
            self.nextFeedingTime = 0.0
        }

        /** Getters for FlowGotchi's attributes */

        pub fun getAgeInSeconds(): UFix64 {
            return getCurrentBlock().timestamp - self.birthdate
        }

        pub fun getAgeInBlocks(): UInt64 {
            return getCurrentBlock().height - self.birthblock
        }
        
        pub fun getCanPet(): Bool {
            self.updateStats()
            return self.canPet
        }

        pub fun getCanFeed(): Bool {
            self.updateStats()
            return self.canFeed
        }

        /** Interactions */

        /// Anyone, any service can Pet your FlowGotchi as long as its within the block limit
        /// TODO petting should increase the Hunger level (max 100)
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

        // TODO
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

        // TODO
        // pub fun getMood(): String {

        // }

        /** Attribute Updater */

        /// Update FlowGotchi's attributes based on current block
        ///
        pub fun updateStats() {
            // TODO: Update hunger, mood, and friendship
            // Update petting & feeding times
            let currentTimestamp = getCurrentBlock().timestamp
            self.canPet = currentTimestamp >= self.nextFeedingTime
            self.canFeed = currentTimestamp >= self.nextFeedingTime

            // Calculate Pet cooldowns since last feeding
            // Calculate Fed cooldowns since last feeding
            // Update stats based on cycles
            // Update friendship
            // Update mood
            // Update hunger
        }

        /** MetadataViews.Resolver */

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<FlowGotchi.ActionStatus>(),
                Type<FlowGotchi.Traits>()
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
            }
            return nil
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
        pub var flowGotchiMinted: Bool
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
            self.flowGotchiMinted = false
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            pre {
                self.ownedNFTs.length == 0:
                    "Collection is already home to a FlowGotchi!"
            }
            // TODO: Update to prevent including more than 1
            let token <- token as! @FlowGotchi.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

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

            metadata["friendship"] = 0
            metadata["mood"] = 0
            metadata["hunger"] = 0
            metadata["items"] = []

            // create a FlowGotchi NFT
            let flowGotchi <-FlowGotchi.mintGotchi(metadata: metadata, residence: self.owner!.address)
            // var flowGotchi <- create NFT(
            //     id: FlowGotchi.totalSupply,
            //     name: FlowGotchi.getNames()[FlowGotchi.nextGotchi],
            //     homeAddress: self.owner!.address,
            //     description: FlowGotchi.getOrigins()[FlowGotchi.nextGotchi],
            //     thumbnail: FlowGotchi.getAvatars()[FlowGotchi.nextGotchi],
            //     royalties: [],
            //     metadata: metadata,
            // )

            // TODO: Add another check
            // if (FlowGotchi.hasFlowGotchi(flowAddress: self.owner!.address)) {
            //     panic("You already have an active Gotchi, please take care of it first")
            // }

            self.mintAndDeposit(token: <-flowGotchi, blockHeight: currentBlock.height)

            // FlowGotchi.totalSupply = FlowGotchi.totalSupply + UInt64(1)

            // FlowGotchi.nextGotchi = FlowGotchi.totalSupply % FlowGotchi.gotchisAndOrigins.length
        }

        access(self) fun mintAndDeposit(token: @NonFungibleToken.NFT, blockHeight: UInt64) {
            let token <- token as! @FlowGotchi.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            if (self.flowGotchiMinted) {
                panic("a FlowGotchi already exists for this account")
            }

            self.flowGotchiMinted = true;

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
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
            "Joyful",
            "Energized",
            "Playful",
            "Content",
            "Apathetic",
            "Irritable",
            "Anxious",
            "Glum",
            "Lonely",
            "Disconsolate"
        ]

        // Set the named paths
        self.CollectionStoragePath = /storage/flowGotchiCollection
        self.CollectionPublicPath = /public/flowGotchiCollection
        self.CollectionPrivatePath = /private/flowGotchiCollection

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
