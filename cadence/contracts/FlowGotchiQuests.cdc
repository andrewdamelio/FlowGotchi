import FungibleToken from "./shared/FungibleToken.cdc"
import NonFungibleToken from "./shared/NonFungibleToken.cdc"
import TopShot from "./shared/TopShot.cdc"
import AllDay from "./shared/AllDay.cdc"

/// A contract defining the sorts of quests that can be completed
pub contract FlowGotchiQuests {

    pub var completedQuestCount: UInt64
    /// A mapping containing all quests that can be completed
    pub let questTypeToIdentifier: {Type: UInt64}

    /* Contract Events */
    pub event ContractInitialized()
    pub event NewQuestAdded(questID: UInt64)
    pub event QuestRetired(questID: UInt64)
    pub event QuestCompleted(address: Address, questIdentifier: UInt64, completedQuestID: UInt64)

    /// Basic enum defining the status of a Quest
    ///
    pub enum QuestStatus: UInt8 {
        pub case Incomplete
        pub case Completed
        pub case Claimed
    }

    /** QuestsView */

    pub struct Quests {
        pub let status: QuestStatus
        pub let name: String
        pub let description: String
        init(
            status: QuestStatus,
            name: String,
            description: String
        ) {
            self.status = status
            self.name = name
            self.description = description
        }
    }

    pub struct QuestsView {
        pub let overviews: [Quests]

        init(
            overviews: [Quests]
        ) {
            self.overviews = overviews
        }
    }

    /** QuestVerifier */
    
    /// Struct interface defining a quest journey that can be completed
    ///
    pub struct interface QuestVerifier {
        pub let questIdentifier: UInt64
        pub let name: String
        pub let description: String
        access(contract) fun verify(address: Address): Bool
    }

    pub struct FlowRookieQuest : QuestVerifier{
        pub let questIdentifier: UInt64
        pub let name: String
        pub let description: String
        pub let balanceThreshold: UFix64

        init() {
            self.questIdentifier = FlowGotchiQuests.questTypeToIdentifier[self.getType()]!
            self.name = "Flow Rookie"
            self.description = "Have at least 10 FLOW tokens in your Dapper Wallet"
            self.balanceThreshold = 10.0
        }

        access(contract) fun verify(address: Address): Bool {
            if FlowGotchiQuests.balanceMeetsThreshold(balanceThreshold: self.balanceThreshold, address: address) {
                return true
            }
            return false
        }
    }

    pub struct FlowVeteranQuest : QuestVerifier {
        pub let questIdentifier: UInt64
        pub let name: String
        pub let description: String
        pub let balanceThreshold: UFix64

        init() {
            self.questIdentifier = FlowGotchiQuests.questTypeToIdentifier[self.getType()]!
            self.name = "Flow Veteran"
            self.description = "Have at least 50 FLOW tokens in your Dapper Wallet"
            self.balanceThreshold = 50.0
        }

        access(contract) fun verify(address: Address): Bool {
            if FlowGotchiQuests.balanceMeetsThreshold(balanceThreshold: self.balanceThreshold, address: address) {
                return true
            }
            return false
        }
    }

    pub struct FlowAllStarQuest : QuestVerifier {
        pub let questIdentifier: UInt64
        pub let name: String
        pub let description: String
        pub let balanceThreshold: UFix64

        init() {
            self.questIdentifier = FlowGotchiQuests.questTypeToIdentifier[self.getType()]!
            self.name = "Flow All Star"
            self.description = "Have at least 1,000 FLOW tokens in your Dapper Wallet"
            self.balanceThreshold = 1000.0
        }

        access(contract) fun verify(address: Address): Bool {
            if FlowGotchiQuests.balanceMeetsThreshold(balanceThreshold: self.balanceThreshold, address: address) {
                return true
            }
            return false
        }
    }

    pub struct NBATopShotDebut : QuestVerifier {
        pub let questIdentifier: UInt64
        pub let name: String
        pub let description: String
        pub let collectionThreshold: Int

        init() {
            self.questIdentifier = FlowGotchiQuests.questTypeToIdentifier[self.getType()]!
            self.name = "NBA Top Shot Debut"
            self.description = "Own one NBA Top Shot Moment"
            self.collectionThreshold = 1
        }

        access(contract) fun verify(address: Address): Bool {
            // Get a reference to the account's MomentCollectionPublic
            let collectionRef = getAccount(address)
                .getCapability<
                    &TopShot.Collection{TopShot.MomentCollectionPublic}
                >(
                    /public/MomentCollection
                )
                .borrow()
                ?? panic("Could not borrow Reference to MomentCollectionPublic for specified Address ".concat(address.toString()))
            // Complete the quest if the collection meets the threshold
            if collectionRef.getIDs().length >= self.collectionThreshold {
                return true
            }
            return false
        }
    }

    pub struct NFLAllDayDebut : QuestVerifier {
        pub let questIdentifier: UInt64
        pub let name: String
        pub let description: String
        pub let collectionThreshold: Int

        init() {
            self.questIdentifier = FlowGotchiQuests.questTypeToIdentifier[self.getType()]!
            self.name = "NFL All Day Debut"
            self.description = "Own one NFL All Day Moment"
            self.collectionThreshold = 1
        }

        access(contract) fun verify(address: Address): Bool {
            // Get a reference to the account's MomentCollectionPublic
            let collectionRef = getAccount(address)
                .getCapability<
                    &AllDay.Collection{AllDay.MomentNFTCollectionPublic}
                >(
                    AllDay.CollectionPublicPath
                )
                .borrow()
                ?? panic("Could not borrow Reference to MomentNFTCollectionPublic for specified Address ".concat(address.toString()))
            // Complete the quest if the collection meets the threshold
            if collectionRef.getIDs().length >= self.collectionThreshold {
                return true
            }
            return false
        }
    }

    /** Quest Resource */
    
    /// Resource maintaining quest progression & proof of completion
    ///
    pub resource Quest: NonFungibleToken.INFT {
        pub let id: UInt64
        pub let questIdentifier: UInt64
        pub var status: QuestStatus
        pub let startBlockHeight: UInt64
        pub let startTimeStamp: UFix64
        pub var completionBlockHeight: UInt64?
        pub var completionTimestamp: UFix64?
        pub let verifier: AnyStruct{QuestVerifier}

        init(_ verifier: AnyStruct{QuestVerifier}) {
            self.id = self.uuid
            self.questIdentifier = verifier.questIdentifier
            self.status = QuestStatus.Incomplete
            let currentBlock = getCurrentBlock()
            self.startBlockHeight = currentBlock.height
            self.startTimeStamp = currentBlock.timestamp
            self.completionBlockHeight = nil
            self.completionTimestamp = nil
            self.verifier = verifier
        }

        pub fun complete(): Bool {
            // Get the owner's address
            let ownerAddress = self.owner!.address
            // Verify completion
            if self.verifier.verify(address: ownerAddress) {
                // Set completion height & time
                let currentBlock = getCurrentBlock()
                self.completionBlockHeight = currentBlock.height
                self.completionTimestamp = currentBlock.timestamp
                // Set as complete
                self.status = QuestStatus.Completed
                // Increment contract's completed quests
                FlowGotchiQuests.completedQuestCount = FlowGotchiQuests.completedQuestCount + 1
                emit QuestCompleted(
                    address: self.owner!.address,
                    questIdentifier: self.verifier.questIdentifier,
                    completedQuestID: self.id
                )
                // Return that quest was verified & completed
                return true
            }
            // Return that quest was not completed
            return false
        }

        pub fun claim() {
            pre {
                self.status == QuestStatus.Completed:
                    "Not eligible to be claimed!"
            }
            self.status = QuestStatus.Claimed
        }

    }

    pub fun startQuest(questIdentifier: UInt64): @Quest {
        pre {
            self.questTypeToIdentifier.values.contains(questIdentifier):
                "No with given identifier!"
        }
        var verifier: AnyStruct{QuestVerifier}? = nil
        switch(questIdentifier) {
            // TODO: Add other quest verifiers
            case 0:
                verifier = FlowRookieQuest()
            case 1:
                verifier = FlowVeteranQuest()
            case 2:
                verifier = FlowVeteranQuest()
            case 3:
                verifier = NBATopShotDebut()
            case 4:
                verifier = NFLAllDayDebut()
        }
        assert(
            verifier!.questIdentifier == self.questTypeToIdentifier[verifier!.getType()],
            message: "Verifier improperly constructed!"
        )
        return <-create Quest(verifier!)
    }

    access(contract) fun balanceMeetsThreshold(balanceThreshold: UFix64, address: Address): Bool {
        let vaultRef = getAccount(address)
                .getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance)
                .borrow()
                ?? panic("Could not borrow Balance reference to the Vault")
        return vaultRef.balance >= balanceThreshold
    }

    init() {
        self.completedQuestCount = 0
        self.questTypeToIdentifier = {
                Type<FlowRookieQuest>(): 0,
                Type<FlowVeteranQuest>(): 1,
                Type<FlowAllStarQuest>(): 2,
                Type<NBATopShotDebut>(): 3,
                Type<NFLAllDayDebut>(): 4
            }

        emit ContractInitialized()
    }
}
 