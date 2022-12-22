import NonFungibleToken from "./shared/NonFungibleToken.cdc"
import MetadataViews from "./shared/MetadataViews.cdc"
import FlowGotchiQuests from "./FlowGotchiQuests"
import AccountBuddy from "./AccountBuddy.cdc"

/// Defines the CompletedQuest resource & issues one on validation of completion
pub contract AccountBuddyQuestCompletion {
    
    pub let completedQuestCount: UInt64
    /// A mapping containing all quests that can be completed
    pub let quests: {UInt64: AnyStruct{FlowGotchiQuests.Quest}}

    /// StoragePath for QuestCompletionAdmin
    pub let QuestCompletionAdminStoragePath: StoragePath
    /// PrivatePath for QuestCompletionAdmin
    pub let QuestCompletionAdminPrivatePath: PrivatePath

    /* Contract Events */
    pub event ContractInitialized()
    pub event NewQuestAdded(questID: UInt64)
    pub event QuestRetired(questID: UInt64)
    pub event QuestCompleted(flowGotchiID: UInt64, address: Address, questID: UInt64)

    /// Resource representing a completed quest
    pub resource CompletedQuest: NonFungibleToken.INFT, FlowGotchiQuests.QuestProof {
        pub let id: UInt64
        pub let completionBlockHeight: UInt64
        pub let completionTimestamp: UFix64
        pub let quest: AnyStruct{FlowGotchiQuests.Quest}

        init(_ quest: AnyStruct{FlowGotchiQuests.Quest}) {
            self.id = self.uuid
            let currentBlock = getCurrentBlock()
            self.completionBlockHeight = currentBlock.height
            self.completionTimestamp = currentBlock.timestamp
            self.quest = quest
        }
    }

    /// Resource to edit mapping of Quests
    pub resource QuestCompletionAdmin {
        pub fun safeAddQuest(quest: AnyStruct{FlowGotchiQuests.Quest}) {
            pre {
                self.quests.containsKey(quest.id):
                    "Quest with specified id already exists!"
            }
            FlowGotchiQuests.quests.insert(key: quest.id, quest)
            emit NewQuestAdded(questID: questID)
        }

        pub fun addQuest(quest: AnyStruct{FlowGotchiQuests.Quest}) {
            FlowGotchiQuests.quests.insert(key: quest.id, quest)
            emit NewQuestAdded(questID: questID)
        }
        
        pub fun removeQuest(questID: UInt64): AnyStruct{FlowGotchiQuests.Quest}? {
            emit QuestRetired(questID: questID)
            return FlowGotchiQuests.quests.remove(key: questID)
        }
    }

    /// Method that allows the FlowGotchi contract (deployed to the same account as this contract) to validate
    /// that quests have been completed
    ///
    // pub fun validateQuestCompletion(questID: UInt64, nft: &{NonFungibleToken.INFT, AccountBuddy.Token}): @CompletedQuest? {
    pub fun validateQuestCompletion(questID: UInt64, collectionRef: &{AccountBuddy.ICollection}) {
        pre {
            self.quests.containsKey(questID):
                "No Quests with exist with given id!"
        }
        // Check that quest was completed & return if so
        if self.quests[questID]!.complete(nft) {
            self.completedQuestCount = self.completedQuestCount + 1
            QuestCompleted(flowGotchiID: nft.id, address: nft.homeAddress, questID: questID)
            collectionRef.addBuddyResource(id)
            return <-create CompletedQuest(quest: self.quests[questID]!)
        }
        // Otherwise return nil
        return nil
    }

    init() {
        self.completedQuestCount = 0
        // TODO: Define and add initial quests here
        self.quests = {}
        self.QuestCompletionStoragePath = /storage/QuestCompletionAdmin
        self.QuestCompletionPrivatePath = /private/QuestCompletionAdmin

        emit ContractInitialized()

        self.account.save(<-create QuestCompletionAdmin(), to: self.QuestCompletionAdminStoragePath)
        self.account.link<&QuestCompletionAdmin>(self.QuestCompletionPrivatePath, target: self.QuestCompletionAdminStoragePath)
    }
}